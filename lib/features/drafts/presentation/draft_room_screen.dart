import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/states/states.dart';
import '../../players/domain/player.dart';
import 'providers/draft_room_provider.dart';
import 'providers/draft_queue_provider.dart';
import 'widgets/draft_status_bar.dart';
import 'widgets/player_search_bar.dart';
import 'widgets/available_players_list.dart';
import 'widgets/recent_picks_widget.dart';
import 'widgets/draft_queue_widget.dart';
import 'widgets/draft_board_grid_view.dart';
import 'widgets/auction_lots_panel.dart';
import 'widgets/auction_bid_dialog.dart';

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
  String _searchQuery = '';
  bool _showGridView = false;

  DraftRoomKey get _providerKey => (leagueId: widget.leagueId, draftId: widget.draftId);
  DraftQueueKey get _queueKey => (leagueId: widget.leagueId, draftId: widget.draftId);

  Future<void> _makePick(int playerId) async {
    final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
    final success = await notifier.makePick(playerId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error making pick')),
      );
    }
  }

  Future<void> _addToQueue(int playerId) async {
    final notifier = ref.read(draftQueueProvider(_queueKey).notifier);
    final success = await notifier.addToQueue(playerId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding to queue')),
      );
    }
  }

  Future<void> _handleNominate(int playerId) async {
    final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
    final success = await notifier.nominate(playerId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error nominating player')),
      );
    }
  }

  Future<void> _handleSetMaxBid(int lotId, int maxBid) async {
    final notifier = ref.read(draftRoomProvider(_providerKey).notifier);
    final success = await notifier.setMaxBid(lotId, maxBid);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error setting bid')),
      );
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
        title: Text('Draft - Round $currentRound'),
        actions: [
          IconButton(
            icon: Icon(_showGridView ? Icons.list : Icons.grid_view),
            tooltip: _showGridView ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                _showGridView = !_showGridView;
              });
            },
          ),
          if (isDraftActive)
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
      body: isAuction
          ? _DraftAuctionBody(
              providerKey: _providerKey,
              onNominate: _handleNominate,
              onSetMaxBid: _handleSetMaxBid,
            )
          : _showGridView
              ? DraftBoardGridView(
                  leagueId: widget.leagueId,
                  draftId: widget.draftId,
                )
              : _DraftLinearBody(
                  providerKey: _providerKey,
                  queueKey: _queueKey,
                  leagueId: widget.leagueId,
                  draftId: widget.draftId,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onMakePick: _makePick,
                  onAddToQueue: _addToQueue,
                ),
    );
  }
}

/// Extracted widget for auction body with granular select()
class _DraftAuctionBody extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final Future<void> Function(int) onNominate;
  final Future<void> Function(int, int) onSetMaxBid;

  const _DraftAuctionBody({
    required this.providerKey,
    required this.onNominate,
    required this.onSetMaxBid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for outbid notifications and show toast
    ref.listen<OutbidNotification?>(
      draftRoomProvider(providerKey).select((s) => s.outbidNotification),
      (previous, next) {
        if (next != null) {
          final players = ref.read(draftRoomProvider(providerKey)).players;
          final player = players.where((p) => p.id == next.playerId).firstOrNull;
          final playerName = player?.fullName ?? 'Player';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You were outbid on $playerName! New bid: \$${next.newBid}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // Could scroll to or highlight the lot
                },
              ),
            ),
          );
          // Clear the notification so it doesn't show again
          ref.read(draftRoomProvider(providerKey).notifier).clearOutbidNotification();
        }
      },
    );

    // Select specific fields needed for auction view
    final draft = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draft),
    );
    final players = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.players),
    );
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draftedPlayerIds),
    );
    final picks = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.picks),
    );
    final myBudget = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.myBudget),
    );

    final availablePlayers = players
        .where((p) => !draftedPlayerIds.contains(p.id))
        .toList();

    // Build state object for AuctionLotsPanel (requires full state interface)
    final state = ref.read(draftRoomProvider(providerKey));
    final currentPickerName = state.currentPicker?.username;
    final isMyTurn = state.isMyTurn;

    return Column(
      children: [
        DraftStatusBar(
          draft: draft,
          currentPickerName: currentPickerName,
          isMyTurn: isMyTurn,
        ),
        Expanded(
          child: AuctionLotsPanel(
            state: state,
            onBidTap: (lot) {
              final player = players.where((p) => p.id == lot.playerId).firstOrNull;
              if (player == null) return;
              AuctionBidDialog.show(
                context,
                lot: lot,
                player: player,
                myBudget: myBudget,
                onSubmit: (maxBid) => onSetMaxBid(lot.id, maxBid),
              );
            },
            onNominateTap: () {
              _showPlayerPickerForNomination(context, availablePlayers);
            },
          ),
        ),
        RecentPicksWidget(picks: picks),
      ],
    );
  }

  void _showPlayerPickerForNomination(
    BuildContext context,
    List<Player> availablePlayers,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Player to Nominate',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: availablePlayers.length,
                itemBuilder: (context, index) {
                  final player = availablePlayers[index];
                  return ListTile(
                    title: Text(player.fullName),
                    subtitle: Text('${player.primaryPosition} - ${player.team ?? 'FA'}'),
                    onTap: () {
                      Navigator.pop(context);
                      onNominate(player.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted widget for linear draft body with granular select()
class _DraftLinearBody extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function(int) onMakePick;
  final Future<void> Function(int) onAddToQueue;

  const _DraftLinearBody({
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onMakePick,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select() for draft status bar - only needs draft object
    final draft = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draft),
    );

    // Use select() for player list - only needs players and draftedPlayerIds
    final players = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.players),
    );
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draftedPlayerIds),
    );

    // Use select() for recent picks
    final picks = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.picks),
    );

    // Use select() for queue - only need queuedPlayerIds (not full queue state)
    final queuedPlayerIds = ref.watch(
      draftQueueProvider(queueKey).select((s) => s.queuedPlayerIds),
    );

    // Use select() for isMyTurn and currentPicker
    final isMyTurn = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.isMyTurn),
    );
    final currentPickerName = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.currentPicker?.username),
    );

    final query = searchQuery.toLowerCase();
    final availablePlayers = players
        .where((p) =>
            !draftedPlayerIds.contains(p.id) &&
            (p.fullName.toLowerCase().contains(query) ||
                p.primaryPosition.toLowerCase().contains(query) ||
                (p.team?.toLowerCase().contains(query) ?? false)))
        .toList();

    return Column(
      children: [
        DraftStatusBar(
          draft: draft,
          currentPickerName: currentPickerName,
          isMyTurn: isMyTurn,
        ),
        PlayerSearchBar(onSearchChanged: onSearchChanged),
        Expanded(
          child: AvailablePlayersList(
            players: availablePlayers,
            isDraftInProgress: draft?.status.isActive ?? false,
            isMyTurn: isMyTurn,
            onDraftPlayer: onMakePick,
            onAddToQueue: onAddToQueue,
            queuedPlayerIds: queuedPlayerIds,
          ),
        ),
        DraftQueueWidget(
          leagueId: leagueId,
          draftId: draftId,
          draftedPlayerIds: draftedPlayerIds,
        ),
        RecentPicksWidget(picks: picks),
      ],
    );
  }
}
