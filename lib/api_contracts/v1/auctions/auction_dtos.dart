class AuctionLotDto {
  final int id;
  final int draftId;
  final int playerId;
  final int nominatorRosterId;
  final int currentBid;
  final int? currentBidderRosterId;
  final int bidCount;
  final DateTime bidDeadline;
  final String status;
  final int? winningRosterId;
  final int? winningBid;
  final int? myMaxBid;

  const AuctionLotDto({
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

  factory AuctionLotDto.fromJson(Map<String, dynamic> json) {
    return AuctionLotDto(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? json['playerId'] as int? ?? 0,
      nominatorRosterId: json['nominator_roster_id'] as int? ?? json['nominatorRosterId'] as int? ?? 0,
      currentBid: json['current_bid'] as int? ?? json['currentBid'] as int? ?? 1,
      currentBidderRosterId: json['current_bidder_roster_id'] as int? ?? json['currentBidderRosterId'] as int?,
      bidCount: json['bid_count'] as int? ?? json['bidCount'] as int? ?? 0,
      bidDeadline: DateTime.tryParse(json['bid_deadline'] as String? ?? json['bidDeadline'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
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
}

class AuctionStateDto {
  final String auctionMode;
  final AuctionLotDto? activeLot;
  final List<AuctionLotDto> activeLots;
  final int? currentNominatorRosterId;
  final int? nominationNumber;
  final DateTime? nominationDeadline;
  final AuctionSettingsDto? settings;
  final List<AuctionBudgetDto> budgets;
  final int? dailyNominationsRemaining;
  final int? dailyNominationLimit;
  final bool globalCapReached;

  const AuctionStateDto({
    required this.auctionMode,
    this.activeLot,
    required this.activeLots,
    this.currentNominatorRosterId,
    this.nominationNumber,
    this.nominationDeadline,
    this.settings,
    required this.budgets,
    this.dailyNominationsRemaining,
    this.dailyNominationLimit,
    this.globalCapReached = false,
  });

  factory AuctionStateDto.fromJson(Map<String, dynamic> json) {
    final activeLotJson = json['active_lot'] as Map<String, dynamic>?;
    final activeLotsJson = json['active_lots'] as List<dynamic>? ?? [];
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    final budgetsJson = json['budgets'] as List<dynamic>? ?? [];
    final nominationStatsJson = json['nomination_stats'] as Map<String, dynamic>?;

    return AuctionStateDto(
      auctionMode: json['auction_mode'] as String? ?? 'slow',
      activeLot: activeLotJson != null ? AuctionLotDto.fromJson(activeLotJson) : null,
      activeLots: activeLotsJson.map((lot) => AuctionLotDto.fromJson(lot as Map<String, dynamic>)).toList(),
      currentNominatorRosterId: json['current_nominator_roster_id'] as int?,
      nominationNumber: json['nomination_number'] as int?,
      nominationDeadline: json['nomination_deadline'] != null ? DateTime.tryParse(json['nomination_deadline'].toString()) : null,
      settings: settingsJson != null ? AuctionSettingsDto.fromJson(settingsJson) : null,
      budgets: budgetsJson.map((b) => AuctionBudgetDto.fromJson(b as Map<String, dynamic>)).toList(),
      dailyNominationsRemaining: nominationStatsJson?['daily_nominations_remaining'] as int?,
      dailyNominationLimit: nominationStatsJson?['daily_nomination_limit'] as int?,
      globalCapReached: nominationStatsJson?['global_cap_reached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auction_mode': auctionMode,
      'active_lot': activeLot?.toJson(),
      'active_lots': activeLots.map((l) => l.toJson()).toList(),
      'current_nominator_roster_id': currentNominatorRosterId,
      'nomination_number': nominationNumber,
      'nomination_deadline': nominationDeadline?.toIso8601String(),
      'settings': settings?.toJson(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
    };
  }
}

class AuctionBudgetDto {
  final int rosterId;
  final String username;
  final int totalBudget;
  final int spent;
  final int leadingCommitment;
  final int available;
  final int wonCount;

  const AuctionBudgetDto({
    required this.rosterId,
    required this.username,
    required this.totalBudget,
    required this.spent,
    required this.leadingCommitment,
    required this.available,
    required this.wonCount,
  });

  factory AuctionBudgetDto.fromJson(Map<String, dynamic> json) {
    return AuctionBudgetDto(
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unknown',
      totalBudget: json['total_budget'] as int? ?? json['totalBudget'] as int? ?? 200,
      spent: json['spent'] as int? ?? 0,
      leadingCommitment: json['leading_commitment'] as int? ?? json['leadingCommitment'] as int? ?? 0,
      available: json['available'] as int? ?? 200,
      wonCount: json['won_count'] as int? ?? json['wonCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roster_id': rosterId,
      'username': username,
      'total_budget': totalBudget,
      'spent': spent,
      'leading_commitment': leadingCommitment,
      'available': available,
      'won_count': wonCount,
    };
  }
}

class AuctionSettingsDto {
  final String auctionMode;
  final int bidWindowSeconds;
  final int maxActiveNominationsPerTeam;
  final int nominationSeconds;
  final int resetOnBidSeconds;
  final int minBid;
  final int minIncrement;

  const AuctionSettingsDto({
    required this.auctionMode,
    required this.bidWindowSeconds,
    required this.maxActiveNominationsPerTeam,
    required this.nominationSeconds,
    required this.resetOnBidSeconds,
    required this.minBid,
    required this.minIncrement,
  });

  factory AuctionSettingsDto.fromJson(Map<String, dynamic> json) {
    return AuctionSettingsDto(
      auctionMode: json['auctionMode'] as String? ?? json['auction_mode'] as String? ?? 'slow',
      bidWindowSeconds: json['bidWindowSeconds'] as int? ?? json['bid_window_seconds'] as int? ?? 43200,
      maxActiveNominationsPerTeam: json['maxActiveNominationsPerTeam'] as int? ?? json['max_active_nominations_per_team'] as int? ?? 2,
      nominationSeconds: json['nominationSeconds'] as int? ?? json['nomination_seconds'] as int? ?? 45,
      resetOnBidSeconds: json['resetOnBidSeconds'] as int? ?? json['reset_on_bid_seconds'] as int? ?? 10,
      minBid: json['minBid'] as int? ?? json['min_bid'] as int? ?? 1,
      minIncrement: json['minIncrement'] as int? ?? json['min_increment'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auction_mode': auctionMode,
      'bid_window_seconds': bidWindowSeconds,
      'max_active_nominations_per_team': maxActiveNominationsPerTeam,
      'nomination_seconds': nominationSeconds,
      'reset_on_bid_seconds': resetOnBidSeconds,
      'min_bid': minBid,
      'min_increment': minIncrement,
    };
  }
}

class BidHistoryEntryDto {
  final int id;
  final int lotId;
  final int rosterId;
  final String? username;
  final int bidAmount;
  final bool isProxy;
  final DateTime createdAt;

  const BidHistoryEntryDto({
    required this.id,
    required this.lotId,
    required this.rosterId,
    this.username,
    required this.bidAmount,
    required this.isProxy,
    required this.createdAt,
  });

  factory BidHistoryEntryDto.fromJson(Map<String, dynamic> json) {
    return BidHistoryEntryDto(
      id: json['id'] as int? ?? 0,
      lotId: json['lot_id'] as int? ?? json['lotId'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      username: json['username'] as String?,
      bidAmount: json['bid_amount'] as int? ?? json['bidAmount'] as int? ?? 0,
      isProxy: json['is_proxy'] as bool? ?? json['isProxy'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lot_id': lotId,
      'roster_id': rosterId,
      'username': username,
      'bid_amount': bidAmount,
      'is_proxy': isProxy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
