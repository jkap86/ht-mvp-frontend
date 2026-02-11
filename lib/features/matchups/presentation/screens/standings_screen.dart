import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../leagues/domain/league.dart';
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
            onPressed: () => navigateBack(context, fallback: '/leagues/$leagueId'),
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
            onPressed: () => navigateBack(context, fallback: '/leagues/$leagueId'),
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
          onPressed: () => navigateBack(context, fallback: '/leagues/$leagueId'),
        ),
        title: Text(state.league?.name ?? 'Standings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(standingsProvider(leagueId).notifier).loadData(),
        child: state.standings.isEmpty
            ? _buildEmptyState(state)
            : _buildStandingsTable(context, state),
      ),
    );
  }

  Widget _buildEmptyState(StandingsState state) {
    final seasonStatus = state.league?.seasonStatus;
    if (seasonStatus == SeasonStatus.offseason) {
      return const AppEmptyView(
        icon: Icons.beach_access,
        title: 'Offseason',
        subtitle: 'The season has ended. Final standings are no longer available.',
      );
    }
    if (seasonStatus == SeasonStatus.preSeason) {
      return const AppEmptyView(
        icon: Icons.calendar_today,
        title: 'Pre-Season',
        subtitle: 'Standings will appear once the season begins.',
      );
    }
    return const AppEmptyView(
      icon: Icons.leaderboard,
      title: 'No Standings Yet',
      subtitle: 'Standings will appear once the season begins.',
    );
  }

  Widget _buildStandingsTable(BuildContext context, StandingsState state) {
    final playoffLine = (state.league?.totalRosters ?? 12) ~/ 2; // Top half makes playoffs
    // Check if any standing has median scoring enabled
    final hasMedianScoring = state.standings.any((s) => s.hasMedianScoring);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: [
            const DataColumn(label: Text('Rank')),
            const DataColumn(label: Text('Team')),
            DataColumn(label: Text(hasMedianScoring ? 'Total' : 'Record')),
            if (hasMedianScoring) const DataColumn(label: Text('H2H')),
            if (hasMedianScoring) const DataColumn(label: Text('Median')),
            const DataColumn(label: Text('PF'), numeric: true),
            const DataColumn(label: Text('PA'), numeric: true),
            const DataColumn(label: Text('+/-'), numeric: true),
            const DataColumn(label: Text('Streak')),
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
                            color: AppTheme.draftActionPrimary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                        ),
                      Text(
                        '${standing.rank}',
                        style: TextStyle(
                          fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (standing.rank == playoffLine)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.horizontal_rule,
                            size: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          standing.teamName,
                          style: TextStyle(
                            fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                            color: isMyTeam ? Theme.of(context).primaryColor : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPlayoffSpot) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: AppTheme.draftActionPrimary.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
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
                if (hasMedianScoring)
                  DataCell(
                    Text(
                      standing.h2hRecord,
                      style: TextStyle(
                        fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (hasMedianScoring)
                  DataCell(
                    Text(
                      standing.medianRecord ?? '-',
                      style: TextStyle(
                        fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
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
                          ? AppTheme.draftActionPrimary
                          : standing.pointDifferential < 0
                              ? Theme.of(context).colorScheme.error
                              : null,
                    ),
                  ),
                ),
                DataCell(_buildStreak(context, standing.streak)),
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

  Widget _buildStreak(BuildContext context, String streak) {
    if (streak.isEmpty) return const Text('-');

    final isWinStreak = streak.startsWith('W');
    final color = isWinStreak ? AppTheme.draftActionPrimary : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.badgeRadius,
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
