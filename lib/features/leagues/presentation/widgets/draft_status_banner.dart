import 'package:flutter/material.dart';

import '../../domain/league.dart';

class DraftStatusBanner extends StatelessWidget {
  final Draft draft;
  final bool isCommissioner;
  final VoidCallback onJoinDraft;
  final VoidCallback onStartDraft;

  const DraftStatusBanner({
    super.key,
    required this.draft,
    required this.isCommissioner,
    required this.onJoinDraft,
    required this.onStartDraft,
  });

  bool get _isLive => draft.status.isActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _isLive ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isLive ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isLive ? Icons.live_tv : Icons.event,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLive ? 'Draft Live' : 'Draft Ready',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isLive ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLive
                        ? 'Round ${draft.currentRound ?? 1}, Pick ${draft.currentPick ?? 1}'
                        : 'Waiting for commissioner to start',
                    style: TextStyle(
                      color: _isLive ? Colors.green.shade700 : Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isLive ? onJoinDraft : (isCommissioner ? onStartDraft : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLive ? Colors.green : Colors.orange,
              ),
              child: Text(
                _isLive ? 'Join' : (isCommissioner ? 'Start' : 'Waiting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
