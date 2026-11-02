import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../platform/harmony_system.dart';

/// The translucent「沉浸光感」material used behind the bottom bar.
///
/// HarmonyOS renders this itself when [HarmonySystem.supportsImmersiveLight];
/// elsewhere the same geometry is reproduced with a backdrop blur and a light
/// sweep so every platform keeps one visual language ("一次开发多端部署"),
/// only the fidelity of the blur differs.
class ImmersiveLightSurface extends StatelessWidget {
  const ImmersiveLightSurface({
    super.key,
    required this.child,
    this.opacity = 0.72,
    this.blurSigma = 20,
    this.showTopEdge = true,
  });

  final Widget child;

  /// Background tint alpha; keep it low enough to read the content behind.
  final double opacity;

  /// Backdrop blur radius in logical pixels. Ignored when the user asked for
  /// reduced transparency via the platform accessibility switch.
  final double blurSigma;

  /// Draws the hairline highlight that separates the bar from the content.
  final bool showTopEdge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceTransparency = MediaQuery.disableAnimationsOf(context);
    final blur = reduceTransparency ? 0.0 : blurSigma;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: opacity),
            border: showTopEdge
                ? Border(
                    top: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surfaceContainerHighest.withValues(alpha: 0.24),
                colors.surface.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
