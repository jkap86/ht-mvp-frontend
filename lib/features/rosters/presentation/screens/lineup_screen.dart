import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import '../providers/team_provider.dart';
import '../widgets/bench_list.dart';
import '../widgets/lineup_locked_banner.dart';
import '../widgets/lineup_slot_column.dart';
import '../widgets/move_player_modal.dart';
import '../widgets/optimal_lineup_banner.dart';

class LineupScreen extends ConsumerWidget {
  final int leagueId;
  final int rosterId;

  const LineupScreen({
    super.key,
    required this.leagueId,
    required this.rosterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamKey = (leagueId: leagueId, rosterId: rosterId);
    final state = ref.watch(teamProvider(teamKey));

    if (state.isLoading && state.players.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: const Text('Set Lineup'),
        ),
        body: const AppLoadingView(),
      );
    }

    if (state.error != null && state.players.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: const Text('Set Lineup'),
        ),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(teamProvider(teamKey).notifier).loadData(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        title: Text(state.league?.name ?? 'Set Lineup'),
        actions: [
          _buildWeekSelector(context, ref, state, teamKey),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamProvider(teamKey).notifier).loadData(),
        child: Column(
          children: [
            if (state.lineup?.isLocked == true) const LineupLockedBanner(),
            _buildPointsSummary(context, state),
            // Show optimal lineup suggestions if not locked and not optimal
            if (state.lineup?.isLocked != true && !state.isOptimalLineup)
              OptimalLineupBanner(
                issues: state.lineupIssues,
                currentProjected: state.projectedStarterPoints,
                optimalProjected: state.optimalProjectedPoints,
                isSaving: state.isSaving,
                onSetOptimal: () =>
                    ref.read(teamProvider(teamKey).notifier).setOptimalLineup(),
              ),
            Expanded(
              child: _buildLineupList(context, ref, state, teamKey),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/leagues/$leagueId');
    }
  }

  Widget _buildWeekSelector(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
  ) {
    return PopupMenuButton<int>(
      initialValue: state.currentWeek,
      onSelected: (week) {
        ref.read(teamProvider(teamKey).notifier).changeWeek(week);
      },
      itemBuilder: (context) {
        return List.generate(
          18,
          (index) => PopupMenuItem(
            value: index + 1,
            child: Text('Week ${index + 1}'),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Week ${state.currentWeek}',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSummary(BuildContext context, TeamState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Projected Points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            state.totalPoints.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineupList(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
  ) {
    final isLocked = state.lineup?.isLocked == true;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        LineupSlotColumn(
          playersBySlot: state.playersBySlot,
          isLocked: isLocked,
          onSlotTap: (slot, player) =>
              _handleSlotTap(context, ref, state, teamKey, slot, player),
        ),
        BenchList(
          benchPlayers: state.bench,
          isLocked: isLocked,
          onPlayerTap: (player) =>
              _handleBenchPlayerTap(context, ref, state, teamKey, player),
        ),
      ],
    );
  }

  void _handleSlotTap(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
    LineupSlot slot,
    RosterPlayer? currentPlayer,
  ) {
    // Find eligible bench players for this slot
    final eligiblePlayers = state.bench
        .where((player) => slot.canFill(player.position))
        .toList();

    if (eligiblePlayers.isEmpty && currentPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible players on bench for this slot'),
        ),
      );
      return;
    }

    MovePlayerModal.showSwapModal(
      context: context,
      slot: slot,
      currentPlayer: currentPlayer,
      eligiblePlayers: eligiblePlayers,
      onSelectPlayer: (player) {
        ref.read(teamProvider(teamKey).notifier).movePlayer(
              player.playerId,
              slot.code,
            );
      },
      onMoveToBench: currentPlayer != null
          ? () {
              ref.read(teamProvider(teamKey).notifier).movePlayer(
                    currentPlayer.playerId,
                    'BN',
                  );
            }
          : null,
    );
  }

  void _handleBenchPlayerTap(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
    RosterPlayer player,
  ) {
    // Find slots this player can fill
    final availableSlots = LineupSlot.values
        .where((slot) => slot != LineupSlot.bn && slot.canFill(player.position))
        .toList();

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This player cannot fill any starter slot'),
        ),
      );
      return;
    }

    MovePlayerModal.showMoveToSlotModal(
      context: context,
      player: player,
      availableSlots: availableSlots,
      onSelectSlot: (slot) {
        ref.read(teamProvider(teamKey).notifier).movePlayer(
              player.playerId,
              slot.code,
            );
      },
    );
  }
}
