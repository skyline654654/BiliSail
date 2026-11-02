import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Where the bottom system bar / gesture indicator sits, in logical pixels.
///
/// ArkTS reports `avoidArea` in px; the bridge converts to logical pixels
/// before it crosses the channel so Dart never needs the device density.
final class HarmonyAvoidArea {
  const HarmonyAvoidArea({
    required this.bottom,
    required this.top,
    required this.sources,
  });

  static const HarmonyAvoidArea zero = HarmonyAvoidArea(
    bottom: 0,
    top: 0,
    sources: <String>{},
  );

  final double bottom;
  final double top;

  /// Which avoid-area types contributed, for diagnostics only:
  /// `system` (status bar + three-button navigation) and
  /// `navigationIndicator` (gesture bar, API 11+).
  final Set<String> sources;

  factory HarmonyAvoidArea.fromMap(Object? map) {
    if (map is! Map) return zero;
    double read(Object? value) => switch (value) {
      final num number => number.toDouble(),
      _ => 0,
    };
    final rawSources = map['sources'];
    return HarmonyAvoidArea(
      bottom: read(map['bottom']),
      top: read(map['top']),
      sources: rawSources is List
          ? rawSources.whereType<String>().toSet()
          : const <String>{},
    );
  }
}

/// What the installed ArkTS shell can actually do.
///
/// The native side answers this at startup; an older shell may answer with a
/// subset (or not answer at all), so every capability defaults to false.
final class HarmonyShellCapabilities {
  const HarmonyShellCapabilities({
    this.apiVersion = 0,
    this.hostsBottomBar = false,
    this.immersiveMaterial = false,
    this.immersiveWindow = false,
    this.avoidAreaStream = false,
  });

  static const HarmonyShellCapabilities none = HarmonyShellCapabilities();

  /// HarmonyOS API level reported by the shell; 0 when unknown.
  final int apiVersion;

  /// The ArkUI shell renders the workspace bottom bar itself, so Flutter must
  /// not draw its own.
  final bool hostsBottomBar;

  /// ArkUI `uiMaterial.ImmersiveMaterial` (`.systemMaterial()`, API 26+) is
  /// available. It is the platform's real「沉浸光感」implementation and only
  /// applies to ArkUI components, never to Flutter-rendered pixels.
  final bool immersiveMaterial;

  /// `window.setImmersiveModeEnabledState` (API 12+) is available.
  final bool immersiveWindow;

  /// `on('avoidAreaChange')` is wired up for live insets.
  final bool avoidAreaStream;

  factory HarmonyShellCapabilities.fromMap(Object? map) {
    if (map is! Map) return none;
    bool flag(String key) => map[key] == true;
    final version = map['apiVersion'];
    return HarmonyShellCapabilities(
      apiVersion: version is num ? version.toInt() : 0,
      hostsBottomBar: flag('hostsBottomBar'),
      immersiveMaterial: flag('immersiveMaterial'),
      immersiveWindow: flag('immersiveWindow'),
      avoidAreaStream: flag('avoidAreaStream'),
    );
  }
}

/// HarmonyOS interop for the pieces Flutter cannot express on its own.
///
/// The OpenHarmony Flutter engine keeps `Platform.operatingSystem` as `ohos`;
/// when that is not the case we fall back to asking the channel, so a shell
/// that renames the platform still gets the native integration.
abstract final class HarmonySystem {
  static const MethodChannel _channel = MethodChannel('bilisail/harmony_system');

  static const EventChannel _avoidAreaEvents = EventChannel(
    'bilisail/harmony_system/avoid_area',
  );

  /// Whether this build runs inside a HarmonyOS/OpenHarmony shell.
  static final bool isHarmonyOS = _detectHarmonyOS();

  static HarmonyShellCapabilities _capabilities = HarmonyShellCapabilities.none;

  /// The capabilities the shell reported; [none] until [attach] succeeds.
  static HarmonyShellCapabilities get capabilities => _capabilities;

  /// Whether ArkUI owns the bottom bar, so Flutter must not draw a second one.
  static bool get hostsBottomBar => _capabilities.hostsBottomBar;

  /// Queries the shell once at startup and caches the answer.
  ///
  /// Any platform error degrades to [HarmonyShellCapabilities.none], which
  /// keeps every non-HarmonyOS build on the Flutter-only path.
  static Future<HarmonyShellCapabilities> attach() async {
    if (!isHarmonyOS) return _capabilities = HarmonyShellCapabilities.none;
    try {
      final reply = await _channel.invokeMethod<Object?>('describe');
      _capabilities = HarmonyShellCapabilities.fromMap(reply);
    } on MissingPluginException {
      _capabilities = HarmonyShellCapabilities.none;
    } on PlatformException {
      _capabilities = HarmonyShellCapabilities.none;
    }
    return _capabilities;
  }

  /// Enables window-level immersion (`setImmersiveModeEnabledState`, API 12+).
  ///
  /// This is the window switch; it is not the same as hiding the system bars,
  /// which `setWindowSystemBarEnable` only applies while the window is
  /// full-screen or maximised.
  static Future<void> applyImmersiveLayout() async {
    if (!_capabilities.immersiveWindow) return;
    await _invokeSafely<void>('applyImmersiveLayout');
  }

  /// Reads the current bottom/top avoid area once.
  static Future<HarmonyAvoidArea> queryAvoidArea() async {
    if (!isHarmonyOS) return HarmonyAvoidArea.zero;
    final reply = await _invokeSafely<Object?>('queryAvoidArea');
    return HarmonyAvoidArea.fromMap(reply);
  }

  /// Live avoid-area updates. Empty when the shell cannot subscribe.
  ///
  /// `avoidAreaChange` fires on rotation, fold/unfold, split-screen and
  /// full-screen switches, so the bottom bar can re-lay itself out instead of
  /// trusting a value captured at startup.
  static Stream<HarmonyAvoidArea> get avoidAreaChanges {
    if (!_capabilities.avoidAreaStream) return const Stream.empty();
    return _avoidAreaEvents.receiveBroadcastStream().map(
      (event) => HarmonyAvoidArea.fromMap(event),
    );
  }

  /// Asks the shell for the bottom safe-area height below the gesture bar.
  static Future<double> bottomAvoidHeight() async =>
      (await queryAvoidArea()).bottom;

  static Future<T?> _invokeSafely<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static bool _detectHarmonyOS() {
    try {
      return Platform.operatingSystem == 'ohos';
    } on UnsupportedError {
      return false;
    }
  }
}
