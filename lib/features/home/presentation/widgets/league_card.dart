import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../leagues/domain/league.dart';
import '../../../leagues/presentation/widgets/league_status_pill.dart';

class LeagueCard extends StatelessWidget {
  final League league;
  final VoidCallback? onNavigate;

  const LeagueCard({super.key, required this.league, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            league.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                league.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusPill(),
          ],
        ),
        subtitle: Text('Season ${league.season}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.go('/leagues/${league.id}');
          onNavigate?.call();
        },
      ),
    );
  }

  Widget _buildStatusPill() {
    // Determine status type based on league season status and league status
    LeagueStatusType statusType;
    int? week;

    switch (league.seasonStatus) {
      case SeasonStatus.regularSeason:
        statusType = LeagueStatusType.inSeason;
        week = league.currentWeek;
        break;
      case SeasonStatus.playoffs:
        statusType = LeagueStatusType.playoffs;
        week = league.currentWeek;
        break;
      case SeasonStatus.offseason:
        statusType = LeagueStatusType.offseason;
        break;
      case SeasonStatus.preSeason:
        // Distinguish pre-draft vs actively drafting
        switch (league.status) {
          case 'drafting':
            statusType = LeagueStatusType.draftLive;
            break;
          case 'complete':
            statusType = LeagueStatusType.complete;
            break;
          default:
            statusType = LeagueStatusType.preSeason;
        }
        break;
    }

    return LeagueStatusPill(
      type: statusType,
      week: week,
    );
  }
}
