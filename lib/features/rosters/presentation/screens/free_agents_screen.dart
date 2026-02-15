import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/utils/error_display.dart';

import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../players/domain/player.dart';
import '../../../waivers/presentation/providers/waiver_provider.dart';
import '../../../waivers/presentation/widgets/waiver_claim_dialog.dart';
import '../../domain/roster_player.dart';
import '../providers/free_agents_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/free_agent_card.dart';
import '../widgets/position_filter_chips.dart';
import '../widgets/add_drop_player_sheet.dart';

enum _PlayerTab { freeAgents, myClaims }

class FreeAgentsScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final int rosterId;

  const FreeAgentsScreen({
    super.key,
    required this.leagueId,
    required this.rosterId,
  });

  @override
  ConsumerState<FreeAgentsScreen> createState() => _FreeAgentsScreenState();
}

class _FreeAgentsScreenState extends ConsumerState<FreeAgentsScreen> {
  final _searchController = TextEditingController();
  _PlayerTab _selectedTab = _PlayerTab.freeAgents;
  final List<ProviderSubscription> _subscriptions = [];

  FreeAgentsKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);
  TeamKey get _teamKey => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        freeAgentsProvider(_key),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
      _subscriptions.add(ref.listenManual<FreeAgentsState>(
        freeAgentsProvider(_key),
        (previous, next) {
          if (next.error != null && previous?.error != next.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    ref.read(freeAgentsProvider(_key).notifier).clearError();
                  },
                ),
              ),
            );
          }
        },
      ));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
    _searchController.dispose();
    super.dispose();
  }

  String _getWaiverType(Map<String, dynamic>? settings) {
    return settings?['waiver_type'] as String? ?? 'none';
  }

  bool _waiversEnabled(Map<String, dynamic>? settings) {
    return _getWaiverType(settings) != 'none';
  }

  double _appBarBottomHeight(bool showTabs) {
    double h = 0;
    if (showTabs) h += 48; // SegmentedButton
    if (_selectedTab == _PlayerTab.freeAgents) {
      h += 56; // Search bar (TextField + padding)
      h += 40; // PositionFilterChips
      h += 8;  // SizedBox
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freeAgentsProvider(_key));
    final teamState = ref.watch(teamProvider(_teamKey));
    final waiversKey = (leagueId: widget.leagueId, userRosterId: widget.rosterId);
    final waiversState = ref.watch(waiversProvider(waiversKey));

    final waiversEnabled = _waiversEnabled(teamState.league?.settings);
    final isFaabLeague = _getWaiverType(teamState.league?.settings) == 'faab';

    final showTabs = waiversEnabled;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateBack(context, fallback: '/leagues/${widget.leagueId}'),
        ),
        title: Text(_selectedTab == _PlayerTab.freeAgents ? 'Free Agents' : 'My Claims'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_appBarBottomHeight(showTabs)),
          child: Column(
            children: [
              if (showTabs)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SegmentedButton<_PlayerTab>(
                    segments: [
                      ButtonSegment(
                        value: _PlayerTab.freeAgents,
                        label: const Text('Free Agents'),
                        icon: const Icon(Icons.person_search, size: 18),
                      ),
                      ButtonSegment(
                        value: _PlayerTab.myClaims,
                        label: Text('My Claims${waiversState.pendingClaims.isNotEmpty ? ' (${waiversState.pendingClaims.length})' : ''}'),
                        icon: const Icon(Icons.access_time, size: 18),
                      ),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (selected) {
                      setState(() => _selectedTab = selected.first);
                    },
                  ),
                ),
              if (_selectedTab == _PlayerTab.freeAgents) ...[
                _buildSearchBar(state),
                PositionFilterChips(
                  selectedPosition: state.selectedPosition,
                  onPositionSelected: (pos) {
                    ref.read(freeAgentsProvider(_key).notifier).setPosition(pos);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      body: _selectedTab == _PlayerTab.myClaims
          ? _buildMyClaimsBody()
          : _buildBody(
              state,
              waiversState: waiversState,
              waiversEnabled: waiversEnabled,
              isFaabLeague: isFaabLeague,
            ),
    );
  }

  Widget _buildMyClaimsBody() {
    final waiversKey = (leagueId: widget.leagueId, userRosterId: widget.rosterId);
    final state = ref.watch(waiversProvider(waiversKey));

    if (state.isLoading) {
      return const SkeletonList(itemCount: 4);
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(waiversProvider(waiversKey).notifier).loadWaiverData(),
      );
    }

    final claims = state.sortedPendingClaims;

    if (claims.isEmpty) {
      return const AppEmptyView(
        icon: Icons.access_time,
        title: 'No Pending Claims',
        subtitle: 'Submit a waiver claim from the Free Agents tab.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(waiversProvider(waiversKey).notifier).loadWaiverData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: claims.length,
        itemBuilder: (context, index) {
          final claim = claims[index];
          return Padding(
            key: ValueKey('claim-${claim.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  claim.playerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  [
                    if (claim.playerPosition != null) claim.playerPosition!,
                    if (claim.playerTeam != null) claim.playerTeam!,
                    if (claim.bidAmount > 0) '\$${claim.bidAmount}',
                    if (claim.dropPlayerName != null) 'Drop: ${claim.dropPlayerName}',
                  ].join(' - '),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error, size: 20),
                  onPressed: () => _handleCancelClaim(claim.id, claim.playerName),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCancelClaim(int claimId, String playerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Claim?'),
        content: Text('Cancel your claim for $playerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Cancel Claim'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final waiversKey = (leagueId: widget.leagueId, userRosterId: widget.rosterId);
      final success = await ref.read(waiversProvider(waiversKey).notifier).cancelClaim(claimId);
      if (success && mounted) {
        showSuccess(ref, 'Claim cancelled');
      }
    }
  }

  Widget _buildSearchBar(FreeAgentsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search players...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(freeAgentsProvider(_key).notifier).setSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          ref.read(freeAgentsProvider(_key).notifier).setSearch(value);
        },
      ),
    );
  }


  Widget _buildBody(
    FreeAgentsState state, {
    required WaiversState waiversState,
    required bool waiversEnabled,
    required bool isFaabLeague,
  }) {
    if (state.isLoading && state.players.isEmpty) {
      return const SkeletonPlayerList();
    }

    if (state.error != null && state.players.isEmpty) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(freeAgentsProvider(_key).notifier).loadData(),
      );
    }

    final players = state.filteredPlayers;

    if (players.isEmpty) {
      return const AppEmptyView(
        icon: Icons.person_search,
        title: 'No Players Found',
        subtitle: 'Try adjusting your search or position filters.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(freeAgentsProvider(_key).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: AppLayout.contentConstraints(context),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (context, index) {
          final player = players[index];
          final isAdding = state.isAddingPlayer && state.addingPlayerId == player.id;
          final isOnWaiverWire = waiversEnabled && waiversState.isOnWaiverWire(player.id);

          return Padding(
            key: ValueKey('fa-${player.id}'),
            padding: const EdgeInsets.only(bottom: 8),
            child: FreeAgentCard(
              player: player,
              isAdding: isAdding,
              isOnWaiverWire: isOnWaiverWire,
              onAdd: () => _showAddPlayerDialog(
                player,
                isOnWaiverWire: isOnWaiverWire,
                isFaabLeague: isFaabLeague,
                waiversState: waiversState,
              ),
            ),
          );
        },
          ),
        ),
      ),
    );
  }

  void _showAddPlayerDialog(
    Player player, {
    required bool isOnWaiverWire,
    required bool isFaabLeague,
    required WaiversState waiversState,
  }) {
    final teamState = ref.read(teamProvider(_teamKey));
    final rosterPlayers = teamState.players;
    final maxRosterSize = teamState.maxRosterSize;
    final isRosterFull = rosterPlayers.length >= maxRosterSize;

    if (isOnWaiverWire) {
      _showWaiverClaimDialog(
        player,
        rosterPlayers: rosterPlayers,
        isFaabLeague: isFaabLeague,
        waiversState: waiversState,
        maxRosterSize: maxRosterSize,
      );
      return;
    }

    if (!isRosterFull) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add ${player.fullName} to your roster?'),
              const SizedBox(height: 8),
              Text(
                'Roster: ${rosterPlayers.length}/$maxRosterSize players',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref.read(freeAgentsProvider(_key).notifier).addPlayer(player.id);
                if (success && mounted) {
                  showSuccess(ref, '${player.fullName} added to roster');
                  ref.read(teamProvider(_teamKey).notifier).loadData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } else {
      showAddDropPlayerSheet(
        context: context,
        addPlayer: player,
        rosterPlayers: rosterPlayers,
        maxRosterSize: maxRosterSize,
        onDropSelected: (dropPlayerId) async {
          return await ref.read(freeAgentsProvider(_key).notifier).addDropPlayer(player.id, dropPlayerId);
        },
        onSuccess: () {
          if (mounted) {
            showSuccess(ref, '${player.fullName} added to roster');
            ref.read(teamProvider(_teamKey).notifier).loadData();
          }
        },
      );
    }
  }

  void _showWaiverClaimDialog(
    Player player, {
    required List<RosterPlayer> rosterPlayers,
    required bool isFaabLeague,
    required WaiversState waiversState,
    required int maxRosterSize,
  }) {
    final faabBudget = waiversState.getBudgetForRoster(widget.rosterId);

    showWaiverClaimDialog(
      context: context,
      leagueId: widget.leagueId,
      rosterId: widget.rosterId,
      playerName: player.fullName,
      playerId: player.id,
      playerPosition: player.position,
      playerTeam: player.team,
      rosterPlayers: rosterPlayers,
      faabBudget: faabBudget,
      isFaabLeague: isFaabLeague,
      maxRosterSize: maxRosterSize,
      onSubmit: ({
        required int playerId,
        int? dropPlayerId,
        int bidAmount = 0,
      }) async {
        final waiversKey = (leagueId: widget.leagueId, userRosterId: widget.rosterId);
        final result = await ref.read(waiversProvider(waiversKey).notifier).submitClaim(
          playerId: playerId,
          dropPlayerId: dropPlayerId,
          bidAmount: bidAmount,
        );
        if (result.claim != null && mounted) {
          showSuccess(ref, 'Waiver claim submitted for ${player.fullName}');
        }
        return result.warnings;
      },
    );
  }
}
