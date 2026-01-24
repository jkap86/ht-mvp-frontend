import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

class LineupSlotWidget extends StatelessWidget {
  final LineupSlot slot;
  final RosterPlayer? player;
  final bool isLocked;
  final VoidCallback? onTap;

  const LineupSlotWidget({
    super.key,
    required this.slot,
    this.player,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Slot badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSlotColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    slot.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Player info or empty state
              Expanded(
                child: player != null
                    ? _buildPlayerInfo(context)
                    : _buildEmptyState(context),
              ),

              // Points or lock icon
              if (isLocked)
                const Icon(Icons.lock, color: Colors.grey, size: 20)
              else if (player != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                player!.fullName ?? 'Unknown Player',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player!.injuryStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getInjuryColor(player!.injuryStatus),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  player!.injuryStatus!,
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
        Text(
          '${player!.position ?? "?"} - ${player!.team ?? "FA"}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Text(
      'Empty ${slot.displayName}',
      style: TextStyle(
        color: Colors.grey[400],
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
    );
  }

  Color _getSlotColor() {
    switch (slot) {
      case LineupSlot.qb:
        return Colors.red;
      case LineupSlot.rb:
        return Colors.green;
      case LineupSlot.wr:
        return Colors.blue;
      case LineupSlot.te:
        return Colors.orange;
      case LineupSlot.flex:
        return Colors.purple;
      case LineupSlot.k:
        return Colors.teal;
      case LineupSlot.def:
        return Colors.brown;
      case LineupSlot.bn:
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
