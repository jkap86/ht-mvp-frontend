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
      body: _showGridView
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
