import 'package:flutter/material.dart';

import '../../../rosters/domain/roster_player.dart';

/// Types of action alerts that can be displayed
enum ActionAlertType {
  injuredStarter,
  byeWeekConflict,
  emptySlot,
  pendingTrade,
  lineupNotSet,
}

/// Represents a single action alert
class ActionAlert {
  final ActionAlertType type;
  final String title;
  final String? subtitle;
  final RosterPlayer? player;
  final VoidCallback? onTap;

  const ActionAlert({
    required this.type,
    required this.title,
    this.subtitle,
    this.player,
    this.onTap,
  });

  IconData get icon {
    switch (type) {
      case ActionAlertType.injuredStarter:
        return Icons.personal_injury;
      case ActionAlertType.byeWeekConflict:
        return Icons.event_busy;
      case ActionAlertType.emptySlot:
        return Icons.person_add;
      case ActionAlertType.pendingTrade:
        return Icons.swap_horiz;
      case ActionAlertType.lineupNotSet:
        return Icons.warning_amber;
    }
  }

  Color get color {
    switch (type) {
      case ActionAlertType.injuredStarter:
        return Colors.red;
      case ActionAlertType.byeWeekConflict:
        return Colors.orange;
      case ActionAlertType.emptySlot:
        return Colors.amber.shade700;
      case ActionAlertType.pendingTrade:
        return Colors.blue;
      case ActionAlertType.lineupNotSet:
        return Colors.orange;
    }
  }

  String get emoji {
    switch (type) {
      case ActionAlertType.injuredStarter:
        return '🚨';
      case ActionAlertType.byeWeekConflict:
        return '⚠️';
      case ActionAlertType.emptySlot:
        return '📋';
      case ActionAlertType.pendingTrade:
        return '📨';
      case ActionAlertType.lineupNotSet:
        return '⏰';
    }
  }
}

/// A banner that displays urgent action items requiring user attention.
/// Shows alerts for injured starters, bye week conflicts, empty slots, etc.
class ActionAlertsBanner extends StatelessWidget {
  final List<ActionAlert> alerts;
  final VoidCallback? onViewAll;
  final int maxVisible;

  const ActionAlertsBanner({
    super.key,
    required this.alerts,
    this.onViewAll,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final visibleAlerts = alerts.take(maxVisible).toList();
    final remainingCount = alerts.length - maxVisible;

    return Card(
      color: Colors.red.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notification_important,
                  size: 18,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'ACTION NEEDED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alert list
          ...visibleAlerts.map((alert) => _AlertRow(alert: alert)),
          // Show more / View all
          if (remainingCount > 0 || onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remainingCount > 0
                          ? '+$remainingCount more alerts'
                          : 'View all alerts',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final ActionAlert alert;

  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alert.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: alert.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alert.icon,
                size: 18,
                color: alert.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (alert.subtitle != null)
                    Text(
                      alert.subtitle!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (alert.onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to build action alerts from roster data
class ActionAlertsBuilder {
  /// Build alerts from roster players and lineup data
  static List<ActionAlert> buildAlerts({
    required List<RosterPlayer> starters,
    required int currentWeek,
    int pendingTradeCount = 0,
    bool lineupSet = true,
    bool lineupLockingSoon = false,
    VoidCallback? onInjuredPlayerTap,
    VoidCallback? onByePlayerTap,
    VoidCallback? onPendingTradeTap,
    VoidCallback? onSetLineupTap,
  }) {
    final alerts = <ActionAlert>[];

    // Check for injured starters (Q, D, O status)
    final injuredStarters = starters.where((p) =>
        p.injuryStatus != null &&
        ['Q', 'D', 'O', 'IR', 'PUP', 'NFI'].contains(p.injuryStatus?.toUpperCase()));

    for (final player in injuredStarters) {
      final status = _getInjuryStatusLabel(player.injuryStatus);
      alerts.add(ActionAlert(
        type: ActionAlertType.injuredStarter,
        title: '${player.fullName ?? 'Player'} is $status',
        subtitle: 'Consider benching or replacing',
        player: player,
        onTap: onInjuredPlayerTap,
      ));
    }

    // Check for players on bye week in starting lineup
    final byeWeekPlayers = starters.where((p) => p.byeWeek == currentWeek);

    for (final player in byeWeekPlayers) {
      alerts.add(ActionAlert(
        type: ActionAlertType.byeWeekConflict,
        title: '${player.fullName ?? 'Player'} on bye',
        subtitle: 'Week $currentWeek bye - bench this player',
        player: player,
        onTap: onByePlayerTap,
      ));
    }

    // Pending trade offers
    if (pendingTradeCount > 0) {
      alerts.add(ActionAlert(
        type: ActionAlertType.pendingTrade,
        title: '$pendingTradeCount pending trade${pendingTradeCount > 1 ? 's' : ''}',
        subtitle: 'Review and respond',
        onTap: onPendingTradeTap,
      ));
    }

    // Lineup not set warning (close to lock time)
    if (!lineupSet && lineupLockingSoon) {
      alerts.add(ActionAlert(
        type: ActionAlertType.lineupNotSet,
        title: 'Lineup not optimized',
        subtitle: 'Lock time approaching',
        onTap: onSetLineupTap,
      ));
    }

    return alerts;
  }

  static String _getInjuryStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'Q':
        return 'Questionable';
      case 'D':
        return 'Doubtful';
      case 'O':
        return 'Out';
      case 'IR':
        return 'on IR';
      case 'PUP':
        return 'on PUP';
      case 'NFI':
        return 'on NFI';
      default:
        return 'injured';
    }
  }
}
