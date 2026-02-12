import 'package:flutter/material.dart';

import '../../../../core/theme/hype_train_colors.dart';
import '../../../players/domain/player.dart';
import 'package:hypetrain_mvp/core/theme/semantic_colors.dart';

class AvailablePlayersList extends StatefulWidget {
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
  State<AvailablePlayersList> createState() => _AvailablePlayersListState();
}

class _AvailablePlayersListState extends State<AvailablePlayersList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  /// Internal copy of the player list that we manage for AnimatedList.
  List<Player> _internalPlayers = [];

  @override
  void initState() {
    super.initState();
    _internalPlayers = List.of(widget.players);
  }

  @override
  void didUpdateWidget(covariant AvailablePlayersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayers(oldWidget.players, widget.players);
  }

  /// Compare old and new player lists, animate removals and insertions.
  void _syncPlayers(List<Player> oldPlayers, List<Player> newPlayers) {
    final newIds = newPlayers.map((p) => p.id).toSet();
    final oldIds = _internalPlayers.map((p) => p.id).toSet();

    // Find removed players (in old but not in new)
    final removedIds = oldIds.difference(newIds);

    // Find added players (in new but not in old)
    final addedIds = newIds.difference(oldIds);

    // Process removals first (animate out)
    if (removedIds.isNotEmpty) {
      // Remove in reverse index order so indices stay valid
      final removeIndices = <int>[];
      for (int i = 0; i < _internalPlayers.length; i++) {
        if (removedIds.contains(_internalPlayers[i].id)) {
          removeIndices.add(i);
        }
      }
      // Sort descending so we remove from the end first
      removeIndices.sort((a, b) => b.compareTo(a));

      for (final index in removeIndices) {
        final removedPlayer = _internalPlayers.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildRemovedItem(removedPlayer, animation),
          duration: const Duration(milliseconds: 250),
        );
      }
    }

    // Process additions (animate in)
    if (addedIds.isNotEmpty) {
      for (final player in newPlayers) {
        if (addedIds.contains(player.id)) {
          // Find the correct insertion index to maintain order
          final targetIndex = _findInsertionIndex(player, newPlayers);
          _internalPlayers.insert(targetIndex, player);
          _listKey.currentState?.insertItem(
            targetIndex,
            duration: const Duration(milliseconds: 250),
          );
        }
      }
    }

    // If the list was reordered or had complex changes beyond simple
    // add/remove, do a full reset to stay in sync
    if (removedIds.isEmpty && addedIds.isEmpty && !_listsMatch(newPlayers)) {
      _internalPlayers = List.of(newPlayers);
      // Force rebuild of AnimatedList
      setState(() {});
    }
  }

  /// Find where to insert a player to match the order in newPlayers.
  int _findInsertionIndex(Player player, List<Player> newPlayers) {
    final targetIdx = newPlayers.indexWhere((p) => p.id == player.id);
    // Find the position relative to already-present items
    int insertAt = 0;
    for (int i = 0; i < targetIdx && i < newPlayers.length; i++) {
      final idx = _internalPlayers.indexWhere((p) => p.id == newPlayers[i].id);
      if (idx >= 0) {
        insertAt = idx + 1;
      }
    }
    return insertAt.clamp(0, _internalPlayers.length);
  }

  /// Check if internal list matches new list by IDs in order.
  bool _listsMatch(List<Player> newPlayers) {
    if (_internalPlayers.length != newPlayers.length) return false;
    for (int i = 0; i < _internalPlayers.length; i++) {
      if (_internalPlayers[i].id != newPlayers[i].id) return false;
    }
    return true;
  }

  /// Build a tile that animates out when removed.
  Widget _buildRemovedItem(Player player, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: animation,
        child: _AvailablePlayerTile(
          key: ValueKey('player-${player.id}'),
          player: player,
          isDraftInProgress: widget.isDraftInProgress,
          isMyTurn: widget.isMyTurn,
          onDraftPlayer: null, // Disable actions during removal animation
          onAddToQueue: null,
          isInQueue: widget.queuedPlayerIds.contains(player.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      controller: widget.scrollController,
      initialItemCount: _internalPlayers.length,
      itemBuilder: (context, index, animation) {
        if (index >= _internalPlayers.length) {
          return const SizedBox.shrink();
        }
        final player = _internalPlayers[index];
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 0.0,
          child: FadeTransition(
            opacity: animation,
            child: _AvailablePlayerTile(
              key: ValueKey('player-${player.id}'),
              player: player,
              isDraftInProgress: widget.isDraftInProgress,
              isMyTurn: widget.isMyTurn,
              onDraftPlayer: widget.onDraftPlayer,
              onAddToQueue: widget.onAddToQueue,
              isInQueue: widget.queuedPlayerIds.contains(player.id),
            ),
          ),
        );
      },
    );
  }
}

class _AvailablePlayerTile extends StatelessWidget {
  final Player player;
  final bool isDraftInProgress;
  final bool isMyTurn;
  final void Function(int playerId)? onDraftPlayer;
  final void Function(int playerId)? onAddToQueue;
  final bool isInQueue;

  const _AvailablePlayerTile({
    super.key,
    required this.player,
    required this.isDraftInProgress,
    required this.isMyTurn,
    this.onDraftPlayer,
    this.onAddToQueue,
    required this.isInQueue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: getPositionColor(player.primaryPosition),
        child: Text(
          player.primaryPosition,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(player.fullName),
      subtitle: Text('${player.team ?? 'FA'} - ${player.primaryPosition}'),
      trailing: _buildTrailingButtons(context),
    );
  }

  Widget? _buildTrailingButtons(BuildContext context) {
    if (!isDraftInProgress) {
      // Before draft starts - only show queue button
      if (onAddToQueue == null) return null;
      return IconButton(
        icon: Icon(
          isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
          color: isInQueue ? context.htColors.draftAction : null,
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
              color: isInQueue ? context.htColors.draftAction : null,
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
