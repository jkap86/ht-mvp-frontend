import 'auction_budget.dart';
import 'auction_lot.dart';
import 'auction_settings.dart';

/// Pure domain class for auction bid calculations.
/// Consolidates bid math previously duplicated across auction_bid_dialog,
/// fast_auction_lot_card, and slow_auction_budget_card.
class AuctionBidCalculator {
  final AuctionSettings settings;
  final int totalRosterSpots;

  const AuctionBidCalculator({
    required this.settings,
    required this.totalRosterSpots,
  });

  /// Whether the given roster is the current leading bidder on a lot.
  bool isLeading(AuctionLot lot, int? myRosterId) =>
      myRosterId != null && lot.currentBidderRosterId == myRosterId;

  /// Minimum bid amount for the given lot.
  /// Leaders can raise from current bid; non-leaders must beat current + increment.
  int minBid(AuctionLot lot, int? myRosterId) {
    if (isLeading(lot, myRosterId)) return lot.currentBid;
    return lot.currentBid + settings.minIncrement;
  }

  /// Maximum bid based on available budget.
  /// Leaders can reuse their current commitment.
  int? maxBid(AuctionLot lot, AuctionBudget? budget, int? myRosterId) {
    if (budget == null) return null;
    int available = budget.available;
    if (isLeading(lot, myRosterId)) {
      available += lot.currentBid;
    }
    return available;
  }

  /// Maximum possible bid accounting for reserved budget for remaining roster spots.
  /// Each unfilled spot (minus the one being bid on) needs at least minBid reserved.
  int? maxPossibleBid(AuctionLot lot, AuctionBudget? budget, int? myRosterId) {
    if (budget == null) return null;
    final remainingSpots = totalRosterSpots - budget.wonCount;
    if (remainingSpots <= 1) return maxBid(lot, budget, myRosterId);
    final reserved = (remainingSpots - 1) * settings.minBid;
    int available = budget.available - reserved;
    if (isLeading(lot, myRosterId)) {
      available += lot.currentBid;
    }
    return available > 0 ? available : 0;
  }

  /// Simplified max possible bid for budget cards (no lot context).
  int maxPossibleBidForBudget(AuctionBudget budget) {
    final remainingSpots = totalRosterSpots - budget.wonCount;
    if (remainingSpots <= 1) return budget.available;
    final reserved = (remainingSpots - 1) * settings.minBid;
    final maxBid = budget.available - reserved;
    return maxBid > 0 ? maxBid : 0;
  }

  /// Validate a bid string and return an error message, or null if valid.
  String? validateBid(
    String? value,
    AuctionLot? lot,
    AuctionBudget? budget,
    int? myRosterId,
  ) {
    if (lot == null) return 'This lot has ended';
    if (value == null || value.isEmpty) return 'Please enter a bid amount';

    final bid = int.tryParse(value);
    if (bid == null) return 'Please enter a valid number';

    final leading = isLeading(lot, myRosterId);
    final min = minBid(lot, myRosterId);
    final max = maxBid(lot, budget, myRosterId);

    if (leading) {
      if (bid < settings.minBid) {
        return 'Bid must be at least \$${settings.minBid}';
      }
      if (bid < lot.currentBid) {
        return 'Max bid must be at least \$${lot.currentBid} (your current commitment)';
      }
    } else {
      if (bid < min) {
        return 'Bid must be at least \$$min';
      }
    }

    if (max != null && bid > max) {
      return 'Bid exceeds your available budget (\$$max)';
    }

    return null;
  }
}
