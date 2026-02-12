import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../domain/draft_order_entry.dart';

/// Header widget for the fast auction panel showing nominator info and budget.
class FastAuctionHeader extends StatelessWidget {
  final DraftOrderEntry? nominator;
  final bool isMyNomination;
  final int nominationNumber;
  final int? myBudgetAvailable;
  final int completedCount;
  final VoidCallback? onHistoryTap;

  const FastAuctionHeader({
    super.key,
    required this.nominator,
    required this.isMyNomination,
    required this.nominationNumber,
    this.myBudgetAvailable,
    this.completedCount = 0,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMyNomination
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gavel,
            size: 20,
            color: isMyNomination
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyNomination
                      ? 'Your Turn to Nominate'
                      : 'Waiting for ${nominator?.username ?? 'Unknown'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isMyNomination
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Nomination #$nominationNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (completedCount > 0 && onHistoryTap != null)
            IconButton(
              icon: const Icon(Icons.history, size: 20),
              tooltip: 'Auction History',
              onPressed: onHistoryTap,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          if (myBudgetAvailable != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.htColors.draftAction.withAlpha(25),
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Text(
                '\$$myBudgetAvailable',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.htColors.draftAction,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
