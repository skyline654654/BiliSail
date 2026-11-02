import 'package:flutter/material.dart';

import 'immersive_light_surface.dart';

/// Paints the app-wide「沉浸光感」backdrop behind every route.
///
/// Installed once in `MaterialApp.builder`, so every page, sheet and dialog
/// shares the same light direction without touching individual screens. When
/// [enabled] is false it degrades to the plain canvas colour, which keeps the
/// non-HarmonyOS builds byte-for-byte identical to upstream.
class ImmersiveCanvas extends StatelessWidget {
  const ImmersiveCanvas({
    super.key,
    required this.canvasColor,
    required this.child,
    required this.enabled,
  });

  /// The platform's original scaffold colour; painted under the gradient so
  /// content contrast never depends on the wallpaper.
  final Color canvasColor;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return ColoredBox(color: canvasColor, child: child);
    }
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: canvasColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.45, 1],
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            canvasColor,
            scheme.surface.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Marks the region whose content should be blurred behind a glass surface.
///
/// Using the app-level canvas keeps a single blur source: sheets and dialogs
/// reuse [ImmersiveLightSurface] and sample whatever sits underneath.
class ImmersiveGlassLayer extends StatelessWidget {
  const ImmersiveGlassLayer({
    super.key,
    required this.child,
    this.opacity = 0.72,
    this.blurSigma = 24,
  });

  final Widget child;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) => ImmersiveLightSurface(
    opacity: opacity,
    blurSigma: blurSigma,
    showTopEdge: false,
    child: child,
  );
}
