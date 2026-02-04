import 'package:flutter/material.dart';

import '../../domain/chat_message.dart';

/// A widget that displays system messages in league chat.
/// System messages have a distinct appearance with centered text,
/// divider lines, and icons based on message type.
class SystemMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const SystemMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildDivider(colorScheme)),
          const SizedBox(width: 12),
          _buildMessageContent(context, colorScheme),
          const SizedBox(width: 12),
          Expanded(child: _buildDivider(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildMessageContent(BuildContext context, ColorScheme colorScheme) {
    final icon = _getIconForMessageType(message.messageType);
    final iconColor = _getIconColor(message.messageType, colorScheme);
    final semanticLabel = _getSemanticLabel(message.messageType);

    return Semantics(
      label: '$semanticLabel: ${message.message}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor, semanticLabel: semanticLabel),
          const SizedBox(width: 6),
          Flexible(
            child: SelectableText(
              message.message,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMessageType(MessageType type) {
    switch (type) {
      case MessageType.tradeProposed:
        return Icons.swap_horiz;
      case MessageType.tradeCountered:
        return Icons.swap_horiz;
      case MessageType.tradeAccepted:
        return Icons.handshake_outlined;
      case MessageType.tradeCompleted:
        return Icons.check_circle_outline;
      case MessageType.tradeRejected:
        return Icons.cancel_outlined;
      case MessageType.tradeCancelled:
        return Icons.block_outlined;
      case MessageType.tradeVetoed:
        return Icons.gavel_outlined;
      case MessageType.tradeInvalidated:
        return Icons.warning_outlined;
      case MessageType.waiverSuccessful:
        return Icons.person_add_outlined;
      case MessageType.waiverProcessed:
        return Icons.sync;
      case MessageType.settingsUpdated:
        return Icons.settings_outlined;
      case MessageType.memberJoined:
        return Icons.group_add_outlined;
      case MessageType.memberKicked:
        return Icons.person_remove_outlined;
      case MessageType.duesPaid:
        return Icons.attach_money;
      case MessageType.duesUnpaid:
        return Icons.money_off;
      case MessageType.chat:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(MessageType type, ColorScheme colorScheme) {
    switch (type) {
      case MessageType.tradeCompleted:
      case MessageType.waiverSuccessful:
      case MessageType.memberJoined:
      case MessageType.duesPaid:
        // Use theme-appropriate success color
        return colorScheme.primary;
      case MessageType.tradeRejected:
      case MessageType.tradeCancelled:
      case MessageType.tradeVetoed:
      case MessageType.tradeInvalidated:
      case MessageType.memberKicked:
      case MessageType.duesUnpaid:
        // Use theme-appropriate error color
        return colorScheme.error;
      case MessageType.tradeProposed:
      case MessageType.tradeCountered:
      case MessageType.tradeAccepted:
        // Use theme-appropriate warning/pending color
        return colorScheme.tertiary;
      case MessageType.waiverProcessed:
      case MessageType.settingsUpdated:
      case MessageType.chat:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getSemanticLabel(MessageType type) {
    switch (type) {
      case MessageType.tradeProposed:
        return 'Trade proposed';
      case MessageType.tradeCountered:
        return 'Trade countered';
      case MessageType.tradeAccepted:
        return 'Trade accepted';
      case MessageType.tradeCompleted:
        return 'Trade completed';
      case MessageType.tradeRejected:
        return 'Trade rejected';
      case MessageType.tradeCancelled:
        return 'Trade cancelled';
      case MessageType.tradeVetoed:
        return 'Trade vetoed';
      case MessageType.tradeInvalidated:
        return 'Trade invalidated';
      case MessageType.waiverSuccessful:
        return 'Waiver claim successful';
      case MessageType.waiverProcessed:
        return 'Waivers processed';
      case MessageType.settingsUpdated:
        return 'Settings updated';
      case MessageType.memberJoined:
        return 'Member joined';
      case MessageType.memberKicked:
        return 'Member removed';
      case MessageType.duesPaid:
        return 'Dues paid';
      case MessageType.duesUnpaid:
        return 'Dues unmarked';
      case MessageType.chat:
        return 'Chat message';
    }
  }
}
