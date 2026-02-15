import '../common/enums.dart';
import '../../../core/utils/date_sentinel.dart';

class TradeDto {
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
  final List<TradeItemDto> items;
  final String proposerTeamName;
  final String recipientTeamName;
  final String proposerUsername;
  final String recipientUsername;
  final List<TradeVoteDto> votes;
  final bool canRespond;
  final bool canCancel;
  final bool canVote;

  const TradeDto({
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

  factory TradeDto.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final votesList = (json['votes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return TradeDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      proposerRosterId: json['proposer_roster_id'] as int? ?? 0,
      recipientRosterId: json['recipient_roster_id'] as int? ?? 0,
      status: TradeStatus.fromString(json['status'] as String?),
      parentTradeId: json['parent_trade_id'] as int?,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? epochUtc(),
      reviewStartsAt: json['review_starts_at'] != null ? DateTime.tryParse(json['review_starts_at'].toString()) : null,
      reviewEndsAt: json['review_ends_at'] != null ? DateTime.tryParse(json['review_ends_at'].toString()) : null,
      message: json['message'] as String?,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? epochUtc(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? epochUtc(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      items: itemsList.map((e) => TradeItemDto.fromJson(e)).toList(),
      proposerTeamName: json['proposer_team_name'] as String? ?? '',
      recipientTeamName: json['recipient_team_name'] as String? ?? '',
      proposerUsername: json['proposer_username'] as String? ?? '',
      recipientUsername: json['recipient_username'] as String? ?? '',
      votes: votesList.map((e) => TradeVoteDto.fromJson(e)).toList(),
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
}

class TradeItemDto {
  final int id;
  final int tradeId;
  final int fromRosterId;
  final int toRosterId;
  final TradeItemType itemType;
  final int playerId;
  final String playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String fullName;
  final String? position;
  final String? team;
  final String? status;
  final int? draftPickAssetId;
  final int? pickSeason;
  final int? pickRound;
  final String? pickOriginalTeam;
  final int? pickOriginalRosterId;

  const TradeItemDto({
    required this.id,
    required this.tradeId,
    required this.fromRosterId,
    required this.toRosterId,
    this.itemType = TradeItemType.player,
    this.playerId = 0,
    this.playerName = '',
    this.playerPosition,
    this.playerTeam,
    this.fullName = '',
    this.position,
    this.team,
    this.status,
    this.draftPickAssetId,
    this.pickSeason,
    this.pickRound,
    this.pickOriginalTeam,
    this.pickOriginalRosterId,
  });

  factory TradeItemDto.fromJson(Map<String, dynamic> json) {
    return TradeItemDto(
      id: json['id'] as int? ?? 0,
      tradeId: json['trade_id'] as int? ?? 0,
      fromRosterId: json['from_roster_id'] as int? ?? 0,
      toRosterId: json['to_roster_id'] as int? ?? 0,
      itemType: TradeItemType.fromString(json['item_type'] as String?),
      playerId: json['player_id'] as int? ?? 0,
      playerName: json['player_name'] as String? ?? '',
      playerPosition: json['player_position'] as String?,
      playerTeam: json['player_team'] as String?,
      fullName: json['full_name'] as String? ?? json['player_name'] as String? ?? '',
      position: json['position'] as String?,
      team: json['team'] as String?,
      status: json['status'] as String?,
      draftPickAssetId: json['draft_pick_asset_id'] as int? ?? json['draftPickAssetId'] as int?,
      pickSeason: json['pick_season'] as int? ?? json['pickSeason'] as int?,
      pickRound: json['pick_round'] as int? ?? json['pickRound'] as int?,
      pickOriginalTeam: json['pick_original_team'] as String? ?? json['pickOriginalTeam'] as String?,
      pickOriginalRosterId: json['pick_original_roster_id'] as int? ?? json['pickOriginalRosterId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'from_roster_id': fromRosterId,
      'to_roster_id': toRosterId,
      'item_type': itemType.value,
      'player_id': playerId,
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'full_name': fullName,
      'position': position,
      'team': team,
      'status': status,
      'draft_pick_asset_id': draftPickAssetId,
      'pick_season': pickSeason,
      'pick_round': pickRound,
      'pick_original_team': pickOriginalTeam,
      'pick_original_roster_id': pickOriginalRosterId,
    };
  }
}

class TradeVoteDto {
  final int id;
  final int tradeId;
  final int rosterId;
  final String vote;
  final String username;
  final String teamName;
  final DateTime createdAt;

  const TradeVoteDto({
    required this.id,
    required this.tradeId,
    required this.rosterId,
    required this.vote,
    required this.username,
    required this.teamName,
    required this.createdAt,
  });

  factory TradeVoteDto.fromJson(Map<String, dynamic> json) {
    return TradeVoteDto(
      id: json['id'] as int? ?? 0,
      tradeId: json['trade_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      vote: json['vote'] as String? ?? 'approve',
      username: json['username'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? epochUtc(),
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
}
