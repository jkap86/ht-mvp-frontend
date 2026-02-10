import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_display.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../dm/presentation/providers/dm_conversation_provider.dart';
import 'chat_message_input.dart';
import 'dm_message_bubble.dart';

/// DM conversation view for the floating chat widget.
/// Shows messages and input field with a back button header.
class DmConversationView extends ConsumerStatefulWidget {
  final int conversationId;
  final String otherUsername;
  final VoidCallback onBack;

  const DmConversationView({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    required this.onBack,
  });

  @override
  ConsumerState<DmConversationView> createState() => _DmConversationViewState();
}

class _DmConversationViewState extends ConsumerState<DmConversationView> {
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

    final notifier = ref.read(dmConversationProvider(widget.conversationId).notifier);
    final success = await notifier.sendMessage(text);
    if (success) {
      _messageController.clear();
    } else if (mounted) {
      'Error sending message'.showAsError(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmConversationProvider(widget.conversationId));
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with back button and username
        _buildHeader(theme),
        // Messages list
        Expanded(
          child: _buildMessageList(state, currentUserId),
        ),
        // Input field
        ChatMessageInput(
          controller: _messageController,
          isSending: state.isSending,
          onSend: _sendMessage,
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          UserAvatar(
            name: widget.otherUsername,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.otherUsername,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(DmConversationState state, String? currentUserId) {
    if (state.isLoading) {
      return const AppLoadingView();
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(dmConversationProvider(widget.conversationId).notifier).loadMessages(),
      );
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
      padding: const EdgeInsets.all(8),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end (oldest messages)
        if (state.isLoadingMore && index == state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final message = state.messages[index];
        final isMe = message.senderId == currentUserId;
        return DmMessageBubble(
          senderUsername: message.senderUsername,
          message: message.message,
          createdAt: message.createdAt,
          isMe: isMe,
          compact: true,
        );
      },
    );
  }
}
