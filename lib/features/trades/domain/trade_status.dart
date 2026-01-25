/// Trade status enum matching backend trade_status type
enum TradeStatus {
  pending('pending', 'Pending'),
  countered('countered', 'Countered'),
  accepted('accepted', 'Accepted'),
  inReview('in_review', 'In Review'),
  completed('completed', 'Completed'),
  rejected('rejected', 'Rejected'),
  cancelled('cancelled', 'Cancelled'),
  expired('expired', 'Expired'),
  vetoed('vetoed', 'Vetoed');

  final String value;
  final String label;

  const TradeStatus(this.value, this.label);

  static TradeStatus fromString(String? value) {
    return TradeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TradeStatus.pending,
    );
  }

  /// Whether the trade is still pending a response
  bool get isPending =>
      this == TradeStatus.pending || this == TradeStatus.countered;

  /// Whether the trade is still active (not finalized)
  bool get isActive =>
      isPending ||
      this == TradeStatus.accepted ||
      this == TradeStatus.inReview;

  /// Whether the trade has reached a final state
  bool get isFinal =>
      this == TradeStatus.completed ||
      this == TradeStatus.rejected ||
      this == TradeStatus.cancelled ||
      this == TradeStatus.expired ||
      this == TradeStatus.vetoed;
}
