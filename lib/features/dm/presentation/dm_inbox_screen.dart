import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/widgets/states/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../domain/conversation.dart';
import 'providers/dm_inbox_provider.dart';
import 'widgets/dm_user_search_sheet.dart';

class DmInboxScreen extends ConsumerWidget {
  const DmInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dmInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dmInboxProvider.notifier).loadConversations(),
        child: _buildBody(context, ref, state),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationSheet(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DmInboxState state) {
    if (state.isLoading) {
      return const AppLoadingView();
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(dmInboxProvider.notifier).loadConversations(),
      );
    }

    if (state.conversations.isEmpty) {
      return const AppEmptyView(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Tap the pencil icon to start a conversation',
      );
    }

    return ListView.builder(
      itemCount: state.conversations.length,
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        return _ConversationTile(
          conversation: conversation,
          onTap: () {
            // Mark as read locally before navigating
            ref.read(dmInboxProvider.notifier).markConversationReadLocally(conversation.id);
            context.push('/messages/${conversation.id}');
          },
        );
      },
    );
  }

  void _showNewConversationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const DmUserSearchSheet(),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;
    final lastMessage = conversation.lastMessage;

    return ListTile(
      onTap: onTap,
      leading: UserAvatar(
        name: conversation.otherUsername,
        size: 48,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUsername,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            )
          : Text(
              'No messages yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
      trailing: lastMessage != null
          ? Text(
              formatMessageTimestamp(lastMessage.createdAt, compact: true),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
    );
  }
}
