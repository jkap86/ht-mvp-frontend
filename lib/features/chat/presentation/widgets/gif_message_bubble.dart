import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Renders a GIF message by extracting the URL from a `gif::` prefixed string.
/// Shows loading shimmer, handles errors, and constrains sizing.
class GifMessageBubble extends StatelessWidget {
  final String messageText;
  final bool isMe;
  final bool compact;

  const GifMessageBubble({
    super.key,
    required this.messageText,
    this.isMe = false,
    this.compact = false,
  });

  String get _gifUrl => messageText.replaceFirst('gif::', '');

  @override
  Widget build(BuildContext context) {
    final maxWidth = compact ? 200.0 : 250.0;
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Image.network(
          _gifUrl,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return Container(
              width: maxWidth,
              height: maxWidth * 0.75,
              color: colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: maxWidth,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 28,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GIF failed to load',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Returns true if the message text represents a GIF.
  static bool isGifMessage(String message) => message.startsWith('gif::');
}
