import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../players/domain/player.dart';
import '../../../domain/auction_budget.dart';
import '../../../domain/auction_lot.dart';
import '../../../domain/draft_order_entry.dart';
import '../../providers/draft_room_provider.dart';
import '../auction_bid_dialog.dart';
import 'slow_auction_action_section.dart';
import 'slow_auction_budget_card.dart';
import 'slow_auction_lot_card.dart';

/// Main screen for slow auction drafts.
/// Replaces the grid view with a task-list/inbox paradigm.
class SlowAuctionScreen extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final int leagueId;
  final int draftId;
  final Future<void> Function(int) onNominate;
  final Future<void> Function(int, int) onSetMaxBid;

  const SlowAuctionScreen({
    super.key,
    required this.providerKey,
    required this.leagueId,
    required this.draftId,
    required this.onNominate,
    required this.onSetMaxBid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLots = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.activeLots),
    );
    final myBudget = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.myBudget),
    );
    final myRosterId = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.myRosterId),
    );
    final players = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.players),
    );
    final draftOrder = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draftOrder),
    );
    final draft = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draft),
    );
    final dailyNominationsRemaining = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.dailyNominationsRemaining),
    );
    final dailyNominationLimit = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.dailyNominationLimit),
    );
    final globalCapReached = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.globalCapReached),
    );

    // Find lots where user has bid but is outbid (not currently winning)
    final outbidLots = activeLots.where((lot) {
      // User has placed a bid (myMaxBid is not null) but is not the high bidder
      return lot.myMaxBid != null &&
          lot.myMaxBid! > 0 &&
          lot.currentBidderRosterId != myRosterId;
    }).toList();

    // Sort active lots by deadline (ending soonest first)
    final sortedLots = [...activeLots]
      ..sort((a, b) => a.bidDeadline.compareTo(b.bidDeadline));

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(draftRoomProvider(providerKey).notifier).loadAuctionData();
            },
            child: CustomScrollView(
              slivers: [
                // Action needed section
                SliverToBoxAdapter(
                  child: SlowAuctionActionSection(
                    activeLots: activeLots,
                    outbidLots: outbidLots,
                    myRosterId: myRosterId,
                    players: players,
                    draftOrder: draftOrder,
                    onNominate: () => _showNominateSheet(context, ref),
                    onViewLot: (lot) => _showBidDialog(
                      context,
                      lot,
                      players,
                      draftOrder,
                      myBudget,
                    ),
                    dailyNominationsRemaining: dailyNominationsRemaining,
                    dailyNominationLimit: dailyNominationLimit,
                    globalCapReached: globalCapReached,
                  ),
                ),

                // Active auctions header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.gavel, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Active Auctions (${activeLots.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Active auctions list
                if (sortedLots.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No active auctions.\nNominate a player to start bidding!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lot = sortedLots[index];
                        final player = players
                            .where((p) => p.id == lot.playerId)
                            .firstOrNull;
                        final highBidder = draftOrder
                            .where((entry) => entry.rosterId == lot.currentBidderRosterId)
                            .firstOrNull;
                        final isWinning = lot.currentBidderRosterId == myRosterId;

                        // Skip if player not found
                        if (player == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: SlowAuctionLotCard(
                            lot: lot,
                            player: player,
                            highBidderName: highBidder?.username ?? 'Unknown',
                            isWinning: isWinning,
                            onTap: () => _showBidDialog(
                              context,
                              lot,
                              players,
                              draftOrder,
                              myBudget,
                            ),
                          ),
                        );
                      },
                      childCount: sortedLots.length,
                    ),
                  ),

                // Bottom padding for budget card
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),

        // Budget card at bottom
        if (myBudget != null)
          SlowAuctionBudgetCard(
            budget: myBudget,
            totalRounds: draft?.rounds ?? 15,
          ),
      ],
    );
  }

  void _showBidDialog(
    BuildContext context,
    AuctionLot lot,
    List<Player> players,
    List<DraftOrderEntry> draftOrder,
    AuctionBudget? myBudget,
  ) {
    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    if (player == null) return;

    AuctionBidDialog.show(
      context,
      leagueId: leagueId,
      draftId: draftId,
      lot: lot,
      player: player,
      myBudget: myBudget,
      draftOrder: draftOrder,
      onSubmit: (maxBid) => onSetMaxBid(lot.id, maxBid),
    );
  }

  void _showNominateSheet(BuildContext context, WidgetRef ref) {
    // Show bottom sheet with player search for nomination
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _NominatePlayerSheet(
            providerKey: providerKey,
            scrollController: scrollController,
            onNominate: onNominate,
          );
        },
      ),
    );
  }
}

/// Bottom sheet for nominating a player.
class _NominatePlayerSheet extends ConsumerStatefulWidget {
  final DraftRoomKey providerKey;
  final ScrollController scrollController;
  final Future<void> Function(int) onNominate;

  const _NominatePlayerSheet({
    required this.providerKey,
    required this.scrollController,
    required this.onNominate,
  });

  @override
  ConsumerState<_NominatePlayerSheet> createState() => _NominatePlayerSheetState();
}

class _NominatePlayerSheetState extends ConsumerState<_NominatePlayerSheet> {
  String _searchQuery = '';
  String _positionFilter = 'All';
  String _sortBy = 'Name'; // Name, Projected, Prior Season
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.players),
    );
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPlayerIds),
    );
    final activeLots = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.activeLots),
    );

    // Get players already in active auction
    final activePlayerIds = activeLots.map((l) => l.playerId).toSet();

    // Filter available players
    var availablePlayers = players.where((p) {
      // Not drafted and not in active auction
      if (draftedPlayerIds.contains(p.id)) return false;
      if (activePlayerIds.contains(p.id)) return false;

      // Position filter
      if (_positionFilter != 'All' && p.primaryPosition != _positionFilter) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.fullName.toLowerCase().contains(query) ||
            (p.team?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();

    // Sort available players
    availablePlayers.sort((a, b) {
      switch (_sortBy) {
        case 'Projected':
          // Sort by remaining projected points (highest first)
          return (b.remainingProjectedPts ?? 0).compareTo(a.remainingProjectedPts ?? 0);
        case 'Prior Season':
          // Sort by prior season points (highest first)
          return (b.priorSeasonPts ?? 0).compareTo(a.priorSeasonPts ?? 0);
        default:
          // Sort by name (alphabetical)
          return a.fullName.compareTo(b.fullName);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.person_add),
                const SizedBox(width: 8),
                Text(
                  'Nominate Player',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search players...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Position filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'QB', 'RB', 'WR', 'TE', 'K', 'DEF'].map((pos) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(pos),
                      selected: _positionFilter == pos,
                      onSelected: (selected) {
                        setState(() => _positionFilter = selected ? pos : 'All');
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Sort: ',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(width: 8),
                ...['Name', 'Projected', 'Prior Season'].map((sort) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sort),
                      selected: _sortBy == sort,
                      onSelected: (selected) {
                        if (selected) setState(() => _sortBy = sort);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Players list
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: availablePlayers.length,
              itemBuilder: (context, index) {
                final player = availablePlayers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPositionColor(player.primaryPosition),
                    child: Text(
                      player.primaryPosition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(player.fullName),
                  subtitle: Text(player.team ?? ''),
                  trailing: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: () => _nominate(player.id),
                          child: const Text('Nominate'),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nominate(int playerId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await widget.onNominate(playerId);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
