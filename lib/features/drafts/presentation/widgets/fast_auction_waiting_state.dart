import 'package:flutter/material.dart';

/// Widget shown when waiting for nomination in fast auction mode.
class FastAuctionWaitingState extends StatelessWidget {
  final bool isMyNomination;
  final VoidCallback onNominateTap;

  const FastAuctionWaitingState({
    super.key,
    required this.isMyNomination,
    required this.onNominateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            isMyNomination ? Icons.person_add : Icons.hourglass_empty,
            size: 32,
            color: Colors.deepPurple[300],
          ),
          const SizedBox(height: 8),
          Text(
            isMyNomination
                ? 'Select a player to nominate'
                : 'Waiting for nomination...',
            style: TextStyle(
              color: Colors.deepPurple[400],
              fontSize: 14,
            ),
          ),
          if (isMyNomination) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onNominateTap,
              icon: const Icon(Icons.add),
              label: const Text('Nominate Player'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
