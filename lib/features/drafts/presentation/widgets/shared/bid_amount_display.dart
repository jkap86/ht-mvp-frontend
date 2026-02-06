import 'package:flutter/material.dart';

import '../../../../../config/app_theme.dart';

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
            ? AppTheme.draftActionPrimary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${label ?? ''}\$$amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          fontFamily: 'monospace',
          color: isWinning ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Large bid amount display for fast auction cards.
class LargeBidAmountDisplay extends StatelessWidget {
  final int amount;
  final String? leadingBidderName;

  const LargeBidAmountDisplay({
    super.key,
    required this.amount,
    this.leadingBidderName,
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
            color: AppTheme.draftActionPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          leadingBidderName ?? 'No bids',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
            ? AppTheme.draftActionPrimary
            : theme.colorScheme.tertiary,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }
}
