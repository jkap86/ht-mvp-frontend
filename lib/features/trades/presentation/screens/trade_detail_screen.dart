import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../../core/utils/idempotency.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../data/trade_repository.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';
import '../providers/trades_provider.dart';
import '../widgets/trade_assets_section.dart';
import '../widgets/trade_status_banner.dart';
import '../widgets/trade_summary_card.dart';
import '../widgets/trade_votes_section.dart';
import '../widgets/trade_action_buttons.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trade Details'),
      ),
      body: tradeAsync.when(
        loading: () => const AppLoadingView(message: 'Loading trade...'),
        error: (error, stack) => AppErrorView(
          message: ErrorSanitizer.sanitize(error),
          onRetry: () => ref.invalidate(
              tradeDetailProvider((leagueId: leagueId, tradeId: tradeId))),
        ),
        data: (trade) => _buildTradeContent(context, ref, trade),
      ),
    );
  }

  Widget _buildTradeContent(BuildContext context, WidgetRef ref, Trade trade) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TradeStatusBanner(trade: trade),
          const SizedBox(height: 16),
          TradeSummaryCard(trade: trade),
          const SizedBox(height: 24),
          TradeAssetsSection(trade: trade),
          const SizedBox(height: 24),
          if (trade.message != null && trade.message!.isNotEmpty) ...[
            _buildMessageSection(context, trade),
            const SizedBox(height: 24),
          ],
          if (trade.status == TradeStatus.inReview) ...[
            TradeVotesSection(trade: trade),
            const SizedBox(height: 24),
          ],
          TradeActionButtons(
            trade: trade,
            leagueId: leagueId,
            onAccept: () => _handleAccept(context, ref, trade),
            onReject: () => _handleReject(context, ref, trade),
            onCancel: () => _handleCancel(context, ref, trade),
            onVote: (vote) => _handleVote(context, ref, trade, vote),
          ),
        ],
          ),
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
      final key = newIdempotencyKey();
      final result =
          await ref.read(tradesProvider(leagueId).notifier).acceptTrade(trade.id, idempotencyKey: key);
      if (context.mounted) {
        if (result != null) {
          ref.invalidate(
              tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
          showSuccess(ref, 'Trade accepted!');
        } else {
          final error = ref.read(tradesProvider(leagueId)).error;
          (error ?? 'Failed to accept trade').showAsError(ref);
        }
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final key = newIdempotencyKey();
      final result =
          await ref.read(tradesProvider(leagueId).notifier).rejectTrade(trade.id, idempotencyKey: key);
      if (context.mounted) {
        if (result != null) {
          ref.invalidate(
              tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
          showSuccess(ref, 'Trade rejected');
        } else {
          final error = ref.read(tradesProvider(leagueId)).error;
          (error ?? 'Failed to reject trade').showAsError(ref);
        }
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiary),
            child: const Text('Cancel Trade'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final key = newIdempotencyKey();
      final result =
          await ref.read(tradesProvider(leagueId).notifier).cancelTrade(trade.id, idempotencyKey: key);
      if (context.mounted) {
        if (result != null) {
          ref.invalidate(
              tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
          showSuccess(ref, 'Trade cancelled');
        } else {
          final error = ref.read(tradesProvider(leagueId)).error;
          (error ?? 'Failed to cancel trade').showAsError(ref);
        }
      }
    }
  }

  Future<void> _handleVote(
      BuildContext context, WidgetRef ref, Trade trade, String vote) async {
    final key = newIdempotencyKey();
    final success = await ref
        .read(tradesProvider(leagueId).notifier)
        .voteTrade(trade.id, vote, idempotencyKey: key);
    if (context.mounted) {
      if (success) {
        ref.invalidate(
            tradeDetailProvider((leagueId: leagueId, tradeId: tradeId)));
        showSuccess(ref, 'Vote recorded: ${vote == 'approve' ? 'Approved' : 'Vetoed'}');
      } else {
        final error = ref.read(tradesProvider(leagueId)).error;
        (error ?? 'Failed to record vote').showAsError(ref);
      }
    }
  }
}
