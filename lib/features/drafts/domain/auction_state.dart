import 'auction_budget.dart';
import 'auction_lot.dart';
import 'auction_settings.dart';

/// Represents the current state of an auction draft.
class AuctionState {
  /// Auction mode: 'slow' or 'fast'
  final String auctionMode;

  /// The currently active lot (for fast auction, there's at most one)
  final AuctionLot? activeLot;

  /// All active lots (for slow auction, can be multiple)
  final List<AuctionLot> activeLots;

  /// Current nominator roster ID (fast auction only)
  final int? currentNominatorRosterId;

  /// Current nomination number (fast auction only)
  final int? nominationNumber;

  /// Auction settings
  final AuctionSettings? settings;

  /// All roster budgets
  final List<AuctionBudget> budgets;

  AuctionState({
    required this.auctionMode,
    this.activeLot,
    required this.activeLots,
    this.currentNominatorRosterId,
    this.nominationNumber,
    this.settings,
    required this.budgets,
  });

  /// Whether this is a fast auction
  bool get isFastAuction => auctionMode == 'fast';

  factory AuctionState.fromJson(Map<String, dynamic> json) {
    final activeLotJson = json['activeLot'] as Map<String, dynamic>?;
    final activeLotsJson = json['activeLots'] as List<dynamic>? ?? [];
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    final budgetsJson = json['budgets'] as List<dynamic>? ?? [];

    return AuctionState(
      auctionMode: json['auctionMode'] as String? ?? 'slow',
      activeLot:
          activeLotJson != null ? AuctionLot.fromJson(activeLotJson) : null,
      activeLots: activeLotsJson
          .map((lot) => AuctionLot.fromJson(lot as Map<String, dynamic>))
          .toList(),
      currentNominatorRosterId: json['currentNominatorRosterId'] as int?,
      nominationNumber: json['nominationNumber'] as int?,
      settings:
          settingsJson != null ? AuctionSettings.fromJson(settingsJson) : null,
      budgets: budgetsJson
          .map((b) => AuctionBudget.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  AuctionState copyWith({
    String? auctionMode,
    AuctionLot? activeLot,
    List<AuctionLot>? activeLots,
    int? currentNominatorRosterId,
    int? nominationNumber,
    AuctionSettings? settings,
    List<AuctionBudget>? budgets,
  }) {
    return AuctionState(
      auctionMode: auctionMode ?? this.auctionMode,
      activeLot: activeLot ?? this.activeLot,
      activeLots: activeLots ?? this.activeLots,
      currentNominatorRosterId:
          currentNominatorRosterId ?? this.currentNominatorRosterId,
      nominationNumber: nominationNumber ?? this.nominationNumber,
      settings: settings ?? this.settings,
      budgets: budgets ?? this.budgets,
    );
  }

  @override
  String toString() {
    return 'AuctionState(mode: $auctionMode, activeLots: ${activeLots.length}, nominator: $currentNominatorRosterId)';
  }
}
