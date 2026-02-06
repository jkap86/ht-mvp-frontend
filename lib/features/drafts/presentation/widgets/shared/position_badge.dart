import 'package:flutter/material.dart';

import '../../utils/position_colors.dart';

/// Reusable position badge widget used across auction lot cards and player cards.
/// Displays a colored badge with the player's position abbreviation.
class PositionBadge extends StatelessWidget {
  final String position;
  final double size;

  const PositionBadge({
    super.key,
    required this.position,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final positionColor = getPositionColor(position);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: positionColor.withAlpha(isDark ? 50 : 35),
        borderRadius: BorderRadius.circular(size * 0.23),
        border: Border.all(
          color: positionColor.withAlpha(isDark ? 100 : 70),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          position,
          style: TextStyle(
            color: positionColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
