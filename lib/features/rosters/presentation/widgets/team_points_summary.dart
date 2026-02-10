import 'package:flutter/material.dart';

class TeamPointsSummary extends StatelessWidget {
  final double totalPoints;
  final int startersCount;
  final int benchCount;

  const TeamPointsSummary({
    super.key,
    required this.totalPoints,
    required this.startersCount,
    required this.benchCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              value: totalPoints.toStringAsFixed(2),
              label: 'Total Points',
            ),
            _StatColumn(
              value: '$startersCount',
              label: 'Starters',
            ),
            _StatColumn(
              value: '$benchCount',
              label: 'Bench',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
