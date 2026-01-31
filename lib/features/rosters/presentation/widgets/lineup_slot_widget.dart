import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

class LineupSlotWidget extends StatelessWidget {
  final LineupSlot slot;
  final RosterPlayer? player;
  final bool isLocked;
  final bool isSelected;
  final bool isHighlighted;
  final bool isOneWayHighlight;
  final VoidCallback? onTap;

  const LineupSlotWidget({
    super.key,
    required this.slot,
    this.player,
    this.isLocked = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isOneWayHighlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : isHighlighted
                ? const BorderSide(color: Colors.green, width: 2)
                : isOneWayHighlight
                    ? const BorderSide(color: Colors.orange, width: 2)
                    : BorderSide.none,
      ),
      color: isSelected
          ? Colors.blue.shade50
          : isHighlighted
              ? Colors.green.shade50
              : isOneWayHighlight
                  ? Colors.orange.shade50
                  : null,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Slot badge (compact)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getSlotColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    slot.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Player info or empty state
              Expanded(
                child: player != null
                    ? _buildPlayerInfo(context)
                    : _buildEmptyState(context),
              ),

              // Points or lock icon
              if (isLocked)
                const Icon(Icons.lock, color: Colors.grey, size: 20)
              else if (player != null) ...[
                if (player!.projectedPoints != null)
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
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
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
                  fontSize: 14,
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
        Row(
          children: [
            Text(
              '${player!.position ?? "?"} - ${player!.team ?? "FA"}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Text(
      'Empty',
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
      case LineupSlot.superFlex:
        return Colors.deepPurple;
      case LineupSlot.recFlex:
        return Colors.cyan;
      case LineupSlot.k:
        return Colors.teal;
      case LineupSlot.def:
        return Colors.brown;
      case LineupSlot.dl:
        return Colors.brown.shade800;
      case LineupSlot.lb:
        return Colors.brown.shade600;
      case LineupSlot.db:
        return Colors.brown.shade400;
      case LineupSlot.idpFlex:
        return Colors.brown;
      case LineupSlot.bn:
        return Colors.grey;
      case LineupSlot.ir:
        return Colors.grey.shade600;
      case LineupSlot.taxi:
        return Colors.amber;
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
