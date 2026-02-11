import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../matchups/data/matchup_repository.dart';
import '../../../matchups/domain/matchup.dart';
import '../../../playoffs/data/playoff_repository.dart';
import '../../../playoffs/domain/playoff.dart';

/// Data class holding all season summary information.
class SeasonSummaryData {
  final List<Standing> standings;
  final PlayoffBracketView bracketView;

  SeasonSummaryData({
    required this.standings,
    required this.bracketView,
  });

  /// The playoff champion (if determined).
  PlayoffTeam? get champion => bracketView.champion;

  /// Determine runner-up from the championship matchup loser.
  PlayoffTeam? get runnerUp {
    if (bracketView.rounds.isEmpty) return null;
    final lastRound = bracketView.rounds.last;
    // Find the championship matchup in the winners bracket
    for (final matchup in lastRound.matchups) {
      if (matchup.bracketType == 'WINNERS' && matchup.isFinal && matchup.winner != null) {
        // The loser is whichever team is not the winner
        if (matchup.team1 != null && matchup.team1!.rosterId != matchup.winner!.rosterId) {
          return matchup.team1;
        }
        if (matchup.team2 != null && matchup.team2!.rosterId != matchup.winner!.rosterId) {
          return matchup.team2;
        }
      }
    }
    return null;
  }

  /// Third place winner (if a third-place game was played).
  PlayoffTeam? get thirdPlace {
    final game = bracketView.thirdPlaceGame;
    if (game == null || !game.isFinal) return null;
    return game.winner;
  }
}

/// Provider that fetches standings and playoff bracket for the season summary.
final seasonSummaryProvider = FutureProvider.autoDispose.family<SeasonSummaryData, int>(
  (ref, leagueId) async {
    final matchupRepo = ref.watch(matchupRepositoryProvider);
    final playoffRepo = ref.watch(playoffRepositoryProvider);

    final results = await Future.wait([
      matchupRepo.getStandings(leagueId),
      playoffRepo.getBracket(leagueId),
    ]);

    return SeasonSummaryData(
      standings: results[0] as List<Standing>,
      bracketView: results[1] as PlayoffBracketView,
    );
  },
);

/// End-of-season wrap-up screen shown before a commissioner can reset the league.
class SeasonSummaryScreen extends ConsumerWidget {
  final int leagueId;

  const SeasonSummaryScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(seasonSummaryProvider(leagueId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/leagues/$leagueId');
            }
          },
        ),
        title: const Text('Season Wrap-Up'),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Failed to load season summary',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => ref.invalidate(seasonSummaryProvider(leagueId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SeasonSummaryData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Trophy icon
              Icon(
                Icons.emoji_events,
                size: 72,
                color: AppTheme.medalGold,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Season Complete!',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Champion card
              if (data.champion != null)
                _buildPlacementCard(
                  context,
                  label: 'Champion',
                  teamName: data.champion!.teamName,
                  record: data.champion!.record,
                  borderColor: AppTheme.medalGold,
                  backgroundColor: AppTheme.medalGold.withAlpha(20),
                  icon: Icons.emoji_events,
                  iconColor: AppTheme.medalGold,
                  isLarge: true,
                ),

              if (data.champion != null) const SizedBox(height: AppSpacing.lg),

              // Runner-up card
              if (data.runnerUp != null)
                _buildPlacementCard(
                  context,
                  label: 'Runner-Up',
                  teamName: data.runnerUp!.teamName,
                  record: data.runnerUp!.record,
                  borderColor: AppTheme.medalSilver,
                  backgroundColor: AppTheme.medalSilver.withAlpha(15),
                  icon: Icons.workspace_premium,
                  iconColor: AppTheme.medalSilver,
                  isLarge: false,
                ),

              if (data.runnerUp != null) const SizedBox(height: AppSpacing.md),

              // Third place card
              if (data.thirdPlace != null)
                _buildPlacementCard(
                  context,
                  label: '3rd Place',
                  teamName: data.thirdPlace!.teamName,
                  record: data.thirdPlace!.record,
                  borderColor: AppTheme.medalBronze,
                  backgroundColor: AppTheme.medalBronze.withAlpha(13),
                  icon: Icons.military_tech,
                  iconColor: AppTheme.medalBronze,
                  isLarge: false,
                ),

              if (data.thirdPlace != null) const SizedBox(height: AppSpacing.lg),

              // No playoff data fallback
              if (data.champion == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No playoff results available.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              const Divider(height: AppSpacing.xxl),

              // Final Standings header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Final Standings',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Standings list
              if (data.standings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No standings data available.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...data.standings.map(
                  (standing) => _buildStandingRow(context, standing),
                ),

              const SizedBox(height: AppSpacing.xxl),

              // Continue to Reset League button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.push('/leagues/$leagueId/commissioner');
                  },
                  child: const Text('Continue to Reset League'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementCard(
    BuildContext context, {
    required String label,
    required String teamName,
    required String record,
    required Color borderColor,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required bool isLarge,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: BorderSide(color: borderColor, width: isLarge ? 2.0 : 1.0),
      ),
      color: backgroundColor,
      elevation: isLarge ? 2 : 1,
      child: Padding(
        padding: EdgeInsets.all(isLarge ? AppSpacing.xl : AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: isLarge ? 40 : 28, color: iconColor),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    teamName,
                    style: (isLarge ? textTheme.titleLarge : textTheme.titleMedium)?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (record.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      record,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingRow(BuildContext context, Standing standing) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${standing.rank}.',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              standing.teamName,
              style: textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            standing.record,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
