import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/lineup_alert_provider.dart';

/// An attention-grabbing banner shown on the home screen when any league has
/// starters who are injured, on bye, or lineup slots are empty.
///
/// Tapping the banner navigates to the first affected league's lineup screen.
class HomeLineupAlertBanner extends ConsumerWidget {
  const HomeLineupAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(lineupAlertProvider);

    // Don't show anything while loading or if there are no alerts
    if (alertState.isLoading || !alertState.hasAlerts) {
      return const SizedBox.shrink();
    }

    final activeAlerts = alertState.activeAlerts;
    final totalInjured = activeAlerts.fold<int>(
      0,
      (sum, a) => sum + a.injuredStarters.length,
    );
    final totalBye = activeAlerts.fold<int>(
      0,
      (sum, a) => sum + a.byeWeekStarters.length,
    );
    final totalEmptySlots = activeAlerts.where((a) => a.hasEmptySlots).length;

    // Build subtitle text
    final subtitle = _buildSubtitle(
      leagueCount: activeAlerts.length,
      injuredCount: totalInjured,
      byeCount: totalBye,
      emptySlotLeagues: totalEmptySlots,
    );

    // Navigate to the first affected league's team/lineup screen
    final first = activeAlerts.first;

    final alertColor = totalInjured > 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: alertColor.withValues(alpha: 0.15),
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          onTap: () {
            context.push(
              '/leagues/${first.leagueId}/team/${first.rosterId}',
            );
          },
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: alertColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lineup Alert',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: alertColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (activeAlerts.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            activeAlerts
                                .map((a) => a.leagueName)
                                .join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: alertColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle({
    required int leagueCount,
    required int injuredCount,
    required int byeCount,
    required int emptySlotLeagues,
  }) {
    final parts = <String>[];
    if (injuredCount > 0) {
      parts.add('$injuredCount injured starter${injuredCount > 1 ? 's' : ''}');
    }
    if (byeCount > 0) {
      parts.add('$byeCount on bye');
    }
    if (emptySlotLeagues > 0) {
      parts.add('empty slots');
    }

    final issueText = parts.join(', ');

    if (leagueCount == 1) {
      return issueText;
    }
    return '$issueText across $leagueCount leagues';
  }
}
