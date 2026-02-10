import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/playoff.dart';
import 'playoff_matchup_card.dart';

class BracketVisualization extends StatelessWidget {
  final PlayoffBracketView bracketView;
  final int? userRosterId;

  const BracketVisualization({
    super.key,
    required this.bracketView,
    this.userRosterId,
  });

  @override
  Widget build(BuildContext context) {
    if (!bracketView.hasPlayoffs) {
      return const Center(
        child: Text('No playoff bracket generated yet'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Winners Bracket (always shown)
          _buildSectionHeader(context, 'Winners Bracket', Icons.emoji_events, AppTheme.draftWarning),
          const SizedBox(height: 8),
          _buildWinnersBracket(context),

          // Section 2: 3rd Place Game (conditional)
          if (bracketView.hasThirdPlaceGame) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(context, '3rd Place Game', Icons.looks_3, Theme.of(context).colorScheme.tertiary),
            const SizedBox(height: 8),
            _buildThirdPlaceSection(context),
          ],

          // Section 3: Consolation Bracket (conditional)
          if (bracketView.hasConsolation) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Consolation Bracket', Icons.sports_handball, Theme.of(context).colorScheme.tertiary),
            const SizedBox(height: 8),
            _buildConsolationBracket(context),
          ],
        ],
      ),
    );
  }

  /// Builds a styled section header
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  /// Builds the winners bracket horizontal scroll
  Widget _buildWinnersBracket(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Seeding column (left side)
          _buildSeedingColumn(context),
          const SizedBox(width: 16),
          // Each round as a column
          ...bracketView.rounds.map((round) => _buildRoundColumn(context, round)),
          // Champion trophy (right side)
          if (bracketView.champion != null) ...[
            const SizedBox(width: 16),
            _buildChampionColumn(context),
          ],
        ],
      ),
    );
  }

  /// Builds the 3rd place game section
  Widget _buildThirdPlaceSection(BuildContext context) {
    final thirdPlaceGame = bracketView.thirdPlaceGame!;

    // Build week label based on series length
    String weekLabel;
    if (thirdPlaceGame.seriesLength > 1) {
      // Multi-week series: show range
      final startWeek = thirdPlaceGame.week - thirdPlaceGame.seriesGame + 1;
      final endWeek = startWeek + thirdPlaceGame.seriesLength - 1;
      weekLabel = 'Weeks $startWeek-$endWeek';
    } else {
      weekLabel = 'Week ${thirdPlaceGame.week}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    weekLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  if (thirdPlaceGame.isFinal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.buttonRadius,
                      ),
                      child: Text(
                        'FINAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: PlayoffMatchupCard(
                  matchup: thirdPlaceGame,
                  userRosterId: userRosterId,
                ),
              ),
              if (thirdPlaceGame.isFinal && thirdPlaceGame.winner != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.tertiary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '3rd Place: ${thirdPlaceGame.winner!.teamName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the consolation bracket section
  Widget _buildConsolationBracket(BuildContext context) {
    final consolation = bracketView.consolation!;

    // Check if there's a consolation winner from the final round
    PlayoffTeam? consolationWinner;
    if (consolation.rounds.isNotEmpty) {
      final lastRound = consolation.rounds.last;
      if (lastRound.matchups.isNotEmpty && lastRound.matchups.first.winner != null) {
        consolationWinner = lastRound.matchups.first.winner;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Consolation seeding column (left side)
          _buildConsolationSeedingColumn(context, consolation.seeds),
          const SizedBox(width: 16),
          // Each round as a column
          ...consolation.rounds.map((round) => _buildRoundColumn(context, round)),
          // Consolation winner (right side)
          if (consolationWinner != null) ...[
            const SizedBox(width: 16),
            _buildConsolationWinnerColumn(context, consolationWinner),
          ],
        ],
      ),
    );
  }

  /// Builds the consolation bracket seeding column
  Widget _buildConsolationSeedingColumn(BuildContext context, List<ConsolationSeed> seeds) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seeds',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...seeds.map((seed) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      child: Center(
                        child: Text(
                          '${seed.standingsPosition}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seed.teamName,
                            style: TextStyle(
                              fontWeight: seed.rosterId == userRosterId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: seed.rosterId == userRosterId
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            seed.record,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Builds the consolation winner column
  Widget _buildConsolationWinnerColumn(BuildContext context, PlayoffTeam winner) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            size: 48,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 8),
          Text(
            'CONSOLATION',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          Text(
            'WINNER',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            winner.teamName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: winner.rosterId == userRosterId
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            winner.record,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }


  Widget _buildSeedingColumn(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seeds',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...bracketView.seeds.map((seed) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getSeedColor(context, seed.seed),
                      ),
                      child: Center(
                        child: Text(
                          '${seed.seed}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seed.teamName ?? 'Team ${seed.seed}',
                            style: TextStyle(
                              fontWeight: seed.rosterId == userRosterId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: seed.rosterId == userRosterId
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            seed.regularSeasonRecord,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (seed.hasBye)
                      Chip(
                        label: const Text('BYE'),
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRoundColumn(BuildContext context, PlayoffRound round) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Text(
              round.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Text(
            round.weekLabel, // Use weekLabel for multi-week support
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (round.matchups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'TBD',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...round.matchups.map(
              (matchup) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PlayoffMatchupCard(
                  matchup: matchup,
                  userRosterId: userRosterId,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChampionColumn(BuildContext context) {
    final champion = bracketView.champion!;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: AppTheme.draftWarning,
          ),
          const SizedBox(height: 8),
          Text(
            'CHAMPION',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.draftWarning,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getSeedColor(context, champion.seed),
            ),
            child: Center(
              child: Text(
                '${champion.seed}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            champion.teamName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: champion.rosterId == userRosterId
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            champion.record,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Color _getSeedColor(BuildContext context, int seed) {
    switch (seed) {
      case 1:
        return AppTheme.draftWarning;
      case 2:
        return Theme.of(context).colorScheme.outline;
      case 3:
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }
}
