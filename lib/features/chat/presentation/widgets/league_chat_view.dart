import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/chat_message.dart';
import '../providers/chat_provider.dart';
import 'chat_message_input.dart';
import 'system_message_bubble.dart';

/// League chat view for the floating chat widget.
/// Shows league chat messages and input field.
class LeagueChatView extends ConsumerStatefulWidget {
  final int leagueId;

  const LeagueChatView({
    super.key,
    required this.leagueId,
  });

  @override
  ConsumerState<LeagueChatView> createState() => _LeagueChatViewState();
}

class _LeagueChatViewState extends ConsumerState<LeagueChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // List is reversed, so "end" (oldest messages) is at maxScrollExtent
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(chatProvider(widget.leagueId).notifier).loadMoreMessages();
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

    final notifier = ref.read(chatProvider(widget.leagueId).notifier);
    final success = await notifier.sendMessage(text);
    if (success) {
      _messageController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.leagueId));

    return Column(
      children: [
        Expanded(child: _buildMessageList(state)),
        ChatMessageInput(
          controller: _messageController,
          isSending: state.isSending,
          onSend: _sendMessage,
        ),
      ],
    );
  }

  Widget _buildMessageList(ChatState state) {
    if (state.isLoading) {
      return const AppLoadingView();
    }

    if (state.error != null) {
      return AppErrorView(
        message: 'Failed to load messages: ${state.error}',
        onRetry: () => ref.read(chatProvider(widget.leagueId).notifier).loadMessages(),
      );
    }

    if (state.messages.isEmpty) {
      return const AppEmptyView(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Start the conversation!',
      );
    }

    // Add 1 to itemCount for loading indicator when loading more
    final itemCount = state.messages.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show loading indicator at the end (oldest messages position)
        if (index == state.messages.length && state.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final message = state.messages[index];
        // Render system messages differently
        if (message.isSystemMessage) {
          return SystemMessageBubble(message: message);
        }
        return _LeagueChatBubble(message: message);
      },
    );
  }
}

/// Message bubble for league chat (group chat style with avatar + name).
class _LeagueChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _LeagueChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = message.username ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: username,
            size: 28,
            backgroundColor: theme.colorScheme.primary,
            textColor: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText(
                  message.message,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
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
