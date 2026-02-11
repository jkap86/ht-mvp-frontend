import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_display.dart';
import '../../../core/utils/idempotency.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/widgets/states/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../domain/chat_message.dart';
import 'providers/chat_provider.dart';
import 'widgets/chat_message_input.dart';
import 'widgets/gif_message_bubble.dart';
import 'widgets/gif_picker.dart';
import 'widgets/reaction_bar.dart';
import 'widgets/reaction_pills.dart';
import 'widgets/slide_in_message.dart';
import 'widgets/system_message_bubble.dart';

class ChatWidget extends ConsumerStatefulWidget {
  final int leagueId;

  const ChatWidget({super.key, required this.leagueId});

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _gifPickerOpen = false;
  Offset? _doubleTapPosition;

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

    final key = newIdempotencyKey();
    final notifier = ref.read(chatProvider(widget.leagueId).notifier);
    final success = await notifier.sendMessage(text, idempotencyKey: key);
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

  /// Two messages belong to the same group if same non-null userId and <2min apart.
  bool _isSameGroup(ChatMessage? earlier, ChatMessage? later) {
    if (earlier == null || later == null) return false;
    if (earlier.isSystemMessage || later.isSystemMessage) return false;
    if (earlier.userId == null || later.userId == null) return false;
    if (earlier.userId != later.userId) return false;
    return later.createdAt.difference(earlier.createdAt).inSeconds.abs() < 120;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.leagueId));

    if (state.isLoading) {
      return const AppLoadingView();
    }

    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? const AppEmptyView(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet',
                  subtitle: 'Start the conversation!',
                )
              : _buildMessageList(state),
        ),
        if (_gifPickerOpen)
          GifPicker(
            compact: true,
            onGifSelected: _sendGif,
          ),
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

  Widget _buildMessageList(ChatState state) {
    // Determine if the newest message is brand-new (for slide animation)
    final newestId = state.messages.isNotEmpty ? state.messages.first.id : null;
    final isNewArrival = _lastSeenMessageId != null &&
        newestId != null &&
        newestId != _lastSeenMessageId;
    _lastSeenMessageId = newestId;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
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

        // Compute grouping flags (list is reversed: index 0 = newest)
        final prevMessage = index + 1 < state.messages.length
            ? state.messages[index + 1]
            : null;
        final nextMessage = index - 1 >= 0
            ? state.messages[index - 1]
            : null;

        final isFirstInGroup = !_isSameGroup(prevMessage, message);
        final isLastInGroup = !_isSameGroup(message, nextMessage);

        final onToggleReaction = (String emoji) {
          ref.read(chatProvider(widget.leagueId).notifier)
              .toggleReaction(message.id, emoji);
        };

        final bubble = GestureDetector(
          onLongPressStart: (details) async {
            final emoji = await showReactionBar(
              context,
              position: details.globalPosition,
            );
            if (emoji != null) {
              onToggleReaction(emoji);
            }
          },
          onDoubleTapDown: (details) => _doubleTapPosition = details.globalPosition,
          onDoubleTap: () async {
            final emoji = await showReactionBar(
              context,
              position: _doubleTapPosition!,
            );
            if (emoji != null) {
              onToggleReaction(emoji);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageBubble(
                message: message,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: ReactionPills(
                    reactions: message.reactions,
                    currentUserId: message.userId,
                    onToggleReaction: onToggleReaction,
                  ),
                ),
            ],
          ),
        );

        // Animate only the very newest message
        if (index == 0 && isNewArrival) {
          return SlideInMessage(child: bubble);
        }

        return bubble;
      },
    );
  }

}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _MessageBubble({
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = message.username ?? 'Unknown';

    return Padding(
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
              size: 32,
              backgroundColor: colorScheme.primary,
              textColor: colorScheme.onPrimary,
            )
          else
            const SizedBox(width: 32),
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
                        formatMessageTimestamp(message.createdAt),
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
                  GifMessageBubble(messageText: message.message)
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
    );
  }
}
