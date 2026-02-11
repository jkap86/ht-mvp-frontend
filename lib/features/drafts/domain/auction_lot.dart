import 'package:flutter/foundation.dart';

DateTime _parseBidDeadline(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed;
  if (kDebugMode) debugPrint('AuctionLot: failed to parse bidDeadline: "$raw"');
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

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
  final int? myMaxBid; // User's max bid on this lot (null if no bid placed)

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
    this.myMaxBid,
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
      bidDeadline: _parseBidDeadline(json['bid_deadline'] as String? ?? json['bidDeadline'] as String? ?? ''),
      status: json['status'] as String? ?? 'active',
      winningRosterId: json['winning_roster_id'] as int? ?? json['winningRosterId'] as int?,
      winningBid: json['winning_bid'] as int? ?? json['winningBid'] as int?,
      myMaxBid: json['my_max_bid'] as int? ?? json['myMaxBid'] as int?,
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
      if (myMaxBid != null) 'my_max_bid': myMaxBid,
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
    int? myMaxBid,
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
      myMaxBid: myMaxBid ?? this.myMaxBid,
    );
  }

  @override
  String toString() {
    return 'AuctionLot(id: $id, playerId: $playerId, currentBid: $currentBid, status: $status)';
  }
}
