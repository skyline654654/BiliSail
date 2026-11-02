import 'package:flutter/material.dart';

import '../core/platform/harmony_system.dart';
import '../core/presentation/immersive_light_surface.dart';

/// One destination slot in the workspace bottom bar.
///
/// Selection is carried per item instead of by index so the centre action does
/// not shift destination indices when the section list changes between the
/// compact and the wide layout.
final class WorkspaceBottomBarItem {
  const WorkspaceBottomBarItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onSelected,
  });

  /// Stable identifier; the widget key is derived from it so widget tests keep
  /// addressing `workspace-bottom-<id>` as before.
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onSelected;
}

/// The Bilibili-style bottom bar: primary destinations with a raised centre
/// action that starts a creation flow.
///
/// The centre slot is always laid out, even when the section list is short, so
/// the plus keeps its place across breakpoints and the bar never reflows when a
/// destination appears or disappears.
class WorkspaceBottomBar extends StatelessWidget {
  const WorkspaceBottomBar({
    super.key,
    required this.items,
    required this.createLabel,
    required this.onCreate,
    this.height = 52,
    this.iconSize = 16,
    this.labelStyle = const TextStyle(fontSize: 11, height: 1.2),
    this.immersive,
  });

  final List<WorkspaceBottomBarItem> items;
  final String createLabel;
  final VoidCallback onCreate;
  final double height;
  final double iconSize;
  final TextStyle labelStyle;

  /// When true the bar paints the「沉浸光感」material under the destinations.
  /// Null means "decide from the platform capabilities at build time"; it has to
  /// stay nullable because a default argument must be a compile-time constant.
  final bool? immersive;

  static const double _createSlotWidth = 64;
  static const double _createButtonSize = 40;

  /// The centre slot sits at the midpoint of the destination row.
  int get _createIndex => items.length ~/ 2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final barTheme = NavigationBarTheme.of(context);
    final useImmersive = immersive ?? HarmonySystem.supportsImmersiveLight;
    final content = SafeArea(
      top: false,
      child: SizedBox(height: height, child: _destinationRow(context)),
    );
    return Material(
      key: const ValueKey('workspace-bottom-navigation'),
      color: Colors.transparent,
      child: useImmersive
          ? ImmersiveLightSurface(child: content)
          : ColoredBox(
              color: barTheme.backgroundColor ?? colors.surface,
              child: content,
            ),
    );
  }

  Widget _destinationRow(BuildContext context) => Row(
    children: [
      for (var index = 0; index <= items.length; index++) ...[
        if (index == _createIndex) _createSlot(context),
        if (index < items.length)
          Expanded(child: _destinationSlot(context, items[index])),
      ],
    ],
  );

  Widget _destinationSlot(BuildContext context, WorkspaceBottomBarItem item) {
    final colors = Theme.of(context).colorScheme;
    final color = item.selected ? colors.onSurface : colors.onSurfaceVariant;
    return Tooltip(
      message: item.label,
      child: Semantics(
        selected: item.selected,
        button: true,
        label: item.label,
        child: InkWell(
          key: ValueKey('workspace-bottom-${item.id}'),
          onTap: item.onSelected,
          child: Center(
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Keep NavigationDestination's indicator slot even when no
                  // primary destination is selected, so labels do not jump.
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const NavigationIndicator(
                        animation: kAlwaysDismissedAnimation,
                      ),
                      Icon(
                        item.selected ? item.selectedIcon : item.icon,
                        size: iconSize,
                        color: color,
                      ),
                    ],
                  ),
                  MediaQuery.withClampedTextScaling(
                    // Match NavigationDestination's label limit.
                    maxScaleFactor: 1.3,
                    child: Text(
                      item.label,
                      style: labelStyle.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _createSlot(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: _createSlotWidth,
      child: Center(
        child: Tooltip(
          message: createLabel,
          child: Semantics(
            button: true,
            label: createLabel,
            child: Material(
              color: colors.primary,
              elevation: 2,
              shape: const CircleBorder(),
              child: InkWell(
                key: const ValueKey('workspace-bottom-create'),
                customBorder: const CircleBorder(),
                onTap: onCreate,
                child: SizedBox(
                  width: _createButtonSize,
                  height: _createButtonSize,
                  child: Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}