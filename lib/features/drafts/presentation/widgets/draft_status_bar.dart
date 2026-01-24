import 'package:flutter/material.dart';

import '../../../leagues/domain/league.dart';
import 'draft_timer_widget.dart';

class DraftStatusBar extends StatelessWidget {
  final Draft? draft;
  final String? currentPickerName;
  final bool isMyTurn;

  const DraftStatusBar({
    super.key,
    required this.draft,
    this.currentPickerName,
    this.isMyTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    final isInProgress = draft?.status.isActive ?? false;
    final isCompleted = draft?.status.isFinished ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isMyTurn ? Colors.green[100] : (isInProgress ? Colors.blue[50] : Colors.grey[100]),
      child: Row(
        children: [
          // Status icon and text
          Icon(
            isCompleted
                ? Icons.check_circle
                : isInProgress
                    ? Icons.play_circle
                    : Icons.hourglass_empty,
            color: isMyTurn ? Colors.green : (isInProgress ? Colors.blue : Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompleted
                      ? 'Draft Complete'
                      : isInProgress
                          ? (isMyTurn ? 'Your Turn!' : 'Draft In Progress')
                          : 'Waiting to Start',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMyTurn ? Colors.green[700] : (isInProgress ? Colors.blue[700] : Colors.grey[700]),
                  ),
                ),
                if (isInProgress && currentPickerName != null)
                  Text(
                    isMyTurn ? 'Make your pick' : 'Waiting for $currentPickerName',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Timer
          if (isInProgress && draft?.pickDeadline != null)
            DraftTimerWidget(
              pickDeadline: draft!.pickDeadline,
            ),
        ],
      ),
    );
  }
}
