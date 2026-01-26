import 'package:flutter/material.dart';

import '../providers/commissioner_provider.dart';

/// Card displaying league status information
class LeagueInfoCard extends StatelessWidget {
  final CommissionerState state;

  const LeagueInfoCard({
    super.key,
    required this.state,
  });

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
              ],
            ),
            const Divider(),
            _buildInfoRow('Season', league.season.toString()),
            _buildInfoRow('Current Week', league.currentWeek.toString()),
            _buildInfoRow('Status', league.status.toUpperCase()),
            _buildInfoRow('Members', '${state.members.length}/${league.totalRosters}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
