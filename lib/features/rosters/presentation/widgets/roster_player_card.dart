import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

class RosterPlayerCard extends StatelessWidget {
  final RosterPlayer player;
  final bool showSlot;
  final LineupSlot? currentSlot;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onDrop;

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
    final card = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : isHighlighted
                ? const BorderSide(color: Colors.green, width: 2)
                : BorderSide.none,
      ),
      color: isSelected
          ? Colors.blue.shade50
          : isHighlighted
              ? Colors.green.shade50
              : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Position badge (compact)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position),
                  borderRadius: BorderRadius.circular(6),
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
              const SizedBox(width: 8),

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
                              fontSize: 14,
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
                        fontSize: 14,
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
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDrop?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.red,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Drop',
                style: TextStyle(
                  color: Colors.white,
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
