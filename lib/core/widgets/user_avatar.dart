import 'package:flutter/material.dart';

/// A reusable avatar widget that displays a user's initial.
/// Supports optional badges like commissioner badge.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool isHighlighted;
  final bool showCommissionerBadge;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.isHighlighted = false,
    this.showCommissionerBadge = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (isHighlighted ? Colors.indigo : Colors.grey[300]);
    final fgColor = textColor ??
        (isHighlighted ? Colors.white : Colors.black87);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: bgColor,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
          ),
        ),
        if (showCommissionerBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(
                Icons.star,
                size: size * 0.3,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
