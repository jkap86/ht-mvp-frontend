import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../providers/standings_provider.dart';

class StandingsScreen extends ConsumerWidget {
  final int leagueId;

  const StandingsScreen({
    super.key,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(standingsProvider(leagueId));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: const Text('Standings'),
        ),
        body: const AppLoadingView(),
      );
    }

    if (state.error != null && state.standings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: const Text('Standings'),
        ),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(standingsProvider(leagueId).notifier).loadData(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        title: Text(state.league?.name ?? 'Standings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(standingsProvider(leagueId).notifier).loadData(),
        child: state.standings.isEmpty
            ? const AppEmptyView(
                icon: Icons.leaderboard,
                title: 'No Standings Yet',
                subtitle: 'Standings will appear once the season begins.',
              )
            : _buildStandingsTable(context, state),
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

  Widget _buildStandingsTable(BuildContext context, StandingsState state) {
    final playoffLine = (state.league?.totalRosters ?? 12) ~/ 2; // Top half makes playoffs

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: const [
            DataColumn(label: Text('Rank')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('Record')),
            DataColumn(label: Text('PF'), numeric: true),
            DataColumn(label: Text('PA'), numeric: true),
            DataColumn(label: Text('+/-'), numeric: true),
            DataColumn(label: Text('Streak')),
          ],
          rows: state.standings.map((standing) {
            final isMyTeam = standing.rosterId == state.myRosterId;
            final isPlayoffSpot = standing.rank <= playoffLine;

            return DataRow(
              color: WidgetStateProperty.all(
                isMyTeam
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : null,
              ),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlayoffSpot)
                        Container(
                          width: 4,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Text(
                        '${standing.rank}',
                        style: TextStyle(
                          fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    standing.teamName,
                    style: TextStyle(
                      fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                      color: isMyTeam ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    standing.record,
                    style: TextStyle(
                      fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    standing.pointsFor.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    standing.pointsAgainst.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDifferential(standing.pointDifferential),
                    style: TextStyle(
                      fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                      color: standing.pointDifferential > 0
                          ? Colors.green
                          : standing.pointDifferential < 0
                              ? Colors.red
                              : null,
                    ),
                  ),
                ),
                DataCell(_buildStreak(standing.streak)),
              ],
            );
          }).toList(),
        ),
          ),
        ),
      ),
    );
  }

  String _formatDifferential(double diff) {
    if (diff > 0) return '+${diff.toStringAsFixed(1)}';
    return diff.toStringAsFixed(1);
  }

  Widget _buildStreak(String streak) {
    if (streak.isEmpty) return const Text('-');

    final isWinStreak = streak.startsWith('W');
    final color = isWinStreak ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        streak,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
