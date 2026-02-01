import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../dm/domain/conversation.dart';
import '../../../dm/presentation/providers/dm_inbox_provider.dart';

/// Compact conversation list for the floating chat widget.
/// Shows a list of DM conversations with option to start a new one.
class DmConversationList extends ConsumerWidget {
  final void Function(int conversationId, String username) onSelect;
  final VoidCallback onNewConversation;

  const DmConversationList({
    super.key,
    required this.onSelect,
    required this.onNewConversation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dmInboxProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Conversation list
        Expanded(
          child: _buildContent(context, ref, state, theme),
        ),
        // New conversation button
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onNewConversation,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('New Message'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DmInboxState state,
    ThemeData theme,
  ) {
    if (state.isLoading) {
      return const AppLoadingView();
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error ?? 'Error loading messages',
        onRetry: () => ref.read(dmInboxProvider.notifier).loadConversations(),
      );
    }

    if (state.conversations.isEmpty) {
      return const AppEmptyView(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Start a conversation!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dmInboxProvider.notifier).loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          final conversation = state.conversations[index];
          return _CompactConversationTile(
            conversation: conversation,
            onTap: () {
              // Mark as read locally before selecting
              ref.read(dmInboxProvider.notifier).markConversationReadLocally(conversation.id);
              onSelect(conversation.id, conversation.otherUsername);
            },
          );
        },
      ),
    );
  }
}

/// Compact conversation tile for the floating chat widget.
class _CompactConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _CompactConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;
    final lastMessage = conversation.lastMessage;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            UserAvatar(
              name: conversation.otherUsername,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUsername,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          _formatTime(lastMessage.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage?.message ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.outline,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            fontStyle: lastMessage == null ? FontStyle.italic : null,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
