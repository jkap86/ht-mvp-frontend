import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import '../../domain/roster_player.dart';

/// Shows a bottom sheet to select a player to drop when adding a new player
/// to a full roster.
void showAddDropPlayerSheet({
  required BuildContext context,
  required Player addPlayer,
  required List<RosterPlayer> rosterPlayers,
  required Future<bool> Function(int dropPlayerId) onDropSelected,
  VoidCallback? onSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _AddDropPlayerSheet(
        addPlayer: addPlayer,
        rosterPlayers: rosterPlayers,
        onDropSelected: onDropSelected,
        onSuccess: onSuccess,
      );
    },
  );
}

class _AddDropPlayerSheet extends StatelessWidget {
  final Player addPlayer;
  final List<RosterPlayer> rosterPlayers;
  final Future<bool> Function(int dropPlayerId) onDropSelected;
  final VoidCallback? onSuccess;

  const _AddDropPlayerSheet({
    required this.addPlayer,
    required this.rosterPlayers,
    required this.onDropSelected,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Player to Drop',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your roster is full. Select a player to drop to add ${addPlayer.fullName}.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: rosterPlayers.length,
                itemBuilder: (context, index) {
                  final dropPlayer = rosterPlayers[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPositionColor(dropPlayer.position),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          dropPlayer.position ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    title: Text(dropPlayer.fullName ?? 'Unknown'),
                    subtitle: Text(dropPlayer.team ?? 'FA'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final success = await onDropSelected(dropPlayer.playerId);
                      if (success) {
                        onSuccess?.call();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
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
}
