import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../../players/domain/player.dart';
import '../../domain/roster_player.dart';
import '../providers/free_agents_provider.dart';
import '../providers/team_provider.dart';

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
  final _positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'];

  FreeAgentsKey get _key => (leagueId: widget.leagueId, rosterId: widget.rosterId);
  TeamKey get _teamKey => (leagueId: widget.leagueId, rosterId: widget.rosterId);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freeAgentsProvider(_key));

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
              // Search bar
              Padding(
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
              ),

              // Position filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: state.selectedPosition == null,
                        onSelected: (_) {
                          ref.read(freeAgentsProvider(_key).notifier).setPosition(null);
                        },
                      ),
                    ),
                    ..._positions.map((pos) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(pos),
                          selected: state.selectedPosition == pos,
                          onSelected: (_) {
                            final currentPos = state.selectedPosition;
                            ref.read(freeAgentsProvider(_key).notifier).setPosition(
                                  currentPos == pos ? null : pos,
                                );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _buildBody(state),
    );
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/leagues/${widget.leagueId}');
    }
  }

  Widget _buildBody(FreeAgentsState state) {
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final isAdding = state.isAddingPlayer && state.addingPlayerId == player.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FreeAgentCard(
              player: player,
              isAdding: isAdding,
              onAdd: () => _showAddPlayerDialog(player),
            ),
          );
        },
      ),
    );
  }

  void _showAddPlayerDialog(Player player) {
    final teamState = ref.read(teamProvider(_teamKey));
    final rosterPlayers = teamState.players;

    // Check if roster is full (assuming 15 max roster size)
    const maxRosterSize = 15;
    final isRosterFull = rosterPlayers.length >= maxRosterSize;

    if (!isRosterFull) {
      // Roster has space - just add the player
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
                  // Refresh team data
                  ref.read(teamProvider(_teamKey).notifier).loadData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } else {
      // Roster is full - need to drop a player
      _showAddDropDialog(player, rosterPlayers);
    }
  }

  void _showAddDropDialog(Player addPlayer, List<RosterPlayer> rosterPlayers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Player to Drop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your roster is full. Select a player to drop to add ${addPlayer.fullName}.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: rosterPlayers.length,
                    itemBuilder: (context, index) {
                      final dropPlayer = rosterPlayers[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPositionColor(dropPlayer.position),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              dropPlayer.position ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(dropPlayer.fullName ?? 'Unknown'),
                        subtitle: Text(dropPlayer.team ?? 'FA'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final success = await ref
                              .read(freeAgentsProvider(_key).notifier)
                              .addDropPlayer(addPlayer.id, dropPlayer.playerId);
                          if (success && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${addPlayer.fullName}, dropped ${dropPlayer.fullName}',
                                ),
                              ),
                            );
                            // Refresh team data
                            ref.read(teamProvider(_teamKey).notifier).loadData();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
      default:
        return Colors.grey;
    }
  }
}

class _FreeAgentCard extends StatelessWidget {
  final Player player;
  final bool isAdding;
  final VoidCallback onAdd;

  const _FreeAgentCard({
    required this.player,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPositionColor(player.position),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  player.position ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.injuryStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getInjuryColor(player.injuryStatus),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.injuryStatus!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.team ?? 'Free Agent',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Add button
            const SizedBox(width: 8),
            if (isAdding)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
                onPressed: onAdd,
              ),
          ],
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
      default:
        return Colors.grey;
    }
  }

  Color _getInjuryColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'OUT':
        return Colors.red;
      case 'DOUBTFUL':
        return Colors.red.shade300;
      case 'QUESTIONABLE':
        return Colors.orange;
      case 'PROBABLE':
        return Colors.yellow.shade700;
      case 'IR':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}
