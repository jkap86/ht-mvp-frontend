import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import 'draft_socket_handler.dart' show OutbidNotification;

/// Auction-specific state extracted from DraftRoomState.
///
/// Groups all auction-related fields into a dedicated sub-state class
/// to improve organization and reduce complexity of the main state.
class AuctionSubState {
  /// Currently active auction lots.
  final List<AuctionLot> activeLots;

  /// Budget information for each roster.
  final List<AuctionBudget> budgets;

  /// Notification when current user is outbid.
  final OutbidNotification? outbidNotification;

  /// Auction mode: 'slow' or 'fast'.
  final String auctionMode;

  /// Roster ID of the current nominator (fast auction only).
  final int? currentNominatorRosterId;

  /// Current nomination number (fast auction only).
  final int? nominationNumber;

  const AuctionSubState({
    this.activeLots = const [],
    this.budgets = const [],
    this.outbidNotification,
    this.auctionMode = 'slow',
    this.currentNominatorRosterId,
    this.nominationNumber,
  });

  /// Whether this is a fast auction mode.
  bool get isFastAuction => auctionMode == 'fast';

  /// Get the budget for a specific roster.
  AuctionBudget? getBudgetForRoster(int? rosterId) {
    if (rosterId == null) return null;
    return budgets.where((b) => b.rosterId == rosterId).firstOrNull;
  }

  /// Creates a copy with updated fields.
  AuctionSubState copyWith({
    List<AuctionLot>? activeLots,
    List<AuctionBudget>? budgets,
    OutbidNotification? outbidNotification,
    bool clearOutbidNotification = false,
    String? auctionMode,
    int? currentNominatorRosterId,
    int? nominationNumber,
  }) {
    return AuctionSubState(
      activeLots: activeLots ?? this.activeLots,
      budgets: budgets ?? this.budgets,
      outbidNotification: clearOutbidNotification
          ? null
          : (outbidNotification ?? this.outbidNotification),
      auctionMode: auctionMode ?? this.auctionMode,
      currentNominatorRosterId:
          currentNominatorRosterId ?? this.currentNominatorRosterId,
      nominationNumber: nominationNumber ?? this.nominationNumber,
    );
  }
}
