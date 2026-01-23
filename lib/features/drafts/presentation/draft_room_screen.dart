import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/states/states.dart';
import '../../players/domain/player.dart';
import '../domain/auction_lot.dart';
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

  List<Player> _getAvailablePlayers(DraftRoomState state) {
    return state.players
        .where((p) =>
            !state.draftedPlayerIds.contains(p.id) &&
            (p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.primaryPosition.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p.team?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                    false)))
        .toList();
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

  void _showBidDialog(DraftRoomState state, AuctionLot lot) {
    final player = state.players.where((p) => p.id == lot.playerId).firstOrNull;
    if (player == null) return; // Cannot show dialog without player info
    AuctionBidDialog.show(
      context,
      lot: lot,
      player: player,
      myBudget: state.myBudget,
      onSubmit: (maxBid) => _handleSetMaxBid(lot.id, maxBid),
    );
  }

  void _showPlayerPickerForNomination(List<Player> availablePlayers) {
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
                      _handleNominate(player.id);
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

  Widget _buildAuctionBody(DraftRoomState state) {
    final availablePlayers = _getAvailablePlayers(state);
    return Column(
      children: [
        DraftStatusBar(draft: state.draft),
        Expanded(
          child: AuctionLotsPanel(
            state: state,
            onBidTap: (lot) {
              _showBidDialog(state, lot);
            },
            onNominateTap: () {
              _showPlayerPickerForNomination(availablePlayers);
            },
          ),
        ),
        RecentPicksWidget(picks: state.picks),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftRoomProvider(_providerKey));
    final queueState = ref.watch(draftQueueProvider(_queueKey));

    if (state.isLoading) {
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

    if (state.error != null) {
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
          message: state.error!,
          onRetry: () => ref.read(draftRoomProvider(_providerKey).notifier).loadData(),
        ),
      );
    }

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
        title: Text('Draft - Round ${state.draft?.currentRound ?? 1}'),
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
          if (state.draft?.status.isActive ?? false)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Pick ${state.draft?.currentPick ?? 1}'),
                backgroundColor: Colors.green,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: state.isAuction
          ? _buildAuctionBody(state)
          : _showGridView
              ? DraftBoardGridView(
                  leagueId: widget.leagueId,
                  draftId: widget.draftId,
                )
              : Column(
                  children: [
                    DraftStatusBar(draft: state.draft),
                    PlayerSearchBar(
                      onSearchChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    Expanded(
                      child: AvailablePlayersList(
                        players: _getAvailablePlayers(state),
                        isDraftInProgress: state.draft?.status.isActive ?? false,
                        onDraftPlayer: _makePick,
                        onAddToQueue: _addToQueue,
                        queuedPlayerIds: queueState.queuedPlayerIds,
                      ),
                    ),
                    DraftQueueWidget(
                      leagueId: widget.leagueId,
                      draftId: widget.draftId,
                      draftedPlayerIds: state.draftedPlayerIds,
                    ),
                    RecentPicksWidget(picks: state.picks),
                  ],
                ),
    );
  }
}
