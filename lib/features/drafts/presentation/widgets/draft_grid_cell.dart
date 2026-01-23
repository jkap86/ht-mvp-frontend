import 'package:flutter/material.dart';

import '../../domain/draft_pick.dart';
import '../utils/position_colors.dart';

class DraftGridCell extends StatelessWidget {
  final DraftPick? pick;
  final bool isCurrentPick;
  final int pickNumber;

  const DraftGridCell({
    super.key,
    this.pick,
    this.isCurrentPick = false,
    required this.pickNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (pick == null) {
      return Container(
        width: 80,
        height: 52,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrentPick ? Colors.amber : Colors.grey.shade300,
            width: isCurrentPick ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isCurrentPick ? Colors.amber.shade50 : Colors.grey.shade50,
        ),
        child: Center(
          child: Text(
            '#$pickNumber',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      );
    }

    final positionColor = getPositionColor(pick!.playerPosition ?? '');

    return Container(
      width: 80,
      height: 52,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: positionColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
        color: positionColor.withValues(alpha: 0.15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pick!.playerName ?? 'Unknown',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: positionColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  pick!.playerPosition ?? '',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: positionColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  pick!.playerTeam ?? '',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
