import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../leagues/domain/league.dart';

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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          league.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${league.status} - Season ${league.season}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await context.push('/leagues/${league.id}');
          onNavigate?.call();
        },
      ),
    );
  }
}
