import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/idempotency.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/team_selector_sheet.dart';
import '../../../../core/widgets/week_selector_strip.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import '../providers/team_provider.dart';
import '../widgets/lineup_locked_banner.dart';
import '../widgets/lineup_slot_widget.dart';
import '../widgets/move_player_sheet.dart';
import '../widgets/optimal_lineup_banner.dart';
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
    with TickerProviderStateMixin {
  TabController? _tabController;

  // Selection state for swap interaction
  int? _selectedPlayerId;
  LineupSlot? _selectedSlot;

  TeamKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  /// Check if viewing own team
  bool _isOwnTeam(TeamState state) {
    return state.league?.userRosterId == widget.rosterId;
  }

  /// Get display name for the team being viewed
  String _getTeamDisplayName(TeamState state) {
    final member = state.leagueMembers
        .where((m) => m.rosterId == widget.rosterId)
        .firstOrNull;
    return member?.teamName ?? member?.username ?? 'Team';
  }

  void _initTabController(bool isOwnTeam) {
    final tabCount = isOwnTeam ? 2 : 1;
    if (_tabController?.length != tabCount) {
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TeamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rosterId != widget.rosterId || oldWidget.leagueId != widget.leagueId) {
      // Clear selection state when switching teams
      _selectedPlayerId = null;
      _selectedSlot = null;
      // Tab controller will be updated in build() via _initTabController
    }
  }

  void _onTabChanged() {
    // Rebuild to show/hide FAB based on current tab
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProvider(_key));
    final isOwnTeam = _isOwnTeam(state);

    // Initialize or update tab controller based on own team status
    _initTabController(isOwnTeam);

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
            onPressed: () => navigateBack(context),
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
            onPressed: () => navigateBack(context),
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
          onPressed: () => navigateBack(context),
        ),
        title: _buildTeamSelector(state),
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: isOwnTeam
                    ? const [
                        Tab(text: 'Lineup'),
                        Tab(text: 'Roster'),
                      ]
                    : const [
                        Tab(text: 'Lineup'),
                      ],
              ),
      ),
      body: _tabController == null
          ? const AppLoadingView()
          : Column(
              children: [
                // Week selector strip
                WeekSelectorStrip(
                  currentWeek: state.currentWeek,
                  totalWeeks: state.league?.totalWeeks ?? 18,
                  onWeekSelected: (week) {
                    ref.read(teamProvider(_key).notifier).changeWeek(week);
                  },
                ),
                // Show viewing banner when not own team
                if (!isOwnTeam)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Viewing ${_getTeamDisplayName(state)}'s lineup",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: isOwnTeam
                        ? [
                            _buildLineupTab(state),
                            _buildRosterTab(state),
                          ]
                        : [
                            _buildLineupTab(state, readOnly: true),
                          ],
                  ),
                ),
              ],
            ),
      // Only show FAB on Roster tab (index 1), not on Lineup tab, and only for own team
      floatingActionButton: isOwnTeam &&
              _tabController?.index == 1 &&
              state.lineup?.isLocked != true
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

  Widget _buildTeamSelector(TeamState state) {
    if (state.leagueMembers.isEmpty) {
      return Text(state.league?.name ?? 'My Team');
    }

    final currentMember = state.leagueMembers
        .where((m) => m.rosterId == widget.rosterId)
        .firstOrNull;
    final displayName = currentMember?.teamName ?? currentMember?.username ?? 'Team';

    return GestureDetector(
      onTap: () {
        showTeamSelectorSheet(
          context: context,
          teams: state.leagueMembers
              .where((m) => m.rosterId != null)
              .map((m) => TeamOption(
                    rosterId: m.rosterId!,
                    teamName: m.teamName ?? m.username,
                    isCurrentUser: m.rosterId == state.league?.userRosterId,
                  ))
              .toList(),
          currentTeamId: widget.rosterId,
          onTeamSelected: (rosterId) {
            if (rosterId != widget.rosterId) {
              context.go('/leagues/${widget.leagueId}/team/$rosterId');
            }
          },
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildLineupTab(TeamState state, {bool readOnly = false}) {
    if (state.lineup?.isLocked == true || readOnly) {
      return _buildLockedLineup(state);
    }

    final starterWidgets = _buildStarterSlots(state);
    final benchWidgets = _buildBenchSlots(state);

    // Build items: header widgets + starters header + starters + bench header + bench
    final items = <Widget>[
      // Optimal lineup banner
      OptimalLineupBanner(
        issues: state.lineupIssues,
        currentProjected: state.projectedStarterPoints,
        optimalProjected: state.optimalProjectedPoints,
        isSaving: state.isSaving,
        onSetOptimal: () {
          final key = newIdempotencyKey();
          ref.read(teamProvider(_key).notifier).setOptimalLineup(idempotencyKey: key);
        },
      ),
      // Points summary
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TeamPointsSummary(
          totalPoints: state.totalPoints,
          startersCount: state.starters.length,
          benchCount: state.bench.length,
        ),
      ),
      // Swap hint banner
      _buildSwapHintBanner(),
      // Starters header
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text('Starters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...starterWidgets,
      // Bench header
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('Bench', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...benchWidgets,
      const SizedBox(height: 16),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedLineup(TeamState state) {
    final starterWidgets = _buildStarterSlots(state);
    final benchWidgets = _buildBenchSlots(state);

    final items = <Widget>[
      const LineupLockedBanner(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TeamPointsSummary(
          totalPoints: state.totalPoints,
          startersCount: state.starters.length,
          benchCount: state.bench.length,
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text('Starters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...starterWidgets,
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('Bench', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...benchWidgets,
      const SizedBox(height: 16),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ),
    );
  }

  Widget _buildSwapHintBanner() {
    final isVisible = _selectedPlayerId != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: isVisible
          ? Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: colorScheme.onPrimaryContainer, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap a highlighted slot to swap',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedPlayerId = null;
                      _selectedSlot = null;
                    }),
                    child: Icon(Icons.close, size: 18, color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No players on bench',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No eligible players for this slot',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        final key = newIdempotencyKey();
        ref.read(teamProvider(_key).notifier).movePlayer(
              player.playerId,
              slotCode,
              idempotencyKey: key,
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
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.of(context).pop();
                final key = newIdempotencyKey();
                ref
                    .read(teamProvider(_key).notifier)
                    .dropPlayer(player.playerId, idempotencyKey: key);
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
    // Use the canFill method from LineupSlot enum
    return slot.canFill(player.position);
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
          final key1 = newIdempotencyKey();
          await ref.read(teamProvider(_key).notifier).movePlayer(
                currentPlayer.playerId,
                'BN',
                idempotencyKey: key1,
              );
        }
        // Then move bench player to this slot
        final key2 = newIdempotencyKey();
        await ref.read(teamProvider(_key).notifier).movePlayer(
              _selectedPlayerId!,
              slot.code,
              idempotencyKey: key2,
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
          final key1 = newIdempotencyKey();
          await ref.read(teamProvider(_key).notifier).movePlayer(
                currentPlayer.playerId,
                _selectedSlot!.code,
                idempotencyKey: key1,
              );
          final key2 = newIdempotencyKey();
          await ref.read(teamProvider(_key).notifier).movePlayer(
                _selectedPlayerId!,
                slot.code,
                idempotencyKey: key2,
              );
        } else {
          // One-way: move target to bench first (if exists), then move selected to target slot
          if (currentPlayer != null) {
            final key1 = newIdempotencyKey();
            await ref.read(teamProvider(_key).notifier).movePlayer(
                  currentPlayer.playerId,
                  'BN',
                  idempotencyKey: key1,
                );
          }
          final key2 = newIdempotencyKey();
          await ref.read(teamProvider(_key).notifier).movePlayer(
                _selectedPlayerId!,
                slot.code,
                idempotencyKey: key2,
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
          final key1 = newIdempotencyKey();
          await ref.read(teamProvider(_key).notifier).movePlayer(
                currentPlayerInSlot.playerId,
                'BN',
                idempotencyKey: key1,
              );
        }
        // Then move this bench player to the selected slot
        final key2 = newIdempotencyKey();
        await ref.read(teamProvider(_key).notifier).movePlayer(
              player.playerId,
              _selectedSlot!.code,
              idempotencyKey: key2,
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
