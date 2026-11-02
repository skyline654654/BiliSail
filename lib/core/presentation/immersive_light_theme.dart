import 'package:flutter/material.dart';

import '../platform/harmony_system.dart';

/// Applies the「沉浸光感」treatment to every system surface the app renders.
///
/// The rules are deliberately narrow so the adaptation stays "一次开发多端部署":
///
/// 1. Only chrome layers (app bar, navigation bar/rail, sheets, dialogs, menu,
///    card) become translucent; content surfaces stay readable.
/// 2. Only documented [ThemeData] slots are overridden. Every system widget
///    keeps its own layout, semantics and behaviour — nothing is re-implemented
///    just to look glassy.
/// 3. Everything is gated by [HarmonySystem.supportsImmersiveLight]; on every
///    other platform this returns the theme unchanged.
///
/// The native shell owns the real backdrop (wallpaper, window blur). Flutter
/// only supplies the tint and the light sweep on top of it.
abstract final class ImmersiveLightTheme {
  /// Whether the immersive treatment is active for this build.
  static bool get enabled => HarmonySystem.supportsImmersiveLight;

  /// Tint alpha for chrome layers; low enough for the wallpaper to read through.
  static const double surfaceOpacity = 0.72;

  /// Returns [base] with the chrome layers translated to glass.
  static ThemeData apply(ThemeData base) {
    if (!enabled) return base;
    final scheme = base.colorScheme;
    final glass = scheme.surface.withValues(alpha: surfaceOpacity);
    final translucent = scheme.surface.withValues(alpha: 0);
    return base.copyWith(
      // The canvas gradient is painted by ImmersiveCanvas; every Scaffold in
      // between must stay transparent for it to show through.
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: glass,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: translucent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: glass,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: translucent,
        modalBackgroundColor: translucent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: glass,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: glass,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
