class TradeProposedPayload {
  final Map<String, dynamic> trade;

  const TradeProposedPayload({required this.trade});

  factory TradeProposedPayload.fromJson(Map<String, dynamic> json) {
    return TradeProposedPayload(trade: json);
  }

  int get tradeId => trade['id'] as int? ?? 0;
  String get status => trade['status'] as String? ?? '';
}

class TradeStatusPayload {
  final Map<String, dynamic> trade;

  const TradeStatusPayload({required this.trade});

  factory TradeStatusPayload.fromJson(Map<String, dynamic> json) {
    return TradeStatusPayload(trade: json);
  }

  int get tradeId => trade['id'] as int? ?? 0;
  String get status => trade['status'] as String? ?? '';
}

class TradeCounteredPayload {
  final int originalTradeId;
  final int counterTradeId;
  final Map<String, dynamic> counterTrade;

  const TradeCounteredPayload({
    required this.originalTradeId,
    required this.counterTradeId,
    required this.counterTrade,
  });

  factory TradeCounteredPayload.fromJson(Map<String, dynamic> json) {
    return TradeCounteredPayload(
      originalTradeId: json['originalTradeId'] as int? ?? 0,
      counterTradeId: json['counterTradeId'] as int? ?? 0,
      counterTrade: json['counterTrade'] as Map<String, dynamic>? ?? {},
    );
  }
}

class TradeVoteCastPayload {
  final int tradeId;
  final int rosterId;
  final String vote;
  final String username;
  final String teamName;

  const TradeVoteCastPayload({
    required this.tradeId,
    required this.rosterId,
    required this.vote,
    required this.username,
    required this.teamName,
  });

  factory TradeVoteCastPayload.fromJson(Map<String, dynamic> json) {
    return TradeVoteCastPayload(
      tradeId: json['tradeId'] as int? ?? 0,
      rosterId: json['rosterId'] as int? ?? 0,
      vote: json['vote'] as String? ?? '',
      username: json['username'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
    );
  }
}

class TradeFailedPayload {
  final int tradeId;
  final String reason;

  const TradeFailedPayload({required this.tradeId, required this.reason});

  factory TradeFailedPayload.fromJson(Map<String, dynamic> json) {
    return TradeFailedPayload(
      tradeId: json['tradeId'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
