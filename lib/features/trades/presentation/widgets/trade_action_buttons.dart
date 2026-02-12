import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/trade.dart';

class TradeActionButtons extends StatelessWidget {
  final Trade trade;
  final int leagueId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final void Function(String vote) onVote;
  final bool isLoading;

  /// Small loading spinner used inside buttons while an action is in flight.
  static const _buttonSpinner = SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  const TradeActionButtons({
    super.key,
    required this.trade,
    required this.leagueId,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
    required this.onVote,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> buttons = [];

    if (trade.canRespond) {
      buttons.addAll([
        Expanded(
          child: Semantics(
            button: true,
            label: 'Accept this trade offer',
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onAccept,
              icon: isLoading ? _buttonSpinner : const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Reject this trade offer',
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onReject,
              icon: isLoading ? _buttonSpinner : const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Counter this trade with a new offer',
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => context
                      .push('/leagues/$leagueId/trades/${trade.id}/counter'),
              icon: const Icon(Icons.reply),
              label: const Text('Counter'),
            ),
          ),
        ),
      ]);
    }

    if (trade.canCancel) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 12));
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'Cancel this trade offer',
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onCancel,
              icon: isLoading ? _buttonSpinner : const Icon(Icons.cancel),
              label: const Text('Cancel Trade'),
              style: OutlinedButton.styleFrom(foregroundColor: colorScheme.tertiary),
            ),
          ),
        ),
      );
    }

    if (trade.canVote) {
      buttons.addAll([
        Expanded(
          child: Semantics(
            button: true,
            label: 'Vote to approve this trade',
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => onVote('approve'),
              icon: isLoading ? _buttonSpinner : const Icon(Icons.thumb_up),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Vote to veto this trade',
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => onVote('veto'),
              icon: isLoading ? _buttonSpinner : const Icon(Icons.thumb_down),
              label: const Text('Veto'),
              style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
            ),
          ),
        ),
      ]);
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if we have only the cancel button which uses Column layout
    if (trade.canCancel && !trade.canRespond && !trade.canVote) {
      return Column(children: buttons);
    }

    // Filter out SizedBox spacers with height 12 (used for vertical spacing)
    final rowButtons = buttons.where((w) {
      if (w is SizedBox && w.height == 12) return false;
      return true;
    }).toList();

    return Row(children: rowButtons);
  }
}
