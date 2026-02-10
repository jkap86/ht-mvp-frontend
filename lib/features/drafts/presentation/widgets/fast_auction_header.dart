import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/draft_order_entry.dart';

/// Header widget for the fast auction panel showing nominator info and budget.
class FastAuctionHeader extends StatelessWidget {
  final DraftOrderEntry? nominator;
  final bool isMyNomination;
  final int nominationNumber;
  final int? myBudgetAvailable;

  const FastAuctionHeader({
    super.key,
    required this.nominator,
    required this.isMyNomination,
    required this.nominationNumber,
    this.myBudgetAvailable,
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
          if (myBudgetAvailable != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.draftActionPrimary.withAlpha(25),
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Text(
                '\$$myBudgetAvailable',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.draftActionPrimary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
