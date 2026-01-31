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

  /// Nomination deadline (fast auction only)
  final DateTime? nominationDeadline;

  /// Auction settings
  final AuctionSettings? settings;

  /// All roster budgets
  final List<AuctionBudget> budgets;

  // Slow auction nomination stats
  final int? dailyNominationsRemaining;
  final int? dailyNominationLimit;
  final bool globalCapReached;

  AuctionState({
    required this.auctionMode,
    this.activeLot,
    required this.activeLots,
    this.currentNominatorRosterId,
    this.nominationNumber,
    this.nominationDeadline,
    this.settings,
    required this.budgets,
    this.dailyNominationsRemaining,
    this.dailyNominationLimit,
    this.globalCapReached = false,
  });

  /// Whether this is a fast auction
  bool get isFastAuction => auctionMode == 'fast';

  factory AuctionState.fromJson(Map<String, dynamic> json) {
    // API returns snake_case keys
    final activeLotJson = json['active_lot'] as Map<String, dynamic>?;
    final activeLotsJson = json['active_lots'] as List<dynamic>? ?? [];
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    final budgetsJson = json['budgets'] as List<dynamic>? ?? [];
    final nominationStatsJson =
        json['nomination_stats'] as Map<String, dynamic>?;

    // Parse nomination deadline from API response
    final nominationDeadlineStr = json['nomination_deadline'] as String?;
    final nominationDeadline = nominationDeadlineStr != null
        ? DateTime.tryParse(nominationDeadlineStr)
        : null;

    return AuctionState(
      auctionMode: json['auction_mode'] as String? ?? 'slow',
      activeLot:
          activeLotJson != null ? AuctionLot.fromJson(activeLotJson) : null,
      activeLots: activeLotsJson
          .map((lot) => AuctionLot.fromJson(lot as Map<String, dynamic>))
          .toList(),
      currentNominatorRosterId: json['current_nominator_roster_id'] as int?,
      nominationNumber: json['nomination_number'] as int?,
      nominationDeadline: nominationDeadline,
      settings:
          settingsJson != null ? AuctionSettings.fromJson(settingsJson) : null,
      budgets: budgetsJson
          .map((b) => AuctionBudget.fromJson(b as Map<String, dynamic>))
          .toList(),
      dailyNominationsRemaining:
          nominationStatsJson?['daily_nominations_remaining'] as int?,
      dailyNominationLimit:
          nominationStatsJson?['daily_nomination_limit'] as int?,
      globalCapReached:
          nominationStatsJson?['global_cap_reached'] as bool? ?? false,
    );
  }

  AuctionState copyWith({
    String? auctionMode,
    AuctionLot? activeLot,
    List<AuctionLot>? activeLots,
    int? currentNominatorRosterId,
    int? nominationNumber,
    DateTime? nominationDeadline,
    AuctionSettings? settings,
    List<AuctionBudget>? budgets,
    int? dailyNominationsRemaining,
    int? dailyNominationLimit,
    bool? globalCapReached,
  }) {
    return AuctionState(
      auctionMode: auctionMode ?? this.auctionMode,
      activeLot: activeLot ?? this.activeLot,
      activeLots: activeLots ?? this.activeLots,
      currentNominatorRosterId:
          currentNominatorRosterId ?? this.currentNominatorRosterId,
      nominationNumber: nominationNumber ?? this.nominationNumber,
      nominationDeadline: nominationDeadline ?? this.nominationDeadline,
      settings: settings ?? this.settings,
      budgets: budgets ?? this.budgets,
      dailyNominationsRemaining:
          dailyNominationsRemaining ?? this.dailyNominationsRemaining,
      dailyNominationLimit: dailyNominationLimit ?? this.dailyNominationLimit,
      globalCapReached: globalCapReached ?? this.globalCapReached,
    );
  }

  @override
  String toString() {
    return 'AuctionState(mode: $auctionMode, activeLots: ${activeLots.length}, nominator: $currentNominatorRosterId)';
  }
}
