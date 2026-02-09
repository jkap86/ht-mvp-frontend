import 'package:flutter/material.dart';

import '../../domain/playoff.dart';

class PlayoffMatchupCard extends StatelessWidget {
  final PlayoffMatchup matchup;
  final int? userRosterId;

  const PlayoffMatchupCard({
    super.key,
    required this.matchup,
    this.userRosterId,
  });

  bool _isUserTeam(int? rosterId) => rosterId != null && rosterId == userRosterId;

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Series game badge for multi-week matchups
            if (matchup.isMultiWeekSeries) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_score,
                      size: 12,
                      color: Colors.indigo.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      matchup.gameLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildTeamRow(context, matchup.team1, isTop: true),
            const Divider(height: 8),
            _buildTeamRow(context, matchup.team2, isTop: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(BuildContext context, PlayoffTeam? team, {required bool isTop}) {
    if (team == null) {
      return _buildByeRow(context);
    }

    final isWinner = matchup.winner?.rosterId == team.rosterId;
    final isUser = _isUserTeam(team.rosterId);

    return Row(
      children: [
        // Seed badge
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getSeedColor(team.seed),
          ),
          child: Center(
            child: Text(
              '${team.seed}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Team name
        Expanded(
          child: Text(
            team.teamName,
            style: TextStyle(
              fontWeight: isWinner || isUser ? FontWeight.bold : FontWeight.normal,
              color: isUser ? Theme.of(context).colorScheme.primary : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Score (if matchup is final)
        if (matchup.isFinal && team.points != null) ...[
          const SizedBox(width: 8),
          Text(
            team.points!.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
        // Winner indicator
        if (isWinner) ...[
          const SizedBox(width: 4),
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ],
    );
  }

  Widget _buildByeRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
          ),
          child: const Center(
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'BYE',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
