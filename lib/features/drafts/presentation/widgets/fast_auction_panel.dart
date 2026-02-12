import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import '../../domain/auction_lot.dart';
import '../../domain/draft_status.dart';
import '../providers/draft_room_provider.dart';
import 'fast_auction_header.dart';
import 'fast_auction_history_sheet.dart';
import 'fast_auction_lot_card.dart';
import 'fast_auction_lot_result.dart';
import 'fast_auction_waiting_state.dart';

/// Panel for fast auction mode showing:
/// - Current nominator indicator
/// - Active lot with countdown timer
/// - Nominate/bid controls
class FastAuctionPanel extends StatelessWidget {
  final DraftRoomState state;
  final void Function(AuctionLot lot) onBidTap;
  final VoidCallback onNominateTap;
  final VoidCallback? onDismissResult;

  const FastAuctionPanel({
    super.key,
    required this.state,
    required this.onBidTap,
    required this.onNominateTap,
    this.onDismissResult,
  });

  @override
  Widget build(BuildContext context) {
    // Active lot is the one with earliest deadline (first in sorted list)
    // activeLots is maintained sorted by bidDeadline ASC in _upsertAndSortLot()
    final activeLot = state.activeLots.isNotEmpty ? state.activeLots.first : null;
    final nominator = state.currentNominator;
    final isMyNomination = state.isMyNomination;
    final nominationNumber = state.nominationNumber ?? 1;

    // Build a map of players by ID for quick lookup
    final playersMap = {for (var p in state.players) p.id: p};
    final budgetsMap = {for (var b in state.budgets) b.rosterId: b};
    final lastResult = state.lastLotResult;

    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with nominator info
          Builder(
            builder: (context) => FastAuctionHeader(
              nominator: nominator,
              isMyNomination: isMyNomination,
              nominationNumber: nominationNumber,
              myBudgetAvailable: state.myBudget?.available,
              completedCount: state.completedLotResults.length,
              onHistoryTap: state.completedLotResults.isNotEmpty
                  ? () => FastAuctionHistorySheet.show(
                        context,
                        completedResults: state.completedLotResults,
                        playersMap: playersMap,
                        budgetsMap: budgetsMap,
                        myRosterId: state.myBudget?.rosterId,
                      )
                  : null,
            ),
          ),

          // Lot result announcement banner
          if (lastResult != null)
            FastAuctionLotResult(
              result: lastResult,
              playerName: playersMap[lastResult.playerId]?.fullName,
              winnerName: lastResult.winnerRosterId != null
                  ? budgetsMap[lastResult.winnerRosterId]?.username
                  : null,
              isMyWin: !lastResult.isPassed &&
                  lastResult.winnerRosterId == state.myBudget?.rosterId,
              onDismiss: onDismissResult,
            ),

          // Paused overlay or active lot / waiting state
          if (state.draft?.status == DraftStatus.paused)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pause_circle_filled,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Draft Paused',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Timers are frozen. Waiting for commissioner to resume.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else if (activeLot != null)
            FastAuctionLotCard(
              lot: activeLot,
              player: playersMap[activeLot.playerId],
              leadingBidderName: activeLot.currentBidderRosterId != null
                  ? budgetsMap[activeLot.currentBidderRosterId]?.username
                  : null,
              myBudget: state.myBudget,
              onBidTap: () => onBidTap(activeLot),
              serverClockOffsetMs: state.serverClockOffsetMs,
              auctionSettings: state.auctionSettings,
              myRosterId: state.myRosterId,
              totalRosterSpots: state.draft?.rounds,
            )
          else
            FastAuctionWaitingState(
              isMyNomination: isMyNomination,
              onNominateTap: onNominateTap,
              nominationDeadline: state.nominationDeadline,
              serverClockOffsetMs: state.serverClockOffsetMs,
            ),
        ],
      ),
    );
  }
}
