import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Quick-reaction emojis for the floating reaction bar.
const _quickReactions = ['🔥', '👍', '😂', '👀', '💀', '💩', '🤡'];

/// A floating reaction bar that appears above a long-pressed message.
/// Shows 5 quick reactions + a "+" button for a picker.
class ReactionBar extends StatefulWidget {
  final void Function(String emoji) onReactionSelected;
  final VoidCallback? onPickerTap;

  const ReactionBar({
    super.key,
    required this.onReactionSelected,
    this.onPickerTap,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
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
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
      alignment: Alignment.center,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.pillRadius,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _quickReactions.length; i++)
              _buildEmojiButton(
                _quickReactions[i],
                delay: i * 30,
              ),
            _buildPickerButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, {int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: InkWell(
          onTap: () => widget.onReactionSelected(emoji),
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerButton(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: InkWell(
          onTap: widget.onPickerTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Icon(
              Icons.add,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a reaction bar overlay above a message at the given position.
/// Returns the selected emoji, or null if dismissed.
Future<String?> showReactionBar(
  BuildContext context, {
  required Offset position,
}) async {
  return showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx - 100,
      position.dy - 56,
      position.dx + 100,
      position.dy,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.pillRadius,
    ),
    elevation: 4,
    items: [
      PopupMenuItem<String>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _quickReactions.map((emoji) {
            return InkWell(
              onTap: () => Navigator.of(context).pop(emoji),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}
