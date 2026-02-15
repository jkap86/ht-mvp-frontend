import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../players/domain/player.dart';
import '../providers/draft_room_provider.dart';
import '../providers/draft_queue_provider.dart';
import '../utils/player_filtering.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import 'auction_bid_dialog.dart';
import 'auction_drawer_content.dart';
import 'draft_activity_feed.dart';
import 'drawer_drag_handle.dart';
import 'fast_auction_panel.dart';
import 'matchups_drawer_content.dart';
import 'nomination_hint_row.dart';
import 'player_search_filter_panel.dart';
import 'snake_linear_drawer_content.dart';

enum _DrawerTab { players, activity }

/// Unified bottom drawer for the draft room.
/// Adapts content based on draft type:
/// - Snake/Linear: Search + Players + Queue
/// - Auction: Active lots + Search + Players for nomination
/// - Matchups: Available matchups + My schedule
class DraftBottomDrawer extends ConsumerStatefulWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final bool isAuction;
  final bool isMatchups;
  final Future<void> Function(int playerId) onMakePick;
  final Future<void> Function(int playerId) onAddToQueue;
  final Future<void> Function(int playerId)? onNominate;
  final Future<String?> Function(int lotId, int maxBid)? onSetMaxBid;
  final Future<void> Function(int pickAssetId)? onMakePickAssetSelection;
  final Future<void> Function(int pickAssetId)? onAddPickAssetToQueue;
  final Future<void> Function(int week, int opponentRosterId)? onPickMatchup;
  final DraggableScrollableController? sheetController;
  final bool isPickSubmitting;
  final bool isQueueSubmitting;
  final bool isPickAssetQueueSubmitting;

  const DraftBottomDrawer({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.isAuction,
    this.isMatchups = false,
    required this.onMakePick,
    required this.onAddToQueue,
    this.onNominate,
    this.onSetMaxBid,
    this.onMakePickAssetSelection,
    this.onAddPickAssetToQueue,
    this.onPickMatchup,
    this.sheetController,
    this.isPickSubmitting = false,
    this.isQueueSubmitting = false,
    this.isPickAssetQueueSubmitting = false,
  });

  @override
  ConsumerState<DraftBottomDrawer> createState() => _DraftBottomDrawerState();
}

class _DraftBottomDrawerState extends ConsumerState<DraftBottomDrawer> {
  String _searchQuery = '';
  String? _selectedPosition;
  DraggableScrollableController? _ownedController;
  _DrawerTab _selectedTab = _DrawerTab.players;
  bool _isExpanded = false;

  DraggableScrollableController get _sheetController =>
      widget.sheetController ?? (_ownedController ??= DraggableScrollableController());

  static const double _collapsedSize = 0.22; // Increased to fit queue
  static const double _expandedSize = 0.70;
  /// Threshold above which the drawer is considered "expanded"
  static const double _expandedThreshold = 0.35;

  @override
  void initState() {
    super.initState();
    // Listen to sheet size changes to track expanded/collapsed state.
    // We defer adding the listener to ensure the controller is attached first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetController.addListener(_onSheetSizeChanged);
    });
  }

  void _onSheetSizeChanged() {
    final expanded = _sheetController.size > _expandedThreshold;
    if (expanded != _isExpanded) {
      setState(() => _isExpanded = expanded);
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _ownedController?.dispose();
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

  void _showBidDialog(BuildContext context, AuctionLot lot) {
    final draftState = ref.read(draftRoomProvider(widget.providerKey));
    final player = draftState.players.where((p) => p.id == lot.playerId).firstOrNull;
    if (player == null || widget.onSetMaxBid == null) return;

    AuctionBidDialog.show(
      context,
      leagueId: widget.leagueId,
      draftId: widget.draftId,
      lotId: lot.id,
      player: player,
      myBudget: draftState.myBudget,
      draftOrder: draftState.draftOrder,
      settings: draftState.auctionSettings ?? AuctionSettings.defaults,
      onSubmit: (maxBid) async => await widget.onSetMaxBid!(lot.id, maxBid),
      serverClockOffsetMs: draftState.serverClockOffsetMs,
      totalRosterSpots: draftState.draft?.rounds,
    );
  }

  Widget _buildFastAuctionContent(
    BuildContext context,
    ScrollController scrollController,
    DraftRoomState draftState,
  ) {
    final isMyNomination = draftState.isMyNomination;
    final availablePlayers = filterAvailablePlayers(
      draftState.players,
      draftedIds: draftState.draftedPlayerIds,
      selectedPosition: _selectedPosition,
      searchQuery: _searchQuery,
    );

    return Column(
      children: [
        // FastAuctionPanel pinned at top
        FastAuctionPanel(
          state: draftState,
          onBidTap: (lot) => _showBidDialog(context, lot),
          onNominateTap: () {
            _sheetController.animateTo(
              _expandedSize,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onDismissResult: () {
            ref.read(draftRoomProvider(widget.providerKey).notifier).dismissLotResult();
          },
          onQuickBid: widget.onSetMaxBid,
        ),
        const Divider(height: 1),
        // Scrollable player list for nomination / browsing
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: PlayerSearchFilterPanel(
                  searchQuery: _searchQuery,
                  selectedPosition: _selectedPosition,
                  onSearchChanged: (value) =>
                      setState(() => _searchQuery = value),
                  onPositionChanged: (pos) =>
                      setState(() => _selectedPosition = pos),
                  hintText: 'Search players to nominate...',
                ),
              ),
              if (isMyNomination)
                const SliverToBoxAdapter(child: NominationHintRow()),
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(player.fullName,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${player.team ?? 'FA'} - ${player.primaryPosition}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                    onTap: isMyNomination && widget.onNominate != null
                        ? () => widget.onNominate!(player.id)
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get draftedPlayerIds to pass to queue widget
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPlayerIds),
    );
    // Get draftedPickAssetIds to pass to queue widget
    final draftedPickAssetIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPickAssetIds),
    );

    // For fast auction, we need the full state
    final draftState = ref.watch(draftRoomProvider(widget.providerKey));
    final isFastAuction = draftState.isFastAuction;

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle with label (tap to toggle) - stays outside scrollable
                DrawerDragHandle(
                  onTap: _toggleDrawer,
                  label: 'Players & Queue',
                  isExpanded: _isExpanded,
                ),
                // Tab toggle: Players | Activity
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: SegmentedButton<_DrawerTab>(
                    segments: const [
                      ButtonSegment(
                        value: _DrawerTab.players,
                        label: Text('Players'),
                        icon: Icon(Icons.people, size: 16),
                      ),
                      ButtonSegment(
                        value: _DrawerTab.activity,
                        label: Text('Activity'),
                        icon: Icon(Icons.history, size: 16),
                      ),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (selected) {
                      setState(() => _selectedTab = selected.first);
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                // Content based on selected tab
                Expanded(
                  child: _selectedTab == _DrawerTab.activity
                      ? DraftActivityFeed(providerKey: widget.providerKey)
                      : widget.isMatchups
                          ? MatchupsDrawerContent(
                              providerKey: widget.providerKey,
                              leagueId: widget.leagueId,
                              draftId: widget.draftId,
                              scrollController: scrollController,
                              onPickMatchup: widget.onPickMatchup ?? (week, opponentId) async {},
                              isPickSubmitting: widget.isPickSubmitting,
                            )
                          : widget.isAuction
                              ? (isFastAuction
                                  ? _buildFastAuctionContent(
                                      context, scrollController, draftState)
                                  : AuctionDrawerContent(
                                      providerKey: widget.providerKey,
                                      scrollController: scrollController,
                                      searchQuery: _searchQuery,
                                      selectedPosition: _selectedPosition,
                                      onSearchChanged: (value) =>
                                          setState(() => _searchQuery = value),
                                      onPositionChanged: (pos) =>
                                          setState(() => _selectedPosition = pos),
                                      onNominate: widget.onNominate,
                                      onSetMaxBid: widget.onSetMaxBid,
                                    ))
                              : SnakeLinearDrawerContent(
                                  providerKey: widget.providerKey,
                                  queueKey: widget.queueKey,
                                  leagueId: widget.leagueId,
                                  draftId: widget.draftId,
                                  draftedPlayerIds: draftedPlayerIds,
                                  draftedPickAssetIds: draftedPickAssetIds,
                                  scrollController: scrollController,
                                  searchQuery: _searchQuery,
                                  selectedPosition: _selectedPosition,
                                  onSearchChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  onPositionChanged: (pos) =>
                                      setState(() => _selectedPosition = pos),
                                  onMakePick: widget.onMakePick,
                                  onAddToQueue: widget.onAddToQueue,
                                  onMakePickAssetSelection: widget.onMakePickAssetSelection,
                                  onAddPickAssetToQueue: widget.onAddPickAssetToQueue,
                                  isPickSubmitting: widget.isPickSubmitting,
                                  isQueueSubmitting: widget.isQueueSubmitting,
                                  isPickAssetQueueSubmitting: widget.isPickAssetQueueSubmitting,
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
