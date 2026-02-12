import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/chat_message.dart';
import '../providers/chat_provider.dart';
import 'chat_message_input.dart';
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

  /// Track the newest message ID so we only animate truly new arrivals.
  int? _lastSeenMessageId;

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
    ref.listen(chatProvider(widget.leagueId), (prev, next) {
      if (next.isForbidden && prev?.isForbidden != true) {
        handleForbiddenNavigation(context, ref);
      }
    });

    final state = ref.watch(chatProvider(widget.leagueId));

    return Column(
      children: [
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

    // Determine if the newest message is brand-new (for slide animation)
    final newestId = state.messages.isNotEmpty ? state.messages.first.id : null;
    final isNewArrival = _lastSeenMessageId != null &&
        newestId != null &&
        newestId != _lastSeenMessageId;
    _lastSeenMessageId = newestId;

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
          return SystemMessageBubble(
            key: ValueKey('sys-${message.id}'),
            message: message,
          );
        }

        // Compute grouping flags (list is reversed: index 0 = newest)
        final prevMessage = index + 1 < state.messages.length
            ? state.messages[index + 1]
            : null;
        final nextMessage = index - 1 >= 0
            ? state.messages[index - 1]
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
  final void Function(String emoji) onToggleReaction;

  const _LeagueChatBubbleWithReactions({
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    required this.onToggleReaction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
