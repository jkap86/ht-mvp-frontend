import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';

/// A row of tappable count indicators for pending trades, waivers, and messages.
class PendingCountsRow extends StatelessWidget {
  final int pendingTrades;
  final int activeWaiverClaims;
  final int unreadChatMessages;
  final VoidCallback? onTradesTap;
  final VoidCallback? onWaiversTap;
  final VoidCallback? onChatTap;

  const PendingCountsRow({
    super.key,
    required this.pendingTrades,
    required this.activeWaiverClaims,
    required this.unreadChatMessages,
    this.onTradesTap,
    this.onWaiversTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if there's something pending
    final hasContent = pendingTrades > 0 || activeWaiverClaims > 0 || unreadChatMessages > 0;
    if (!hasContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (pendingTrades > 0) ...[
            Expanded(
              child: _CountChip(
                icon: Icons.swap_horiz,
                count: pendingTrades,
                label: 'Trade${pendingTrades == 1 ? '' : 's'}',
                color: AppTheme.draftWarning,
                onTap: onTradesTap,
              ),
            ),
          ],
          if (pendingTrades > 0 && (activeWaiverClaims > 0 || unreadChatMessages > 0))
            const SizedBox(width: 12),
          if (activeWaiverClaims > 0) ...[
            Expanded(
              child: _CountChip(
                icon: Icons.person_add,
                count: activeWaiverClaims,
                label: 'Waiver${activeWaiverClaims == 1 ? '' : 's'}',
                color: AppTheme.draftNormal,
                onTap: onWaiversTap,
              ),
            ),
          ],
          if (activeWaiverClaims > 0 && unreadChatMessages > 0)
            const SizedBox(width: 12),
          if (unreadChatMessages > 0) ...[
            Expanded(
              child: _CountChip(
                icon: Icons.chat_bubble_outline,
                count: unreadChatMessages,
                label: 'Message${unreadChatMessages == 1 ? '' : 's'}',
                color: AppTheme.draftActionPrimary,
                onTap: onChatTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CountChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
