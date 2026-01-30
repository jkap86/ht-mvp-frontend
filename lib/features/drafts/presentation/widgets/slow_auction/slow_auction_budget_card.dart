import 'package:flutter/material.dart';

import '../../../domain/auction_budget.dart';

/// Budget summary card for slow auction.
/// Shows remaining budget and roster progress.
class SlowAuctionBudgetCard extends StatelessWidget {
  final AuctionBudget budget;
  final int totalRounds;

  const SlowAuctionBudgetCard({
    super.key,
    required this.budget,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetPercent = budget.available / budget.totalBudget;
    final rosterPercent = budget.wonCount / totalRounds;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Budget section
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Budget',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${budget.available}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getBudgetColor(context, budgetPercent),
                        ),
                      ),
                      Text(
                        ' / \$${budget.totalBudget}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: budgetPercent,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: _getBudgetColor(context, budgetPercent),
                  ),
                  if (budget.leadingCommitment > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Leading bids: \$${budget.leadingCommitment}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Roster progress section
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Roster',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${budget.wonCount}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      ' / $totalRounds',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: rosterPercent,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAvgBudgetText(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBudgetColor(BuildContext context, double percent) {
    final theme = Theme.of(context);
    if (percent > 0.5) return theme.colorScheme.primary;
    if (percent > 0.25) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }

  String _getAvgBudgetText() {
    final remaining = totalRounds - budget.wonCount;
    if (remaining <= 0) return 'Complete';
    final avgPerPlayer = budget.available ~/ remaining;
    return '~\$$avgPerPlayer/player';
  }
}
