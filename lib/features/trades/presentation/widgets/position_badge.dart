import 'package:flutter/material.dart';

/// A badge displaying a player's position with color coding
class PositionBadge extends StatelessWidget {
  final String position;
  final double size;

  const PositionBadge({
    super.key,
    required this.position,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getPositionColor(position),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          position.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
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
      default:
        return Colors.grey;
    }
  }
}
