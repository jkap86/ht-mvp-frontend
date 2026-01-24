import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import '../providers/team_provider.dart';
import '../widgets/lineup_slot_widget.dart';
import '../widgets/roster_player_card.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final int rosterId;

  const TeamScreen({
    super.key,
    required this.leagueId,
    required this.rosterId,
  });

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  TeamKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProvider(_key));

    // Show error snackbar when error occurs
    ref.listen<TeamState>(teamProvider(_key), (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ref.read(teamProvider(_key).notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    if (state.isLoading && state.players.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: const Text('My Team'),
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
          title: const Text('My Team'),
        ),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(teamProvider(_key).notifier).loadData(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        title: Text(state.league?.name ?? 'My Team'),
        actions: [
          // Week selector - 18 weeks is standard for NFL regular season + playoffs
          // TODO: Consider making this dynamic based on league settings if available
          PopupMenuButton<int>(
            initialValue: state.currentWeek,
            onSelected: (week) {
              ref.read(teamProvider(_key).notifier).changeWeek(week);
            },
            itemBuilder: (context) {
              return List.generate(
                18, // NFL regular season weeks
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lineup'),
            Tab(text: 'Roster'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLineupTab(state),
          _buildRosterTab(state),
        ],
      ),
      floatingActionButton: state.lineup?.isLocked == true
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.push('/leagues/${widget.leagueId}/free-agents',
                    extra: widget.rosterId);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
            ),
    );
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/leagues/${widget.leagueId}');
    }
  }

  Widget _buildLineupTab(TeamState state) {
    if (state.lineup?.isLocked == true) {
      return _buildLockedLineup(state);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Points summary
          _buildPointsSummary(state),
          const SizedBox(height: 16),

          // Starters section
          const Text(
            'Starters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildStarterSlots(state),

          const SizedBox(height: 24),

          // Bench section
          const Text(
            'Bench',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildBenchSlots(state),
        ],
      ),
    );
  }

  Widget _buildLockedLineup(TeamState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Locked banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lineup is locked for this week. Games have started.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPointsSummary(state),
          const SizedBox(height: 16),
          ..._buildStarterSlots(state),
          const SizedBox(height: 24),
          const Text(
            'Bench',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildBenchSlots(state),
        ],
      ),
    );
  }

  Widget _buildPointsSummary(TeamState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  state.totalPoints.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Total Points',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  '${state.starters.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Starters',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  '${state.bench.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Bench',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStarterSlots(TeamState state) {
    final slots = [
      LineupSlot.qb,
      LineupSlot.rb,
      LineupSlot.rb,
      LineupSlot.wr,
      LineupSlot.wr,
      LineupSlot.te,
      LineupSlot.flex,
      LineupSlot.k,
      LineupSlot.def,
    ];

    final playersBySlot = state.playersBySlot;
    final usedPlayers = <int>{};

    return slots.map((slot) {
      // Find a player for this slot that hasn't been used yet
      final slotPlayers = playersBySlot[slot] ?? [];
      RosterPlayer? player;
      for (final p in slotPlayers) {
        if (!usedPlayers.contains(p.playerId)) {
          player = p;
          usedPlayers.add(p.playerId);
          break;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LineupSlotWidget(
          slot: slot,
          player: player,
          isLocked: state.lineup?.isLocked ?? false,
          onTap: state.lineup?.isLocked == true
              ? null
              : () => _showMovePlayerDialog(state, player),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBenchSlots(TeamState state) {
    final benchPlayers = state.bench;

    if (benchPlayers.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No players on bench',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return benchPlayers.map((player) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RosterPlayerCard(
          player: player,
          showActions: state.lineup?.isLocked != true,
          onMove: () => _showMovePlayerDialog(state, player),
          onDrop: () => _confirmDropPlayer(player),
        ),
      );
    }).toList();
  }

  Widget _buildRosterTab(TeamState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.players.length,
        itemBuilder: (context, index) {
          final player = state.players[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RosterPlayerCard(
              player: player,
              showSlot: true,
              currentSlot: state.lineup?.lineup.getPlayerSlot(player.playerId),
              showActions: true,
              onMove: () => _showMovePlayerDialog(state, player),
              onDrop: () => _confirmDropPlayer(player),
            ),
          );
        },
      ),
    );
  }

  void _showMovePlayerDialog(TeamState state, RosterPlayer? player) {
    if (player == null) return;

    // Determine which slots this player can fill based on position
    final position = player.position;
    final validSlots =
        LineupSlot.values.where((slot) => slot.canFill(position)).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Move ${player.fullName ?? "Player"}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...validSlots.map((slot) {
                final isCurrentSlot =
                    state.lineup?.lineup.getPlayerSlot(player.playerId) == slot;
                return ListTile(
                  leading: Icon(
                    _getSlotIcon(slot),
                    color:
                        isCurrentSlot ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(slot.displayName),
                  trailing: isCurrentSlot
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: isCurrentSlot
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          ref.read(teamProvider(_key).notifier).movePlayer(
                                player.playerId,
                                slot.code,
                              );
                        },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  IconData _getSlotIcon(LineupSlot slot) {
    switch (slot) {
      case LineupSlot.qb:
        return Icons.sports_football;
      case LineupSlot.rb:
        return Icons.directions_run;
      case LineupSlot.wr:
        return Icons.catching_pokemon;
      case LineupSlot.te:
        return Icons.person;
      case LineupSlot.flex:
        return Icons.swap_horiz;
      case LineupSlot.k:
        return Icons.sports_soccer;
      case LineupSlot.def:
        return Icons.shield;
      case LineupSlot.bn:
        return Icons.chair;
    }
  }

  void _confirmDropPlayer(RosterPlayer player) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Drop Player'),
          content: Text(
            'Are you sure you want to drop ${player.fullName ?? "this player"}? '
            'They will become a free agent.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(teamProvider(_key).notifier)
                    .dropPlayer(player.playerId);
              },
              child: const Text('Drop'),
            ),
          ],
        );
      },
    );
  }
}
