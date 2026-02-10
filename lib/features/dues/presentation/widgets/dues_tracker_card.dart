import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/dues_provider.dart';

/// Card for tracking payment status (commissioner only)
class DuesTrackerCard extends ConsumerWidget {
  final int leagueId;

  const DuesTrackerCard({super.key, required this.leagueId});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duesProvider(leagueId));
    final colorScheme = Theme.of(context).colorScheme;

    // Don't show tracker if dues is not enabled
    if (!state.isEnabled || state.config == null) {
      return const SizedBox.shrink();
    }

    final summary = state.summary;
    final payments = state.payments;
    final buyIn = state.config!.buyInAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long),
                const SizedBox(width: 8),
                Text(
                  'Payment Tracker',
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
              // Summary header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.buttonRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Collected: \$${summary.amountCollected.toStringAsFixed(2)} / \$${summary.totalPot.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${summary.paidCount} of ${summary.totalCount}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: AppSpacing.badgeRadius,
                      child: LinearProgressIndicator(
                        value: summary.progressPercent,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerLow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(summary.progressPercent * 100).toStringAsFixed(0)}% collected',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Payment list
              ...payments.map((payment) {
                final isUpdating = state.updatingRosterId == payment.rosterId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: payment.isPaid
                        ? Colors.green.withAlpha(51)
                        : Colors.red.withAlpha(51),
                    child: Icon(
                      payment.isPaid ? Icons.check : Icons.close,
                      size: 18,
                      color: payment.isPaid ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    payment.teamName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: payment.isPaid ? null : null,
                    ),
                  ),
                  subtitle: payment.isPaid && payment.paidAt != null
                      ? Text(
                          'paid ${_formatDate(payment.paidAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Text(
                          '\$${buyIn.toStringAsFixed(2)} due',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.error,
                          ),
                        ),
                  trailing: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : payment.isPaid
                          ? TextButton(
                              onPressed: () => _togglePayment(ref, payment.rosterId, false),
                              child: const Text('Undo'),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _togglePayment(ref, payment.rosterId, true),
                              child: const Text('Mark Paid'),
                            ),
                );
              }),
            ],

            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _togglePayment(WidgetRef ref, int rosterId, bool isPaid) {
    ref.read(duesProvider(leagueId).notifier).markPayment(rosterId, isPaid);
  }
}
