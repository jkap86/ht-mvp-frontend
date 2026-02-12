/// Draft type enumeration matching backend values
enum DraftType {
  snake('snake', 'Snake', 'Pick order reverses each round'),
  linear('linear', 'Linear', 'Same pick order every round'),
  auction('auction', 'Auction', 'Bid on players with a budget'),
  matchups('matchups', 'Matchups', 'Draft your schedule strategically');

  final String value;
  final String label;
  final String description;

  const DraftType(this.value, this.label, this.description);

  /// Parse draft type from API string value
  static DraftType fromString(String? value) {
    return DraftType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DraftType.snake,
    );
  }

  /// Check if this is an auction draft
  bool get isAuction => this == DraftType.auction;

  /// Check if this is a matchups draft
  bool get isMatchups => this == DraftType.matchups;
}
