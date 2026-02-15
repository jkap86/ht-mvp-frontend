import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/idempotency.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
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
import '../widgets/roster_legality_banner.dart';
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

  // Onboarding tooltip state
  bool _showSwapOnboarding = false;
  Timer? _onboardingDismissTimer;
  final List<ProviderSubscription> _subscriptions = [];

  TeamKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  @override
  void initState() {
    super.initState();
    _checkSwapOnboarding();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        teamProvider(_key),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
      _subscriptions.add(ref.listenManual<TeamState>(
        teamProvider(_key),
        (previous, next) {
          if (next.error != null && previous?.error != next.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(next.error!)),
                  ],
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    ref.read(teamProvider(_key).notifier).clearError();
                  },
                ),
              ),
            );
          }
        },
      ));
    });
  }

  Future<void> _checkSwapOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    final hasSeen = await storage.hasSeenLineupSwapOnboarding();
    if (!hasSeen && mounted) {
      setState(() {
        _showSwapOnboarding = true;
      });
      // Auto-dismiss after 6 seconds
      _onboardingDismissTimer = Timer(const Duration(seconds: 6), () {
        _dismissSwapOnboarding();
      });
    }
  }

  void _dismissSwapOnboarding() {
    if (_showSwapOnboarding && mounted) {
      setState(() {
        _showSwapOnboarding = false;
      });
      _onboardingDismissTimer?.cancel();
      _onboardingDismissTimer = null;
      // Persist that the user has seen the onboarding
      ref.read(storageServiceProvider).markLineupSwapOnboardingSeen();
    }
  }

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
    for (final sub in _subscriptions) sub.close();
    _subscriptions.clear();
    _onboardingDismissTimer?.cancel();
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

    if (state.isLoading && state.players.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => navigateBack(context),
          ),
          title: const Text('Team'),
        ),
        body: const SkeletonLineup(),
      );
    }

    if (state.error != null && state.players.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => navigateBack(context),
          ),
          title: const Text('Team'),
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
      // First-visit onboarding tooltip for swap interaction
      _buildSwapOnboardingTooltip(),
      // Roster legality warnings
      RosterLegalityBanner(
        warnings: state.legalityWarnings,
      ),
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
          constraints: AppLayout.contentConstraints(context),
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
          constraints: AppLayout.contentConstraints(context),
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
                  Semantics(
                    button: true,
                    label: 'Cancel swap selection',
                    child: IconButton(
                      icon: Icon(Icons.close, size: 18, color: colorScheme.onPrimaryContainer),
                      onPressed: () => setState(() {
                        _selectedPlayerId = null;
                        _selectedSlot = null;
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSwapOnboardingTooltip() {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _showSwapOnboarding
          ? GestureDetector(
              onTap: _dismissSwapOnboarding,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.tertiary.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_vert_rounded,
                      color: colorScheme.onTertiaryContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap a player, then tap a slot to swap positions',
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onTertiaryContainer.withAlpha(180),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _buildStarterSlots(TeamState state) {
    final config = state.rosterConfig;
    final slots = <LineupSlot>[
      ...List.filled(config.qb, LineupSlot.qb),
      ...List.filled(config.rb, LineupSlot.rb),
      ...List.filled(config.wr, LineupSlot.wr),
      ...List.filled(config.te, LineupSlot.te),
      ...List.filled(config.flex, LineupSlot.flex),
      ...List.filled(config.superFlex, LineupSlot.superFlex),
      ...List.filled(config.recFlex, LineupSlot.recFlex),
      ...List.filled(config.k, LineupSlot.k),
      ...List.filled(config.def, LineupSlot.def),
      ...List.filled(config.dl, LineupSlot.dl),
      ...List.filled(config.lb, LineupSlot.lb),
      ...List.filled(config.db, LineupSlot.db),
      ...List.filled(config.idpFlex, LineupSlot.idpFlex),
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
          currentWeek: state.currentWeek,
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
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_seat_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'No players on bench',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
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
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list_off, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'No eligible players for this slot',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
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

      final stateDescription = isSelected
          ? 'Selected for swap'
          : isHighlighted
              ? 'Available swap target'
              : '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          label: '${player.fullName ?? "Unknown"}, ${player.position ?? "?"}, bench'
              '${stateDescription.isNotEmpty ? ", $stateDescription" : ""}',
          child: RosterPlayerCard(
            player: player,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            onTap: state.lineup?.isLocked == true
                ? null
                : () => _handleBenchTap(state, player),
            // No drop on Lineup tab - only available on Roster tab
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRosterTab(TeamState state) {
    // Build header + player list
    final headerCount = 1; // roster capacity header
    final totalCount = headerCount + state.players.length;

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider(_key).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: AppLayout.contentConstraints(context),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              // Roster capacity header
              if (index == 0) {
                return _buildRosterCapacityHeader(state);
              }

              final playerIndex = index - headerCount;
              final player = state.players[playerIndex];
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

  Widget _buildRosterCapacityHeader(TeamState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentCount = state.players.length;
    final maxSize = state.maxRosterSize;
    final isFull = currentCount >= maxSize;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFull
              ? colorScheme.errorContainer.withAlpha(100)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: isFull
              ? Border.all(color: colorScheme.error.withAlpha(100))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isFull ? Icons.group : Icons.people_outline,
              size: 18,
              color: isFull
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.rosterCapacityDescription,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isFull
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovePlayerSheet(TeamState state, RosterPlayer player) {
    final moveValidation = state.getMoveValidation(player);
    showMovePlayerSheet(
      context: context,
      player: player,
      currentSlot: state.lineup?.lineup.getPlayerSlot(player.playerId),
      moveValidation: moveValidation,
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

  Future<bool> _confirmDropPlayer(RosterPlayer player) async {
    final confirmed = await showDialog<bool>(
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Drop'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final key = newIdempotencyKey();
      ref.read(teamProvider(_key).notifier).dropPlayer(player.playerId, idempotencyKey: key);
      return true;
    }
    return false;
  }

  /// Check if a player can fit in a given lineup slot based on position
  bool _canPlayerFitInSlot(RosterPlayer player, LineupSlot slot) {
    // Use the canFill method from LineupSlot enum
    return slot.canFill(player.position);
  }

  /// Handle tap on a starter slot
  Future<void> _handleSlotTap(TeamState state, LineupSlot slot, RosterPlayer? currentPlayer) async {
    // Dismiss onboarding on first interaction
    if (_showSwapOnboarding) _dismissSwapOnboarding();

    final currentLineup = state.lineup?.lineup;
    if (currentLineup == null) return;

    // If a bench player is selected and this slot is eligible, perform swap
    if (_selectedPlayerId != null && _selectedSlot == null) {
      final selectedPlayer = state.bench
          .where((p) => p.playerId == _selectedPlayerId)
          .firstOrNull;

      if (selectedPlayer != null && _canPlayerFitInSlot(selectedPlayer, slot)) {
        var newSlots = currentLineup.withPlayerMoved(_selectedPlayerId!, LineupSlot.bn, slot);
        if (currentPlayer != null) {
          newSlots = newSlots.withPlayerMoved(currentPlayer.playerId, slot, LineupSlot.bn);
        }
        final key = newIdempotencyKey();
        await ref.read(teamProvider(_key).notifier).saveLineup(newSlots, idempotencyKey: key);
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
        LineupSlots newSlots;
        if (currentPlayer != null && _canPlayerFitInSlot(currentPlayer, _selectedSlot!)) {
          // True swap: swap both players between their slots
          newSlots = currentLineup.withSwap(_selectedPlayerId!, _selectedSlot!, currentPlayer.playerId, slot);
        } else {
          // One-way: move selected player to target slot, move target (if any) to bench
          newSlots = currentLineup.withPlayerMoved(_selectedPlayerId!, _selectedSlot!, slot);
          if (currentPlayer != null) {
            newSlots = newSlots.withPlayerMoved(currentPlayer.playerId, slot, LineupSlot.bn);
          }
        }
        final key = newIdempotencyKey();
        await ref.read(teamProvider(_key).notifier).saveLineup(newSlots, idempotencyKey: key);
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
    // Dismiss onboarding on first interaction
    if (_showSwapOnboarding) _dismissSwapOnboarding();

    final currentLineup = state.lineup?.lineup;
    if (currentLineup == null) return;

    // If a starter slot is selected and this player is eligible, perform swap
    if (_selectedSlot != null) {
      if (_canPlayerFitInSlot(player, _selectedSlot!)) {
        var newSlots = currentLineup.withPlayerMoved(player.playerId, LineupSlot.bn, _selectedSlot!);
        final currentPlayerInSlot = state.playersBySlot[_selectedSlot]?.firstOrNull;
        if (currentPlayerInSlot != null) {
          newSlots = newSlots.withPlayerMoved(currentPlayerInSlot.playerId, _selectedSlot!, LineupSlot.bn);
        }
        final key = newIdempotencyKey();
        await ref.read(teamProvider(_key).notifier).saveLineup(newSlots, idempotencyKey: key);
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
