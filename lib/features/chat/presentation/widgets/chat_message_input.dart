import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// A reusable message input widget for chat interfaces.
/// Used by both league chat and DM conversations.
class ChatMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final String hintText;

  const ChatMessageInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.hintText = 'Type a message...',
  });

  @override
  State<ChatMessageInput> createState() => _ChatMessageInputState();
}

class _ChatMessageInputState extends State<ChatMessageInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = _hasText && !widget.isSending;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.pillRadius,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                isDense: true,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isEnabled ? widget.onSend() : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isEnabled ? widget.onSend : null,
            icon: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 18),
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}
