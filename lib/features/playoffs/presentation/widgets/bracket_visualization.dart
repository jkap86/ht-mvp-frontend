import 'package:flutter/material.dart';

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
                        color: _getSeedColor(seed.seed),
                      ),
                      child: Center(
                        child: Text(
                          '${seed.seed}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                                  color: Colors.grey.shade600,
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
              borderRadius: BorderRadius.circular(16),
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
            'Week ${round.week}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          if (round.matchups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'TBD',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
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
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          Text(
            'CHAMPION',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getSeedColor(champion.seed),
            ),
            child: Center(
              child: Text(
                '${champion.seed}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Color _getSeedColor(int seed) {
    switch (seed) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.blueGrey.shade200;
    }
  }
}
