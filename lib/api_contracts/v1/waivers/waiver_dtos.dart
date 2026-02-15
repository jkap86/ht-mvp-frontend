import '../common/enums.dart';
import '../../../core/utils/date_sentinel.dart';

class WaiverClaimDto {
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

  const WaiverClaimDto({
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

  factory WaiverClaimDto.fromJson(Map<String, dynamic> json) {
    return WaiverClaimDto(
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
      processedAt: json['processed_at'] != null ? DateTime.tryParse(json['processed_at'].toString()) : null,
      failureReason: json['failure_reason'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? epochUtc(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? epochUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'roster_id': rosterId,
      'player_id': playerId,
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'drop_player_id': dropPlayerId,
      'drop_player_name': dropPlayerName,
      'drop_player_position': dropPlayerPosition,
      'bid_amount': bidAmount,
      'priority_at_claim': priorityAtClaim,
      'claim_order': claimOrder,
      'status': status.value,
      'season': season,
      'week': week,
      'team_name': teamName,
      'username': username,
      'processed_at': processedAt?.toIso8601String(),
      'failure_reason': failureReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WaiverPriorityDto {
  final int id;
  final int leagueId;
  final int rosterId;
  final int season;
  final int priority;
  final String teamName;
  final String username;
  final DateTime updatedAt;

  const WaiverPriorityDto({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.season,
    required this.priority,
    required this.teamName,
    required this.username,
    required this.updatedAt,
  });

  factory WaiverPriorityDto.fromJson(Map<String, dynamic> json) {
    return WaiverPriorityDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      priority: json['priority'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? epochUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'roster_id': rosterId,
      'season': season,
      'priority': priority,
      'team_name': teamName,
      'username': username,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FaabBudgetDto {
  final int id;
  final int leagueId;
  final int rosterId;
  final int season;
  final int initialBudget;
  final int remainingBudget;
  final String teamName;
  final String username;
  final DateTime updatedAt;

  const FaabBudgetDto({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.season,
    required this.initialBudget,
    required this.remainingBudget,
    required this.teamName,
    required this.username,
    required this.updatedAt,
  });

  factory FaabBudgetDto.fromJson(Map<String, dynamic> json) {
    return FaabBudgetDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      initialBudget: json['initial_budget'] as int? ?? 100,
      remainingBudget: json['remaining_budget'] as int? ?? 100,
      teamName: json['team_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? epochUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'roster_id': rosterId,
      'season': season,
      'initial_budget': initialBudget,
      'remaining_budget': remainingBudget,
      'team_name': teamName,
      'username': username,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
