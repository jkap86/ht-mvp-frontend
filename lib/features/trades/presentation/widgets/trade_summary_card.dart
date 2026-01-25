import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/trade.dart';

class TradeSummaryCard extends StatelessWidget {
  final Trade trade;

  const TradeSummaryCard({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.proposerTeamName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${trade.proposerUsername}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.swap_horiz, size: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trade.recipientTeamName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${trade.recipientUsername}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Proposed ${DateFormat.yMMMd().add_jm().format(trade.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
