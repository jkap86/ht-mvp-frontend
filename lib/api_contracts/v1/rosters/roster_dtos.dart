import '../common/enums.dart';

class RosterPlayerDto {
  final int id;
  final int rosterId;
  final int playerId;
  final AcquiredType acquiredType;
  final DateTime acquiredAt;
  final String? fullName;
  final String? position;
  final String? team;
  final String? status;
  final String? injuryStatus;
  final double? projectedPoints;
  final double? seasonPoints;
  final int? byeWeek;

  const RosterPlayerDto({
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

  factory RosterPlayerDto.fromJson(Map<String, dynamic> json) {
    return RosterPlayerDto(
      id: json['id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      acquiredType: AcquiredType.fromString(json['acquired_type'] as String?),
      acquiredAt: DateTime.tryParse(json['acquired_at']?.toString() ?? '') ?? DateTime.utc(1970),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roster_id': rosterId,
      'player_id': playerId,
      'acquired_type': acquiredType.value,
      'acquired_at': acquiredAt.toIso8601String(),
      'full_name': fullName,
      'position': position,
      'team': team,
      'status': status,
      'injury_status': injuryStatus,
      'projected_points': projectedPoints,
      'season_points': seasonPoints,
      'bye_week': byeWeek,
    };
  }
}

class LineupEntryDto {
  final String slot;
  final List<int> playerIds;

  const LineupEntryDto({required this.slot, required this.playerIds});

  factory LineupEntryDto.fromJson(String slot, List<dynamic> playerIds) {
    return LineupEntryDto(
      slot: slot,
      playerIds: playerIds.cast<int>(),
    );
  }
}

class RosterLineupDto {
  final int id;
  final int rosterId;
  final int season;
  final int week;
  final Map<String, List<int>> lineup;
  final double? totalPoints;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RosterLineupDto({
    required this.id,
    required this.rosterId,
    required this.season,
    required this.week,
    required this.lineup,
    this.totalPoints,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RosterLineupDto.fromJson(Map<String, dynamic> json) {
    final rawLineup = (json['lineup'] as Map<String, dynamic>?) ?? {};
    final lineup = <String, List<int>>{};
    rawLineup.forEach((key, value) {
      if (value is List) lineup[key] = value.cast<int>();
    });
    return RosterLineupDto(
      id: json['id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      lineup: lineup,
      totalPoints: (json['total_points'] as num?)?.toDouble(),
      isLocked: json['is_locked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.utc(1970),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.utc(1970),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roster_id': rosterId,
      'season': season,
      'week': week,
      'lineup': lineup,
      'total_points': totalPoints,
      'is_locked': isLocked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
