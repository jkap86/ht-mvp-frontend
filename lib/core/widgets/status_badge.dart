import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Reusable badge widget for status indicators (injury, draft status, etc.)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.badgePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.badgeRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
