import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../data/trade_repository.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';
import '../providers/trades_provider.dart';
import '../widgets/trade_players_section.dart';

/// Provider for loading a single trade's details
final tradeDetailProvider =
    FutureProvider.family<Trade, ({int leagueId, int tradeId})>(
  (ref, params) async {
    final repo = ref.watch(tradeRepositoryProvider);
    return repo.getTrade(params.leagueId, params.tradeId);
  },
);

/// Screen showing detailed information about a single trade
class TradeDetailScreen extends ConsumerWidget {
  final int leagueId;
  final int tradeId;

  const TradeDetailScreen({
    super.key,
    required this.leagueId,
    required this.tradeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradeAsync =
        ref.watch(tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Details'),
      ),
      body: tradeAsync.when(
        loading: () => const AppLoadingView(message: 'Loading trade...'),
        error: (error, stack) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(
              tradeDetailProvider((leagueId: leagueId, tradeId: tradeId))),
        ),
        data: (trade) => _buildTradeContent(context, ref, trade),
      ),
    );
  }

  Widget _buildTradeContent(BuildContext context, WidgetRef ref, Trade trade) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          _buildStatusBanner(context, trade),
          const SizedBox(height: 16),

          // Trade Summary
          _buildTradeSummary(context, trade),
          const SizedBox(height: 24),

          // Players Being Traded
          TradePlayersSection(trade: trade),
          const SizedBox(height: 24),

          // Message (if any)
          if (trade.message != null && trade.message!.isNotEmpty) ...[
            _buildMessageSection(context, trade),
            const SizedBox(height: 24),
          ],

          // Votes (if in review)
          if (trade.status == TradeStatus.inReview &&
              trade.votes.isNotEmpty) ...[
            _buildVotesSection(context, trade),
            const SizedBox(height: 24),
          ],

          // Action Buttons
          _buildActionButtons(context, ref, trade),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, Trade trade) {
    Color backgroundColor;
    IconData icon;

    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.countered:
        backgroundColor = Colors.orange.shade100;
        icon = Icons.pending;
        break;
      case TradeStatus.accepted:
      case TradeStatus.inReview:
        backgroundColor = Colors.blue.shade100;
        icon = Icons.hourglass_empty;
        break;
      case TradeStatus.completed:
        backgroundColor = Colors.green.shade100;
        icon = Icons.check_circle;
        break;
      case TradeStatus.rejected:
      case TradeStatus.cancelled:
      case TradeStatus.expired:
      case TradeStatus.vetoed:
        backgroundColor = Colors.grey.shade200;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trade.status.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (trade.status.isPending) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires ${DateFormat.yMMMd().add_jm().format(trade.expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (trade.isInReviewPeriod) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Review ends ${DateFormat.yMMMd().add_jm().format(trade.reviewEndsAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeSummary(BuildContext context, Trade trade) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.proposerTeamName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${trade.proposerUsername}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.swap_horiz, size: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trade.recipientTeamName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${trade.recipientUsername}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Proposed ${DateFormat.yMMMd().add_jm().format(trade.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection(BuildContext context, Trade trade) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(trade.message!),
          ],
        ),
      ),
    );
  }

  Widget _buildVotesSection(BuildContext context, Trade trade) {
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
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _VoteChip(
                  label: 'Veto',
                  count: trade.vetoCount,
                  color: Colors.red,
                ),
              ],
            ),
            if (trade.votes.isNotEmpty) ...[
              const Divider(height: 24),
              ...trade.votes.map((vote) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          vote.isApprove ? Icons.thumb_up : Icons.thumb_down,
                          size: 16,
                          color: vote.isApprove ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text('${vote.teamName} (@${vote.username})'),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Trade trade) {
    final List<Widget> buttons = [];

    if (trade.canRespond) {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleAccept(context, ref, trade),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleReject(context, ref, trade),
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
            onPressed: () => _handleCancel(context, ref, trade),
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
            onPressed: () => _handleVote(context, ref, trade, 'approve'),
            icon: const Icon(Icons.thumb_up),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleVote(context, ref, trade, 'veto'),
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

  Future<void> _handleAccept(
      BuildContext context, WidgetRef ref, Trade trade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Trade?'),
        content: const Text('Are you sure you want to accept this trade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result =
          await ref.read(tradesProvider(leagueId).notifier).acceptTrade(trade.id);
      if (result != null && context.mounted) {
        ref.invalidate(
            tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade accepted!')),
        );
      }
    }
  }

  Future<void> _handleReject(
      BuildContext context, WidgetRef ref, Trade trade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Trade?'),
        content: const Text('Are you sure you want to reject this trade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result =
          await ref.read(tradesProvider(leagueId).notifier).rejectTrade(trade.id);
      if (result != null && context.mounted) {
        ref.invalidate(
            tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade rejected')),
        );
      }
    }
  }

  Future<void> _handleCancel(
      BuildContext context, WidgetRef ref, Trade trade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trade?'),
        content: const Text('Are you sure you want to cancel this trade offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Trade'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result =
          await ref.read(tradesProvider(leagueId).notifier).cancelTrade(trade.id);
      if (result != null && context.mounted) {
        ref.invalidate(
            tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade cancelled')),
        );
      }
    }
  }

  Future<void> _handleVote(
      BuildContext context, WidgetRef ref, Trade trade, String vote) async {
    final success = await ref
        .read(tradesProvider(leagueId).notifier)
        .voteTrade(trade.id, vote);
    if (success && context.mounted) {
      ref.invalidate(
          tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Vote recorded: ${vote == 'approve' ? 'Approved' : 'Vetoed'}')),
      );
    }
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
        borderRadius: BorderRadius.circular(16),
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
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
