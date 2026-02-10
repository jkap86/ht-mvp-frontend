import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../matchups/domain/matchup.dart';
import 'countdown_timer_widget.dart';

/// A card showing the user's current week matchup preview.
/// Displays both teams, records, projected scores, and countdown to lineup lock.
class MatchupPreviewCard extends StatelessWidget {
  final int currentWeek;
  final Matchup matchup;
  final Standing? userStanding;
  final Standing? opponentStanding;
  final double? userProjectedPoints;
  final double? opponentProjectedPoints;
  final DateTime? lineupLockTime;
  final VoidCallback? onViewMatchup;
  final VoidCallback? onSetLineup;

  const MatchupPreviewCard({
    super.key,
    required this.currentWeek,
    required this.matchup,
    this.userStanding,
    this.opponentStanding,
    this.userProjectedPoints,
    this.opponentProjectedPoints,
    this.lineupLockTime,
    this.onViewMatchup,
    this.onSetLineup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_football,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'WEEK $currentWeek MATCHUP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.onPrimaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (matchup.isPlayoff)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.draftWarning,
                      borderRadius: AppSpacing.badgeRadius,
                    ),
                    child: Text(
                      'PLAYOFF',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Teams comparison
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User's team
                _TeamRow(
                  teamName: matchup.roster1TeamName ?? 'Your Team',
                  record: userStanding?.record ?? '0-0',
                  points: matchup.isFinal ? matchup.roster1Points : null,
                  projectedPoints: userProjectedPoints,
                  isUser: true,
                  isWinner: matchup.isFinal && matchup.winnerId == matchup.roster1Id,
                ),
                const SizedBox(height: 8),
                // VS divider
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'vs',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                // Opponent's team
                _TeamRow(
                  teamName: matchup.roster2TeamName ?? 'Opponent',
                  record: opponentStanding?.record ?? '0-0',
                  points: matchup.isFinal ? matchup.roster2Points : null,
                  projectedPoints: opponentProjectedPoints,
                  isUser: false,
                  isWinner: matchup.isFinal && matchup.winnerId == matchup.roster2Id,
                ),
              ],
            ),
          ),
          // Projected scores or final result
          if (!matchup.isFinal && (userProjectedPoints != null || opponentProjectedPoints != null))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Projected: ',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${(userProjectedPoints ?? 0).toStringAsFixed(1)} - ${(opponentProjectedPoints ?? 0).toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // Countdown and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (lineupLockTime != null && !matchup.isFinal) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lineup locks in: ',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      CountdownTimerWidget(
                        deadline: lineupLockTime!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewMatchup,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Matchup'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (!matchup.isFinal) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onSetLineup,
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('Set Lineup'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String teamName;
  final String record;
  final double? points;
  final double? projectedPoints;
  final bool isUser;
  final bool isWinner;

  const _TeamRow({
    required this.teamName,
    required this.record,
    this.points,
    this.projectedPoints,
    required this.isUser,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Avatar placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: AppSpacing.buttonRadius,
          ),
          child: Icon(
            Icons.person,
            color: isUser ? colorScheme.primary : colorScheme.outlineVariant,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        // Team info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      teamName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isUser ? colorScheme.primary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isWinner) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: AppTheme.draftWarning,
                    ),
                  ],
                ],
              ),
              Text(
                record,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Points
        if (points != null)
          Text(
            points!.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isWinner ? AppTheme.draftActionPrimary : null,
            ),
          ),
      ],
    );
  }
}
