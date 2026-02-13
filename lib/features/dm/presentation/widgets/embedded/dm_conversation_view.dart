import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/error_display.dart';
import '../../../../../core/widgets/states/states.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/auth_provider.dart';
import '../../../../chat/domain/chat_message.dart' show MessageSendStatus;
import '../../../domain/direct_message.dart';
import '../../providers/dm_conversation_provider.dart';
import '../dm_date_picker.dart';
import '../dm_search_bar.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../chat/presentation/widgets/chat_message_input.dart';
import '../../../../chat/presentation/widgets/connection_banner.dart';
import 'dm_message_bubble.dart';
import '../../../../chat/presentation/widgets/gif_picker.dart';
import '../../../../chat/presentation/widgets/message_status_indicator.dart';
import '../../../../chat/presentation/widgets/reaction_bar.dart';
import '../../../../chat/presentation/widgets/reaction_pills.dart';
import '../../../../chat/presentation/widgets/slide_in_message.dart';

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
  bool _gifPickerOpen = false;
  bool _searchBarVisible = false;

  /// Track the newest message ID so we only animate truly new arrivals.
  int? _lastSeenMessageId;

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

  Future<void> _sendGif(String gifUrl) async {
    setState(() => _gifPickerOpen = false);
    final notifier = ref.read(dmConversationProvider(widget.conversationId).notifier);
    final success = await notifier.sendMessage('gif::$gifUrl');
    if (!success && mounted) {
      'Error sending GIF'.showAsError(ref);
    }
  }

  /// Two DM messages belong to the same group if same sender and <2min apart.
  bool _isSameGroup(DirectMessage? earlier, DirectMessage? later) {
    if (earlier == null || later == null) return false;
    if (earlier.senderId != later.senderId) return false;
    return later.createdAt.difference(earlier.createdAt).inSeconds.abs() < 120;
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
        // Search bar (collapsible)
        if (_searchBarVisible) DmSearchBar(conversationId: widget.conversationId),
        // Connection banner
        const ConnectionBanner(),
        // Messages list
        Expanded(
          child: _buildMessageList(state, currentUserId),
        ),
        // GIF picker (inline, between messages and input)
        if (_gifPickerOpen)
          GifPicker(
            compact: true,
            onGifSelected: _sendGif,
          ),
        // Input field
        ChatMessageInput(
          controller: _messageController,
          isSending: state.isSending,
          onSend: _sendMessage,
          gifPickerOpen: _gifPickerOpen,
          onInputModeChanged: (mode) {
            setState(() {
              _gifPickerOpen = mode == InputMode.gif;
            });
          },
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
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
          // Action buttons
          IconButton(
            icon: Icon(
              _searchBarVisible ? Icons.search_off : Icons.search,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _searchBarVisible = !_searchBarVisible;
                if (!_searchBarVisible) {
                  ref.read(dmConversationProvider(widget.conversationId).notifier).clearSearch();
                }
              });
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: _searchBarVisible ? 'Hide search' : 'Search messages',
          ),
          IconButton(
            icon: const Icon(Icons.date_range, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DmDatePicker(conversationId: widget.conversationId),
              );
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Jump to date',
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

    // Determine if the newest message is brand-new (for slide animation)
    final newestId = state.messages.isNotEmpty ? state.messages.first.id : null;
    final isNewArrival = _lastSeenMessageId != null &&
        newestId != null &&
        newestId != _lastSeenMessageId;
    _lastSeenMessageId = newestId;

    // Track search state for highlighting
    final currentSearchMessageId = state.searchResults.isNotEmpty
        ? state.searchResults[state.currentSearchIndex].id
        : null;
    final highlightedId = state.highlightedMessageId;

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

        // Determine if this message should be highlighted
        final isSearchResult = currentSearchMessageId == message.id;
        final isHighlighted = highlightedId == message.id;

        // Compute grouping flags (list is reversed: index 0 = newest)
        final prevMessage = index + 1 < state.messages.length
            ? state.messages[index + 1]
            : null;
        final nextMessage = index - 1 >= 0
            ? state.messages[index - 1]
            : null;

        final isFirstInGroup = !_isSameGroup(prevMessage, message);
        final isLastInGroup = !_isSameGroup(message, nextMessage);

        final dmBubble = DmMessageBubble(
          senderUsername: message.senderUsername,
          message: message.message,
          createdAt: message.createdAt,
          isMe: isMe,
          compact: true,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        );

        final toggleReaction = (String emoji) {
          if (currentUserId != null) {
            ref.read(dmConversationProvider(widget.conversationId).notifier)
                .toggleReaction(message.id, emoji, currentUserId);
          }
        };

        final bubbleContent = GestureDetector(
          onLongPressStart: (details) async {
            final emoji = await showReactionBar(
              context,
              position: details.globalPosition,
            );
            if (emoji != null) {
              toggleReaction(emoji);
            }
          },
          onDoubleTap: () => toggleReaction('\u{1F525}'),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              dmBubble,
              if (message.sendStatus != MessageSendStatus.sent)
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 0 : 36,
                    right: isMe ? 36 : 0,
                  ),
                  child: MessageStatusIndicator(
                    status: message.sendStatus,
                    compact: true,
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
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 0 : 36,
                    right: isMe ? 36 : 0,
                  ),
                  child: ReactionPills(
                    reactions: message.reactions,
                    currentUserId: currentUserId,
                    onToggleReaction: toggleReaction,
                    compact: true,
                  ),
                ),
            ],
          ),
        );

        // Wrap with highlight container if needed
        final bubble = (isSearchResult || isHighlighted)
            ? _DmHighlightedMessageContainer(
                isSearchResult: isSearchResult,
                isHighlighted: isHighlighted,
                child: bubbleContent,
              )
            : bubbleContent;

        // Animate only the very newest message
        if (index == 0 && isNewArrival) {
          return SlideInMessage(child: bubble);
        }

        return bubble;
      },
    );
  }
}

/// Highlights a DM message with a colored background
class _DmHighlightedMessageContainer extends StatelessWidget {
  final Widget child;
  final bool isSearchResult;
  final bool isHighlighted;

  const _DmHighlightedMessageContainer({
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
