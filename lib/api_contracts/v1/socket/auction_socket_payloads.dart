class AuctionLotPayload {
  final Map<String, dynamic> lot;
  final DateTime? serverTime;

  const AuctionLotPayload({required this.lot, this.serverTime});

  factory AuctionLotPayload.fromJson(Map<String, dynamic> json) {
    return AuctionLotPayload(
      lot: json['lot'] as Map<String, dynamic>? ?? json,
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'].toString())
          : null,
    );
  }

  int get lotId => lot['id'] as int? ?? 0;
  int get playerId => lot['player_id'] as int? ?? 0;
  int get currentBid => lot['current_bid'] as int? ?? 0;
  int? get currentBidderRosterId => lot['current_bidder_roster_id'] as int?;
  int get bidCount => lot['bid_count'] as int? ?? 0;
  String? get status => lot['status'] as String?;
}

class AuctionLotUpdatedPayload {
  final Map<String, dynamic> lot;
  final int? newBidderRosterId;
  final DateTime? serverTime;

  const AuctionLotUpdatedPayload({
    required this.lot,
    this.newBidderRosterId,
    this.serverTime,
  });

  factory AuctionLotUpdatedPayload.fromJson(Map<String, dynamic> json) {
    return AuctionLotUpdatedPayload(
      lot: json['lot'] as Map<String, dynamic>? ?? {},
      newBidderRosterId: json['newBidderRosterId'] as int?,
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'].toString())
          : null,
    );
  }
}

class AuctionLotWonPayload {
  final int lotId;
  final int playerId;
  final int winnerRosterId;
  final int price;

  const AuctionLotWonPayload({
    required this.lotId,
    required this.playerId,
    required this.winnerRosterId,
    required this.price,
  });

  factory AuctionLotWonPayload.fromJson(Map<String, dynamic> json) {
    return AuctionLotWonPayload(
      lotId: json['lotId'] as int? ?? 0,
      playerId: json['playerId'] as int? ?? 0,
      winnerRosterId: json['winnerRosterId'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
    );
  }
}

class AuctionLotPassedPayload {
  final int lotId;
  final int playerId;

  const AuctionLotPassedPayload({required this.lotId, required this.playerId});

  factory AuctionLotPassedPayload.fromJson(Map<String, dynamic> json) {
    return AuctionLotPassedPayload(
      lotId: json['lotId'] as int? ?? 0,
      playerId: json['playerId'] as int? ?? 0,
    );
  }
}

class AuctionOutbidPayload {
  final int lotId;
  final int playerId;
  final int newCurrentBid;
  final int outbiddedByRosterId;

  const AuctionOutbidPayload({
    required this.lotId,
    required this.playerId,
    required this.newCurrentBid,
    required this.outbiddedByRosterId,
  });

  factory AuctionOutbidPayload.fromJson(Map<String, dynamic> json) {
    return AuctionOutbidPayload(
      lotId: json['lotId'] as int? ?? 0,
      playerId: json['playerId'] as int? ?? 0,
      newCurrentBid: json['newCurrentBid'] as int? ?? 0,
      outbiddedByRosterId: json['outbiddedByRosterId'] as int? ?? 0,
    );
  }
}

class AuctionNominatorPayload {
  final int nominatorRosterId;
  final int nominationNumber;
  final DateTime? nominationDeadline;

  const AuctionNominatorPayload({
    required this.nominatorRosterId,
    required this.nominationNumber,
    this.nominationDeadline,
  });

  factory AuctionNominatorPayload.fromJson(Map<String, dynamic> json) {
    return AuctionNominatorPayload(
      nominatorRosterId: json['nominatorRosterId'] as int? ?? 0,
      nominationNumber: json['nominationNumber'] as int? ?? 0,
      nominationDeadline: json['nominationDeadline'] != null
          ? DateTime.tryParse(json['nominationDeadline'].toString())
          : null,
    );
  }
}

class AuctionErrorPayload {
  final String action;
  final String message;

  const AuctionErrorPayload({required this.action, required this.message});

  factory AuctionErrorPayload.fromJson(Map<String, dynamic> json) {
    return AuctionErrorPayload(
      action: json['action'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
