import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/draft_pick.dart';

/// Widget displaying the user's drafted schedule in a matchups draft.
///
/// Replaces "my roster" for matchups drafts, showing drafted matchups
/// organized by week with calendar/list view.
class MyScheduleWidget extends StatelessWidget {
  final List<DraftPick> myPicks;
  final String username;
  final int totalWeeks;

  const MyScheduleWidget({
    super.key,
    required this.myPicks,
    required this.totalWeeks,
    this.username = 'My Team',
  });

  /// Get the pick for a specific week
  DraftPick? _getPickForWeek(int week) {
    // In matchups draft, the pick metadata contains the week number
    // For now, we'll use round number as week number
    return myPicks
        .where((pick) => pick.round == week)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(theme),
        const Divider(height: 1),

        // Schedule list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: totalWeeks,
            itemBuilder: (context, index) {
              final week = index + 1;
              final pick = _getPickForWeek(week);
              return _buildWeekCard(theme, week, pick);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            username,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Text(
              '${myPicks.length}/$totalWeeks weeks',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(ThemeData theme, int week, DraftPick? pick) {
    final isEmpty = pick == null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: isEmpty
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Week badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEmpty
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Matchup info
            Expanded(
              child: isEmpty
                  ? _buildEmptyWeek(theme)
                  : _buildFilledWeek(theme, pick),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWeek(ThemeData theme) {
    return Text(
      'No matchup selected',
      style: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildFilledWeek(ThemeData theme, DraftPick pick) {
    // For matchups drafts, we need to extract opponent info from pick metadata
    // The backend stores this in the pick_metadata JSONB field
    // For now, we'll show placeholder data

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'vs ',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Text(
                pick.username ?? 'Opponent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        if (pick.pickedAt != null)
          Text(
            'Picked ${_formatPickTime(pick.pickedAt!)}',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }

  String _formatPickTime(DateTime pickedAt) {
    final now = DateTime.now();
    final diff = now.difference(pickedAt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
