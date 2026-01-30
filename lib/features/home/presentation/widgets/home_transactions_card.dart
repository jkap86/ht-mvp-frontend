import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Card showing transactions summary with navigation to transactions page
class HomeTransactionsCard extends StatelessWidget {
  final int tradeCount;

  const HomeTransactionsCard({
    super.key,
    required this.tradeCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.go('/transactions'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Badge(
                  isLabelVisible: tradeCount > 0,
                  label: Text('$tradeCount'),
                  child: Icon(
                    Icons.swap_horiz,
                    size: 24,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      tradeCount == 0
                          ? 'No pending trades'
                          : '$tradeCount trade${tradeCount == 1 ? '' : 's'} requiring action',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
