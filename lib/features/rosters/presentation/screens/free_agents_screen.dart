import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  FreeAgentsKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);
  TeamKey get _teamKey => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getWaiverType(Map<String, dynamic>? settings) {
    return settings?['waiver_type'] as String? ?? 'none';
  }

  bool _waiversEnabled(Map<String, dynamic>? settings) {
    return _getWaiverType(settings) != 'none';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freeAgentsProvider(_key));
    final teamState = ref.watch(teamProvider(_teamKey));
    final waiversKey = (leagueId: widget.leagueId, userRosterId: widget.rosterId);
    final waiversState = ref.watch(waiversProvider(waiversKey));

    final waiversEnabled = _waiversEnabled(teamState.league?.settings);
    final isFaabLeague = _getWaiverType(teamState.league?.settings) == 'faab';

    // Show error snackbar
    ref.listen<FreeAgentsState>(freeAgentsProvider(_key), (previous, next) {
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
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        title: const Text('Free Agents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildSearchBar(state),
              PositionFilterChips(
                selectedPosition: state.selectedPosition,
                onPositionSelected: (pos) {
                  ref.read(freeAgentsProvider(_key).notifier).setPosition(pos);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _buildBody(
        state,
        waiversState: waiversState,
        waiversEnabled: waiversEnabled,
        isFaabLeague: isFaabLeague,
      ),
    );
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
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          ref.read(freeAgentsProvider(_key).notifier).setSearch(value);
        },
        onSubmitted: (value) {
          ref.read(freeAgentsProvider(_key).notifier).searchAndReload(value);
        },
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

  Widget _buildBody(
    FreeAgentsState state, {
    required WaiversState waiversState,
    required bool waiversEnabled,
    required bool isFaabLeague,
  }) {
    if (state.isLoading && state.players.isEmpty) {
      return const AppLoadingView();
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
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (context, index) {
          final player = players[index];
          final isAdding = state.isAddingPlayer && state.addingPlayerId == player.id;
          final isOnWaiverWire = waiversEnabled && waiversState.isOnWaiverWire(player.id);

          return Padding(
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
    final league = teamState.league;

    final rosterConfig = league?.settings['roster_config'] as Map<String, dynamic>?;
    final maxRosterSize = rosterConfig != null
        ? rosterConfig.values.fold<int>(0, (sum, val) => sum + (val as int))
        : 15;
    final isRosterFull = rosterPlayers.length >= maxRosterSize;

    if (isOnWaiverWire) {
      _showWaiverClaimDialog(
        player,
        rosterPlayers: rosterPlayers,
        isFaabLeague: isFaabLeague,
        waiversState: waiversState,
      );
      return;
    }

    if (!isRosterFull) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Player'),
          content: Text('Add ${player.fullName} to your roster?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                final success = await ref.read(freeAgentsProvider(_key).notifier).addPlayer(player.id);
                if (success && mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('${player.fullName} added to roster')),
                  );
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
        onDropSelected: (dropPlayerId) async {
          return await ref.read(freeAgentsProvider(_key).notifier).addDropPlayer(player.id, dropPlayerId);
        },
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${player.fullName} added to roster')),
            );
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
      onSubmit: ({
        required int playerId,
        int? dropPlayerId,
        int bidAmount = 0,
      }) async {
        final waiversKey = (leagueId: widget.leagueId, userRosterId: widget.rosterId);
        final claim = await ref.read(waiversProvider(waiversKey).notifier).submitClaim(
          playerId: playerId,
          dropPlayerId: dropPlayerId,
          bidAmount: bidAmount,
        );
        if (claim != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Waiver claim submitted for ${player.fullName}')),
          );
        }
      },
    );
  }
}
