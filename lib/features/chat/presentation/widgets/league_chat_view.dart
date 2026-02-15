import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/chat_message.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_date_picker.dart';
import 'chat_filter_panel.dart';
import 'chat_message_input.dart';
import 'chat_search_bar.dart';
import 'connection_banner.dart';
import 'gif_message_bubble.dart';
import 'gif_picker.dart';
import 'message_status_indicator.dart';
import 'reaction_bar.dart';
import 'reaction_pills.dart';
import 'slide_in_message.dart';
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
  bool _gifPickerOpen = false;
  bool _searchBarVisible = false;

  /// Track the newest message ID so we only animate truly new arrivals.
  int? _lastSeenMessageId;
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark this league chat as active to suppress notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeLeagueChatProvider.notifier).state = widget.leagueId;
      _subscriptions.add(ref.listenManual(
        chatProvider(widget.leagueId),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
    });
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
    for (final sub in _subscriptions) sub.close();
    _subscriptions.clear();
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    // Clear active chat on exit
    ref.read(activeLeagueChatProvider.notifier).state = null;
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
      'Error sending message'.showAsError(ref);
    }
  }

  Future<void> _sendGif(String gifUrl) async {
    setState(() => _gifPickerOpen = false);
    final notifier = ref.read(chatProvider(widget.leagueId).notifier);
    final success = await notifier.sendMessage('gif::$gifUrl');
    if (!success && mounted) {
      'Error sending GIF'.showAsError(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.leagueId));

    return Column(
      children: [
        _buildToolbar(),
        if (_searchBarVisible) ChatSearchBar(leagueId: widget.leagueId),
        const ConnectionBanner(),
        Expanded(child: _buildMessageList(state)),
        if (_gifPickerOpen)
          GifPicker(
            compact: true,
            onGifSelected: _sendGif,
          ),
        Consumer(
          builder: (context, ref, _) {
            final isSending = ref.watch(
              chatProvider(widget.leagueId).select((s) => s.isSending),
            );
            return ChatMessageInput(
              controller: _messageController,
              isSending: isSending,
              onSend: _sendMessage,
              gifPickerOpen: _gifPickerOpen,
              onInputModeChanged: (mode) {
                setState(() {
                  _gifPickerOpen = mode == InputMode.gif;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              _searchBarVisible ? Icons.search_off : Icons.search,
            ),
            onPressed: () {
              setState(() {
                _searchBarVisible = !_searchBarVisible;
                if (!_searchBarVisible) {
                  // Clear search when hiding search bar
                  ref.read(chatProvider(widget.leagueId).notifier).clearSearch();
                }
              });
            },
            tooltip: _searchBarVisible ? 'Hide search' : 'Search messages',
          ),
          ChatDatePickerButton(leagueId: widget.leagueId),
          ChatFilterButton(leagueId: widget.leagueId),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    if (state.isLoading) {
      return const SkeletonChatMessageList();
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

    // Use filtered messages instead of all messages
    final displayMessages = state.filteredMessages;

    if (displayMessages.isEmpty && state.messages.isNotEmpty) {
      // All messages are filtered out
      return const AppEmptyView(
        icon: Icons.filter_alt_off,
        title: 'All messages filtered',
        subtitle: 'Adjust your filters to see messages',
      );
    }

    // Determine if the newest message is brand-new (for slide animation)
    final newestId = displayMessages.isNotEmpty ? displayMessages.first.id : null;
    final isNewArrival = _lastSeenMessageId != null &&
        newestId != null &&
        newestId != _lastSeenMessageId;
    _lastSeenMessageId = newestId;

    // Add 1 to itemCount for loading indicator when loading more
    final itemCount = displayMessages.length + (state.isLoadingMore ? 1 : 0);

    // Track search state for highlighting
    final currentSearchMessageId = state.searchResults.isNotEmpty
        ? state.searchResults[state.currentSearchIndex].id
        : null;
    final highlightedId = state.highlightedMessageId;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show loading indicator at the end (oldest messages position)
        if (index == displayMessages.length && state.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final message = displayMessages[index];

        // Determine if this message should be highlighted
        final isSearchResult = currentSearchMessageId == message.id;
        final isHighlighted = highlightedId == message.id;
        // Render system messages differently
        if (message.isSystemMessage) {
          final systemBubble = SystemMessageBubble(
            key: ValueKey('sys-${message.id}'),
            message: message,
          );

          // Wrap with highlight container if needed
          if (isSearchResult || isHighlighted) {
            return _HighlightedMessageContainer(
              isSearchResult: isSearchResult,
              isHighlighted: isHighlighted,
              child: systemBubble,
            );
          }

          return systemBubble;
        }

        // Compute grouping flags (list is reversed: index 0 = newest)
        final prevMessage = index + 1 < displayMessages.length
            ? displayMessages[index + 1]
            : null;
        final nextMessage = index - 1 >= 0
            ? displayMessages[index - 1]
            : null;

        final isFirstInGroup = !_isSameGroup(prevMessage, message);
        final isLastInGroup = !_isSameGroup(message, nextMessage);

        final bubble = Column(
          key: ValueKey('msg-${message.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeagueChatBubbleWithReactions(
              message: message,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
              isSearchResult: isSearchResult,
              isHighlighted: isHighlighted,
              onToggleReaction: (emoji) {
                ref.read(chatProvider(widget.leagueId).notifier)
                    .toggleReaction(message.id, emoji);
              },
            ),
            if (message.sendStatus != MessageSendStatus.sent)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: MessageStatusIndicator(
                  status: message.sendStatus,
                  compact: true,
                  onRetry: message.sendStatus == MessageSendStatus.failed
                      ? () => ref.read(chatProvider(widget.leagueId).notifier)
                          .retryMessage(message.id)
                      : null,
                  onDismiss: message.sendStatus == MessageSendStatus.failed
                      ? () => ref.read(chatProvider(widget.leagueId).notifier)
                          .dismissFailedMessage(message.id)
                      : null,
                ),
              ),
          ],
        );

        // Animate only the very newest message
        if (index == 0 && isNewArrival) {
          return SlideInMessage(child: bubble);
        }

        return bubble;
      },
    );
  }

  /// Two messages belong to the same group if same non-null userId and <2min apart.
  bool _isSameGroup(ChatMessage? earlier, ChatMessage? later) {
    if (earlier == null || later == null) return false;
    if (earlier.isSystemMessage || later.isSystemMessage) return false;
    if (earlier.userId == null || later.userId == null) return false;
    if (earlier.userId != later.userId) return false;
    return later.createdAt.difference(earlier.createdAt).inSeconds.abs() < 120;
  }
}

/// Wraps a league chat bubble with long-press reaction support and reaction pills.
class _LeagueChatBubbleWithReactions extends StatelessWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isSearchResult;
  final bool isHighlighted;
  final void Function(String emoji) onToggleReaction;

  const _LeagueChatBubbleWithReactions({
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.isSearchResult = false,
    this.isHighlighted = false,
    required this.onToggleReaction,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleContent = GestureDetector(
      onLongPressStart: (details) async {
        final emoji = await showReactionBar(
          context,
          position: details.globalPosition,
        );
        if (emoji != null) {
          onToggleReaction(emoji);
        }
      },
      onDoubleTap: () => onToggleReaction('🔥'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeagueChatBubble(
            message: message,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: ReactionPills(
                reactions: message.reactions,
                currentUserId: message.userId,
                onToggleReaction: onToggleReaction,
                compact: true,
              ),
            ),
        ],
      ),
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
  }
}

/// Message bubble for league chat (group chat style with avatar + name).
class _LeagueChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _LeagueChatBubble({
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = message.username ?? 'Unknown';
    final timestamp = formatMessageTimestamp(message.createdAt);

    return Semantics(
      label: '$username sent: ${message.message}, at $timestamp',
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirstInGroup ? 4 : 1,
          bottom: isLastInGroup ? 4 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show avatar only for first message in group, otherwise indent
            if (isFirstInGroup)
              UserAvatar(
                name: username,
                size: 28,
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show username + timestamp only for first in group
                  if (isFirstInGroup) ...[
                    Row(
                      children: [
                        Text(
                          username,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timestamp,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Message bubble with background (or GIF)
                  if (GifMessageBubble.isGifMessage(message.message))
                    GifMessageBubble(
                      messageText: message.message,
                      compact: true,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            isFirstInGroup ? AppSpacing.radiusXl : AppSpacing.radiusSm,
                          ),
                          topRight: const Radius.circular(AppSpacing.radiusXl),
                          bottomLeft: Radius.circular(
                            isLastInGroup ? AppSpacing.radiusSm : AppSpacing.radiusSm,
                          ),
                          bottomRight: const Radius.circular(AppSpacing.radiusXl),
                        ),
                      ),
                      child: SelectableText(
                        message.message,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Highlights a message with a colored background
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
