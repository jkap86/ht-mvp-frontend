import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_display.dart';
import '../../../core/utils/idempotency.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/states/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../domain/direct_message.dart';
import 'providers/dm_conversation_provider.dart';
import 'providers/dm_inbox_provider.dart';

class DmConversationScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const DmConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<DmConversationScreen> createState() => _DmConversationScreenState();
}

class _DmConversationScreenState extends ConsumerState<DmConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Since list is reversed, "top" (oldest messages) is at maxScrollExtent
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final state = ref.read(dmConversationProvider(widget.conversationId));
      if (state.hasMore && !state.isLoadingMore) {
        ref.read(dmConversationProvider(widget.conversationId).notifier)
            .loadMoreMessages();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final key = newIdempotencyKey();
    final notifier = ref.read(dmConversationProvider(widget.conversationId).notifier);
    final success = await notifier.sendMessage(text, idempotencyKey: key);
    if (success) {
      _messageController.clear();
    } else if (mounted) {
      'Error sending message'.showAsError(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmConversationProvider(widget.conversationId));
    final inboxState = ref.watch(dmInboxProvider);
    final currentUserId = ref.watch(authStateProvider).user?.id;

    // Find conversation to get other user's name
    final conversation = inboxState.conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    final otherUsername = conversation?.otherUsername ?? 'Messages';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(name: otherUsername, size: 32),
            const SizedBox(width: 12),
            Text(otherUsername),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(state, currentUserId),
          ),
          _buildMessageInput(state),
        ],
      ),
    );
  }

  Widget _buildMessageList(DmConversationState state, String? currentUserId) {
    if (state.isLoading) {
      return const AppLoadingView();
    }

    if (state.messages.isEmpty) {
      return const AppEmptyView(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Start the conversation!',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end (oldest messages)
        if (state.isLoadingMore && index == state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final message = state.messages[index];
        final isMe = message.senderId == currentUserId;
        return _MessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildMessageInput(DmConversationState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: state.isSending ? null : _sendMessage,
              icon: state.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              name: message.senderUsername,
              size: 28,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusXl),
                  topRight: const Radius.circular(AppSpacing.radiusXl),
                  bottomLeft: Radius.circular(isMe ? AppSpacing.radiusXl : AppSpacing.radiusSm),
                  bottomRight: Radius.circular(isMe ? AppSpacing.radiusSm : AppSpacing.radiusXl),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 36), // Balance avatar space
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
