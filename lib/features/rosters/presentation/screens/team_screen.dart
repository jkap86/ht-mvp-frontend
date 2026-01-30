import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import '../providers/team_provider.dart';
import '../widgets/lineup_locked_banner.dart';
import '../widgets/lineup_slot_widget.dart';
import '../widgets/move_player_sheet.dart';
import '../widgets/roster_player_card.dart';
import '../widgets/team_points_summary.dart';

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

  // Selection state for swap interaction
  int? _selectedPlayerId;
  LineupSlot? _selectedSlot;

  TeamKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Rebuild to show/hide FAB based on current tab
    setState(() {});
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
          _buildWeekSelector(state),
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
      // Only show FAB on Roster tab (index 1), not on Lineup tab
      floatingActionButton: _tabController.index == 1 && state.lineup?.isLocked != true
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/leagues/${widget.leagueId}/free-agents',
                    extra: widget.rosterId);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
            )
          : null,
    );
  }

  Widget _buildWeekSelector(TeamState state) {
    final totalWeeks = state.league?.totalWeeks ?? 18;
    return PopupMenuButton<int>(
      initialValue: state.currentWeek,
      onSelected: (week) {
        ref.read(teamProvider(_key).notifier).changeWeek(week);
      },
      itemBuilder: (context) {
        return List.generate(
          totalWeeks,
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

  void _navigateBack(BuildContext context) {
    // Team tab is the entry point to a league - always go back to leagues list
    context.go('/leagues');
  }

  Widget _buildLineupTab(TeamState state) {
    if (state.lineup?.isLocked == true) {
      return _buildLockedLineup(state);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: Column(
        children: [
          // Points summary at top (not scrollable)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TeamPointsSummary(
              totalPoints: state.totalPoints,
              startersCount: state.starters.length,
              benchCount: state.bench.length,
            ),
          ),
          // Side-by-side columns (scrollable)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Starters column (left)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const Text(
                        'Starters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildStarterSlots(state),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Bench column (right)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedLineup(TeamState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: Column(
        children: [
          // Locked banner and points summary at top (not scrollable)
          const LineupLockedBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TeamPointsSummary(
              totalPoints: state.totalPoints,
              startersCount: state.starters.length,
              benchCount: state.bench.length,
            ),
          ),
          // Side-by-side columns (scrollable)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Starters column (left)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const Text(
                        'Starters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildStarterSlots(state),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Bench column (right)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
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
                ),
              ],
            ),
          ),
        ],
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

    // Check if a bench player is selected - if so, determine which slots are eligible
    final selectedBenchPlayer = _selectedPlayerId != null && _selectedSlot == null
        ? state.bench.where((p) => p.playerId == _selectedPlayerId).firstOrNull
        : null;

    // Check if a starter is selected - find that player for highlighting other slots
    final selectedStarterPlayer = _selectedPlayerId != null && _selectedSlot != null
        ? state.starters.where((p) => p.playerId == _selectedPlayerId).firstOrNull
        : null;

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

      // Check if this slot is selected (use player ID to handle duplicate slot types)
      final isSelected = player != null && player.playerId == _selectedPlayerId && _selectedSlot != null;

      // Check if this slot is eligible for the selected bench player
      bool isHighlighted = selectedBenchPlayer != null &&
          _canPlayerFitInSlot(selectedBenchPlayer, slot);

      // Check if this slot is eligible for starter-to-starter swap
      bool isOneWayHighlight = false;
      if (selectedStarterPlayer != null && !isSelected) {
        // Can the selected starter fit in this slot?
        if (_canPlayerFitInSlot(selectedStarterPlayer, slot)) {
          // Check if swap is possible (target player can fit back in selected slot)
          if (player == null) {
            // Empty slot - can move there (green highlight)
            isHighlighted = true;
          } else if (_canPlayerFitInSlot(player, _selectedSlot!)) {
            // Target player can fit back - swap possible (green highlight)
            isHighlighted = true;
          } else {
            // Target player can't fit back - one-way only (orange highlight)
            isOneWayHighlight = true;
          }
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LineupSlotWidget(
          slot: slot,
          player: player,
          isLocked: state.lineup?.isLocked ?? false,
          isSelected: isSelected,
          isHighlighted: isHighlighted,
          isOneWayHighlight: isOneWayHighlight,
          onTap: state.lineup?.isLocked == true
              ? null
              : () => _handleSlotTap(state, slot, player),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBenchSlots(TeamState state) {
    var benchPlayers = state.bench;

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

    // If a starter slot is selected, filter bench to show only eligible players
    if (_selectedSlot != null) {
      benchPlayers = benchPlayers
          .where((p) => _canPlayerFitInSlot(p, _selectedSlot!))
          .toList();

      if (benchPlayers.isEmpty) {
        return [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No eligible players for this slot',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ];
      }
    }

    return benchPlayers.map((player) {
      final isSelected = _selectedPlayerId == player.playerId;
      // Highlight if a slot is selected and this player can fit
      final isHighlighted = _selectedSlot != null &&
          _canPlayerFitInSlot(player, _selectedSlot!);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RosterPlayerCard(
          player: player,
          isSelected: isSelected,
          isHighlighted: isHighlighted,
          onTap: state.lineup?.isLocked == true
              ? null
              : () => _handleBenchTap(state, player),
          // No drop on Lineup tab - only available on Roster tab
        ),
      );
    }).toList();
  }

  Widget _buildRosterTab(TeamState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                  onTap: () => _showMovePlayerSheet(state, player),
                  onDrop: () => _confirmDropPlayer(player),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMovePlayerSheet(TeamState state, RosterPlayer player) {
    showMovePlayerSheet(
      context: context,
      player: player,
      currentSlot: state.lineup?.lineup.getPlayerSlot(player.playerId),
      onMove: (slotCode) {
        ref.read(teamProvider(_key).notifier).movePlayer(
              player.playerId,
              slotCode,
            );
      },
    );
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

  /// Check if a player can fit in a given lineup slot based on position
  bool _canPlayerFitInSlot(RosterPlayer player, LineupSlot slot) {
    final position = player.position?.toUpperCase();
    switch (slot) {
      case LineupSlot.qb:
        return position == 'QB';
      case LineupSlot.rb:
        return position == 'RB';
      case LineupSlot.wr:
        return position == 'WR';
      case LineupSlot.te:
        return position == 'TE';
      case LineupSlot.flex:
        return position == 'RB' || position == 'WR' || position == 'TE';
      case LineupSlot.k:
        return position == 'K';
      case LineupSlot.def:
        return position == 'DEF';
      case LineupSlot.bn:
        return true; // Any player can go on bench
    }
  }

  /// Handle tap on a starter slot
  Future<void> _handleSlotTap(TeamState state, LineupSlot slot, RosterPlayer? currentPlayer) async {
    // If a bench player is selected and this slot is eligible, perform swap
    if (_selectedPlayerId != null && _selectedSlot == null) {
      final selectedPlayer = state.bench
          .where((p) => p.playerId == _selectedPlayerId)
          .firstOrNull;

      if (selectedPlayer != null && _canPlayerFitInSlot(selectedPlayer, slot)) {
        // If slot has a player, move them to bench first (await to prevent race condition)
        if (currentPlayer != null) {
          await ref.read(teamProvider(_key).notifier).movePlayer(
                currentPlayer.playerId,
                'BN',
              );
        }
        // Then move bench player to this slot
        await ref.read(teamProvider(_key).notifier).movePlayer(
              _selectedPlayerId!,
              slot.code,
            );
        setState(() {
          _selectedPlayerId = null;
          _selectedSlot = null;
        });
        return;
      }
    }

    // If a starter is selected (has both playerId and slot), handle starter-to-starter swap
    if (_selectedPlayerId != null && _selectedSlot != null) {
      // Don't do anything if clicking the same player
      if (currentPlayer?.playerId == _selectedPlayerId) {
        setState(() {
          _selectedPlayerId = null;
          _selectedSlot = null;
        });
        return;
      }

      // Find the selected starter player
      final selectedPlayer = state.starters
          .where((p) => p.playerId == _selectedPlayerId)
          .firstOrNull;

      if (selectedPlayer != null && _canPlayerFitInSlot(selectedPlayer, slot)) {
        // Check if target player can swap back
        if (currentPlayer != null && _canPlayerFitInSlot(currentPlayer, _selectedSlot!)) {
          // True swap: move each player to the other's slot
          await ref.read(teamProvider(_key).notifier).movePlayer(
                currentPlayer.playerId,
                _selectedSlot!.code,
              );
          await ref.read(teamProvider(_key).notifier).movePlayer(
                _selectedPlayerId!,
                slot.code,
              );
        } else {
          // One-way: move target to bench first (if exists), then move selected to target slot
          if (currentPlayer != null) {
            await ref.read(teamProvider(_key).notifier).movePlayer(
                  currentPlayer.playerId,
                  'BN',
                );
          }
          await ref.read(teamProvider(_key).notifier).movePlayer(
                _selectedPlayerId!,
                slot.code,
              );
        }
        setState(() {
          _selectedPlayerId = null;
          _selectedSlot = null;
        });
        return;
      }
    }

    // If this slot is already selected (same player), deselect it
    if (currentPlayer?.playerId == _selectedPlayerId) {
      setState(() {
        _selectedSlot = null;
        _selectedPlayerId = null;
      });
      return;
    }

    // Select this slot (store both slot type and player ID)
    setState(() {
      _selectedSlot = slot;
      _selectedPlayerId = currentPlayer?.playerId;
    });
  }

  /// Handle tap on a bench player
  Future<void> _handleBenchTap(TeamState state, RosterPlayer player) async {
    // If a starter slot is selected and this player is eligible, perform swap
    if (_selectedSlot != null) {
      if (_canPlayerFitInSlot(player, _selectedSlot!)) {
        // Find current player in the selected slot and move them to bench first (await to prevent race condition)
        final currentPlayerInSlot = state.playersBySlot[_selectedSlot]?.firstOrNull;
        if (currentPlayerInSlot != null) {
          await ref.read(teamProvider(_key).notifier).movePlayer(
                currentPlayerInSlot.playerId,
                'BN',
              );
        }
        // Then move this bench player to the selected slot
        await ref.read(teamProvider(_key).notifier).movePlayer(
              player.playerId,
              _selectedSlot!.code,
            );
        setState(() {
          _selectedPlayerId = null;
          _selectedSlot = null;
        });
        return;
      }
    }

    // If this player is already selected, deselect
    if (_selectedPlayerId == player.playerId) {
      setState(() {
        _selectedPlayerId = null;
        _selectedSlot = null;
      });
      return;
    }

    // Select this bench player
    setState(() {
      _selectedPlayerId = player.playerId;
      _selectedSlot = null;
    });
  }
}
