import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../players/domain/player.dart';
import '../../domain/auction_settings.dart';
import '../providers/draft_room_provider.dart';
import '../utils/player_filtering.dart';
import '../../../../core/theme/semantic_colors.dart';
import 'auction_bid_dialog.dart';
import 'auction_lots_panel.dart';
import 'nomination_hint_row.dart';
import 'player_search_filter_panel.dart';

/// Content for auction drafts in the bottom drawer.
/// Shows active lots panel, search/filter, and player nomination list.
class AuctionDrawerContent extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final ScrollController scrollController;
  final String searchQuery;
  final String? selectedPosition;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onPositionChanged;
  final Future<void> Function(int playerId)? onNominate;
  final Future<void> Function(int lotId, int maxBid)? onSetMaxBid;

  const AuctionDrawerContent({
    super.key,
    required this.providerKey,
    required this.scrollController,
    required this.searchQuery,
    required this.selectedPosition,
    required this.onSearchChanged,
    required this.onPositionChanged,
    this.onNominate,
    this.onSetMaxBid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftRoomProvider(providerKey));
    final players = state.players;
    final draftedPlayerIds = state.draftedPlayerIds;
    final myBudget = state.myBudget;
    final auctionSettings = state.auctionSettings;

    final availablePlayers = filterAvailablePlayers(
      players,
      draftedIds: draftedPlayerIds,
      selectedPosition: selectedPosition,
      searchQuery: searchQuery,
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Active lots section (horizontal scroll)
        SliverToBoxAdapter(
          child: AuctionLotsPanel(
            state: state,
            onBidTap: (lot) {
              final player =
                  players.where((p) => p.id == lot.playerId).firstOrNull;
              if (player == null || onSetMaxBid == null) return;
              AuctionBidDialog.show(
                context,
                leagueId: providerKey.leagueId,
                draftId: providerKey.draftId,
                lot: lot,
                player: player,
                myBudget: myBudget,
                draftOrder: state.draftOrder,
                settings: auctionSettings ?? AuctionSettings.defaults,
                onSubmit: (maxBid) => onSetMaxBid!(lot.id, maxBid),
                serverClockOffsetMs: state.serverClockOffsetMs,
              );
            },
            onNominateTap: () {
              // Don't show bottom sheet, just expand drawer for nomination
            },
          ),
        ),

        const SliverToBoxAdapter(child: Divider(height: 1)),

        // Search bar with position filter
        SliverToBoxAdapter(
          child: PlayerSearchFilterPanel(
            searchQuery: searchQuery,
            selectedPosition: selectedPosition,
            onSearchChanged: onSearchChanged,
            onPositionChanged: onPositionChanged,
            hintText: 'Search players to nominate...',
          ),
        ),

        // Label for nomination section
        const SliverToBoxAdapter(child: NominationHintRow()),

        // Players list for nomination
        SliverList.builder(
          itemCount: availablePlayers.length,
          itemBuilder: (context, index) {
            final player = availablePlayers[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: getPositionColor(player.primaryPosition),
                child: Text(
                  player.primaryPosition,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title:
                  Text(player.fullName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                '${player.team ?? 'FA'} - ${player.primaryPosition}',
                style: const TextStyle(fontSize: 12),
              ),
              dense: true,
              onTap: onNominate != null ? () => onNominate!(player.id) : null,
            );
          },
        ),
      ],
    );
  }
}
