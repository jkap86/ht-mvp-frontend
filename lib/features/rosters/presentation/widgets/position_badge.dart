import 'package:flutter/material.dart';
import 'package:hypetrain_mvp/config/app_theme.dart';

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

  static Color _getPositionColor(String? position) {
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
        return AppTheme.positionDEF;
      case 'FLEX':
        return AppTheme.positionFLEX;
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
      default:
        return Colors.grey;
    }
  }

  /// Get the position color for use in other widgets
  static Color getColor(String? position) => _getPositionColor(position);
}
