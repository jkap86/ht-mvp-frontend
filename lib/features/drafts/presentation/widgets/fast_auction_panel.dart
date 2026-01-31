import 'package:flutter/material.dart';

import '../../domain/auction_lot.dart';
import '../providers/draft_room_provider.dart';
import 'fast_auction_header.dart';
import 'fast_auction_lot_card.dart';
import 'fast_auction_waiting_state.dart';

/// Panel for fast auction mode showing:
/// - Current nominator indicator
/// - Active lot with countdown timer
/// - Nominate/bid controls
class FastAuctionPanel extends StatelessWidget {
  final DraftRoomState state;
  final void Function(AuctionLot lot) onBidTap;
  final VoidCallback onNominateTap;

  const FastAuctionPanel({
    super.key,
    required this.state,
    required this.onBidTap,
    required this.onNominateTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeLot = state.activeLots.isNotEmpty ? state.activeLots.first : null;
    final nominator = state.currentNominator;
    final isMyNomination = state.isMyNomination;
    final nominationNumber = state.nominationNumber ?? 1;

    // Build a map of players by ID for quick lookup
    final playersMap = {for (var p in state.players) p.id: p};
    final budgetsMap = {for (var b in state.budgets) b.rosterId: b};

    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        border: Border(top: BorderSide(color: Colors.deepPurple[200]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with nominator info
          FastAuctionHeader(
            nominator: nominator,
            isMyNomination: isMyNomination,
            nominationNumber: nominationNumber,
            myBudgetAvailable: state.myBudget?.available,
          ),

          // Active lot or waiting state
          if (activeLot != null)
            FastAuctionLotCard(
              lot: activeLot,
              player: playersMap[activeLot.playerId],
              leadingBidderName: activeLot.currentBidderRosterId != null
                  ? budgetsMap[activeLot.currentBidderRosterId]?.username
                  : null,
              myBudget: state.myBudget,
              onBidTap: () => onBidTap(activeLot),
            )
          else
            FastAuctionWaitingState(
              isMyNomination: isMyNomination,
              onNominateTap: onNominateTap,
              nominationDeadline: state.nominationDeadline,
            ),
        ],
      ),
    );
  }
}
