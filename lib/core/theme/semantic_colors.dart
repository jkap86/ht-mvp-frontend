import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';

/// Centralized color helper functions for semantic colors.
/// Use these instead of hardcoding colors in widgets.

/// Returns the industry-standard color for a given position.
/// These colors are optimized for visual distinction and accessibility.
Color getPositionColor(String? position) {
  switch (position?.toUpperCase()) {
    case 'QB':
      return AppTheme.positionQB;
    case 'RB':
      return AppTheme.positionRB;
    case 'WR':
      return AppTheme.positionWR;
    case 'TE':
      return AppTheme.positionTE;
    case 'K':
      return AppTheme.positionK;
    case 'DEF':
    case 'DST':
      return AppTheme.positionDEF;
    case 'FLEX':
      return AppTheme.positionFLEX;
    case 'SUPER_FLEX':
    case 'SUPERFLEX':
    case 'SF':
      return AppTheme.positionSuperFlex;
    case 'REC_FLEX':
      return AppTheme.positionRecFlex;
    case 'DL':
      return AppTheme.positionDL;
    case 'LB':
      return AppTheme.positionLB;
    case 'DB':
      return AppTheme.positionDB;
    case 'IDP_FLEX':
      return AppTheme.positionIdpFlex;
    case 'IR':
      return AppTheme.positionIR;
    case 'TAXI':
      return AppTheme.positionTaxi;
    case 'BN':
    case 'BENCH':
      return AppTheme.positionFLEX;
    case 'PICK':
      return AppTheme.positionPick;
    default:
      return AppTheme.positionFLEX;
  }
}

/// Returns the appropriate color for an injury status.
Color getInjuryColor(String? status) {
  switch (status?.toUpperCase()) {
    case 'OUT':
      return AppTheme.injuryOut;
    case 'DOUBTFUL':
      return AppTheme.injuryDoubtful;
    case 'QUESTIONABLE':
      return AppTheme.injuryQuestionable;
    case 'PROBABLE':
      return AppTheme.injuryProbable;
    case 'IR':
      return AppTheme.injuryOut;
    case 'PUP':
      return const Color(0xFF6E7681);
    default:
      return const Color(0xFF6E7681);
  }
}

/// Semantic colors for trade statuses.
class TradeStatusColors {
  TradeStatusColors._();

  static const Color pending = Color(0xFFFF9800);
  static const Color inReview = Color(0xFF1E88E5);
  static const Color completed = Color(0xFF43A047);
  static const Color failed = Color(0xFF9E9E9E);
}

/// Returns the appropriate color for a trade status.
Color getTradeStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'countered':
      return TradeStatusColors.pending;
    case 'accepted':
    case 'in_review':
    case 'inreview':
      return TradeStatusColors.inReview;
    case 'completed':
      return TradeStatusColors.completed;
    default:
      return TradeStatusColors.failed;
  }
}

/// Semantic colors for selection states.
class SelectionColors {
  SelectionColors._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFF9800);
}
