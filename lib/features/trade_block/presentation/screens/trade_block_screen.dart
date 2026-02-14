import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../../core/widgets/states/app_empty_view.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../providers/trade_block_provider.dart';
import '../widgets/trade_block_roster_section.dart';
import '../widgets/add_to_trade_block_sheet.dart';

class TradeBlockScreen extends ConsumerWidget {
  final int leagueId;

  const TradeBlockScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradeBlockProvider(leagueId));
    final leagueState = ref.watch(leagueDetailProvider(leagueId));
    final userRosterId = leagueState.league?.userRosterId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Block'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildPositionFilters(context, ref, state),
        ),
      ),
      body: _buildBody(context, ref, state, userRosterId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add to Block'),
      ),
    );
  }

  Widget _buildPositionFilters(
    BuildContext context,
    WidgetRef ref,
    TradeBlockState state,
  ) {
    const positions = ['All', 'QB', 'RB', 'WR', 'TE'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: positions.map((pos) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppFilterChip(
                label: pos,
                selected: state.positionFilter == pos,
                onSelected: () => ref
                    .read(tradeBlockProvider(leagueId).notifier)
                    .setPositionFilter(pos),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TradeBlockState state,
    int? userRosterId,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(tradeBlockProvider(leagueId).notifier).loadItems(),
      );
    }

    final grouped = state.groupedByRoster;

    if (grouped.isEmpty) {
      return AppEmptyView(
        icon: Icons.storefront_outlined,
        title: 'Trade Block is Empty',
        subtitle: 'No players are being shopped right now',
        action: FilledButton.icon(
          onPressed: () => _showAddSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Add a Player'),
        ),
      );
    }

    // Sort: current user's section first
    final sortedRosterIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == userRosterId) return -1;
        if (b == userRosterId) return 1;
        return 0;
      });

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(tradeBlockProvider(leagueId).notifier).loadItems(),
      child: Center(
        child: ConstrainedBox(
          constraints: AppLayout.contentConstraints(context),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: sortedRosterIds.length,
            itemBuilder: (context, index) {
              final rosterId = sortedRosterIds[index];
              final items = grouped[rosterId]!;
              final isCurrentUser = rosterId == userRosterId;

              return TradeBlockRosterSection(
                items: items,
                isCurrentUser: isCurrentUser,
                onTap: isCurrentUser
                    ? null
                    : (item) {
                        // Navigate to propose trade screen with recipient pre-filled
                        context.push(
                          '/leagues/$leagueId/trades/propose',
                          extra: {'recipientRosterId': item.rosterId},
                        );
                      },
                onRemove: isCurrentUser
                    ? (item) => _confirmRemove(context, ref, item.playerId, item.fullName)
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddToTradeBlockSheet(leagueId: leagueId),
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    int playerId,
    String playerName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Trade Block'),
        content: Text('Remove $playerName from your trade block?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(tradeBlockProvider(leagueId).notifier)
                  .removeItem(playerId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
