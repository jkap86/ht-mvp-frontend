import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_router.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_item.dart';

/// Full screen showing all notifications
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final lastLeagueRoute = ref.watch(lastLeagueRouteProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the exact league route (tab) the user was on, or home
            if (lastLeagueRoute != null) {
              context.go(lastLeagueRoute);
            } else {
              context.go('/');
            }
          },
          tooltip: 'Back',
        ),
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
      return const SkeletonList(itemCount: 6);
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
        subtitle: 'You\'re all caught up!\nNotifications appear here while the app is open.',
      );
    }

    final grouped = state.groupedByDate;

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(),
      child: ListView.builder(
        // +1 for the info banner at top
        itemCount: grouped.entries.length + 1,
        itemBuilder: (context, index) {
          // First item: in-app only info banner
          if (index == 0) {
            return _buildInAppOnlyBanner(context);
          }

          final sectionIndex = index - 1;
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

  Widget _buildInAppOnlyBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'In-app only. Push notifications are not yet available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
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
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
