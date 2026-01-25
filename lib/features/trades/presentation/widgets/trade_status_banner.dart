import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/trade.dart';
import '../../domain/trade_status.dart';

class TradeStatusBanner extends StatelessWidget {
  final Trade trade;

  const TradeStatusBanner({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.countered:
        backgroundColor = Colors.orange.shade100;
        icon = Icons.pending;
        break;
      case TradeStatus.accepted:
      case TradeStatus.inReview:
        backgroundColor = Colors.blue.shade100;
        icon = Icons.hourglass_empty;
        break;
      case TradeStatus.completed:
        backgroundColor = Colors.green.shade100;
        icon = Icons.check_circle;
        break;
      case TradeStatus.rejected:
      case TradeStatus.cancelled:
      case TradeStatus.expired:
      case TradeStatus.vetoed:
        backgroundColor = Colors.grey.shade200;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trade.status.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (trade.status.isPending) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires ${DateFormat.yMMMd().add_jm().format(trade.expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (trade.isInReviewPeriod) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Review ends ${DateFormat.yMMMd().add_jm().format(trade.reviewEndsAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
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
