import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';

/// Returns the industry-standard color for a given position.
/// These colors are optimized for visual distinction and accessibility.
Color getPositionColor(String position) {
  switch (position.toUpperCase()) {
    case 'QB':
      return AppTheme.positionQB;   // Pink/Magenta
    case 'RB':
      return AppTheme.positionRB;   // Teal
    case 'WR':
      return AppTheme.positionWR;   // Blue
    case 'TE':
      return AppTheme.positionTE;   // Orange
    case 'K':
      return AppTheme.positionK;    // Purple
    case 'DEF':
    case 'DST':
      return AppTheme.positionDEF;  // Brown
    case 'FLEX':
      return AppTheme.positionFLEX; // Blue-grey
    default:
      return AppTheme.positionFLEX; // Blue-grey for unknown
  }
}
