class ProposeTradeRequest {
  final int leagueId;
  final int recipientRosterId;
  final List<TradeItemRequest> items;
  final String? message;

  const ProposeTradeRequest({
    required this.leagueId,
    required this.recipientRosterId,
    required this.items,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'league_id': leagueId,
      'recipient_roster_id': recipientRosterId,
      'items': items.map((i) => i.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

class TradeItemRequest {
  final String itemType;
  final int fromRosterId;
  final int toRosterId;
  final int? playerId;
  final int? draftPickAssetId;

  const TradeItemRequest({
    required this.itemType,
    required this.fromRosterId,
    required this.toRosterId,
    this.playerId,
    this.draftPickAssetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_type': itemType,
      'from_roster_id': fromRosterId,
      'to_roster_id': toRosterId,
      if (playerId != null) 'player_id': playerId,
      if (draftPickAssetId != null) 'draft_pick_asset_id': draftPickAssetId,
    };
  }
}

class CounterTradeRequest {
  final int tradeId;
  final List<TradeItemRequest> items;
  final String? message;

  const CounterTradeRequest({
    required this.tradeId,
    required this.items,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'trade_id': tradeId,
      'items': items.map((i) => i.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

class VoteTradeRequest {
  final int tradeId;
  final String vote;

  const VoteTradeRequest({required this.tradeId, required this.vote});

  Map<String, dynamic> toJson() => {'trade_id': tradeId, 'vote': vote};
}
