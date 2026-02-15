import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_display.dart';
import '../../../core/utils/idempotency.dart';
import '../../../core/utils/time_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../chat/domain/chat_message.dart' show MessageSendStatus;
import '../../chat/presentation/widgets/connection_banner.dart';
import '../../chat/presentation/widgets/message_status_indicator.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/hype_train_colors.dart';
import '../../../core/widgets/skeletons/skeletons.dart';
import '../../../core/widgets/states/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../domain/direct_message.dart';
import 'providers/dm_conversation_provider.dart';
import 'providers/dm_inbox_provider.dart';
import 'widgets/dm_date_picker.dart';
import 'widgets/dm_search_bar.dart';

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
  bool _searchBarVisible = false;
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        dmConversationProvider(widget.conversationId),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
    });
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
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
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
    final currentUserId = ref.watch(authStateProvider.select((s) => s.user?.id));

    // Only rebuild when this conversation's username changes, not on every inbox update
    final otherUsername = ref.watch(dmInboxProvider.select((s) =>
        s.conversations
            .where((c) => c.id == widget.conversationId)
            .firstOrNull
            ?.otherUsername)) ?? 'Messages';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(name: otherUsername, size: 32),
            const SizedBox(width: 12),
            Text(otherUsername),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_searchBarVisible ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _searchBarVisible = !_searchBarVisible;
                if (!_searchBarVisible) {
                  ref.read(dmConversationProvider(widget.conversationId).notifier).clearSearch();
                }
              });
            },
            tooltip: _searchBarVisible ? 'Hide search' : 'Search messages',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DmDatePicker(conversationId: widget.conversationId),
              );
            },
            tooltip: 'Jump to date',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchBarVisible) DmSearchBar(conversationId: widget.conversationId),
          const ConnectionBanner(),
          Expanded(
            child: _buildMessageList(state, currentUserId),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList(DmConversationState state, String? currentUserId) {
    if (state.isLoading) {
      return const SkeletonChatMessageList();
    }

    if (state.error != null && state.messages.isEmpty) {
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

    // Track search state for highlighting
    final currentSearchMessageId = state.searchResults.isNotEmpty
        ? state.searchResults[state.currentSearchIndex].id
        : null;
    final highlightedId = state.highlightedMessageId;

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

        // Determine if this message should be highlighted
        final isSearchResult = currentSearchMessageId == message.id;
        final isHighlighted = highlightedId == message.id;

        final bubbleContent = Column(
          key: ValueKey('dm-${message.id}'),
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _MessageBubble(
              message: message,
              isMe: isMe,
            ),
            if (message.sendStatus != MessageSendStatus.sent)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 36,
                  right: isMe ? 36 : 0,
                ),
                child: MessageStatusIndicator(
                  status: message.sendStatus,
                  onRetry: message.sendStatus == MessageSendStatus.failed
                      ? () => ref.read(dmConversationProvider(widget.conversationId).notifier)
                          .retryMessage(message.id)
                      : null,
                  onDismiss: message.sendStatus == MessageSendStatus.failed
                      ? () => ref.read(dmConversationProvider(widget.conversationId).notifier)
                          .dismissFailedMessage(message.id)
                      : null,
                ),
              ),
          ],
        );

        // Wrap with highlight container if needed
        if (isSearchResult || isHighlighted) {
          return _HighlightedMessageContainer(
            isSearchResult: isSearchResult,
            isHighlighted: isHighlighted,
            child: bubbleContent,
          );
        }

        return bubbleContent;
      },
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    // Use Consumer to isolate isSending rebuilds from the message list
    return Consumer(
      builder: (context, ref, _) {
        final isSending = ref.watch(
          dmConversationProvider(widget.conversationId).select((s) => s.isSending),
        );
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: context.htColors.shadow,
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
                  onPressed: isSending ? null : _sendMessage,
                  icon: isSending
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
      },
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
                    formatMessageTimestamp(message.createdAt),
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
}

/// Highlights a DM message with a colored background
class _HighlightedMessageContainer extends StatelessWidget {
  final Widget child;
  final bool isSearchResult;
  final bool isHighlighted;

  const _HighlightedMessageContainer({
    required this.child,
    this.isSearchResult = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? backgroundColor;

    if (isSearchResult) {
      // Yellow highlight for active search result
      backgroundColor = theme.colorScheme.secondary.withValues(alpha: 0.2);
    } else if (isHighlighted) {
      // Blue highlight for date jump target
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.15);
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: child,
    );
  }
}
