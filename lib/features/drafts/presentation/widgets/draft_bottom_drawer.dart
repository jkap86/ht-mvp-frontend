import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../players/domain/player.dart';
import '../providers/draft_room_provider.dart';
import '../providers/draft_queue_provider.dart';
import '../utils/player_filtering.dart';
import '../utils/position_colors.dart';
import 'auction_bid_dialog.dart';
import 'auction_lots_panel.dart';
import 'draft_queue_widget.dart';
import 'drawer_drag_handle.dart';
import 'nomination_hint_row.dart';
import 'player_search_filter_panel.dart';

/// Unified bottom drawer for the draft room.
/// Adapts content based on draft type:
/// - Snake/Linear: Search + Players + Queue
/// - Auction: Active lots + Search + Players for nomination
class DraftBottomDrawer extends ConsumerStatefulWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final bool isAuction;
  final Future<void> Function(int playerId) onMakePick;
  final Future<void> Function(int playerId) onAddToQueue;
  final Future<void> Function(int playerId)? onNominate;
  final Future<void> Function(int lotId, int maxBid)? onSetMaxBid;

  const DraftBottomDrawer({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.isAuction,
    required this.onMakePick,
    required this.onAddToQueue,
    this.onNominate,
    this.onSetMaxBid,
  });

  @override
  ConsumerState<DraftBottomDrawer> createState() => _DraftBottomDrawerState();
}

class _DraftBottomDrawerState extends ConsumerState<DraftBottomDrawer> {
  String _searchQuery = '';
  String? _selectedPosition;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  static const double _collapsedSize = 0.22;  // Increased to fit queue
  static const double _expandedSize = 0.70;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    final currentSize = _sheetController.size;
    final targetSize = currentSize < 0.35 ? _expandedSize : _collapsedSize;
    _sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get draftedPlayerIds to pass to queue widget
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPlayerIds),
    );

    return SizedBox.expand(
      child: DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      snapSizes: const [_collapsedSize, 0.45, _expandedSize],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle (tap to toggle) - stays outside scrollable
              DrawerDragHandle(onTap: _toggleDrawer),
              // ALL content inside one scrollable for proper drag gestures
              // Queue is now a pinned sliver inside _SnakeLinearDrawerContent
              Expanded(
                child: widget.isAuction
                    ? _AuctionDrawerContent(
                        providerKey: widget.providerKey,
                        scrollController: scrollController,
                        searchQuery: _searchQuery,
                        selectedPosition: _selectedPosition,
                        onSearchChanged: (value) => setState(() => _searchQuery = value),
                        onPositionChanged: (pos) => setState(() => _selectedPosition = pos),
                        onNominate: widget.onNominate,
                        onSetMaxBid: widget.onSetMaxBid,
                      )
                    : _SnakeLinearDrawerContent(
                        providerKey: widget.providerKey,
                        queueKey: widget.queueKey,
                        leagueId: widget.leagueId,
                        draftId: widget.draftId,
                        draftedPlayerIds: draftedPlayerIds,
                        scrollController: scrollController,
                        searchQuery: _searchQuery,
                        selectedPosition: _selectedPosition,
                        onSearchChanged: (value) => setState(() => _searchQuery = value),
                        onPositionChanged: (pos) => setState(() => _selectedPosition = pos),
                        onMakePick: widget.onMakePick,
                        onAddToQueue: widget.onAddToQueue,
                      ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

}

/// Content for snake/linear drafts
class _SnakeLinearDrawerContent extends ConsumerWidget {
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

  const _SnakeLinearDrawerContent({
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
          delegate: _QueueHeaderDelegate(
            child: DraftQueueWidget(
              leagueId: leagueId,
              draftId: draftId,
              draftedPlayerIds: draftedPlayerIds,
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

/// Content for auction drafts
class _AuctionDrawerContent extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final ScrollController scrollController;
  final String searchQuery;
  final String? selectedPosition;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onPositionChanged;
  final Future<void> Function(int playerId)? onNominate;
  final Future<void> Function(int lotId, int maxBid)? onSetMaxBid;

  const _AuctionDrawerContent({
    required this.providerKey,
    required this.scrollController,
    required this.searchQuery,
    required this.selectedPosition,
    required this.onSearchChanged,
    required this.onPositionChanged,
    this.onNominate,
    this.onSetMaxBid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftRoomProvider(providerKey));
    final players = state.players;
    final draftedPlayerIds = state.draftedPlayerIds;
    final myBudget = state.myBudget;

    final availablePlayers = filterAvailablePlayers(
      players,
      draftedIds: draftedPlayerIds,
      selectedPosition: selectedPosition,
      searchQuery: searchQuery,
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Active lots section (horizontal scroll)
        SliverToBoxAdapter(
          child: AuctionLotsPanel(
            state: state,
            onBidTap: (lot) {
              final player =
                  players.where((p) => p.id == lot.playerId).firstOrNull;
              if (player == null || onSetMaxBid == null) return;
              AuctionBidDialog.show(
                context,
                lot: lot,
                player: player,
                myBudget: myBudget,
                onSubmit: (maxBid) => onSetMaxBid!(lot.id, maxBid),
              );
            },
            onNominateTap: () {
              // Don't show bottom sheet, just expand drawer for nomination
            },
          ),
        ),

        const SliverToBoxAdapter(child: Divider(height: 1)),

        // Search bar with position filter
        SliverToBoxAdapter(
          child: PlayerSearchFilterPanel(
            searchQuery: searchQuery,
            selectedPosition: selectedPosition,
            onSearchChanged: onSearchChanged,
            onPositionChanged: onPositionChanged,
            hintText: 'Search players to nominate...',
          ),
        ),

        // Label for nomination section
        const SliverToBoxAdapter(child: NominationHintRow()),

        // Players list for nomination
        SliverList.builder(
          itemCount: availablePlayers.length,
          itemBuilder: (context, index) {
            final player = availablePlayers[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: getPositionColor(player.primaryPosition),
                child: Text(
                  player.primaryPosition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title:
                  Text(player.fullName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                '${player.team ?? 'FA'} - ${player.primaryPosition}',
                style: const TextStyle(fontSize: 12),
              ),
              dense: true,
              onTap: onNominate != null ? () => onNominate!(player.id) : null,
            );
          },
        ),
      ],
    );
  }
}

/// Delegate for the pinned queue header in the sliver list.
/// This keeps the queue visible at the top while allowing drag gestures
/// to propagate to the DraggableScrollableSheet.
class _QueueHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _QueueHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  // Queue height: ~120px when populated (header row + card row)
  // ~50px when empty (compact single row)
  // Use 120 to accommodate the larger state
  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant _QueueHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
