import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/position_badge.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

/// A row displaying a player in a lineup slot
class LineupPlayerRow extends StatelessWidget {
  final LineupSlot slot;
  final int slotIndex;
  final RosterPlayer? player;
  final bool isLocked;
  final VoidCallback? onTap;

  const LineupPlayerRow({
    super.key,
    required this.slot,
    required this.slotIndex,
    this.player,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = player == null;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              PositionBadge(position: slot.code),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: isEmpty
                    ? Text(
                        'Empty ${slot.displayName}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player!.fullName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (player!.injuryStatus != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: StatusBadge(
                                    label: player!.injuryStatus!,
                                    backgroundColor: getInjuryColor(player!.injuryStatus),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${player!.position ?? ''} - ${player!.team ?? 'FA'}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              if (player!.byeWeek != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: AppSpacing.badgeRadius,
                                  ),
                                  child: Text(
                                    'BYE ${player!.byeWeek}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
              ),

              // Projected points - larger and more prominent
              if (player != null && player!.projectedPoints != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.buttonRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player!.projectedPoints!.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        'PROJ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Swap indicator
              if (!isLocked)
                Icon(
                  Icons.swap_horiz,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
