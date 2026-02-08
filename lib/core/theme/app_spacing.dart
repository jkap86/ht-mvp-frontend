import 'package:flutter/material.dart';

/// Standardized spacing and dimension constants for consistent UI.
class AppSpacing {
  AppSpacing._();

  // Base spacing scale (4px base unit)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Border radius scale
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;

  // Common padding presets
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(sm);
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // Common border radius presets
  static final BorderRadius cardRadius = BorderRadius.circular(radiusLg);
  static final BorderRadius badgeRadius = BorderRadius.circular(radiusSm);
  static final BorderRadius buttonRadius = BorderRadius.circular(radiusMd);
  static final BorderRadius inputRadius = BorderRadius.circular(radiusMd);
}
