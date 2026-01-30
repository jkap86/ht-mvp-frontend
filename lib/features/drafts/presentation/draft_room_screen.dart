import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/states/states.dart';
import '../../players/domain/player.dart';
import 'providers/draft_room_provider.dart';
import 'providers/draft_queue_provider.dart';
import 'widgets/draft_status_bar.dart';
import 'widgets/draft_board_grid_view.dart';
import 'widgets/draft_bottom_drawer.dart';
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
  // Separate flags per operation to prevent one failed operation from blocking others
  bool _isPickSubmitting = false;
  bool _isQueueSubmitting = false;
  bool _isNominateSubmitting = false;
  bool _isMaxBidSubmitting = false;

  DraftRoomKey get _providerKey => (leagueId: widget.leagueId, draftId: widget.draftId);
  DraftQueueKey get _queueKey => (leagueId: widget.leagueId, draftId: widget.draftId);

  Future<void> _makePick(int playerId) async {
    if (_isPickSubmitting) return; // Prevent double-tap
    setState(() => _isPickSubmitting = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.makePick(playerId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isPickSubmitting = false);
    }
  }

  Future<void> _addToQueue(int playerId) async {
    if (_isQueueSubmitting) return; // Prevent double-tap
    setState(() => _isQueueSubmitting = true);
    try {
      final notifier = ref.read(draftQueueProvider(_queueKey).notifier);
      final success = await notifier.addToQueue(playerId);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to add player to queue'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isQueueSubmitting = false);
    }
  }

  Future<void> _handleNominate(int playerId) async {
    if (_isNominateSubmitting) return; // Prevent double-tap
    setState(() => _isNominateSubmitting = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.nominate(playerId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isNominateSubmitting = false);
    }
  }

  Future<void> _handleSetMaxBid(int lotId, int maxBid) async {
    if (_isMaxBidSubmitting) return; // Prevent double-tap
    setState(() => _isMaxBidSubmitting = true);
    try {
      final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
      final error = await notifier.setMaxBid(lotId, maxBid);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isMaxBidSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: const AppLoadingView(),
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

    // Listen for outbid notifications
    ref.listen<OutbidNotification?>(
      draftRoomProvider(_providerKey).select((s) => s.outbidNotification),
      (previous, next) {
        if (next != null) {
          final players = ref.read(draftRoomProvider(_providerKey)).players;
          final player = players.where((p) => p.id == next.playerId).firstOrNull;
          final playerName = player?.fullName ?? 'Player';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You were outbid on $playerName! New bid: \$${next.newBid}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
          ref.read(draftRoomProvider(_providerKey).notifier).clearOutbidNotification();
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
          // Budget chip for auction drafts
          if (isAuction && myBudget != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.attach_money, size: 16),
                label: Text('\$${myBudget.available}'),
                backgroundColor: Colors.green[100],
                labelStyle: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
              ),
            ),
          // Pick chip for active drafts (not applicable to slow auctions)
          if (isDraftActive && !isSlowAuction)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Pick $currentPick'),
                backgroundColor: Colors.green,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _DraftRoomBody(
        providerKey: _providerKey,
        queueKey: _queueKey,
        leagueId: widget.leagueId,
        draftId: widget.draftId,
        isAuction: isAuction,
        onMakePick: _makePick,
        onAddToQueue: _addToQueue,
        onNominate: _handleNominate,
        onSetMaxBid: _handleSetMaxBid,
      ),
    );
  }
}

/// Main body with grid view and bottom drawer
class _DraftRoomBody extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final bool isAuction;
  final Future<void> Function(int) onMakePick;
  final Future<void> Function(int) onAddToQueue;
  final Future<void> Function(int) onNominate;
  final Future<void> Function(int, int) onSetMaxBid;

  const _DraftRoomBody({
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.isAuction,
    required this.onMakePick,
    required this.onAddToQueue,
    required this.onNominate,
    required this.onSetMaxBid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draft),
    );
    final currentPickerName = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.currentPicker?.username),
    );
    final isMyTurn = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.isMyTurn),
    );
    final isAutodraftEnabled = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.isMyAutodraftEnabled),
    );
    final isFastAuction = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.isFastAuction),
    );

    // Slow auction uses completely different UI (no grid)
    if (isAuction && !isFastAuction) {
      return SlowAuctionScreen(
        providerKey: providerKey,
        leagueId: leagueId,
        draftId: draftId,
        onNominate: onNominate,
        onSetMaxBid: onSetMaxBid,
      );
    }

    // Snake, linear, and fast auction use grid view
    return Stack(
      children: [
        // Main content: status bar + grid view
        Column(
          children: [
            DraftStatusBar(
              draft: draft,
              currentPickerName: currentPickerName,
              isMyTurn: isMyTurn,
              isAutodraftEnabled: isAutodraftEnabled,
              onToggleAutodraft: () async {
                final notifier = ref.read(draftRoomProvider(providerKey).notifier);
                final error = await notifier.toggleAutodraft(!isAutodraftEnabled);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            Expanded(
              child: DraftBoardGridView(
                leagueId: leagueId,
                draftId: draftId,
              ),
            ),
            // Space for collapsed drawer
            const SizedBox(height: 60),
          ],
        ),
        // Bottom drawer overlay
        DraftBottomDrawer(
          providerKey: providerKey,
          queueKey: queueKey,
          leagueId: leagueId,
          draftId: draftId,
          isAuction: isAuction,
          onMakePick: onMakePick,
          onAddToQueue: onAddToQueue,
          onNominate: onNominate,
          onSetMaxBid: onSetMaxBid,
        ),
      ],
    );
  }
}
