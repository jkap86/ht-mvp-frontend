/// Auction-specific settings for slow auction drafts
class AuctionSettings {
  /// Time in seconds for each bid window (default: 43200 = 12 hours)
  final int bidWindowSeconds;

  /// Maximum concurrent nominations per team (default: 2)
  final int maxActiveNominationsPerTeam;

  /// Minimum starting bid (default: $1)
  final int minBid;

  /// Minimum bid increment (default: $1)
  final int minIncrement;

  const AuctionSettings({
    required this.bidWindowSeconds,
    required this.maxActiveNominationsPerTeam,
    required this.minBid,
    required this.minIncrement,
  });

  /// Default auction settings matching backend defaults
  static const AuctionSettings defaults = AuctionSettings(
    bidWindowSeconds: 43200,
    maxActiveNominationsPerTeam: 2,
    minBid: 1,
    minIncrement: 1,
  );

  /// Parse from JSON (camelCase from backend)
  factory AuctionSettings.fromJson(Map<String, dynamic> json) {
    return AuctionSettings(
      bidWindowSeconds: json['bidWindowSeconds'] as int? ?? 43200,
      maxActiveNominationsPerTeam:
          json['maxActiveNominationsPerTeam'] as int? ?? 2,
      minBid: json['minBid'] as int? ?? 1,
      minIncrement: json['minIncrement'] as int? ?? 1,
    );
  }

  /// Convert to JSON for API requests (snake_case for backend input)
  Map<String, dynamic> toJson() {
    return {
      'bid_window_seconds': bidWindowSeconds,
      'max_active_nominations_per_team': maxActiveNominationsPerTeam,
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
    int? bidWindowSeconds,
    int? maxActiveNominationsPerTeam,
    int? minBid,
    int? minIncrement,
  }) {
    return AuctionSettings(
      bidWindowSeconds: bidWindowSeconds ?? this.bidWindowSeconds,
      maxActiveNominationsPerTeam:
          maxActiveNominationsPerTeam ?? this.maxActiveNominationsPerTeam,
      minBid: minBid ?? this.minBid,
      minIncrement: minIncrement ?? this.minIncrement,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionSettings &&
          runtimeType == other.runtimeType &&
          bidWindowSeconds == other.bidWindowSeconds &&
          maxActiveNominationsPerTeam == other.maxActiveNominationsPerTeam &&
          minBid == other.minBid &&
          minIncrement == other.minIncrement;

  @override
  int get hashCode =>
      bidWindowSeconds.hashCode ^
      maxActiveNominationsPerTeam.hashCode ^
      minBid.hashCode ^
      minIncrement.hashCode;
}
