import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/chat_message.dart';

/// Displays reaction pills below a message bubble.
/// Each pill shows the emoji and count. "Mine" reactions are highlighted.
/// Tap toggles the reaction. Long-press shows reactor usernames.
class ReactionPills extends StatelessWidget {
  final List<ReactionGroup> reactions;
  final String? currentUserId;
  final void Function(String emoji) onToggleReaction;
  final bool compact;

  const ReactionPills({
    super.key,
    required this.reactions,
    this.currentUserId,
    required this.onToggleReaction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions.map((reaction) {
          final hasReacted = reaction.hasReacted ||
              (currentUserId != null && reaction.users.contains(currentUserId));

          return GestureDetector(
            onTap: () => onToggleReaction(reaction.emoji),
            onLongPress: () => _showReactorTooltip(context, reaction),
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: hasReacted
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                border: Border.all(
                  color: hasReacted
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
                borderRadius: AppSpacing.pillRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reaction.emoji,
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
                  if (reaction.count >= 2) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${reaction.count}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: hasReacted
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            hasReacted ? FontWeight.w600 : FontWeight.normal,
                        fontSize: compact ? 10 : 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReactorTooltip(BuildContext context, ReactionGroup reaction) {
    final names = reaction.users.join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reaction.emoji} $names'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
