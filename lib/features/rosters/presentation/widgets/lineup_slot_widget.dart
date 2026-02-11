import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

class LineupSlotWidget extends StatelessWidget {
  final LineupSlot slot;
  final RosterPlayer? player;
  final bool isLocked;
  final bool isSelected;
  final bool isHighlighted;
  final bool isOneWayHighlight;
  final VoidCallback? onTap;

  const LineupSlotWidget({
    super.key,
    required this.slot,
    this.player,
    this.isLocked = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isOneWayHighlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: isSelected
            ? BorderSide(color: context.htColors.info, width: 2)
            : isHighlighted
                ? BorderSide(color: context.htColors.success, width: 2)
                : isOneWayHighlight
                    ? BorderSide(color: context.htColors.warning, width: 2)
                    : BorderSide.none,
      ),
      color: isSelected
          ? context.htColors.selectionPrimary
          : isHighlighted
              ? context.htColors.selectionSuccess
              : isOneWayHighlight
                  ? context.htColors.selectionWarning
                  : null,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.cardPaddingCompact,
          child: Row(
            children: [
              // Slot badge (compact)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getSlotColor(),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                ),
                child: Center(
                  child: Text(
                    slot.code,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.fontSm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Player info or empty state
              Expanded(
                child: player != null
                    ? _buildPlayerInfo(context)
                    : _buildEmptyState(context),
              ),

              // Points or lock icon
              if (isLocked)
                Icon(Icons.lock, color: theme.colorScheme.onSurfaceVariant, size: 20)
              else if (player != null) ...[
                if (player!.projectedPoints != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player!.projectedPoints!.toStringAsFixed(1),
                        style: AppTypography.bodyBold.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        'PROJ',
                        style: AppTypography.label.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                player!.fullName ?? 'Unknown Player',
                style: AppTypography.bodyBold.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player!.injuryStatus != null)
              StatusBadge(
                label: player!.injuryStatus!,
                backgroundColor: getInjuryColor(player!.injuryStatus),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${player!.position ?? "?"} - ${player!.team ?? "FA"}',
              style: AppTypography.body.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (player!.byeWeek != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'BYE ${player!.byeWeek}',
                  style: AppTypography.label.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Empty',
      style: AppTypography.title.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Color _getSlotColor() {
    switch (slot) {
      case LineupSlot.qb:
        return AppTheme.positionQB;
      case LineupSlot.rb:
        return AppTheme.positionRB;
      case LineupSlot.wr:
        return AppTheme.positionWR;
      case LineupSlot.te:
        return AppTheme.positionTE;
      case LineupSlot.flex:
        return AppTheme.positionFLEX;
      case LineupSlot.superFlex:
        return AppTheme.positionSuperFlex;
      case LineupSlot.recFlex:
        return AppTheme.positionRecFlex;
      case LineupSlot.k:
        return AppTheme.positionK;
      case LineupSlot.def:
        return AppTheme.positionDEF;
      case LineupSlot.dl:
        return AppTheme.positionDL;
      case LineupSlot.lb:
        return AppTheme.positionLB;
      case LineupSlot.db:
        return AppTheme.positionDB;
      case LineupSlot.idpFlex:
        return AppTheme.positionIdpFlex;
      case LineupSlot.bn:
        return AppTheme.positionFLEX;
      case LineupSlot.ir:
        return AppTheme.positionIR;
      case LineupSlot.taxi:
        return AppTheme.positionTaxi;
    }
  }
}
