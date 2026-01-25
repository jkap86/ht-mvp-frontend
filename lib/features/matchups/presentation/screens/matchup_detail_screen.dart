import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          onPressed: () => _navigateBack(context),
        ),
        title: const Text('Matchup Details'),
      ),
      body: detailsAsync.when(
        data: (details) => _buildContent(context, details),
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

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/leagues/$leagueId/matchups');
    }
  }

  Widget _buildContent(BuildContext context, MatchupDetails details) {
    final matchup = details.matchup;
    final team1 = details.team1;
    final team2 = details.team2;
    final isTeam1Winner = team1.totalPoints > team2.totalPoints;
    final isTeam2Winner = team2.totalPoints > team1.totalPoints;
    final isTie = team1.totalPoints == team2.totalPoints && matchup.isFinal;

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh by invalidating the provider
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Score header
            _ScoreHeader(
              team1Name: team1.teamName,
              team2Name: team2.teamName,
              team1Points: team1.totalPoints,
              team2Points: team2.totalPoints,
              isTeam1Winner: isTeam1Winner,
              isTeam2Winner: isTeam2Winner,
              isFinal: matchup.isFinal,
              week: matchup.week,
            ),

            if (isTie)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.shade100,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.balance, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'TIE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
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
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final String team1Name;
  final String team2Name;
  final double team1Points;
  final double team2Points;
  final bool isTeam1Winner;
  final bool isTeam2Winner;
  final bool isFinal;
  final int week;

  const _ScoreHeader({
    required this.team1Name,
    required this.team2Name,
    required this.team1Points,
    required this.team2Points,
    required this.isTeam1Winner,
    required this.isTeam2Winner,
    required this.isFinal,
    required this.week,
  });

  @override
  Widget build(BuildContext context) {
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
          // Week indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Week $week${isFinal ? ' - Final' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
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
                            ? Colors.green.shade700
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team1Points.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTeam1Winner && isFinal
                            ? Colors.green.shade700
                            : null,
                      ),
                    ),
                    if (isTeam1Winner && isFinal)
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  ],
                ),
              ),

              // VS divider
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (isFinal)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FINAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
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
                            ? Colors.green.shade700
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team2Points.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTeam2Winner && isFinal
                            ? Colors.green.shade700
                            : null,
                      ),
                    ),
                    if (isTeam2Winner && isFinal)
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
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
