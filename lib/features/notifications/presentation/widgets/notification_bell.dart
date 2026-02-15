import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';

/// AppBar icon button with badge showing unread notification count
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : '$unreadCount',
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notifications',
      onPressed: () {
        context.go('/notifications');
      },
    );
  }
}

/// Alternative notification bell that opens a popup menu instead of navigating
class NotificationBellPopup extends ConsumerWidget {
  const NotificationBellPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final state = ref.watch(notificationsProvider);

    return PopupMenuButton<String>(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : '$unreadCount',
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notifications',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
      itemBuilder: (context) {
        if (state.notifications.isEmpty) {
          return [
            const PopupMenuItem(
              enabled: false,
              child: Text('No notifications'),
            ),
          ];
        }

        final items = <PopupMenuEntry<String>>[
          PopupMenuItem(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                      Navigator.pop(context);
                    },
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ];

        // Show up to 5 recent notifications
        for (final notification in state.notifications.take(5)) {
          items.add(
            PopupMenuItem(
              value: notification.id,
              child: _NotificationPopupItem(notification: notification),
            ),
          );
        }

        if (state.notifications.length > 5) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem(
              value: 'view_all',
              child: Center(
                child: Text(
                  'View all notifications',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        return items;
      },
      onSelected: (value) {
        if (value == 'view_all') {
          context.go('/notifications');
        } else {
          // Mark as read and navigate
          final notification = state.notifications.where((n) => n.id == value).firstOrNull;
          if (notification == null) return;
          ref.read(notificationsProvider.notifier).markAsRead(value);
          if (notification.navigationRoute != null) {
            context.push(notification.navigationRoute!);
          }
        }
      },
    );
  }
}

class _NotificationPopupItem extends StatelessWidget {
  final AppNotification notification;

  const _NotificationPopupItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notification.isRead;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUnread)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
