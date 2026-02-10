import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/trade.dart';

class TradeVotesSection extends StatelessWidget {
  final Trade trade;

  const TradeVotesSection({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'League Votes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _VoteChip(
                  label: 'Approve',
                  count: trade.approveCount,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _VoteChip(
                  label: 'Veto',
                  count: trade.vetoCount,
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const Divider(height: 24),
            if (trade.votes.isEmpty)
              Text(
                'No votes yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...trade.votes.map((vote) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          vote.isApprove ? Icons.thumb_up : Icons.thumb_down,
                          size: 16,
                          color: vote.isApprove
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text('${vote.teamName} (@${vote.username})'),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _VoteChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VoteChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
