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

  const TradeActionButtons({
    super.key,
    required this.trade,
    required this.leagueId,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = [];

    if (trade.canRespond) {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push('/leagues/$leagueId/trades/${trade.id}/counter'),
            icon: const Icon(Icons.reply),
            label: const Text('Counter'),
          ),
        ),
      ]);
    }

    if (trade.canCancel) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 12));
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Trade'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
          ),
        ),
      );
    }

    if (trade.canVote) {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onVote('approve'),
            icon: const Icon(Icons.thumb_up),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onVote('veto'),
            icon: const Icon(Icons.thumb_down),
            label: const Text('Veto'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
