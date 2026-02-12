import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Drag handle for DraggableScrollableSheet.
///
/// Provides a visual affordance (pill-shaped indicator), a label, and an
/// up-arrow icon to clearly signal that the drawer can be expanded.
/// Supports optional tap-to-toggle functionality.
class DrawerDragHandle extends StatelessWidget {
  /// Called when the handle is tapped.
  final VoidCallback? onTap;

  /// Label displayed below the handle pill (e.g. "Players & Queue").
  /// When null, only the pill is shown.
  final String? label;

  /// Whether the drawer is currently expanded. Controls the direction of the
  /// chevron icon (up when collapsed, down when expanded).
  final bool isExpanded;

  const DrawerDragHandle({
    super.key,
    this.onTap,
    this.label,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill-shaped drag indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
