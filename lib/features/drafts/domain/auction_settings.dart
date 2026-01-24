/// Auction-specific settings for auction drafts
class AuctionSettings {
  /// Auction mode: 'slow' for async multi-lot, 'fast' for turn-based single-lot
  final String auctionMode;

  /// Time in seconds for each bid window in slow auction (default: 43200 = 12 hours)
  final int bidWindowSeconds;

  /// Maximum concurrent nominations per team in slow auction (default: 2)
  final int maxActiveNominationsPerTeam;

  /// Time in seconds for nomination/bidding in fast auction (default: 45)
  final int nominationSeconds;

  /// Time in seconds to reset timer on bid changes in fast auction (default: 10)
  final int resetOnBidSeconds;

  /// Minimum starting bid (default: $1)
  final int minBid;

  /// Minimum bid increment (default: $1)
  final int minIncrement;

  const AuctionSettings({
    required this.auctionMode,
    required this.bidWindowSeconds,
    required this.maxActiveNominationsPerTeam,
    required this.nominationSeconds,
    required this.resetOnBidSeconds,
    required this.minBid,
    required this.minIncrement,
  });

  /// Default auction settings matching backend defaults
  static const AuctionSettings defaults = AuctionSettings(
    auctionMode: 'slow',
    bidWindowSeconds: 43200,
    maxActiveNominationsPerTeam: 2,
    nominationSeconds: 45,
    resetOnBidSeconds: 10,
    minBid: 1,
    minIncrement: 1,
  );

  /// Whether this is a fast auction
  bool get isFastAuction => auctionMode == 'fast';

  /// Parse from JSON (camelCase from backend)
  factory AuctionSettings.fromJson(Map<String, dynamic> json) {
    return AuctionSettings(
      auctionMode: json['auctionMode'] as String? ?? 'slow',
      bidWindowSeconds: json['bidWindowSeconds'] as int? ?? 43200,
      maxActiveNominationsPerTeam:
          json['maxActiveNominationsPerTeam'] as int? ?? 2,
      nominationSeconds: json['nominationSeconds'] as int? ?? 45,
      resetOnBidSeconds: json['resetOnBidSeconds'] as int? ?? 10,
      minBid: json['minBid'] as int? ?? 1,
      minIncrement: json['minIncrement'] as int? ?? 1,
    );
  }

  /// Convert to JSON for API requests (snake_case for backend input)
  Map<String, dynamic> toJson() {
    return {
      'auction_mode': auctionMode,
      'bid_window_seconds': bidWindowSeconds,
      'max_active_nominations_per_team': maxActiveNominationsPerTeam,
      'nomination_seconds': nominationSeconds,
      'reset_on_bid_seconds': resetOnBidSeconds,
      'min_bid': minBid,
      'min_increment': minIncrement,
    };
  }

  /// Get bid window as Duration
  Duration get bidWindowDuration => Duration(seconds: bidWindowSeconds);

  /// Format bid window for display (e.g., "12 hours")
  String get bidWindowDisplay {
    final hours = bidWindowSeconds ~/ 3600;
    if (hours >= 24) {
      final days = hours ~/ 24;
      return '$days day${days == 1 ? '' : 's'}';
    }
    return '$hours hour${hours == 1 ? '' : 's'}';
  }

  AuctionSettings copyWith({
    String? auctionMode,
    int? bidWindowSeconds,
    int? maxActiveNominationsPerTeam,
    int? nominationSeconds,
    int? resetOnBidSeconds,
    int? minBid,
    int? minIncrement,
  }) {
    return AuctionSettings(
      auctionMode: auctionMode ?? this.auctionMode,
      bidWindowSeconds: bidWindowSeconds ?? this.bidWindowSeconds,
      maxActiveNominationsPerTeam:
          maxActiveNominationsPerTeam ?? this.maxActiveNominationsPerTeam,
      nominationSeconds: nominationSeconds ?? this.nominationSeconds,
      resetOnBidSeconds: resetOnBidSeconds ?? this.resetOnBidSeconds,
      minBid: minBid ?? this.minBid,
      minIncrement: minIncrement ?? this.minIncrement,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionSettings &&
          runtimeType == other.runtimeType &&
          auctionMode == other.auctionMode &&
          bidWindowSeconds == other.bidWindowSeconds &&
          maxActiveNominationsPerTeam == other.maxActiveNominationsPerTeam &&
          nominationSeconds == other.nominationSeconds &&
          resetOnBidSeconds == other.resetOnBidSeconds &&
          minBid == other.minBid &&
          minIncrement == other.minIncrement;

  @override
  int get hashCode =>
      auctionMode.hashCode ^
      bidWindowSeconds.hashCode ^
      maxActiveNominationsPerTeam.hashCode ^
      nominationSeconds.hashCode ^
      resetOnBidSeconds.hashCode ^
      minBid.hashCode ^
      minIncrement.hashCode;
}
