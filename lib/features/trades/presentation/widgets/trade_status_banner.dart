import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';

class TradeStatusBanner extends StatefulWidget {
  final Trade trade;

  const TradeStatusBanner({super.key, required this.trade});

  @override
  State<TradeStatusBanner> createState() => _TradeStatusBannerState();
}

class _TradeStatusBannerState extends State<TradeStatusBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_needsCountdown) {
      _timer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(TradeStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_needsCountdown && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) setState(() {});
      });
    } else if (!_needsCountdown && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _needsCountdown =>
      widget.trade.status.isPending || widget.trade.isInReviewPeriod;

  String _formatCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final theme = Theme.of(context);

    Color statusColor;
    IconData icon;

    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.countered:
        statusColor = AppTheme.brandOrange;
        icon = Icons.pending;
        break;
      case TradeStatus.accepted:
      case TradeStatus.inReview:
        statusColor = AppTheme.brandBlue;
        icon = Icons.hourglass_empty;
        break;
      case TradeStatus.completed:
        statusColor = context.htColors.success;
        icon = Icons.check_circle;
        break;
      case TradeStatus.rejected:
        statusColor = AppTheme.errorColor;
        icon = Icons.block;
        break;
      case TradeStatus.cancelled:
        statusColor = AppTheme.injuryMuted;
        icon = Icons.cancel;
        break;
      case TradeStatus.expired:
        statusColor = AppTheme.injuryMuted;
        icon = Icons.timer_off;
        break;
      case TradeStatus.vetoed:
        statusColor = AppTheme.errorColor;
        icon = Icons.gavel;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: statusColor.withAlpha(60),
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
                    'Expires in ${_formatCountdown(trade.expiresAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.isInReviewPeriod) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Review ends in ${_formatCountdown(trade.reviewEndsAt!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.status == TradeStatus.expired) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Expired on ${DateFormat.yMMMd().format(trade.expiresAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.status == TradeStatus.completed &&
                    trade.completedAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Completed on ${DateFormat.yMMMd().format(trade.completedAt!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.status == TradeStatus.rejected) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Rejected on ${DateFormat.yMMMd().format(trade.updatedAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.status == TradeStatus.cancelled) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cancelled on ${DateFormat.yMMMd().format(trade.updatedAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trade.status == TradeStatus.vetoed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Vetoed on ${DateFormat.yMMMd().format(trade.updatedAt)}',
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
