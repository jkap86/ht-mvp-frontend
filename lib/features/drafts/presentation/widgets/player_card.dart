import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../players/domain/player.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/position_badge.dart';
import '../../../../core/widgets/status_badge.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool isQueued;
  final bool isDrafted;
  final bool canDraft;
  final bool showDraftButton;
  final bool isSubmitting;
  final VoidCallback? onDraft;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onRemoveFromQueue;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.player,
    this.isQueued = false,
    this.isDrafted = false,
    this.canDraft = false,
    this.showDraftButton = true,
    this.isSubmitting = false,
    this.onDraft,
    this.onAddToQueue,
    this.onRemoveFromQueue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positionColor = getPositionColor(player.primaryPosition);

    return Opacity(
      opacity: isDrafted ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: isDrafted ? null : onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Position Badge
                PositionBadge(position: player.primaryPosition),
                const SizedBox(width: 12),

                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (player.injuryStatus != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: StatusBadge(
                                label: player.injuryStatus!,
                                backgroundColor: getInjuryColor(player.injuryStatus),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            player.playerType == 'college' && player.college != null
                                ? player.college!
                                : player.team ?? 'FA',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          if (player.team != null || player.college != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            Text(
                              player.primaryPosition,
                              style: TextStyle(
                                color: positionColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Projection Points
                if (player.remainingProjectedPts != null || player.priorSeasonPts != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (player.remainingProjectedPts ?? player.priorSeasonPts ?? 0).toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        player.remainingProjectedPts != null ? 'PROJ' : 'LAST YR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action Buttons
                if (!isDrafted) _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Queue Button
        if (onAddToQueue != null || onRemoveFromQueue != null)
          IconButton(
            icon: Icon(
              isQueued ? Icons.playlist_add_check : Icons.playlist_add,
              color: isQueued ? context.htColors.draftAction : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: isQueued ? onRemoveFromQueue : onAddToQueue,
            tooltip: isQueued ? 'Remove from queue' : 'Add to queue',
            visualDensity: VisualDensity.compact,
          ),

        // Draft Button
        if (showDraftButton && canDraft && onDraft != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.htColors.draftAction,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: context.htColors.draftAction.withAlpha(153),
                disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha(178),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.pillRadius,
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    )
                  : const Text(
                      'DRAFT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
            ),
          ),
      ],
    );
  }
}

