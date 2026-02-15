/// Trade vote model representing a league member's vote on a trade
class TradeVote {
  final int id;
  final int tradeId;
  final int rosterId;
  final String vote; // 'approve' or 'veto'
  final String username;
  final String teamName;
  final DateTime createdAt;

  TradeVote({
    required this.id,
    required this.tradeId,
    required this.rosterId,
    required this.vote,
    required this.username,
    required this.teamName,
    required this.createdAt,
  });

  factory TradeVote.fromJson(Map<String, dynamic> json) {
    return TradeVote(
      id: json['id'] as int? ?? 0,
      tradeId: json['trade_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      vote: json['vote'] as String? ?? 'approve',
      username: json['username'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.utc(1970),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'roster_id': rosterId,
      'vote': vote,
      'username': username,
      'team_name': teamName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isApprove => vote == 'approve';
  bool get isVeto => vote == 'veto';
}
