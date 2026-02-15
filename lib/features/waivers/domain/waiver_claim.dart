import 'waiver_claim_status.dart';

/// Waiver claim model
class WaiverClaim {
  final int id;
  final int leagueId;
  final int rosterId;
  final int playerId;
  final String playerName;
  final String? playerPosition;
  final String? playerTeam;
  final int? dropPlayerId;
  final String? dropPlayerName;
  final String? dropPlayerPosition;
  final int bidAmount;
  final int? priorityAtClaim;
  /// User-defined priority order for claims within a roster. Lower = higher priority.
  final int claimOrder;
  final WaiverClaimStatus status;
  final int season;
  final int week;
  final String teamName;
  final String username;
  final DateTime? processedAt;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  WaiverClaim({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.playerId,
    required this.playerName,
    this.playerPosition,
    this.playerTeam,
    this.dropPlayerId,
    this.dropPlayerName,
    this.dropPlayerPosition,
    required this.bidAmount,
    this.priorityAtClaim,
    this.claimOrder = 1,
    required this.status,
    required this.season,
    required this.week,
    required this.teamName,
    required this.username,
    this.processedAt,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaiverClaim.fromJson(Map<String, dynamic> json) {
    return WaiverClaim(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      playerName: json['player_name'] as String? ?? '',
      playerPosition: json['player_position'] as String?,
      playerTeam: json['player_team'] as String?,
      dropPlayerId: json['drop_player_id'] as int?,
      dropPlayerName: json['drop_player_name'] as String?,
      dropPlayerPosition: json['drop_player_position'] as String?,
      bidAmount: json['bid_amount'] as int? ?? 0,
      priorityAtClaim: json['priority_at_claim'] as int?,
      claimOrder: json['claim_order'] as int? ?? 1,
      status: WaiverClaimStatus.fromString(json['status'] as String?),
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      teamName: json['team_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())
          : null,
      failureReason: json['failure_reason'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.utc(1970),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.utc(1970),
    );
  }

  WaiverClaim copyWith({
    int? id,
    int? leagueId,
    int? rosterId,
    int? playerId,
    String? playerName,
    String? playerPosition,
    String? playerTeam,
    int? dropPlayerId,
    String? dropPlayerName,
    String? dropPlayerPosition,
    int? bidAmount,
    int? priorityAtClaim,
    int? claimOrder,
    WaiverClaimStatus? status,
    int? season,
    int? week,
    String? teamName,
    String? username,
    DateTime? processedAt,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaiverClaim(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      rosterId: rosterId ?? this.rosterId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerPosition: playerPosition ?? this.playerPosition,
      playerTeam: playerTeam ?? this.playerTeam,
      dropPlayerId: dropPlayerId ?? this.dropPlayerId,
      dropPlayerName: dropPlayerName ?? this.dropPlayerName,
      dropPlayerPosition: dropPlayerPosition ?? this.dropPlayerPosition,
      bidAmount: bidAmount ?? this.bidAmount,
      priorityAtClaim: priorityAtClaim ?? this.priorityAtClaim,
      claimOrder: claimOrder ?? this.claimOrder,
      status: status ?? this.status,
      season: season ?? this.season,
      week: week ?? this.week,
      teamName: teamName ?? this.teamName,
      username: username ?? this.username,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
