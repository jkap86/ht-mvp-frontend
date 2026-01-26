import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import '../utils/position_colors.dart';

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
                _PositionBadge(
                  position: player.primaryPosition,
                  color: positionColor,
                ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            player.team ?? 'FA',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          if (player.team != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            Text(
                              player.primaryPosition,
                              style: TextStyle(
                                color: positionColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (player.remainingProjectedPts ?? player.priorSeasonPts ?? 0).toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        player.remainingProjectedPts != null ? 'PROJ' : 'LAST YR',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Queue Button
        if (onAddToQueue != null || onRemoveFromQueue != null)
          IconButton(
            icon: Icon(
              isQueued ? Icons.playlist_add_check : Icons.playlist_add,
              color: isQueued ? Colors.green : Colors.grey,
            ),
            onPressed: isQueued ? onRemoveFromQueue : onAddToQueue,
            tooltip: isQueued ? 'Remove from queue' : 'Add to queue',
            visualDensity: VisualDensity.compact,
          ),

        // Draft Button
        if (showDraftButton && canDraft && onDraft != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ElevatedButton(
              onPressed: onDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
        return Colors.red;
      case 'DOUBTFUL':
        return Colors.red.shade300;
      case 'QUESTIONABLE':
        return Colors.orange;
      case 'PROBABLE':
        return Colors.yellow.shade700;
      case 'IR':
        return Colors.red.shade900;
      case 'PUP':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class _PositionBadge extends StatelessWidget {
  final String position;
  final Color color;

  const _PositionBadge({
    required this.position,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          position,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
