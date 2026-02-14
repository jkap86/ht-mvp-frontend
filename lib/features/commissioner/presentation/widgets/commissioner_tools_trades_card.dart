import 'package:flutter/material.dart';

/// Commissioner trade admin card.
///
/// Provides a trading lock toggle. Trade cancellation is done
/// from the trade detail screen via commissioner context.
class CommissionerToolsTradesCard extends StatelessWidget {
  final bool tradingLocked;
  final void Function(bool locked) onToggleTradingLocked;

  const CommissionerToolsTradesCard({
    super.key,
    required this.tradingLocked,
    required this.onToggleTradingLocked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Trade Admin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Lock Trading'),
              subtitle: Text(
                tradingLocked
                    ? 'Trading is locked. No new trades can be proposed or accepted.'
                    : 'Trading is open. Managers can propose and accept trades.',
              ),
              value: tradingLocked,
              onChanged: (value) => onToggleTradingLocked(value),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),
            Text(
              'To cancel a specific trade, visit the trade detail screen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
