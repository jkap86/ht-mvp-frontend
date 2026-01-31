import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Card showing messages summary with navigation to DM inbox
class HomeMessagesCard extends StatelessWidget {
  final int unreadCount;

  const HomeMessagesCard({
    super.key,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUnread = unreadCount > 0;

    return Card(
      color: hasUnread ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () => context.go('/messages'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasUnread
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasUnread ? Icons.mark_chat_unread : Icons.chat_bubble_outline,
                  size: 24,
                  color: hasUnread
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasUnread ? colorScheme.onPrimaryContainer : null,
                          ),
                    ),
                    Text(
                      hasUnread
                          ? '$unreadCount unread message${unreadCount == 1 ? '' : 's'}'
                          : 'Direct messages',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: hasUnread ? FontWeight.w600 : null,
                            color: hasUnread
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (hasUnread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
