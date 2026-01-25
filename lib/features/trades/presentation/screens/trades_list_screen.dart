import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../../core/widgets/states/app_empty_view.dart';
import '../providers/trades_provider.dart';
import '../widgets/trade_card.dart';

/// Screen displaying all trades for a league
class TradesListScreen extends ConsumerWidget {
  final int leagueId;

  const TradesListScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradesProvider(leagueId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Propose Trade',
            onPressed: () => context.push('/leagues/$leagueId/trades/propose'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterChips(context, ref, state),
        ),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, WidgetRef ref, TradesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: state.filter == 'all',
            onSelected: () =>
                ref.read(tradesProvider(leagueId).notifier).setFilter('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pending',
            selected: state.filter == 'pending',
            onSelected: () => ref
                .read(tradesProvider(leagueId).notifier)
                .setFilter('pending'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Completed',
            selected: state.filter == 'completed',
            onSelected: () => ref
                .read(tradesProvider(leagueId).notifier)
                .setFilter('completed'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TradesState state) {
    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading trades...');
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(tradesProvider(leagueId).notifier).loadTrades(),
      );
    }

    final trades = state.filteredTrades;

    if (trades.isEmpty) {
      return AppEmptyView(
        icon: Icons.swap_horiz,
        title: 'No Trades',
        subtitle: state.filter == 'pending'
            ? 'No pending trades at the moment'
            : 'No trades have been made yet',
        action: ElevatedButton.icon(
          onPressed: () => context.push('/leagues/$leagueId/trades/propose'),
          icon: const Icon(Icons.add),
          label: const Text('Propose a Trade'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tradesProvider(leagueId).notifier).loadTrades(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TradeCard(
              trade: trade,
              onTap: () =>
                  context.push('/leagues/$leagueId/trades/${trade.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
