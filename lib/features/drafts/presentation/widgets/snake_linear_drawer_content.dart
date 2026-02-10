import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../players/domain/player.dart';
import '../../domain/draft_pick_asset.dart';
import '../providers/draft_room_provider.dart';
import '../providers/draft_queue_provider.dart';
import '../utils/player_filtering.dart';
import '../../../../config/app_theme.dart';
import '../../../../core/theme/semantic_colors.dart';
import 'draft_queue_widget.dart';
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
  final Set<int> draftedPickAssetIds;
  final ScrollController scrollController;
  final String searchQuery;
  final String? selectedPosition;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onPositionChanged;
  final Future<void> Function(int) onMakePick;
  final Future<void> Function(int) onAddToQueue;
  final Future<void> Function(int)? onMakePickAssetSelection;
  final Future<void> Function(int)? onAddPickAssetToQueue;
  final bool isPickSubmitting;
  final bool isQueueSubmitting;
  final bool isPickAssetQueueSubmitting;

  const SnakeLinearDrawerContent({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.draftedPlayerIds,
    this.draftedPickAssetIds = const {},
    required this.scrollController,
    required this.searchQuery,
    required this.selectedPosition,
    required this.onSearchChanged,
    required this.onPositionChanged,
    required this.onMakePick,
    required this.onAddToQueue,
    this.onMakePickAssetSelection,
    this.onAddPickAssetToQueue,
    this.isPickSubmitting = false,
    this.isQueueSubmitting = false,
    this.isPickAssetQueueSubmitting = false,
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
    final queuedPickAssetIds = ref.watch(
      draftQueueProvider(queueKey).select((s) => s.queuedPickAssetIds),
    );
    final includeRookiePicks = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.includeRookiePicks),
    );
    final availablePickAssets = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.availablePickAssets),
    );

    final isDraftInProgress = draft?.status.isActive ?? false;

    // Build unified list based on filter selection
    final showPicks = includeRookiePicks &&
        availablePickAssets.isNotEmpty &&
        (selectedPosition == null || selectedPosition == 'PICK');
    final showPlayers = selectedPosition != 'PICK';

    // Filter players (only when not filtering for PICK)
    final availablePlayers = showPlayers
        ? filterAvailablePlayers(
            players,
            draftedIds: draftedPlayerIds,
            selectedPosition: selectedPosition,
            searchQuery: searchQuery,
          )
        : <Player>[];

    // Filter picks by search query if applicable
    final filteredPickAssets = showPicks
        ? _filterPickAssets(availablePickAssets, searchQuery)
        : <DraftPickAsset>[];

    // Build unified list items
    final unifiedItems = <_UnifiedListItem>[
      // Add picks first (when showing)
      ...filteredPickAssets.map((p) => _UnifiedListItem.pick(p)),
      // Add players after picks
      ...availablePlayers.map((p) => _UnifiedListItem.player(p)),
    ];

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
              draftedPickAssetIds: draftedPickAssetIds,
              isMyTurn: isMyTurn,
              onDraftPlayer: onMakePick,
              onDraftPickAsset: onMakePickAssetSelection,
              isPickSubmitting: isPickSubmitting,
            ),
          ),
        ),

        // Search bar with position filter
        SliverToBoxAdapter(
          child: PlayerSearchFilterPanel(
            searchQuery: searchQuery,
            selectedPosition: selectedPosition,
            onSearchChanged: onSearchChanged,
            onPositionChanged: onPositionChanged,
            showPickFilter: includeRookiePicks && availablePickAssets.isNotEmpty,
          ),
        ),

        // Unified list of picks and players
        SliverList.builder(
          itemCount: unifiedItems.length,
          itemBuilder: (context, index) {
            final item = unifiedItems[index];
            if (item.pickAsset != null) {
              return _buildPickAssetTile(
                context,
                item.pickAsset!,
                isDraftInProgress: isDraftInProgress,
                isMyTurn: isMyTurn,
                isInQueue: queuedPickAssetIds.contains(item.pickAsset!.id),
                isSubmitting: isPickSubmitting,
              );
            } else {
              return _buildPlayerTile(
                context,
                item.player!,
                isDraftInProgress: isDraftInProgress,
                isMyTurn: isMyTurn,
                isInQueue: queuedPlayerIds.contains(item.player!.id),
                isSubmitting: isPickSubmitting,
              );
            }
          },
        ),
      ],
    );
  }

  /// Filter pick assets by search query
  List<DraftPickAsset> _filterPickAssets(
    List<DraftPickAsset> picks,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return picks;
    final query = searchQuery.toLowerCase();
    return picks.where((p) {
      // Match against display name, season, round, or team name
      return p.displayName.toLowerCase().contains(query) ||
          p.season.toString().contains(query) ||
          (p.originalTeamName?.toLowerCase().contains(query) ?? false) ||
          (p.originalUsername?.toLowerCase().contains(query) ?? false) ||
          'pick'.contains(query);
    }).toList();
  }

  Widget _buildPickAssetTile(
    BuildContext context,
    DraftPickAsset pickAsset, {
    required bool isDraftInProgress,
    required bool isMyTurn,
    required bool isInQueue,
    required bool isSubmitting,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: getPositionColor('PICK'),
        child: Icon(
          Icons.how_to_vote_outlined,
          color: Theme.of(context).colorScheme.onPrimary, // text on position-colored badge
          size: 20,
        ),
      ),
      title: Text(pickAsset.displayName),
      subtitle: Text(
        pickAsset.isTraded
            ? pickAsset.originDescription ?? 'Traded pick'
            : 'Rookie Draft Pick',
      ),
      trailing: _buildPickTrailingButtons(
        pickAsset,
        isDraftInProgress: isDraftInProgress,
        isMyTurn: isMyTurn,
        isInQueue: isInQueue,
        isSubmitting: isSubmitting,
      ),
    );
  }

  Widget? _buildPickTrailingButtons(
    DraftPickAsset pickAsset, {
    required bool isDraftInProgress,
    required bool isMyTurn,
    required bool isInQueue,
    required bool isSubmitting,
  }) {
    if (!isDraftInProgress) {
      // Before draft starts - show queue button
      return IconButton(
        icon: Icon(
          isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
          color: isInQueue ? AppTheme.draftActionPrimary : null,
        ),
        onPressed: (isInQueue || isPickAssetQueueSubmitting || onAddPickAssetToQueue == null)
            ? null
            : () => onAddPickAssetToQueue!(pickAsset.id),
        tooltip: isInQueue ? 'In queue' : 'Add to queue',
      );
    }

    // During draft - show both queue and draft buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
            color: isInQueue ? AppTheme.draftActionPrimary : null,
          ),
          onPressed: (isInQueue || isPickAssetQueueSubmitting || onAddPickAssetToQueue == null)
              ? null
              : () => onAddPickAssetToQueue!(pickAsset.id),
          tooltip: isInQueue ? 'In queue' : 'Add to queue',
        ),
        ElevatedButton(
          onPressed: isMyTurn && !isSubmitting && onMakePickAssetSelection != null
              ? () => onMakePickAssetSelection!(pickAsset.id)
              : null,
          child: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Draft'),
        ),
      ],
    );
  }

  Widget _buildPlayerTile(
    BuildContext context,
    Player player, {
    required bool isDraftInProgress,
    required bool isMyTurn,
    required bool isInQueue,
    required bool isSubmitting,
  }) {
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
      trailing: _buildTrailingButtons(
        player,
        isDraftInProgress: isDraftInProgress,
        isMyTurn: isMyTurn,
        isInQueue: isInQueue,
        isSubmitting: isSubmitting,
      ),
    );
  }

  Widget? _buildTrailingButtons(
    Player player, {
    required bool isDraftInProgress,
    required bool isMyTurn,
    required bool isInQueue,
    required bool isSubmitting,
  }) {
    if (!isDraftInProgress) {
      // Before draft starts - only show queue button
      return IconButton(
        icon: Icon(
          isInQueue ? Icons.playlist_add_check : Icons.playlist_add,
          color: isInQueue ? AppTheme.draftActionPrimary : null,
        ),
        onPressed: (isInQueue || isQueueSubmitting) ? null : () => onAddToQueue(player.id),
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
            color: isInQueue ? AppTheme.draftActionPrimary : null,
          ),
          onPressed: (isInQueue || isQueueSubmitting) ? null : () => onAddToQueue(player.id),
          tooltip: isInQueue ? 'In queue' : 'Add to queue',
        ),
        ElevatedButton(
          onPressed: isMyTurn && !isSubmitting ? () => onMakePick(player.id) : null,
          child: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Draft'),
        ),
      ],
    );
  }
}

/// Helper class to represent either a player or a pick asset in the unified list.
class _UnifiedListItem {
  final Player? player;
  final DraftPickAsset? pickAsset;

  _UnifiedListItem._({this.player, this.pickAsset});

  factory _UnifiedListItem.player(Player player) =>
      _UnifiedListItem._(player: player);

  factory _UnifiedListItem.pick(DraftPickAsset pickAsset) =>
      _UnifiedListItem._(pickAsset: pickAsset);
}
