import 'package:flutter/material.dart';

import '../../domain/chat_message.dart';

/// Shows a visual indicator for message send status.
///
/// - [MessageSendStatus.sending]: pulsing "Sending..." text
/// - [MessageSendStatus.failed]: red "Failed" text with retry icon
/// - [MessageSendStatus.sent]: hidden (no indicator)
class MessageStatusIndicator extends StatelessWidget {
  final MessageSendStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool compact;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
    this.onDismiss,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == MessageSendStatus.sent) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = (compact ? theme.textTheme.labelSmall : theme.textTheme.bodySmall)
        ?.copyWith(fontSize: compact ? 9.0 : null);

    if (status == MessageSendStatus.sending) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 8 : 10,
              height: compact ? 8 : 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Sending...',
              style: textStyle?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // Failed state
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: compact ? 12 : 14,
            color: colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Failed to send',
            style: textStyle?.copyWith(color: colorScheme.error),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: compact ? 12 : 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Retry',
                    style: textStyle?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: compact ? 12 : 14,
                color: colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
