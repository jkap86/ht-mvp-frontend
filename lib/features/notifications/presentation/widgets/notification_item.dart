import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/notification_model.dart';

/// Widget displaying a single notification in a list
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.tradePending:
      case NotificationType.tradeAccepted:
      case NotificationType.tradeRejected:
      case NotificationType.tradeCompleted:
        return Icons.swap_horiz;
      case NotificationType.draftStarting:
      case NotificationType.draftStarted:
      case NotificationType.draftPick:
        return Icons.timer;
      case NotificationType.waiverProcessed:
      case NotificationType.waiverSuccess:
      case NotificationType.waiverFailed:
        return Icons.assignment;
      case NotificationType.scoresUpdated:
      case NotificationType.weekFinalized:
        return Icons.sports_score;
      case NotificationType.messageReceived:
        return Icons.chat_bubble_outline;
      case NotificationType.leagueInvite:
      case NotificationType.invitationReceived:
        return Icons.person_add;
      case NotificationType.matchupResult:
        return Icons.sports_football;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (notification.type) {
      case NotificationType.tradePending:
        return colorScheme.tertiary;
      case NotificationType.tradeAccepted:
      case NotificationType.tradeCompleted:
        return colorScheme.primary;
      case NotificationType.tradeRejected:
        return colorScheme.error;
      case NotificationType.draftStarting:
      case NotificationType.draftStarted:
      case NotificationType.draftPick:
        return colorScheme.secondary;
      case NotificationType.waiverProcessed:
        return colorScheme.primary;
      case NotificationType.waiverSuccess:
        return colorScheme.primary;
      case NotificationType.waiverFailed:
        return colorScheme.error;
      case NotificationType.scoresUpdated:
      case NotificationType.weekFinalized:
        return colorScheme.primary;
      case NotificationType.messageReceived:
        return colorScheme.primary;
      case NotificationType.leagueInvite:
      case NotificationType.invitationReceived:
        return colorScheme.tertiary;
      case NotificationType.matchupResult:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: Icon(
          Icons.delete,
          color: colorScheme.onError,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? null : colorScheme.primaryContainer.withValues(alpha: 0.3),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconColor(colorScheme).withValues(alpha: 0.1),
                  borderRadius: AppSpacing.buttonRadius,
                ),
                child: Icon(
                  _getIcon(),
                  color: _getIconColor(colorScheme),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.leagueName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.leagueName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
