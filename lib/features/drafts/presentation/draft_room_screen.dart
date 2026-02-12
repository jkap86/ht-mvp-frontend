import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../core/utils/error_display.dart';
import '../../../core/utils/idempotency.dart';
import '../../../core/widgets/data_freshness_bar.dart';
import '../../../core/widgets/skeletons/skeletons.dart';
import '../../../core/widgets/states/states.dart';
import '../../players/domain/player.dart';
import '../domain/auction_settings.dart';
import '../domain/draft_phase.dart';
import '../domain/draft_status.dart';
import 'providers/draft_room_provider.dart';
import 'providers/draft_queue_provider.dart';
import 'screens/derby_screen.dart';
import 'widgets/auction_bid_dialog.dart';
import 'widgets/draft_status_bar.dart';
import 'widgets/draft_board_grid_view.dart';
import 'widgets/draft_bottom_drawer.dart';
import 'widgets/edit_draft_time_dialog.dart';
import 'widgets/slow_auction/slow_auction_roster_drawer.dart';
import 'widgets/slow_auction/slow_auction_screen.dart';

class DraftRoomScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final int draftId;

  const DraftRoomScreen({
    super.key,
    required this.leagueId,
    required this.draftId,
  });

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen> {
  final GlobalKey<_DraftRoomBodyState> _bodyKey = GlobalKey();

  // Separate flags per operation to prevent one failed operation from blocking others
  // _isPickSubmitting moved to DraftRoomState to survive navigation
  bool _isQueueSubmitting = false;
  bool _isPickAssetQueueSubmitting = false;
  bool _isNominateSubmitting = false;
  bool _isMaxBidSubmitting = false;
  bool _isStartingDraft = false;
  bool _isConfirmingOrder = false;
  bool _isPickAssetSubmitting = false;

  DraftRoomKey get _providerKey => (leagueId: widget.leagueId, draftId: widget.draftId);
  DraftQueueKey get _queueKey => (leagueId: widget.leagueId, draftId: widget.draftId);

  Future<void> _makePick(int playerId) async {
    final draftState = ref.read(draftRoomProvider(_providerKey));
    if (draftState.isPickSubmitting) return; // Prevent double-tap (state in provider)

    // Look up player name before the pick for use in success message
    final player = draftState.players.where((p) => p.id == playerId).firstOrNull;
    final playerName = player?.fullName ?? 'Player';

    final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
    final error = await notifier.makePick(playerId);
    if (context.mounted) {
      if (error != null) {
        error.showAsError(ref);
      } else {
        showSuccess(ref, 'Drafted: $playerName');
      }
    }
  }

  Future<void> _addToQueue(int playerId) async {
    if (_isQueueSubmitting) return; // Prevent double-tap
    setState(() => _isQueueSubmitting = true);
    try {
      final key = newIdempotencyKey();
      final notifier = ref.read(draftQueueProvider(_queueKey).notifier);
      final success = await notifier.addToQueue(playerId, idempotencyKey: key);
      if (!success && context.mounted) {
        'Failed to add player to queue'.showAsError(ref);
      }
    } finally {
      _isQueueSubmitting = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  Future<void> _addPickAssetToQueue(int pickAssetId) async {
    if (_isPickAssetQueueSubmitting) return; // Prevent double-tap
    setState(() => _isPickAssetQueueSubmitting = true);
    try {
      final key = newIdempotencyKey();
      final notifier = ref.read(draftQueueProvider(_queueKey).notifier);
      final success = await notifier.addPickAssetToQueue(pickAssetId, idempotencyKey: key);
      if (!success && context.mounted) {
        'Failed to add pick to queue'.showAsError(ref);
      }
    } finally {
      _isPickAssetQueueSubmitting = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  Future<void> _handleNominate(int playerId) async {
    if (_isNominateSubmitting) return; // Prevent double-tap
    setState(() => _isNominateSubmitting = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.nominate(playerId);
      if (error != null && context.mounted) {
        error.showAsError(ref);
      }
    } finally {
      _isNominateSubmitting = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  Future<String?> _handleSetMaxBid(int lotId, int maxBid) async {
    if (_isMaxBidSubmitting) return 'Bid already in progress';
    setState(() => _isMaxBidSubmitting = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.setMaxBid(lotId, maxBid);
      if (error != null && context.mounted) {
        // Don't show error here - caller (bid dialog) will handle it
      }
      return error;
    } finally {
      _isMaxBidSubmitting = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  Future<void> _startDraft() async {
    if (_isStartingDraft) return; // Prevent double-tap
    setState(() => _isStartingDraft = true);
    try {
      final key = newIdempotencyKey();
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.startDraft(idempotencyKey: key);
      if (error != null && context.mounted) {
        error.showAsError(ref);
      }
    } finally {
      _isStartingDraft = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  Future<void> _confirmOrder() async {
    if (_isConfirmingOrder) return; // Prevent double-tap
    setState(() => _isConfirmingOrder = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.confirmDraftOrder();
      if (error != null && context.mounted) {
        error.showAsError(ref);
      }
    } finally {
      _isConfirmingOrder = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  Future<void> _makePickAssetSelection(int pickAssetId) async {
    if (_isPickAssetSubmitting) return; // Prevent double-tap
    setState(() => _isPickAssetSubmitting = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.makePickAssetSelection(pickAssetId);
      if (error != null && context.mounted) {
        error.showAsError(ref);
      }
    } finally {
      _isPickAssetSubmitting = false; // Always reset flag
      if (context.mounted) setState(() {}); // Only trigger rebuild if mounted
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(draftRoomProvider(_providerKey), (prev, next) {
      if (next.isForbidden && prev?.isForbidden != true) {
        handleForbiddenNavigation(context, ref);
      }
    });

    // Use select() for loading state - only rebuilds when isLoading changes
    final isLoading = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.isLoading),
    );

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Draft Room'),
        ),
        body: const SkeletonList(itemCount: 6),
      );
    }

    // Use select() for error state - only rebuilds when error changes
    final error = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.error),
    );

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Draft Room'),
        ),
        body: AppErrorView(
          message: error,
          onRetry: () => ref.read(draftRoomProvider(_providerKey).notifier).loadData(),
        ),
      );
    }

    // Check if draft is in derby phase (draft order selection)
    final phase = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft?.phase),
    );
    if (phase == DraftPhase.derby) {
      return DerbyScreen(leagueId: widget.leagueId, draftId: widget.draftId);
    }

    // Use select() for specific fields needed by the app bar
    final currentRound = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft?.currentRound ?? 1),
    );
    final currentPick = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft?.currentPick ?? 1),
    );
    final isDraftActive = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft?.status.isActive ?? false),
    );
    final isAuction = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.isAuction),
    );
    final isFastAuction = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.isFastAuction),
    );
    final isSlowAuction = isAuction && !isFastAuction;
    final myBudget = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.myBudget),
    );
    final isCommissioner = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.isCommissioner),
    );
    final isDraftNotStarted = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft?.status.canStart ?? false),
    );
    final draft = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft),
    );
    final isDraftPaused = ref.watch(
      draftRoomProvider(_providerKey).select((s) => s.draft?.status == DraftStatus.paused),
    );

    // Listen for outbid notifications
    ref.listen<OutbidNotification?>(
      draftRoomProvider(_providerKey).select((s) => s.outbidNotification),
      (previous, next) {
        if (next != null) {
          final state = ref.read(draftRoomProvider(_providerKey));
          final players = state.players;
          final player = players.where((p) => p.id == next.playerId).firstOrNull;
          final playerName = player?.fullName ?? 'Player';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You were outbid on $playerName! New bid: \$${next.newBid}'),
              backgroundColor: AppTheme.draftWarning,
              action: SnackBarAction(
                label: 'View',
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  // Find the lot user was outbid on and open bid dialog
                  final currentState = ref.read(draftRoomProvider(_providerKey));
                  final lot = currentState.activeLots.where((l) => l.id == next.lotId).firstOrNull;
                  final lotPlayer = lot != null
                      ? currentState.players.where((p) => p.id == lot.playerId).firstOrNull
                      : null;
                  if (lot != null && lotPlayer != null && context.mounted) {
                    _bodyKey.currentState?.expandDrawer();
                    AuctionBidDialog.show(
                      context,
                      leagueId: widget.leagueId,
                      draftId: widget.draftId,
                      lot: lot,
                      player: lotPlayer,
                      myBudget: currentState.myBudget,
                      draftOrder: currentState.draftOrder,
                      settings: currentState.auctionSettings ?? AuctionSettings.defaults,
                      onSubmit: (maxBid) async => await _handleSetMaxBid(lot.id, maxBid),
                      serverClockOffsetMs: currentState.serverClockOffsetMs,
                      totalRosterSpots: currentState.draft?.rounds,
                    );
                  }
                },
              ),
            ),
          );
          ref.read(draftRoomProvider(_providerKey).notifier).clearOutbidNotification();
        }
      },
    );

    // Listen for auction errors (expired/closed lots) and show snackbar
    ref.listen<String?>(
      draftRoomProvider(_providerKey).select((s) => s.error),
      (previous, next) {
        if (next != null && previous != next) {
          final lower = next.toLowerCase();
          if (lower.contains('expired') ||
              lower.contains('ended') ||
              lower.contains('closed') ||
              lower.contains('closing')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          ref.read(draftRoomProvider(_providerKey).notifier).clearError();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(isSlowAuction ? 'Slow Auction' : 'Draft - Round $currentRound'),
        actions: [
          // Edit schedule button for commissioner (draft not started)
          if (isCommissioner && isDraftNotStarted && draft != null)
            IconButton(
              icon: const Icon(Icons.schedule),
              tooltip: 'Edit Schedule',
              onPressed: () => EditDraftTimeDialog.show(
                context,
                draft: draft,
                onSave: (scheduledStart) async {
                  final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
                  await notifier.updateScheduledStart(scheduledStart);
                },
              ),
            ),
          // Pause/Resume button for commissioner during active/paused fast auctions
          if (isCommissioner && isFastAuction && (isDraftActive || isDraftPaused == true))
            IconButton(
              icon: Icon(isDraftPaused == true ? Icons.play_arrow : Icons.pause),
              tooltip: isDraftPaused == true ? 'Resume Draft' : 'Pause Draft',
              onPressed: () async {
                if (isDraftPaused == true) {
                  final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
                  final error = await notifier.resumeDraft();
                  if (error != null && context.mounted) {
                    error.showAsError(ref);
                  }
                } else {
                  // Show confirmation dialog before pausing
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pause Draft?'),
                      content: const Text('This will freeze all timers and prevent bidding until resumed.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Pause'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
                    final error = await notifier.pauseDraft();
                    if (error != null && context.mounted) {
                      error.showAsError(ref);
                    }
                  }
                }
              },
            ),
          // Budget chip for auction drafts
          if (isAuction && myBudget != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.attach_money, size: 16),
                label: Text('\$${myBudget.available}'),
                backgroundColor: AppTheme.draftActionPrimary.withAlpha(25),
                labelStyle: const TextStyle(color: AppTheme.draftActionPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          // Pick chip for active drafts (not applicable to slow auctions)
          if (isDraftActive && !isSlowAuction)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Pick $currentPick'),
                backgroundColor: AppTheme.draftActionPrimary,
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          // Team rosters button for slow auctions
          if (isSlowAuction)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.groups),
                tooltip: 'Team Rosters',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      endDrawer: isSlowAuction
          ? SlowAuctionRosterDrawer(providerKey: _providerKey)
          : null,
      body: _DraftRoomBody(
        key: _bodyKey,
        providerKey: _providerKey,
        queueKey: _queueKey,
        leagueId: widget.leagueId,
        draftId: widget.draftId,
        isAuction: isAuction,
        onMakePick: _makePick,
        onAddToQueue: _addToQueue,
        onAddPickAssetToQueue: _addPickAssetToQueue,
        onNominate: _handleNominate,
        onSetMaxBid: _handleSetMaxBid,
        onStartDraft: _startDraft,
        isStartingDraft: _isStartingDraft,
        onConfirmOrder: _confirmOrder,
        isConfirmingOrder: _isConfirmingOrder,
        onMakePickAssetSelection: _makePickAssetSelection,
        isPickSubmitting: ref.watch(draftRoomProvider(_providerKey)).isPickSubmitting,
        isQueueSubmitting: _isQueueSubmitting,
        isPickAssetQueueSubmitting: _isPickAssetQueueSubmitting,
      ),
    );
  }
}

/// Main body with grid view and bottom drawer
class _DraftRoomBody extends ConsumerStatefulWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final bool isAuction;
  final Future<void> Function(int) onMakePick;
  final Future<void> Function(int) onAddToQueue;
  final Future<void> Function(int) onAddPickAssetToQueue;
  final Future<void> Function(int) onNominate;
  final Future<String?> Function(int, int) onSetMaxBid;
  final Future<void> Function() onStartDraft;
  final bool isStartingDraft;
  final Future<void> Function() onConfirmOrder;
  final bool isConfirmingOrder;
  final Future<void> Function(int) onMakePickAssetSelection;
  final bool isPickSubmitting;
  final bool isQueueSubmitting;
  final bool isPickAssetQueueSubmitting;

  const _DraftRoomBody({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.isAuction,
    required this.onMakePick,
    required this.onAddToQueue,
    required this.onAddPickAssetToQueue,
    required this.onNominate,
    required this.onSetMaxBid,
    required this.onStartDraft,
    required this.isStartingDraft,
    required this.onConfirmOrder,
    required this.isConfirmingOrder,
    required this.onMakePickAssetSelection,
    required this.isPickSubmitting,
    required this.isQueueSubmitting,
    required this.isPickAssetQueueSubmitting,
  });

  @override
  ConsumerState<_DraftRoomBody> createState() => _DraftRoomBodyState();
}

class _DraftRoomBodyState extends ConsumerState<_DraftRoomBody> {
  final GlobalKey<_DraftBottomDrawerWithControllerState> _drawerKey = GlobalKey();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Tick every 30s to update the "last updated" relative time text
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void expandDrawer() {
    _drawerKey.currentState?.expand();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draft),
    );
    final currentPickerName = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.currentPicker?.username),
    );
    final isMyTurn = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.isMyTurn),
    );
    final isAutodraftEnabled = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.isMyAutodraftEnabled),
    );
    final isFastAuction = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.isFastAuction),
    );
    final isCommissioner = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.isCommissioner),
    );
    final serverClockOffsetMs = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.serverClockOffsetMs),
    );
    final autopickExplanation = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.autopickExplanation),
    );
    final lastUpdatedDisplay = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.lastUpdatedDisplay),
    );
    final isStale = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.isStale),
    );
    final isDraftActive = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draft?.status.isActive ?? false),
    );

    // Watch queue for top queued player (for CTA button)
    final queueState = ref.watch(draftQueueProvider(widget.queueKey));
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPlayerIds),
    );
    final draftedPickAssetIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPickAssetIds),
    );
    // Get top available queue entry (filter out already drafted items)
    final availableQueue = queueState.queue.where((e) {
      if (e.isPlayer) return !draftedPlayerIds.contains(e.playerId);
      if (e.isPickAsset) return !draftedPickAssetIds.contains(e.pickAssetId);
      return false;
    }).toList();
    final topQueueEntry = availableQueue.isNotEmpty ? availableQueue.first : null;
    final topQueuedPlayerName = topQueueEntry?.isPlayer == true
        ? topQueueEntry?.playerName
        : topQueueEntry?.pickAssetDisplayName;

    // Check if draft can be started
    final isDraftNotStarted = draft?.status.canStart ?? false;
    // Auctions don't require explicit order confirmation (initial order is created automatically)
    final canStartDraft = isDraftNotStarted &&
        isCommissioner &&
        (draft?.orderConfirmed == true || widget.isAuction);
    // Check if order needs confirmation (non-auction drafts only)
    final needsOrderConfirmation = isDraftNotStarted &&
        isCommissioner &&
        draft?.orderConfirmed != true &&
        !widget.isAuction;

    // Slow auction uses completely different UI (no grid)
    if (widget.isAuction && !isFastAuction) {
      return SlowAuctionScreen(
        providerKey: widget.providerKey,
        leagueId: widget.leagueId,
        draftId: widget.draftId,
        onNominate: widget.onNominate,
        onSetMaxBid: widget.onSetMaxBid,
        onStartDraft: widget.onStartDraft,
        isStartingDraft: widget.isStartingDraft,
      );
    }

    // Snake, linear, and fast auction use grid view
    return Stack(
      children: [
        // Main content: status bar + grid view
        Column(
          children: [
            // Confirm Order banner for commissioners (before start)
            if (needsOrderConfirmation)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Confirm draft order to start',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.isConfirmingOrder ? null : widget.onConfirmOrder,
                      icon: widget.isConfirmingOrder
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(widget.isConfirmingOrder ? 'Confirming...' : 'Confirm Order'),
                    ),
                  ],
                ),
              ),
            // Start Draft banner for commissioners
            if (canStartDraft)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ready to start the draft!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.isStartingDraft ? null : widget.onStartDraft,
                      icon: widget.isStartingDraft
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(widget.isStartingDraft ? 'Starting...' : 'Start Draft'),
                    ),
                  ],
                ),
              ),
            // Freshness indicator
            DataFreshnessBar(
              lastUpdatedDisplay: lastUpdatedDisplay,
              isStale: isStale,
              label: isDraftActive ? 'Live' : null,
              labelIcon: isDraftActive ? Icons.circle : null,
              labelColor: isDraftActive ? Theme.of(context).colorScheme.error : null,
            ),
            DraftStatusBar(
              draft: draft,
              currentPickerName: currentPickerName,
              isMyTurn: isMyTurn,
              isAutodraftEnabled: isAutodraftEnabled,
              onToggleAutodraft: () async {
                final key = newIdempotencyKey();
                final notifier = ref.read(draftRoomProvider(widget.providerKey).notifier);
                final error = await notifier.toggleAutodraft(!isAutodraftEnabled, idempotencyKey: key);
                if (error != null && context.mounted) {
                  error.showAsError(ref);
                }
              },
              topQueuedPlayerName: topQueuedPlayerName,
              onDraftFromQueue: topQueueEntry != null
                  ? () {
                      if (topQueueEntry.isPlayer && topQueueEntry.playerId != null) {
                        widget.onMakePick(topQueueEntry.playerId!);
                      } else if (topQueueEntry.isPickAsset && topQueueEntry.pickAssetId != null) {
                        widget.onMakePickAssetSelection(topQueueEntry.pickAssetId!);
                      }
                    }
                  : null,
              onPickPlayer: expandDrawer,
              serverClockOffsetMs: serverClockOffsetMs,
              autopickExplanation: autopickExplanation,
              onDismissAutopickExplanation: autopickExplanation != null
                  ? () => ref.read(draftRoomProvider(widget.providerKey).notifier).clearAutopickExplanation()
                  : null,
            ),
            Expanded(
              child: DraftBoardGridView(
                leagueId: widget.leagueId,
                draftId: widget.draftId,
              ),
            ),
            // Space for collapsed drawer
            const SizedBox(height: 60),
          ],
        ),
        // Bottom drawer overlay
        _DraftBottomDrawerWithController(
          key: _drawerKey,
          providerKey: widget.providerKey,
          queueKey: widget.queueKey,
          leagueId: widget.leagueId,
          draftId: widget.draftId,
          isAuction: widget.isAuction,
          onMakePick: widget.onMakePick,
          onAddToQueue: widget.onAddToQueue,
          onAddPickAssetToQueue: widget.onAddPickAssetToQueue,
          onNominate: widget.onNominate,
          onSetMaxBid: widget.onSetMaxBid,
          onMakePickAssetSelection: widget.onMakePickAssetSelection,
          isPickSubmitting: widget.isPickSubmitting,
          isQueueSubmitting: widget.isQueueSubmitting,
          isPickAssetQueueSubmitting: widget.isPickAssetQueueSubmitting,
        ),
      ],
    );
  }
}

/// Wrapper around DraftBottomDrawer that exposes an expand() method
class _DraftBottomDrawerWithController extends StatefulWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final bool isAuction;
  final Future<void> Function(int) onMakePick;
  final Future<void> Function(int) onAddToQueue;
  final Future<void> Function(int) onAddPickAssetToQueue;
  final Future<void> Function(int) onNominate;
  final Future<String?> Function(int, int) onSetMaxBid;
  final Future<void> Function(int) onMakePickAssetSelection;
  final bool isPickSubmitting;
  final bool isQueueSubmitting;
  final bool isPickAssetQueueSubmitting;

  const _DraftBottomDrawerWithController({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.isAuction,
    required this.onMakePick,
    required this.onAddToQueue,
    required this.onAddPickAssetToQueue,
    required this.onNominate,
    required this.onSetMaxBid,
    required this.onMakePickAssetSelection,
    required this.isPickSubmitting,
    required this.isQueueSubmitting,
    required this.isPickAssetQueueSubmitting,
  });

  @override
  State<_DraftBottomDrawerWithController> createState() =>
      _DraftBottomDrawerWithControllerState();
}

class _DraftBottomDrawerWithControllerState
    extends State<_DraftBottomDrawerWithController> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double _expandedSize = 0.70;

  void expand() {
    _sheetController.animateTo(
      _expandedSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraftBottomDrawer(
      providerKey: widget.providerKey,
      queueKey: widget.queueKey,
      leagueId: widget.leagueId,
      draftId: widget.draftId,
      isAuction: widget.isAuction,
      onMakePick: widget.onMakePick,
      onAddToQueue: widget.onAddToQueue,
      onAddPickAssetToQueue: widget.onAddPickAssetToQueue,
      onNominate: widget.onNominate,
      onSetMaxBid: widget.onSetMaxBid,
      onMakePickAssetSelection: widget.onMakePickAssetSelection,
      sheetController: _sheetController,
      isPickSubmitting: widget.isPickSubmitting,
      isQueueSubmitting: widget.isQueueSubmitting,
      isPickAssetQueueSubmitting: widget.isPickAssetQueueSubmitting,
    );
  }
}
