import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_dashboard_provider.dart';

/// Card showing user's matchups across all leagues
class HomeMatchupsCard extends StatelessWidget {
  final List<DashboardMatchup> matchups;

  const HomeMatchupsCard({
    super.key,
    required this.matchups,
  });

  @override
  Widget build(BuildContext context) {
    if (matchups.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.sports_football,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Matchups This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...matchups.map((m) => _MatchupItem(matchup: m)),
        ],
      ),
    );
  }
}

class _MatchupItem extends StatelessWidget {
  final DashboardMatchup matchup;

  const _MatchupItem({required this.matchup});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWinning = (matchup.userScore ?? 0) > (matchup.opponentScore ?? 0);
    final isLosing = (matchup.userScore ?? 0) < (matchup.opponentScore ?? 0);

    return InkWell(
      onTap: () {
        context.push('/leagues/${matchup.leagueId}/matchups/${matchup.matchup.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // League indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isWinning
                    ? Colors.green
                    : isLosing
                        ? Colors.red
                        : colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Matchup info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matchup.leagueName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'vs ${matchup.opponentName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            // Scores
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      matchup.userScore?.toStringAsFixed(1) ?? '-',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isWinning ? Colors.green : null,
                          ),
                    ),
                    Text(
                      ' - ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      matchup.opponentScore?.toStringAsFixed(1) ?? '-',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLosing ? Colors.red : null,
                          ),
                    ),
                  ],
                ),
                if (matchup.matchup.isFinal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Final',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
