import 'package:flutter/material.dart';

import '../../domain/league.dart';

class LeagueSettingsSummary extends StatelessWidget {
  final League league;
  final int memberCount;
  final String draftType;

  const LeagueSettingsSummary({
    super.key,
    required this.league,
    required this.memberCount,
    required this.draftType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SettingCard(
            label: 'Scoring',
            value: league.scoringType,
            icon: Icons.scoreboard,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SettingCard(
            label: 'Teams',
            value: '$memberCount/${league.totalRosters}',
            icon: Icons.group,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SettingCard(
            label: 'Draft',
            value: draftType,
            icon: Icons.event,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SettingCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
