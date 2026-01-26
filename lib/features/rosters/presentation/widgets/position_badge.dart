import 'package:flutter/material.dart';

/// A badge displaying a player position with color coding
class PositionBadge extends StatelessWidget {
  final String? position;
  final double size;

  const PositionBadge({
    super.key,
    this.position,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPositionColor(position);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          position ?? '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String? position) {
    switch (position?.toUpperCase()) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
        return Colors.brown;
      case 'FLEX':
        return Colors.teal;
      case 'BN':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
