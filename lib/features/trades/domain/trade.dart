import 'trade_status.dart';
import 'trade_item.dart';
import 'trade_vote.dart';

/// Trade model representing a trade proposal between two teams
class Trade {
  final int id;
  final int leagueId;
  final int proposerRosterId;
  final int recipientRosterId;
  final TradeStatus status;
  final int? parentTradeId;
  final DateTime expiresAt;
  final DateTime? reviewStartsAt;
  final DateTime? reviewEndsAt;
  final String? message;
  final int season;
  final int week;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<TradeItem> items;
  final String proposerTeamName;
  final String recipientTeamName;
  final String proposerUsername;
  final String recipientUsername;
  final List<TradeVote> votes;
  final bool canRespond;
  final bool canCancel;
  final bool canVote;

  Trade({
    required this.id,
    required this.leagueId,
    required this.proposerRosterId,
    required this.recipientRosterId,
    required this.status,
    this.parentTradeId,
    required this.expiresAt,
    this.reviewStartsAt,
    this.reviewEndsAt,
    this.message,
    required this.season,
    required this.week,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.items,
    required this.proposerTeamName,
    required this.recipientTeamName,
    required this.proposerUsername,
    required this.recipientUsername,
    this.votes = const [],
    this.canRespond = false,
    this.canCancel = false,
    this.canVote = false,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final votesList = (json['votes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Trade(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      proposerRosterId: json['proposer_roster_id'] as int? ?? 0,
      recipientRosterId: json['recipient_roster_id'] as int? ?? 0,
      status: TradeStatus.fromString(json['status'] as String?),
      parentTradeId: json['parent_trade_id'] as int?,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      reviewStartsAt: json['review_starts_at'] != null
          ? DateTime.tryParse(json['review_starts_at'].toString())
          : null,
      reviewEndsAt: json['review_ends_at'] != null
          ? DateTime.tryParse(json['review_ends_at'].toString())
          : null,
      message: json['message'] as String?,
      season: json['season'] as int? ?? DateTime.now().year,
      week: json['week'] as int? ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      items: itemsList.map((e) => TradeItem.fromJson(e)).toList(),
      proposerTeamName: json['proposer_team_name'] as String? ?? '',
      recipientTeamName: json['recipient_team_name'] as String? ?? '',
      proposerUsername: json['proposer_username'] as String? ?? '',
      recipientUsername: json['recipient_username'] as String? ?? '',
      votes: votesList.map((e) => TradeVote.fromJson(e)).toList(),
      canRespond: json['can_respond'] as bool? ?? false,
      canCancel: json['can_cancel'] as bool? ?? false,
      canVote: json['can_vote'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'proposer_roster_id': proposerRosterId,
      'recipient_roster_id': recipientRosterId,
      'status': status.value,
      'parent_trade_id': parentTradeId,
      'expires_at': expiresAt.toIso8601String(),
      'review_starts_at': reviewStartsAt?.toIso8601String(),
      'review_ends_at': reviewEndsAt?.toIso8601String(),
      'message': message,
      'season': season,
      'week': week,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      'proposer_team_name': proposerTeamName,
      'recipient_team_name': recipientTeamName,
      'proposer_username': proposerUsername,
      'recipient_username': recipientUsername,
      'votes': votes.map((e) => e.toJson()).toList(),
      'can_respond': canRespond,
      'can_cancel': canCancel,
      'can_vote': canVote,
    };
  }

  /// Get players being given by proposer (going to recipient)
  List<TradeItem> get proposerGiving =>
      items.where((item) => item.fromRosterId == proposerRosterId).toList();

  /// Get players being given by recipient (going to proposer)
  List<TradeItem> get recipientGiving =>
      items.where((item) => item.fromRosterId == recipientRosterId).toList();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isInReviewPeriod => status == TradeStatus.inReview && reviewEndsAt != null;

  int get vetoCount => votes.where((v) => v.isVeto).length;
  int get approveCount => votes.where((v) => v.isApprove).length;

  Trade copyWith({
    int? id,
    int? leagueId,
    int? proposerRosterId,
    int? recipientRosterId,
    TradeStatus? status,
    int? parentTradeId,
    DateTime? expiresAt,
    DateTime? reviewStartsAt,
    DateTime? reviewEndsAt,
    String? message,
    int? season,
    int? week,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<TradeItem>? items,
    String? proposerTeamName,
    String? recipientTeamName,
    String? proposerUsername,
    String? recipientUsername,
    List<TradeVote>? votes,
    bool? canRespond,
    bool? canCancel,
    bool? canVote,
  }) {
    return Trade(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      proposerRosterId: proposerRosterId ?? this.proposerRosterId,
      recipientRosterId: recipientRosterId ?? this.recipientRosterId,
      status: status ?? this.status,
      parentTradeId: parentTradeId ?? this.parentTradeId,
      expiresAt: expiresAt ?? this.expiresAt,
      reviewStartsAt: reviewStartsAt ?? this.reviewStartsAt,
      reviewEndsAt: reviewEndsAt ?? this.reviewEndsAt,
      message: message ?? this.message,
      season: season ?? this.season,
      week: week ?? this.week,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      items: items ?? this.items,
      proposerTeamName: proposerTeamName ?? this.proposerTeamName,
      recipientTeamName: recipientTeamName ?? this.recipientTeamName,
      proposerUsername: proposerUsername ?? this.proposerUsername,
      recipientUsername: recipientUsername ?? this.recipientUsername,
      votes: votes ?? this.votes,
      canRespond: canRespond ?? this.canRespond,
      canCancel: canCancel ?? this.canCancel,
      canVote: canVote ?? this.canVote,
    );
  }
}
