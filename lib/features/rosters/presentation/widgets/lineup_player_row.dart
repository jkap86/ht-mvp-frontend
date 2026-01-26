import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import 'position_badge.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
                          color: Colors.grey.shade500,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: _getInjuryColor(player!.injuryStatus),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    player!.injuryStatus!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
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
                                '${player!.position ?? ''} - ${player!.team ?? 'FA'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (player!.byeWeek != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BYE ${player!.byeWeek}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
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

              // Projected points
              if (player != null && player!.projectedPoints != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player!.projectedPoints!.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      'PROJ',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],

              // Swap indicator
              if (!isLocked)
                Icon(
                  Icons.swap_horiz,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
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
