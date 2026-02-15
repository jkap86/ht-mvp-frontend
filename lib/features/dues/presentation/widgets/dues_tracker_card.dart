import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/idempotency.dart';
import '../../domain/dues.dart';
import '../providers/dues_provider.dart';

/// Card for tracking payment status (commissioner only)
class DuesTrackerCard extends ConsumerStatefulWidget {
  final int leagueId;

  const DuesTrackerCard({super.key, required this.leagueId});

  @override
  ConsumerState<DuesTrackerCard> createState() => _DuesTrackerCardState();
}

class _DuesTrackerCardState extends ConsumerState<DuesTrackerCard> {
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual<DuesState>(
        duesProvider(widget.leagueId),
        (prev, next) {
          if (next.error != null && prev?.error != next.error) {
            next.error!.showAsErrorWithContext(context);
          }
        },
      ));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) sub.close();
    _subscriptions.clear();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final state = ref.watch(duesProvider(widget.leagueId));
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
                final anyUpdating = state.updatingRosterId != null;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: payment.isPaid
                        ? context.htColors.success.withAlpha(51)
                        : context.htColors.error.withAlpha(51),
                    child: Icon(
                      payment.isPaid ? Icons.check : Icons.close,
                      size: 18,
                      color: payment.isPaid ? context.htColors.success : context.htColors.error,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment.teamName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      _buildStatusBadge(payment),
                    ],
                  ),
                  subtitle: payment.isPaid && payment.paidAt != null
                      ? Text(
                          'Paid ${_formatDate(payment.paidAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Text(
                          '\$${buyIn.toStringAsFixed(2)} owed',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.htColors.error,
                            fontWeight: FontWeight.w500,
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
                              onPressed: anyUpdating
                                  ? null
                                  : () => _showMarkUnpaidConfirmation(
                                        payment,
                                        buyIn,
                                      ),
                              child: const Text('Undo'),
                            )
                          : FilledButton.tonal(
                              onPressed: anyUpdating
                                  ? null
                                  : () => _showMarkPaidConfirmation(
                                        payment,
                                        buyIn,
                                      ),
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

  /// Builds a colored status badge for the payment row.
  Widget _buildStatusBadge(DuesPayment payment) {
    final Color bgColor;
    final Color textColor;
    final String label;

    if (payment.isPaid) {
      bgColor = context.htColors.success.withAlpha(31);
      textColor = context.htColors.success;
      label = 'Paid';
    } else {
      bgColor = context.htColors.error.withAlpha(31);
      textColor = context.htColors.error;
      label = 'Owed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.badgeRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before marking a member as paid.
  void _showMarkPaidConfirmation(
    DuesPayment payment,
    double buyIn,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark ${payment.teamName} (${payment.username}) as paid '
          '(\$${buyIn.toStringAsFixed(2)})?\n\n'
          'This will update their dues status to paid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executePaymentToggle(payment.rosterId, true, payment.teamName);
            },
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before marking a member as unpaid.
  void _showMarkUnpaidConfirmation(
    DuesPayment payment,
    double buyIn,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Unpaid'),
        content: Text(
          'Mark ${payment.teamName} (${payment.username}) as unpaid?\n\n'
          'This will revert their payment status to owed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executePaymentToggle(payment.rosterId, false, payment.teamName);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Mark Unpaid'),
          ),
        ],
      ),
    );
  }

  /// Executes the payment status toggle and shows feedback.
  Future<void> _executePaymentToggle(
    int rosterId,
    bool isPaid,
    String teamName,
  ) async {
    final key = newIdempotencyKey();
    final success = await ref
        .read(duesProvider(widget.leagueId).notifier)
        .markPayment(rosterId, isPaid, idempotencyKey: key);

    if (!context.mounted) return;

    if (success) {
      final action = isPaid ? 'paid' : 'unpaid';
      showSuccessWithContext(context, '$teamName marked as $action');
    }
    // Error case is handled by the ref.listen above
  }
}
