import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';

class TradeStatusBanner extends StatelessWidget {
  final Trade trade;

  const TradeStatusBanner({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    IconData icon;

    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.countered:
        statusColor = TradeStatusColors.pending;
        icon = Icons.pending;
        break;
      case TradeStatus.accepted:
      case TradeStatus.inReview:
        statusColor = TradeStatusColors.inReview;
        icon = Icons.hourglass_empty;
        break;
      case TradeStatus.completed:
        statusColor = TradeStatusColors.completed;
        icon = Icons.check_circle;
        break;
      case TradeStatus.rejected:
      case TradeStatus.cancelled:
      case TradeStatus.expired:
      case TradeStatus.vetoed:
        statusColor = TradeStatusColors.failed;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(isDark ? 40 : 30),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: statusColor.withAlpha(isDark ? 75 : 50),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: statusColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trade.status.label,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (trade.status.isPending) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Expires ${DateFormat.yMMMd().add_jm().format(trade.expiresAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.isInReviewPeriod) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Review ends ${DateFormat.yMMMd().add_jm().format(trade.reviewEndsAt!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
