import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import '../providers/team_provider.dart';
import '../widgets/lineup_locked_banner.dart';

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
          // Week selector
          PopupMenuButton<int>(
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
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamProvider(teamKey).notifier).loadData(),
        child: Column(
          children: [
            // Locked banner
            if (state.lineup?.isLocked == true)
              const LineupLockedBanner(),

            // Total points display
            Container(
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
            ),

            // Lineup list
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

  Widget _buildLineupList(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
  ) {
    final playersBySlot = state.playersBySlot;
    final isLocked = state.lineup?.isLocked == true;

    // Define slot display order with slot requirements
    final slotConfig = [
      (LineupSlot.qb, 1),
      (LineupSlot.rb, 2),
      (LineupSlot.wr, 2),
      (LineupSlot.te, 1),
      (LineupSlot.flex, 1),
      (LineupSlot.k, 1),
      (LineupSlot.def, 1),
    ];

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Starters section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'STARTERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...slotConfig.expand((config) {
          final slot = config.$1;
          final count = config.$2;
          final playersInSlot = playersBySlot[slot] ?? [];

          return List.generate(count, (index) {
            final player = index < playersInSlot.length ? playersInSlot[index] : null;
            return _SlotCard(
              slot: slot,
              slotIndex: index,
              player: player,
              isLocked: isLocked,
              onTap: isLocked
                  ? null
                  : () => _showSwapDialog(context, ref, state, teamKey, slot, player),
            );
          });
        }),

        const SizedBox(height: 16),

        // Bench section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'BENCH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...state.bench.map((player) => _SlotCard(
              slot: LineupSlot.bn,
              slotIndex: 0,
              player: player,
              isLocked: isLocked,
              onTap: isLocked
                  ? null
                  : () => _showSwapDialog(context, ref, state, teamKey, LineupSlot.bn, player),
            )),

        if (state.bench.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No bench players',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  void _showSwapDialog(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
    LineupSlot currentSlot,
    RosterPlayer? currentPlayer,
  ) {
    // Find eligible players for this slot
    final eligiblePlayers = <RosterPlayer>[];

    if (currentSlot == LineupSlot.bn) {
      // From bench - show slots this player can move to
      if (currentPlayer != null) {
        _showMoveToSlotDialog(context, ref, state, teamKey, currentPlayer);
      }
      return;
    }

    // For starter slots - show eligible bench players that can fill this slot
    for (final player in state.bench) {
      if (currentSlot.canFill(player.position)) {
        eligiblePlayers.add(player);
      }
    }

    if (eligiblePlayers.isEmpty && currentPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible players on bench for this slot')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      currentPlayer != null
                          ? 'Replace ${currentPlayer.fullName ?? 'Player'}'
                          : 'Select ${currentSlot.displayName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (currentPlayer != null)
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.orange),
                title: const Text('Move to Bench'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(teamProvider(teamKey).notifier).movePlayer(
                        currentPlayer.playerId,
                        'BN',
                      );
                },
              ),
            if (currentPlayer != null) const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: eligiblePlayers.length,
                itemBuilder: (context, index) {
                  final player = eligiblePlayers[index];
                  return ListTile(
                    leading: _PositionBadge(position: player.position),
                    title: Text(player.fullName ?? 'Unknown'),
                    subtitle: Text(player.team ?? ''),
                    trailing: player.injuryStatus != null
                        ? Chip(
                            label: Text(
                              player.injuryStatus!,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.red.shade100,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(teamProvider(teamKey).notifier).movePlayer(
                            player.playerId,
                            currentSlot.code,
                          );
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

  void _showMoveToSlotDialog(
    BuildContext context,
    WidgetRef ref,
    TeamState state,
    TeamKey teamKey,
    RosterPlayer player,
  ) {
    // Find slots this player can fill
    final availableSlots = <LineupSlot>[];
    for (final slot in LineupSlot.values) {
      if (slot != LineupSlot.bn && slot.canFill(player.position)) {
        availableSlots.add(slot);
      }
    }

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This player cannot fill any starter slot')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Move ${player.fullName ?? 'Player'} to:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...availableSlots.map((slot) => ListTile(
                  leading: _PositionBadge(position: slot.code),
                  title: Text(slot.displayName),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(teamProvider(teamKey).notifier).movePlayer(
                          player.playerId,
                          slot.code,
                        );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final LineupSlot slot;
  final int slotIndex;
  final RosterPlayer? player;
  final bool isLocked;
  final VoidCallback? onTap;

  const _SlotCard({
    required this.slot,
    required this.slotIndex,
    this.player,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = player == null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              _PositionBadge(position: slot.code),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: isEmpty
                    ? Text(
                        'Empty ${slot.displayName}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player!.fullName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (player!.injuryStatus != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    player!.injuryStatus!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${player!.position ?? ''} - ${player!.team ?? 'FA'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),

              // Swap indicator
              if (!isLocked)
                Icon(
                  Icons.swap_horiz,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final String? position;

  const _PositionBadge({this.position});

  @override
  Widget build(BuildContext context) {
    final color = _getPositionColor(position);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          position ?? '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String? position) {
    switch (position?.toUpperCase()) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
        return Colors.brown;
      case 'FLEX':
        return Colors.teal;
      case 'BN':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
