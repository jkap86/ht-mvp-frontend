import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';
import '../theme/app_spacing.dart';

/// A badge displaying a player position with color coding.
/// Uses semantic position colors from AppTheme.
class PositionBadge extends StatelessWidget {
  final String? position;
  final double size;

  const PositionBadge({
    super.key,
    this.position,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final positionColor = getPositionColor(position);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: positionColor.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: positionColor.withAlpha(85),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          position ?? '?',
          style: TextStyle(
            color: positionColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }

  /// Get the position color for use in other widgets.
  static Color getColor(String? position) => getPositionColor(position);
}
