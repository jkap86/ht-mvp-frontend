import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_dashboard_provider.dart';

/// Card showing pending trades requiring user action
class HomePendingTradesCard extends StatelessWidget {
  final List<DashboardTrade> trades;

  const HomePendingTradesCard({
    super.key,
    required this.trades,
  });

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Badge(
                  label: Text('${trades.length}'),
                  child: Icon(
                    Icons.swap_horiz,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trades Requiring Action',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...trades.take(3).map((t) => _TradeItem(trade: t)),
          if (trades.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  '+${trades.length - 3} more trades',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TradeItem extends StatelessWidget {
  final DashboardTrade trade;

  const _TradeItem({required this.trade});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        context.push('/leagues/${trade.leagueId}/trades/${trade.trade.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.leagueName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${trade.trade.proposerTeamName} <-> ${trade.trade.recipientTeamName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Text(
                trade.trade.status.label,
                style: TextStyle(
                  color: colorScheme.onTertiaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
