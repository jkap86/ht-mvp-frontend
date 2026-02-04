import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dues_provider.dart';

/// Card showing dues summary for all league members (read-only)
class DuesSummaryCard extends ConsumerStatefulWidget {
  final int leagueId;
  final int? currentRosterId;

  const DuesSummaryCard({
    super.key,
    required this.leagueId,
    this.currentRosterId,
  });

  @override
  ConsumerState<DuesSummaryCard> createState() => _DuesSummaryCardState();
}

class _DuesSummaryCardState extends ConsumerState<DuesSummaryCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(duesProvider(widget.leagueId).notifier).loadDues(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duesProvider(widget.leagueId));
    final colorScheme = Theme.of(context).colorScheme;

    // Don't show card if dues is not enabled
    if (!state.isEnabled || state.config == null) {
      return const SizedBox.shrink();
    }

    final summary = state.summary;
    final config = state.config!;
    final payouts = state.payouts;

    // Find current user's payment status
    final myPayment = widget.currentRosterId != null
        ? state.payments.where((p) => p.rosterId == widget.currentRosterId).firstOrNull
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on),
                const SizedBox(width: 8),
                Text(
                  'League Dues',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),

            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (summary != null) ...[
              // Buy-in info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buy-in:',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '\$${config.buyInAmount.toStringAsFixed(2)} ${config.currency}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Payout structure
              if (payouts.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pot:',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '\$${summary.totalPot.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: payouts.map((p) {
                    return Chip(
                      label: Text('${p.place}: \$${p.amount.toStringAsFixed(0)}'),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Collection progress
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Progress',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${summary.paidCount} of ${summary.totalCount} paid',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: summary.progressPercent,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerLow,
                      ),
                    ),
                  ],
                ),
              ),

              // Current user's payment status
              if (myPayment != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: myPayment.isPaid
                        ? Colors.green.withAlpha(26)
                        : Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: myPayment.isPaid ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        myPayment.isPaid ? Icons.check_circle : Icons.pending,
                        color: myPayment.isPaid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        myPayment.isPaid
                            ? 'Your dues are paid!'
                            : 'Your dues are pending',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: myPayment.isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Notes from commissioner
              if (config.notes != null && config.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Payment Instructions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
