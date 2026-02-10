import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/states/states.dart';
import '../../domain/matchup.dart';
import '../providers/matchup_provider.dart';
import '../widgets/lineup_comparison_widget.dart';

class MatchupDetailScreen extends ConsumerWidget {
  final int leagueId;
  final int matchupId;

  const MatchupDetailScreen({
    super.key,
    required this.leagueId,
    required this.matchupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(
      matchupDetailsProvider((leagueId: leagueId, matchupId: matchupId)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateBack(context, fallback: '/leagues/$leagueId/matchups'),
        ),
        title: const Text('Matchup Details'),
      ),
      body: detailsAsync.when(
        data: (details) => _buildContent(context, ref, details),
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(
            matchupDetailsProvider((leagueId: leagueId, matchupId: matchupId)),
          ),
        ),
      ),
    );
  }


  Widget _buildContent(BuildContext context, WidgetRef ref, MatchupDetails details) {
    final matchup = details.matchup;
    final team1 = details.team1;
    final team2 = details.team2;

    // Use live actual points if available, otherwise use team total points
    final team1ActualPoints = matchup.isFinal
        ? team1.totalPoints
        : (matchup.roster1PointsActual ?? team1.totalPoints);
    final team2ActualPoints = matchup.isFinal
        ? team2.totalPoints
        : (matchup.roster2PointsActual ?? team2.totalPoints);

    final isTeam1Winner = team1ActualPoints > team2ActualPoints;
    final isTeam2Winner = team2ActualPoints > team1ActualPoints;
    final isTie = team1ActualPoints == team2ActualPoints && matchup.isFinal;

    return RefreshIndicator(
      onRefresh: () async {
        final key = (leagueId: leagueId, matchupId: matchupId);
        ref.invalidate(matchupDetailsProvider(key));
        await ref.read(matchupDetailsProvider(key).future);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
          children: [
            // Score header
            _ScoreHeader(
              team1Name: team1.teamName,
              team2Name: team2.teamName,
              team1Points: team1ActualPoints,
              team2Points: team2ActualPoints,
              team1ProjectedPoints: matchup.roster1PointsProjected,
              team2ProjectedPoints: matchup.roster2PointsProjected,
              isTeam1Winner: isTeam1Winner,
              isTeam2Winner: isTeam2Winner,
              isFinal: matchup.isFinal,
              isLive: matchup.hasLiveData,
              week: matchup.week,
            ),

            if (isTie)
              Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.tertiary.withAlpha(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.balance, size: 16, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      'TIE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Lineup comparison
            LineupComparisonWidget(
              team1: team1,
              team2: team2,
              isTeam1Winner: isTeam1Winner,
              isTeam2Winner: isTeam2Winner,
            ),

            const SizedBox(height: 24),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final String team1Name;
  final String team2Name;
  final double team1Points;
  final double team2Points;
  final double? team1ProjectedPoints;
  final double? team2ProjectedPoints;
  final bool isTeam1Winner;
  final bool isTeam2Winner;
  final bool isFinal;
  final bool isLive;
  final int week;

  const _ScoreHeader({
    required this.team1Name,
    required this.team2Name,
    required this.team1Points,
    required this.team2Points,
    this.team1ProjectedPoints,
    this.team2ProjectedPoints,
    required this.isTeam1Winner,
    required this.isTeam2Winner,
    required this.isFinal,
    this.isLive = false,
    required this.week,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Week indicator with status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Text(
                  'Week $week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (isLive && !isFinal) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(30),
                    borderRadius: AppSpacing.cardRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team 1
              Expanded(
                child: Column(
                  children: [
                    Text(
                      team1Name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isTeam1Winner && isFinal
                            ? AppTheme.draftActionPrimary
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team1Points.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTeam1Winner && isFinal
                            ? AppTheme.draftActionPrimary
                            : null,
                      ),
                    ),
                    // Projected points (for live games)
                    if (!isFinal && team1ProjectedPoints != null)
                      Text(
                        'Proj: ${team1ProjectedPoints!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (isTeam1Winner && isFinal)
                      Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 20),
                  ],
                ),
              ),

              // VS divider
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isFinal)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.draftActionPrimary.withAlpha(30),
                          borderRadius: AppSpacing.badgeRadius,
                        ),
                        child: const Text(
                          'FINAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.draftActionPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Team 2
              Expanded(
                child: Column(
                  children: [
                    Text(
                      team2Name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isTeam2Winner && isFinal
                            ? AppTheme.draftActionPrimary
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team2Points.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTeam2Winner && isFinal
                            ? AppTheme.draftActionPrimary
                            : null,
                      ),
                    ),
                    // Projected points (for live games)
                    if (!isFinal && team2ProjectedPoints != null)
                      Text(
                        'Proj: ${team2ProjectedPoints!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (isTeam2Winner && isFinal)
                      Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
