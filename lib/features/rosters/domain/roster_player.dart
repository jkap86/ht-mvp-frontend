export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show AcquiredType, TransactionType;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension AcquiredTypeUI on AcquiredType {
  String get displayName => switch (this) {
    AcquiredType.draft => 'Drafted',
    AcquiredType.freeAgent => 'Free Agent',
    AcquiredType.trade => 'Trade',
    AcquiredType.waiver => 'Waivers',
  };
}

/// A player on a roster
class RosterPlayer {
  final int id;
  final int rosterId;
  final int playerId;
  final AcquiredType acquiredType;
  final DateTime acquiredAt;
  // Extended player details (optional)
  final String? fullName;
  final String? position;
  final String? team;
  final String? status;
  final String? injuryStatus;
  // Projection data
  final double? projectedPoints;
  final double? seasonPoints;
  final int? byeWeek;

  RosterPlayer({
    required this.id,
    required this.rosterId,
    required this.playerId,
    required this.acquiredType,
    required this.acquiredAt,
    this.fullName,
    this.position,
    this.team,
    this.status,
    this.injuryStatus,
    this.projectedPoints,
    this.seasonPoints,
    this.byeWeek,
  });

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    return RosterPlayer(
      id: json['id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      acquiredType: AcquiredType.fromString(json['acquired_type'] as String?),
      acquiredAt: DateTime.tryParse(json['acquired_at']?.toString() ?? '') ?? DateTime.now(),
      fullName: json['full_name'] as String?,
      position: json['position'] as String?,
      team: json['team'] as String?,
      status: json['status'] as String?,
      injuryStatus: json['injury_status'] as String?,
      projectedPoints: (json['projected_points'] as num?)?.toDouble(),
      seasonPoints: (json['season_points'] as num?)?.toDouble(),
      byeWeek: json['bye_week'] as int?,
    );
  }
}

/// A roster transaction record
class RosterTransaction {
  final int id;
  final int leagueId;
  final int rosterId;
  final int playerId;
  final TransactionType transactionType;
  final int? relatedTransactionId;
  final int season;
  final int week;
  final DateTime createdAt;
  // Extended details
  final String? playerName;
  final String? teamName;

  RosterTransaction({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.playerId,
    required this.transactionType,
    this.relatedTransactionId,
    required this.season,
    required this.week,
    required this.createdAt,
    this.playerName,
    this.teamName,
  });

  factory RosterTransaction.fromJson(Map<String, dynamic> json) {
    return RosterTransaction(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      transactionType: TransactionType.fromString(json['transaction_type'] as String?),
      relatedTransactionId: json['related_transaction_id'] as int?,
      season: json['season'] as int? ?? DateTime.now().year,
      week: json['week'] as int? ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      playerName: json['player_name'] as String?,
      teamName: json['team_name'] as String?,
    );
  }
}
