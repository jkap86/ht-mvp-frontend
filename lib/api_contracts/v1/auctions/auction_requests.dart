class PlaceBidRequest {
  final int draftId;
  final int lotId;
  final int amount;

  const PlaceBidRequest({required this.draftId, required this.lotId, required this.amount});

  Map<String, dynamic> toJson() => {'draftId': draftId, 'lotId': lotId, 'amount': amount};
}

class NominateRequest {
  final int draftId;
  final int playerId;
  final int? initialBid;

  const NominateRequest({required this.draftId, required this.playerId, this.initialBid});

  Map<String, dynamic> toJson() {
    return {
      'draftId': draftId,
      'playerId': playerId,
      if (initialBid != null) 'initialBid': initialBid,
    };
  }
}

class SetMaxBidRequest {
  final int draftId;
  final int lotId;
  final int maxBid;

  const SetMaxBidRequest({required this.draftId, required this.lotId, required this.maxBid});

  Map<String, dynamic> toJson() => {'draftId': draftId, 'lotId': lotId, 'maxBid': maxBid};
}
