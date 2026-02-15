import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../../core/widgets/states/app_empty_view.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../providers/trades_provider.dart';
import '../widgets/trade_card.dart';

/// Screen displaying all trades for a league
class TradesListScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const TradesListScreen({super.key, required this.leagueId});

  @override
  ConsumerState<TradesListScreen> createState() => _TradesListScreenState();
}

class _TradesListScreenState extends ConsumerState<TradesListScreen> {
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        tradesProvider(widget.leagueId),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
      // Sync userRosterId into trades provider when league data changes
      _subscriptions.add(ref.listenManual(
        leagueDetailProvider(widget.leagueId).select((s) => s.league?.userRosterId),
        (prev, next) {
          if (next != null && next != prev) {
            ref.read(tradesProvider(widget.leagueId).notifier).setUserRosterId(next);
          }
        },
        fireImmediately: true,
      ));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tradesProvider(widget.leagueId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Propose Trade',
            onPressed: () => context.push('/leagues/${widget.leagueId}/trades/propose'),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppFilterChip(
              label: 'Trade Block',
              selected: false,
              onSelected: () =>
                  context.push('/leagues/${widget.leagueId}/trades/block'),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: 'My Trades',
              selected: state.filter == 'mine',
              onSelected: () =>
                  ref.read(tradesProvider(widget.leagueId).notifier).setFilter('mine'),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: 'All',
              selected: state.filter == 'all',
              onSelected: () =>
                  ref.read(tradesProvider(widget.leagueId).notifier).setFilter('all'),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: 'Pending',
              selected: state.filter == 'pending',
              onSelected: () => ref
                  .read(tradesProvider(widget.leagueId).notifier)
                  .setFilter('pending'),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: 'Completed',
              selected: state.filter == 'completed',
              onSelected: () => ref
                  .read(tradesProvider(widget.leagueId).notifier)
                  .setFilter('completed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TradesState state) {
    if (state.isLoading) {
      return const SkeletonTradeList(itemCount: 4);
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(tradesProvider(widget.leagueId).notifier).loadTrades(),
      );
    }

    final trades = state.filteredTrades;

    if (trades.isEmpty) {
      return AppEmptyView(
        icon: Icons.swap_horiz,
        title: 'No Trades',
        subtitle: state.filter == 'mine'
            ? 'You have no trades yet'
            : state.filter == 'pending'
                ? 'No pending trades at the moment'
                : 'No trades have been made yet',
        action: ElevatedButton.icon(
          onPressed: () => context.push('/leagues/${widget.leagueId}/trades/propose'),
          icon: const Icon(Icons.add),
          label: const Text('Propose a Trade'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tradesProvider(widget.leagueId).notifier).loadTrades(),
      child: Center(
        child: ConstrainedBox(
          constraints: AppLayout.contentConstraints(context),
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
                      context.push('/leagues/${widget.leagueId}/trades/${trade.id}'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

