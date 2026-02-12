import 'package:flutter/material.dart';

/// A bar that always shows the "last updated" timestamp, with a stale
/// warning when data is older than 5 minutes.
///
/// Follows the same visual pattern as the matchup screen's freshness bar
/// for consistency across the app.
///
/// Usage:
/// ```dart
/// DataFreshnessBar(
///   lastUpdatedDisplay: state.lastUpdatedDisplay,
///   isStale: state.isStale,
///   label: 'Live Draft',      // optional context label on the left
///   labelIcon: Icons.circle,  // optional icon for the label
/// )
/// ```
class DataFreshnessBar extends StatelessWidget {
  /// Human-readable string like "Updated just now" or "Updated 3m ago".
  /// When empty the bar is hidden.
  final String lastUpdatedDisplay;

  /// Whether the data is considered stale (>5 min).
  final bool isStale;

  /// Optional context label shown on the left side of the bar.
  final String? label;

  /// Optional icon for the context label.
  final IconData? labelIcon;

  /// Optional color override for the label.
  final Color? labelColor;

  const DataFreshnessBar({
    super.key,
    required this.lastUpdatedDisplay,
    required this.isStale,
    this.label,
    this.labelIcon,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show bar if we have no data yet and no label
    if (lastUpdatedDisplay.isEmpty && label == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Row(
        children: [
          // Context label
          if (label != null) ...[
            if (labelIcon != null) ...[
              Icon(
                labelIcon,
                size: 14,
                color: labelColor ?? colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: labelColor ?? colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          // Last updated timestamp
          if (lastUpdatedDisplay.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStale)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: colorScheme.error,
                    ),
                  ),
                Text(
                  lastUpdatedDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: isStale
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
