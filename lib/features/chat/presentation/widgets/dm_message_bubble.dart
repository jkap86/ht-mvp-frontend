import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'gif_message_bubble.dart';

/// A message bubble for DM conversations with mine/theirs alignment.
/// Shows avatar for received messages, right-aligned for sent messages.
/// Supports message grouping via [isFirstInGroup] and [isLastInGroup].
class DmMessageBubble extends StatelessWidget {
  final String senderUsername;
  final String message;
  final DateTime createdAt;
  final bool isMe;
  final bool compact;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const DmMessageBubble({
    super.key,
    required this.senderUsername,
    required this.message,
    required this.createdAt,
    required this.isMe,
    this.compact = false,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatarSize = compact ? 24.0 : 28.0;
    final paddingH = compact ? 10.0 : 14.0;
    final paddingVBubble = compact ? 6.0 : 10.0;
    final fontSize = compact ? 12.0 : null;
    final timestamp = formatMessageTimestamp(createdAt);
    final sender = isMe ? 'You' : senderUsername;

    return Semantics(
      label: '$sender sent: $message, at $timestamp',
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirstInGroup ? (compact ? 2 : 4) : 1,
          bottom: isLastInGroup ? (compact ? 2 : 4) : 0,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              if (isLastInGroup)
                UserAvatar(
                  name: senderUsername,
                  size: avatarSize,
                )
              else
                SizedBox(width: avatarSize),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Show timestamp only for first message in group
                  if (isFirstInGroup && !isMe) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        timestamp,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                          fontSize: compact ? 9.0 : null,
                        ),
                      ),
                    ),
                  ],
                  if (GifMessageBubble.isGifMessage(message))
                    GifMessageBubble(
                      messageText: message,
                      isMe: isMe,
                      compact: compact,
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingH,
                        vertical: paddingVBubble,
                      ),
                      decoration: BoxDecoration(
                        // Subtle gradient for "mine" bubbles
                        gradient: isMe
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.85),
                                ],
                              )
                            : null,
                        color: isMe ? null : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            !isMe && !isFirstInGroup
                                ? AppSpacing.radiusSm
                                : AppSpacing.radiusXl,
                          ),
                          topRight: Radius.circular(
                            isMe && !isFirstInGroup
                                ? AppSpacing.radiusSm
                                : AppSpacing.radiusXl,
                          ),
                          bottomLeft: Radius.circular(
                            isMe || !isLastInGroup
                                ? AppSpacing.radiusXl
                                : AppSpacing.radiusSm,
                          ),
                          bottomRight: Radius.circular(
                            !isMe || !isLastInGroup
                                ? AppSpacing.radiusXl
                                : AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                      child: SelectableText(
                        message,
                        style: (compact
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(
                          color: isMe
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  // Show timestamp for "mine" first-in-group
                  if (isFirstInGroup && isMe) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      child: Text(
                        timestamp,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                          fontSize: compact ? 9.0 : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isMe)
              SizedBox(width: avatarSize + 8), // Balance avatar space
          ],
        ),
      ),
    );
  }
}
