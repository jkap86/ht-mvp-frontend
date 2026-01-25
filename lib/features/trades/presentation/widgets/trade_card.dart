import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teams
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.proposerTeamName,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${trade.proposerGiving.length} player(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.swap_horiz, color: Colors.grey),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trade.recipientTeamName,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${trade.recipientGiving.length} player(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Player preview
              if (trade.items.isNotEmpty) ...[
                const Divider(height: 24),
                _buildPlayerPreview(context),
              ],

              // Expiry info for pending trades
              if (trade.status.isPending) ...[
                const SizedBox(height: 8),
                Text(
                  'Expires ${DateFormat.MMMd().add_jm().format(trade.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: trade.isExpired ? Colors.red : Colors.orange,
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
    Color color;
    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.countered:
        color = Colors.orange;
        break;
      case TradeStatus.accepted:
      case TradeStatus.inReview:
        color = Colors.blue;
        break;
      case TradeStatus.completed:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        trade.status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlayerPreview(BuildContext context) {
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
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recipientPlayers
                .map((item) => Text(
                      '${item.fullName} ${item.displayPosition}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
