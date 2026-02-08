import 'package:flutter/material.dart';

/// Standardized typography constants for consistent text styling.
class AppTypography {
  AppTypography._();

  // Font size scale
  static const double fontXs = 10;
  static const double fontSm = 12;
  static const double fontMd = 14;
  static const double fontLg = 16;
  static const double fontXl = 18;
  static const double fontXxl = 20;

  // Pre-built text styles (use copyWith to apply colors from theme)
  static const TextStyle label = TextStyle(
    fontSize: fontXs,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: fontXs,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSm,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontMd,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: fontMd,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle title = TextStyle(
    fontSize: fontLg,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: fontXl,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headline = TextStyle(
    fontSize: fontXxl,
    fontWeight: FontWeight.bold,
  );
}
