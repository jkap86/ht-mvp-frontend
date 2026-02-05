import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../players/domain/player.dart';
import '../providers/draft_room_provider.dart';
import '../providers/draft_queue_provider.dart';
import '../utils/player_filtering.dart';
import '../utils/position_colors.dart';
import 'draft_queue_widget.dart';
import 'pick_asset_tile.dart';
import 'player_search_filter_panel.dart';
import 'queue_header_delegate.dart';

/// Content for snake/linear drafts in the bottom drawer.
/// Shows draft queue, search/filter panel, and available players list.
class SnakeLinearDrawerContent extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final Set<int> draftedPlayerIds;
  final ScrollController scrollController;
  final String searchQuery;
  final String? selectedPosition;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onPositionChanged;
  final Future<void> Function(int) onMakePick;
  final Future<void> Function(int) onAddToQueue;
  final Future<void> Function(int)? onMakePickAssetSelection;

  const SnakeLinearDrawerContent({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.draftedPlayerIds,
    required this.scrollController,
    required this.searchQuery,
    required this.selectedPosition,
    required this.onSearchChanged,
    required this.onPositionChanged,
    required this.onMakePick,
    required this.onAddToQueue,
    this.onMakePickAssetSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.players),
    );
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draftedPlayerIds),
    );
    final draft = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draft),
    );
    final isMyTurn = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.isMyTurn),
    );
    final queuedPlayerIds = ref.watch(
      draftQueueProvider(queueKey).select((s) => s.queuedPlayerIds),
    );
    final includeRookiePicks = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.includeRookiePicks),
    );
    final availablePickAssets = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.availablePickAssets),
    );

    final availablePlayers = filterAvailablePlayers(
      players,
      draftedIds: draftedPlayerIds,
      selectedPosition: selectedPosition,
      searchQuery: searchQuery,
    );
    final isDraftInProgress = draft?.status.isActive ?? false;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // PINNED queue header - stays visible at top while scrolling
        SliverPersistentHeader(
          pinned: true,
          delegate: QueueHeaderDelegate(
            child: DraftQueueWidget(
              leagueId: leagueId,
              draftId: draftId,
              draftedPlayerIds: draftedPlayerIds,
            ),
          ),
        ),

        // Rookie Draft Picks section (when enabled and assets available)
        if (includeRookiePicks && availablePickAssets.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PickAssetsSectionHeader(count: availablePickAssets.length),
          ),
          SliverList.builder(
            itemCount: availablePickAssets.length,
            itemBuilder: (context, index) {
              final pickAsset = availablePickAssets[index];
              return PickAssetTile(
                pickAsset: pickAsset,
                isMyTurn: isMyTurn,
                isDraftInProgress: isDraftInProgress,
                onDraft: onMakePickAssetSelection != null
                    ? () => onMakePickAssetSelection!(pickAsset.id)
                    : null,
              );
            },
          ),
          const SliverToBoxAdapter(
            child: Divider(height: 1),
          ),
        ],

        // Search bar with position filter
        SliverToBoxAdapter(
          child: PlayerSearchFilterPanel(
            searchQuery: searchQuery,
            selectedPosition: selectedPosition,
            onSearchChanged: onSearchChanged,
            onPositionChanged: onPositionChanged,
          ),
        ),

        // Available players list
        SliverList.builder(
          itemCount: availablePlayers.length,
          itemBuilder: (context, index) {
            final player = availablePlayers[index];
            return _buildPlayerTile(
              player,
              isDraftInProgress: isDraftInProgress,
              isMyTurn: isMyTurn,
              isInQueue: queuedPlayerIds.contains(player.id),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayerTile(
    Player player, {
    required bool isDraftInProgress,
    required bool isMyTurn,
    required bool isInQueue,
  }) {
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
      trailing: _buildTrailingButtons(
        player,
        isDraftInProgress: isDraftInProgress,
        isMyTurn: isMyTurn,
        isInQueue: isInQueue,
      ),
    );
  }

  Widget? _buildTrailingButtons(
    Player player, {
    required bool isDraftInProgress,
    required bool isMyTurn,
    required bool isInQueue,
  }) {
    if (!isDraftInProgress) {
      // Before draft starts - only show queue button
      return IconButton(
        icon: Icon(
          isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
          color: isInQueue ? Colors.green : null,
        ),
        onPressed: isInQueue ? null : () => onAddToQueue(player.id),
        tooltip: isInQueue ? 'In queue' : 'Add to queue',
      );
    }

    // During draft - show both buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
            color: isInQueue ? Colors.green : null,
          ),
          onPressed: isInQueue ? null : () => onAddToQueue(player.id),
          tooltip: isInQueue ? 'In queue' : 'Add to queue',
        ),
        ElevatedButton(
          onPressed: isMyTurn ? () => onMakePick(player.id) : null,
          child: const Text('Draft'),
        ),
      ],
    );
  }
}
