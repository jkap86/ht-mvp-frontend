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
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    player!.injuryStatus!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${player!.position ?? ''} - ${player!.team ?? 'FA'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),

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
}
