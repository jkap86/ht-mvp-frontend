import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/states/states.dart';
import '../../players/domain/player.dart';
import 'providers/draft_room_provider.dart';
import 'widgets/draft_status_bar.dart';
import 'widgets/player_search_bar.dart';
import 'widgets/available_players_list.dart';
import 'widgets/recent_picks_widget.dart';

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

  DraftRoomKey get _providerKey => (leagueId: widget.leagueId, draftId: widget.draftId);

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftRoomProvider(_providerKey));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Room')),
        body: const AppLoadingView(),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Room')),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(draftRoomProvider(_providerKey).notifier).loadData(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Draft - Round ${state.draft?.currentRound ?? 1}'),
        actions: [
          if (state.draft?.status == 'in_progress')
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
      body: Column(
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
              isDraftInProgress: state.draft?.status == 'in_progress',
              onDraftPlayer: _makePick,
            ),
          ),
          RecentPicksWidget(picks: state.picks),
        ],
      ),
    );
  }
}
