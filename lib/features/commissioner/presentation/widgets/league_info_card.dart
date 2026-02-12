import 'package:flutter/material.dart';

import '../../../leagues/domain/league.dart';
import '../../../leagues/presentation/widgets/league_status_pill.dart';
import '../providers/commissioner_provider.dart';

/// Card displaying league status information
class LeagueInfoCard extends StatelessWidget {
  final CommissionerState state;

  const LeagueInfoCard({
    super.key,
    required this.state,
  });

  LeagueStatusType _resolveStatusType(League league) {
    switch (league.seasonStatus) {
      case SeasonStatus.regularSeason:
        return LeagueStatusType.inSeason;
      case SeasonStatus.playoffs:
        return LeagueStatusType.playoffs;
      case SeasonStatus.offseason:
        return LeagueStatusType.offseason;
      case SeasonStatus.preSeason:
        switch (league.status) {
          case 'drafting':
            return LeagueStatusType.draftLive;
          case 'complete':
            return LeagueStatusType.complete;
          default:
            return LeagueStatusType.preSeason;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final league = state.league;
    if (league == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'League Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                LeagueStatusPill(
                  type: _resolveStatusType(league),
                  week: (league.seasonStatus == SeasonStatus.regularSeason ||
                          league.seasonStatus == SeasonStatus.playoffs)
                      ? league.currentWeek
                      : null,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(context, 'Season', league.season.toString()),
            _buildInfoRow(context, 'Current Week', league.currentWeek.toString()),
            _buildInfoRow(context, 'Season Phase', league.seasonStatus.displayName),
            _buildInfoRow(context, 'Members', '${state.members.length}/${league.totalRosters}'),
            _buildInfoRow(context, 'Visibility', league.isPublic ? 'Public' : 'Invite Only'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
