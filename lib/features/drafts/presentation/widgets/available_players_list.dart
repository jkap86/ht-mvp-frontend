import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import 'package:hypetrain_mvp/features/drafts/presentation/utils/position_colors.dart';

class AvailablePlayersList extends StatelessWidget {
  final List<Player> players;
  final bool isDraftInProgress;
  final void Function(int playerId)? onDraftPlayer;

  const AvailablePlayersList({
    super.key,
    required this.players,
    required this.isDraftInProgress,
    this.onDraftPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: getPositionColor(player.primaryPosition),
            child: Text(
              player.primaryPosition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(player.fullName),
          subtitle: Text('${player.team ?? 'FA'} - ${player.primaryPosition}'),
          trailing: isDraftInProgress && onDraftPlayer != null
              ? ElevatedButton(
                  onPressed: () => onDraftPlayer!(player.id),
                  child: const Text('Draft'),
                )
              : null,
        );
      },
    );
  }
}
