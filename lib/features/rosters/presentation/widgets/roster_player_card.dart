import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

class RosterPlayerCard extends StatelessWidget {
  final RosterPlayer player;
  final bool showSlot;
  final LineupSlot? currentSlot;
  final bool showActions;
  final VoidCallback? onMove;
  final VoidCallback? onDrop;

  const RosterPlayerCard({
    super.key,
    required this.player,
    this.showSlot = false,
    this.currentSlot,
    this.showActions = false,
    this.onMove,
    this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: showActions ? onMove : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    player.position ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                          player.team ?? 'FA',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (showSlot && currentSlot != null) ...[
                          const Text(' - '),
                          Text(
                            currentSlot!.code,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (player.byeWeek != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BYE ${player.byeWeek}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          player.acquiredType.displayName,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Projected Points
              if (player.projectedPoints != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      player.projectedPoints!.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      'PROJ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              if (showActions) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'move':
                        onMove?.call();
                        break;
                      case 'drop':
                        onDrop?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 20),
                          SizedBox(width: 8),
                          Text('Move'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'drop',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Drop', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String? position) {
    switch (position?.toUpperCase()) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
        return Colors.brown;
      default:
        return Colors.grey;
    }
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
