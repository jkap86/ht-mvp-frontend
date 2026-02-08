import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';

/// Card widget displaying a trade summary in a list
class TradeCard extends StatelessWidget {
  final Trade trade;
  final VoidCallback? onTap;

  const TradeCard({
    super.key,
    required this.trade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  _buildStatusBadge(context),
                  const Spacer(),
                  Text(
                    DateFormat.MMMd().format(trade.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Teams
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.proposerTeamName,
                          style: AppTypography.bodyBold.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${trade.proposerGiving.length} player(s)',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Icon(
                      Icons.swap_horiz,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trade.recipientTeamName,
                          style: AppTypography.bodyBold.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${trade.recipientGiving.length} player(s)',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Player preview
              if (trade.items.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl),
                _buildPlayerPreview(context),
              ],

              // Expiry info for pending trades
              if (trade.status.isPending) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Expires ${DateFormat.MMMd().add_jm().format(trade.expiresAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: trade.isExpired
                        ? AppTheme.errorColor
                        : TradeStatusColors.pending,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color color;
    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.countered:
        color = TradeStatusColors.pending;
        break;
      case TradeStatus.accepted:
      case TradeStatus.inReview:
        color = TradeStatusColors.inReview;
        break;
      case TradeStatus.completed:
        color = TradeStatusColors.completed;
        break;
      default:
        color = TradeStatusColors.failed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 30 : 25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withAlpha(isDark ? 75 : 75)),
      ),
      child: Text(
        trade.status.label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlayerPreview(BuildContext context) {
    final theme = Theme.of(context);
    final proposerPlayers = trade.proposerGiving.take(2).toList();
    final recipientPlayers = trade.recipientGiving.take(2).toList();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: proposerPlayers
                .map((item) => Text(
                      '${item.displayPosition} ${item.fullName}',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recipientPlayers
                .map((item) => Text(
                      '${item.fullName} ${item.displayPosition}',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
