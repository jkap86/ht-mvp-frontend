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
import 'widgets/gif_message_bubble.dart';
import 'widgets/reaction_bar.dart';
import 'widgets/reaction_pills.dart';
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
        _buildMessageInput(state),
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
          onDoubleTap: () => onToggleReaction('🔥'),
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
          return _SlideInMessage(child: bubble);
        }

        return bubble;
      },
    );
  }

  Widget _buildMessageInput(ChatState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
    );
  }
}

/// Slide-up + fade animation for newly arrived messages.
class _SlideInMessage extends StatefulWidget {
  final Widget child;
  const _SlideInMessage({required this.child});

  @override
  State<_SlideInMessage> createState() => _SlideInMessageState();
}

class _SlideInMessageState extends State<_SlideInMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
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
                    child: Text(
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
