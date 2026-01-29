import 'package:flutter/material.dart';

import '../../domain/draft_pick.dart';
import '../utils/position_colors.dart';

/// Individual roster slot showing a drafted player or empty slot.
class RosterSlot extends StatelessWidget {
  final DraftPick? pick;
  final String position;

  const RosterSlot({
    super.key,
    required this.pick,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final color = pick != null
        ? getPositionColor(pick!.playerPosition ?? position)
        : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pick != null ? color.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pick != null ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: pick != null ? _buildFilledSlot(color) : _buildEmptySlot(),
    );
  }

  Widget _buildFilledSlot(Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              pick!.playerPosition ?? '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pick!.playerName ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${pick!.playerTeam ?? 'FA'} • Pick #${pick!.pickNumber}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySlot() {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Empty',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
