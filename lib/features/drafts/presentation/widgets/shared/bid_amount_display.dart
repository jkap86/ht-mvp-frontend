import 'package:flutter/material.dart';

import '../../../../../config/app_theme.dart';
import '../../../../../core/theme/hype_train_colors.dart';

/// Reusable widget for displaying bid amounts in auction lot cards.
/// Supports both current bid display and max bid display with optional labels.
class BidAmountDisplay extends StatelessWidget {
  final int amount;
  final bool isWinning;
  final String? label;
  final double fontSize;

  const BidAmountDisplay({
    super.key,
    required this.amount,
    this.isWinning = false,
    this.label,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWinning
            ? context.htColors.draftAction
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${label ?? ''}\$$amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          fontFamily: 'monospace',
          color: isWinning ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Large bid amount display for fast auction cards.
class LargeBidAmountDisplay extends StatelessWidget {
  final int amount;
  final String? leadingBidderName;
  final bool isWinning;

  const LargeBidAmountDisplay({
    super.key,
    required this.amount,
    this.leadingBidderName,
    this.isWinning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$$amount',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isWinning ? AppTheme.draftSuccess : context.htColors.draftAction,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWinning)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.check_circle, size: 14, color: AppTheme.draftSuccess),
              ),
            Text(
              isWinning ? "You're winning" : (leadingBidderName ?? 'No bids'),
              style: TextStyle(
                fontSize: 12,
                color: isWinning ? AppTheme.draftSuccess : theme.colorScheme.onSurfaceVariant,
                fontWeight: isWinning ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Max bid indicator text for showing user's max bid on a lot.
class MaxBidIndicator extends StatelessWidget {
  final int maxBid;
  final bool isWinning;

  const MaxBidIndicator({
    super.key,
    required this.maxBid,
    required this.isWinning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Max: \$$maxBid',
      style: theme.textTheme.labelSmall?.copyWith(
        color: isWinning
            ? context.htColors.draftAction
            : theme.colorScheme.tertiary,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }
}
