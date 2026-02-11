import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

class RosterPlayerCard extends StatelessWidget {
  final RosterPlayer player;
  final bool showSlot;
  final LineupSlot? currentSlot;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final Future<bool> Function()? onDrop;

  const RosterPlayerCard({
    super.key,
    required this.player,
    this.showSlot = false,
    this.currentSlot,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positionColor = getPositionColor(player.position);

    final card = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: isSelected
            ? BorderSide(color: SelectionColors.primary, width: 2)
            : isHighlighted
                ? BorderSide(color: SelectionColors.success, width: 2)
                : BorderSide.none,
      ),
      color: isSelected
          ? SelectionColors.primary.withAlpha(isDark ? 30 : 20)
          : isHighlighted
              ? SelectionColors.success.withAlpha(isDark ? 30 : 20)
              : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.cardPaddingCompact,
          child: Row(
            children: [
              // Position badge (compact)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: positionColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                ),
                child: Center(
                  child: Text(
                    player.position ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.fontSm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.fullName ?? 'Unknown Player',
                            style: AppTypography.bodyBold.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.injuryStatus != null)
                          StatusBadge(
                            label: player.injuryStatus!,
                            backgroundColor: getInjuryColor(player.injuryStatus),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          player.team ?? 'FA',
                          style: AppTypography.body.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (showSlot && currentSlot != null) ...[
                          const Text(' - '),
                          Text(
                            currentSlot!.code,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (player.byeWeek != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'BYE ${player.byeWeek}',
                              style: AppTypography.label.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Projected Points
              if (player.projectedPoints != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      player.projectedPoints!.toStringAsFixed(1),
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
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Wrap in Dismissible for swipe-to-drop if onDrop is provided
    if (onDrop != null) {
      return Dismissible(
        key: Key('player-${player.playerId}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onDrop!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          color: AppTheme.errorColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete, color: theme.colorScheme.onError),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Drop',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}
