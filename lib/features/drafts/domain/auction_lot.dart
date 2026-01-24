/// Represents an auction lot in a slow auction draft.
class AuctionLot {
  final int id;
  final int draftId;
  final int playerId;
  final int nominatorRosterId;
  final int currentBid;
  final int? currentBidderRosterId;
  final int bidCount;
  final DateTime bidDeadline;
  final String status; // active, won, passed
  final int? winningRosterId;
  final int? winningBid;

  AuctionLot({
    required this.id,
    required this.draftId,
    required this.playerId,
    required this.nominatorRosterId,
    required this.currentBid,
    this.currentBidderRosterId,
    required this.bidCount,
    required this.bidDeadline,
    required this.status,
    this.winningRosterId,
    this.winningBid,
  });

  factory AuctionLot.fromJson(Map<String, dynamic> json) {
    return AuctionLot(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? json['playerId'] as int? ?? 0,
      nominatorRosterId: json['nominator_roster_id'] as int? ?? json['nominatorRosterId'] as int? ?? 0,
      currentBid: json['current_bid'] as int? ?? json['currentBid'] as int? ?? 1,
      currentBidderRosterId: json['current_bidder_roster_id'] as int? ?? json['currentBidderRosterId'] as int?,
      bidCount: json['bid_count'] as int? ?? json['bidCount'] as int? ?? 0,
      bidDeadline: DateTime.tryParse(json['bid_deadline'] as String? ?? json['bidDeadline'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'active',
      winningRosterId: json['winning_roster_id'] as int? ?? json['winningRosterId'] as int?,
      winningBid: json['winning_bid'] as int? ?? json['winningBid'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'draft_id': draftId,
      'player_id': playerId,
      'nominator_roster_id': nominatorRosterId,
      'current_bid': currentBid,
      'current_bidder_roster_id': currentBidderRosterId,
      'bid_count': bidCount,
      'bid_deadline': bidDeadline.toIso8601String(),
      'status': status,
      'winning_roster_id': winningRosterId,
      'winning_bid': winningBid,
    };
  }

  AuctionLot copyWith({
    int? id,
    int? draftId,
    int? playerId,
    int? nominatorRosterId,
    int? currentBid,
    int? currentBidderRosterId,
    int? bidCount,
    DateTime? bidDeadline,
    String? status,
    int? winningRosterId,
    int? winningBid,
  }) {
    return AuctionLot(
      id: id ?? this.id,
      draftId: draftId ?? this.draftId,
      playerId: playerId ?? this.playerId,
      nominatorRosterId: nominatorRosterId ?? this.nominatorRosterId,
      currentBid: currentBid ?? this.currentBid,
      currentBidderRosterId: currentBidderRosterId ?? this.currentBidderRosterId,
      bidCount: bidCount ?? this.bidCount,
      bidDeadline: bidDeadline ?? this.bidDeadline,
      status: status ?? this.status,
      winningRosterId: winningRosterId ?? this.winningRosterId,
      winningBid: winningBid ?? this.winningBid,
    );
  }

  @override
  String toString() {
    return 'AuctionLot(id: $id, playerId: $playerId, currentBid: $currentBid, status: $status)';
  }
}
