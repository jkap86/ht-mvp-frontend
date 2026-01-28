import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../rosters/data/roster_repository.dart';
import '../../../rosters/domain/roster_player.dart';
import 'position_badge.dart';

/// Provider for roster players used in trade player selection
final tradeRosterPlayersProvider =
    FutureProvider.family<List<RosterPlayer>, ({int leagueId, int rosterId})>(
  (ref, params) async {
    final repo = ref.watch(rosterRepositoryProvider);
    return repo.getRosterPlayers(params.leagueId, params.rosterId);
  },
);

/// Widget for selecting players from a roster for trading
class PlayerSelectorWidget extends ConsumerWidget {
  final int leagueId;
  final int rosterId;
  final List<int> selectedPlayerIds;
  final void Function(List<int>) onSelectionChanged;

  const PlayerSelectorWidget({
    super.key,
    required this.leagueId,
    required this.rosterId,
    required this.selectedPlayerIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(tradeRosterPlayersProvider((
      leagueId: leagueId,
      rosterId: rosterId,
    )));

    return playersAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading players: $error'),
      ),
      data: (players) => _buildPlayerList(context, players),
    );
  }

  Widget _buildPlayerList(BuildContext context, List<RosterPlayer> players) {
    if (players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No players on roster',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: players.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final player = players[index];
          final isSelected = selectedPlayerIds.contains(player.playerId);

          return InkWell(
            onTap: () {
              final newSelection = List<int>.from(selectedPlayerIds);
              if (isSelected) {
                newSelection.remove(player.playerId);
              } else {
                newSelection.add(player.playerId);
              }
              onSelectionChanged(newSelection);
            },
            child: Container(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading:
                    PositionBadge(position: player.position ?? '?', size: 28),
                title: Text(
                  player.fullName ?? 'Unknown Player',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Text(player.team ?? 'FA'),
                    if (player.injuryStatus != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
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
                  ],
                ),
                dense: true,
              ),
            ),
          );
        },
      ),
    );
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
