class MatchupDto {
  final int id;
  final int leagueId;
  final int season;
  final int week;
  final int roster1Id;
  final int roster2Id;
  final double? roster1Points;
  final double? roster2Points;
  final bool isPlayoff;
  final bool isFinal;
  final DateTime createdAt;
  final String? roster1TeamName;
  final String? roster2TeamName;
  final double? roster1PointsActual;
  final double? roster1PointsProjected;
  final double? roster2PointsActual;
  final double? roster2PointsProjected;

  const MatchupDto({
    required this.id,
    required this.leagueId,
    required this.season,
    required this.week,
    required this.roster1Id,
    required this.roster2Id,
    this.roster1Points,
    this.roster2Points,
    this.isPlayoff = false,
    this.isFinal = false,
    required this.createdAt,
    this.roster1TeamName,
    this.roster2TeamName,
    this.roster1PointsActual,
    this.roster1PointsProjected,
    this.roster2PointsActual,
    this.roster2PointsProjected,
  });

  factory MatchupDto.fromJson(Map<String, dynamic> json) {
    return MatchupDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      roster1Id: json['roster1_id'] as int? ?? 0,
      roster2Id: json['roster2_id'] as int? ?? 0,
      roster1Points: (json['roster1_points'] as num?)?.toDouble(),
      roster2Points: (json['roster2_points'] as num?)?.toDouble(),
      isPlayoff: json['is_playoff'] as bool? ?? false,
      isFinal: json['is_final'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.utc(1970),
      roster1TeamName: json['roster1_team_name'] as String?,
      roster2TeamName: json['roster2_team_name'] as String?,
      roster1PointsActual: (json['roster1_points_actual'] as num?)?.toDouble(),
      roster1PointsProjected: (json['roster1_points_projected'] as num?)?.toDouble(),
      roster2PointsActual: (json['roster2_points_actual'] as num?)?.toDouble(),
      roster2PointsProjected: (json['roster2_points_projected'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'season': season,
      'week': week,
      'roster1_id': roster1Id,
      'roster2_id': roster2Id,
      'roster1_points': roster1Points,
      'roster2_points': roster2Points,
      'is_playoff': isPlayoff,
      'is_final': isFinal,
      'created_at': createdAt.toIso8601String(),
      'roster1_team_name': roster1TeamName,
      'roster2_team_name': roster2TeamName,
    };
  }
}

class MatchupDetailDto {
  final MatchupDto matchup;
  final MatchupTeamDto team1;
  final MatchupTeamDto team2;

  const MatchupDetailDto({required this.matchup, required this.team1, required this.team2});

  factory MatchupDetailDto.fromJson(Map<String, dynamic> json) {
    final matchupData = json['matchup'] as Map<String, dynamic>?;
    return MatchupDetailDto(
      matchup: MatchupDto.fromJson(matchupData ?? json),
      team1: MatchupTeamDto.fromJson(json['team1'] as Map<String, dynamic>? ?? {}),
      team2: MatchupTeamDto.fromJson(json['team2'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MatchupTeamDto {
  final int rosterId;
  final String teamName;
  final double totalPoints;
  final List<MatchupPlayerScoreDto> players;

  const MatchupTeamDto({required this.rosterId, required this.teamName, required this.totalPoints, required this.players});

  factory MatchupTeamDto.fromJson(Map<String, dynamic> json) {
    return MatchupTeamDto(
      rosterId: json['roster_id'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? 'Unknown',
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      players: ((json['players'] as List?) ?? []).map((p) => MatchupPlayerScoreDto.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class MatchupPlayerScoreDto {
  final int playerId;
  final String fullName;
  final String? position;
  final String? team;
  final String slot;
  final double points;
  final bool isStarter;
  final double? projectedPoints;
  final String? gameStatus;
  final double? remainingProjected;

  const MatchupPlayerScoreDto({
    required this.playerId,
    required this.fullName,
    this.position,
    this.team,
    required this.slot,
    required this.points,
    required this.isStarter,
    this.projectedPoints,
    this.gameStatus,
    this.remainingProjected,
  });

  factory MatchupPlayerScoreDto.fromJson(Map<String, dynamic> json) {
    return MatchupPlayerScoreDto(
      playerId: json['player_id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? 'Unknown',
      position: json['position'] as String?,
      team: json['team'] as String?,
      slot: json['slot'] as String? ?? 'BN',
      points: (json['points'] as num?)?.toDouble() ?? 0,
      isStarter: json['is_starter'] as bool? ?? false,
      projectedPoints: (json['projected_points'] as num?)?.toDouble(),
      gameStatus: json['game_status'] as String?,
      remainingProjected: (json['remaining_projected'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'full_name': fullName,
      'position': position,
      'team': team,
      'slot': slot,
      'points': points,
      'is_starter': isStarter,
      'projected_points': projectedPoints,
      'game_status': gameStatus,
      'remaining_projected': remainingProjected,
    };
  }
}
