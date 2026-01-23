import 'package:flutter/material.dart';

import '../../../leagues/domain/league.dart';

class DraftStatusBar extends StatelessWidget {
  final Draft? draft;

  const DraftStatusBar({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final isInProgress = draft?.status == 'in_progress';
    final isCompleted = draft?.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(12),
      color: isInProgress ? Colors.green[50] : Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : isInProgress
                    ? Icons.play_circle
                    : Icons.hourglass_empty,
            color: isInProgress ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted
                ? 'Draft Complete'
                : isInProgress
                    ? 'Draft In Progress'
                    : 'Waiting to Start',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isInProgress ? Colors.green[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
