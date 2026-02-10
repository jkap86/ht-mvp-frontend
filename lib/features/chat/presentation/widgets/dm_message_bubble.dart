import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';

/// A message bubble for DM conversations with mine/theirs alignment.
/// Shows avatar for received messages, right-aligned for sent messages.
class DmMessageBubble extends StatelessWidget {
  final String senderUsername;
  final String message;
  final DateTime createdAt;
  final bool isMe;
  final bool compact;

  const DmMessageBubble({
    super.key,
    required this.senderUsername,
    required this.message,
    required this.createdAt,
    required this.isMe,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarSize = compact ? 24.0 : 28.0;
    final paddingV = compact ? 2.0 : 4.0;
    final paddingH = compact ? 10.0 : 14.0;
    final paddingVBubble = compact ? 6.0 : 10.0;
    final fontSize = compact ? 12.0 : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: paddingV),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              name: senderUsername,
              size: avatarSize,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: paddingH,
                vertical: paddingVBubble,
              ),
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
                  SelectableText(
                    message,
                    style: (compact
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: fontSize,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : theme.colorScheme.outline,
                      fontSize: compact ? 9.0 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe)
            SizedBox(width: avatarSize + 8), // Balance avatar space
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
