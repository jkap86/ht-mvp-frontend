import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../players/domain/player.dart';
import '../utils/position_colors.dart';
import 'shared/position_badge.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool isQueued;
  final bool isDrafted;
  final bool canDraft;
  final bool showDraftButton;
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
          borderRadius: BorderRadius.circular(12),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: _getInjuryColor(player.injuryStatus),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                player.injuryStatus!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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
              color: isQueued ? AppTheme.draftActionPrimary : theme.colorScheme.onSurfaceVariant,
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
              onPressed: onDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.draftActionPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'DRAFT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Color _getInjuryColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'OUT':
        return AppTheme.injuryOut;
      case 'DOUBTFUL':
        return AppTheme.injuryDoubtful.withAlpha(200);
      case 'QUESTIONABLE':
        return AppTheme.injuryQuestionable;
      case 'PROBABLE':
        return AppTheme.injuryProbable.withAlpha(180);
      case 'IR':
        return AppTheme.injuryOut;
      case 'PUP':
        return const Color(0xFF6E7681);
      default:
        return const Color(0xFF6E7681);
    }
  }
}

