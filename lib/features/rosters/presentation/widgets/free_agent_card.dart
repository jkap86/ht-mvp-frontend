import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';

class FreeAgentCard extends StatelessWidget {
  final Player player;
  final bool isAdding;
  final bool isOnWaiverWire;
  final VoidCallback onAdd;

  const FreeAgentCard({
    super.key,
    required this.player,
    required this.isAdding,
    this.isOnWaiverWire = false,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                          player.fullName,
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
                  Text(
                    player.team ?? 'Free Agent',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Add/Claim button
            const SizedBox(width: 8),
            if (isAdding)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isOnWaiverWire)
              // Show "Claim" chip for waiver wire players
              ActionChip(
                avatar: const Icon(Icons.access_time, size: 18),
                label: const Text('Claim'),
                onPressed: onAdd,
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
                onPressed: onAdd,
              ),
          ],
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
      default:
        return Colors.grey;
    }
  }
}
