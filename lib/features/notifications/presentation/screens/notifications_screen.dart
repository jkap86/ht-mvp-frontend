import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_item.dart';

/// Full screen showing all notifications
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    ref.read(notificationsProvider.notifier).markAllAsRead();
                    break;
                  case 'clear_all':
                    _showClearAllDialog(context, ref);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (state.unreadCount > 0)
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 12),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20),
                      SizedBox(width: 12),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, NotificationsState state) {
    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading notifications...');
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(notificationsProvider.notifier).loadNotifications(),
      );
    }

    if (state.notifications.isEmpty) {
      return const AppEmptyView(
        icon: Icons.notifications_none,
        title: 'No Notifications',
        subtitle: 'You\'re all caught up!',
      );
    }

    final grouped = state.groupedByDate;

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(),
      child: ListView.builder(
        itemCount: grouped.entries.length,
        itemBuilder: (context, sectionIndex) {
          final entry = grouped.entries.elementAt(sectionIndex);
          final sectionTitle = entry.key;
          final notifications = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Notifications in this section
              ...notifications.map((notification) => NotificationItem(
                    notification: notification,
                    onTap: () {
                      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                      if (notification.navigationRoute != null) {
                        context.push(notification.navigationRoute!);
                      }
                    },
                    onDismiss: () {
                      ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notification dismissed'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // Re-add the notification
                              ref.read(notificationsProvider.notifier).addNotification(notification);
                            },
                          ),
                        ),
                      );
                    },
                  )),
              if (sectionIndex < grouped.length - 1) const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
