import 'package:flutter/material.dart';
import '../../domain/trade.dart';
import '../../domain/trade_item.dart';
import 'position_badge.dart';

/// Widget showing the players involved in a trade, split by team
class TradePlayersSection extends StatelessWidget {
  final Trade trade;

  const TradePlayersSection({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Proposer's side (players they're giving away)
        Expanded(
          child: _buildTeamColumn(
            context,
            teamName: trade.proposerTeamName,
            label: 'Gives',
            items: trade.proposerGiving,
            isLeft: true,
          ),
        ),
        const SizedBox(width: 16),
        // Recipient's side (players they're giving away)
        Expanded(
          child: _buildTeamColumn(
            context,
            teamName: trade.recipientTeamName,
            label: 'Gives',
            items: trade.recipientGiving,
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamColumn(
    BuildContext context, {
    required String teamName,
    required String label,
    required List<TradeItem> items,
    required bool isLeft,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              teamName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const Divider(),
            if (items.isEmpty)
              Text(
                'No players',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              )
            else
              ...items.map((item) => _buildPlayerRow(context, item, isLeft)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(BuildContext context, TradeItem item, bool isLeft) {
    final position = item.displayPosition;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isLeft
            ? [
                PositionBadge(position: position, size: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.displayTeam.isNotEmpty)
                        Text(
                          item.displayTeam,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                    ],
                  ),
                ),
              ]
            : [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.displayTeam.isNotEmpty)
                        Text(
                          item.displayTeam,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PositionBadge(position: position, size: 32),
              ],
      ),
    );
  }
}
