import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import 'package:hypetrain_mvp/core/theme/semantic_colors.dart';

class AvailablePlayersList extends StatelessWidget {
  final List<Player> players;
  final bool isDraftInProgress;
  final bool isMyTurn;
  final void Function(int playerId)? onDraftPlayer;
  final void Function(int playerId)? onAddToQueue;
  final Set<int> queuedPlayerIds;
  final ScrollController? scrollController;

  const AvailablePlayersList({
    super.key,
    required this.players,
    required this.isDraftInProgress,
    this.isMyTurn = false,
    this.onDraftPlayer,
    this.onAddToQueue,
    this.queuedPlayerIds = const {},
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
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
          trailing: _buildTrailingButtons(player),
        );
      },
    );
  }

  Widget? _buildTrailingButtons(Player player) {
    final isInQueue = queuedPlayerIds.contains(player.id);

    if (!isDraftInProgress) {
      // Before draft starts - only show queue button
      if (onAddToQueue == null) return null;
      return IconButton(
        icon: Icon(
          isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
          color: isInQueue ? Colors.green : null,
        ),
        onPressed: isInQueue ? null : () => onAddToQueue!(player.id),
        tooltip: isInQueue ? 'In queue' : 'Add to queue',
      );
    }

    // During draft - show both buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onAddToQueue != null)
          IconButton(
            icon: Icon(
              isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
              color: isInQueue ? Colors.green : null,
            ),
            onPressed: isInQueue ? null : () => onAddToQueue!(player.id),
            tooltip: isInQueue ? 'In queue' : 'Add to queue',
          ),
        if (onDraftPlayer != null)
          ElevatedButton(
            onPressed: isMyTurn ? () => onDraftPlayer!(player.id) : null,
            child: const Text('Draft'),
          ),
      ],
    );
  }
}
