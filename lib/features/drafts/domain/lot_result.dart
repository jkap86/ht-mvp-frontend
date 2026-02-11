/// Represents the result of a completed auction lot (won or passed).
class LotResult {
  final int lotId;
  final int playerId;
  final int? winnerRosterId;
  final int? price;
  final bool isPassed;

  const LotResult({
    required this.lotId,
    required this.playerId,
    this.winnerRosterId,
    this.price,
    this.isPassed = false,
  });
}
