import 'package:flutter/material.dart';

import '../../domain/league.dart';

class LeagueHeaderWidget extends StatelessWidget {
  final League league;
  final int memberCount;
  final bool isCommissioner;
  final VoidCallback? onSettingsTap;

  const LeagueHeaderWidget({
    super.key,
    required this.league,
    required this.memberCount,
    required this.isCommissioner,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  league.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isCommissioner)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  onPressed: onSettingsTap,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(icon: Icons.calendar_today, label: '${league.season}'),
              _HeaderChip(icon: Icons.sports_football, label: league.modeDisplay),
              _HeaderChip(
                icon: league.rosterType == 'bestball' ? Icons.auto_awesome : Icons.view_list,
                label: league.rosterTypeDisplay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
