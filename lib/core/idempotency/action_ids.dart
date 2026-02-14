import '../utils/stable_hash.dart';

/// Deterministic action ID builders for idempotency.
///
/// Each builder produces a stable string that uniquely identifies a logical
/// user action. These are used as keys in [ActionIdempotencyNotifier] to
/// map actions to their UUID idempotency keys.
class ActionIds {
  ActionIds._();

  static String draftPick(int draftId, int rosterId, int pickNumber) =>
      'draft.pick:$draftId:$rosterId:$pickNumber';

  static String auctionNominate(
          int draftId, int rosterId, int nominationNumber) =>
      'auction.nominate:$draftId:$rosterId:$nominationNumber';

  static String auctionMaxBid(int draftId, int rosterId, int playerId) =>
      'auction.maxBid:$draftId:$rosterId:$playerId';

  static String auctionBid(int lotId, int rosterId, int amount) =>
      'auction.bid:$lotId:$rosterId:$amount';

  static String waiverSubmit(
    int leagueId,
    int rosterId,
    int week,
    Map<String, dynamic> payload,
  ) =>
      'waiver.submit:$leagueId:$rosterId:$week:${stablePayloadHash(payload)}';

  static String tradePropose(
    int leagueId,
    int fromRosterId,
    Map<String, dynamic> payload,
  ) =>
      'trade.propose:$leagueId:$fromRosterId:${stablePayloadHash(payload)}';

  static String tradeCounter(
    int tradeId,
    int fromRosterId,
    Map<String, dynamic> payload,
  ) =>
      'trade.counter:$tradeId:$fromRosterId:${stablePayloadHash(payload)}';

  static String tradeAction(String action, int tradeId, int rosterId) =>
      'trade.$action:$tradeId:$rosterId';

  static String commishSave(int leagueId, Map<String, dynamic> payload) =>
      'commish.save:$leagueId:${stablePayloadHash(payload)}';

  static String faAddDrop(
    int leagueId,
    int rosterId,
    int addPlayerId,
    int? dropPlayerId,
  ) =>
      'fa.addDrop:$leagueId:$rosterId:$addPlayerId:${dropPlayerId ?? 0}';
}
