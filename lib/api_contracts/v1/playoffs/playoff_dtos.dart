import '../common/enums.dart';

class PlayoffBracketDto {
  final int id;
  final int leagueId;
  final int season;
  final int playoffTeams;
  final int totalRounds;
  final int startWeek;
  final int championshipWeek;
  final PlayoffStatus status;
  final int? championRosterId;
  final List<int>? weeksByRound;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlayoffBracketDto({
    required this.id,
    required this.leagueId,
    required this.season,
    required this.playoffTeams,
    required this.totalRounds,
    required this.startWeek,
    required this.championshipWeek,
    required this.status,
    this.championRosterId,
    this.weeksByRound,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayoffBracketDto.fromJson(Map<String, dynamic> json) {
    return PlayoffBracketDto(
      id: json['id'] as int,
      leagueId: json['league_id'] as int,
      season: json['season'] as int,
      playoffTeams: json['playoff_teams'] as int,
      totalRounds: json['total_rounds'] as int,
      startWeek: json['start_week'] as int,
      championshipWeek: json['championship_week'] as int,
      status: PlayoffStatus.fromString(json['status'] as String?),
      championRosterId: json['champion_roster_id'] as int?,
      weeksByRound: (json['weeks_by_round'] as List<dynamic>?)?.cast<int>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'season': season,
      'playoff_teams': playoffTeams,
      'total_rounds': totalRounds,
      'start_week': startWeek,
      'championship_week': championshipWeek,
      'status': status.value,
      'champion_roster_id': championRosterId,
      'weeks_by_round': weeksByRound,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PlayoffMatchupDto {
  final int matchupId;
  final int week;
  final int round;
  final int bracketPosition;
  final String bracketType;
  final PlayoffTeamDto? team1;
  final PlayoffTeamDto? team2;
  final PlayoffTeamDto? winner;
  final bool isFinal;
  final String? seriesId;
  final int seriesGame;
  final int seriesLength;

  const PlayoffMatchupDto({
    required this.matchupId,
    required this.week,
    required this.round,
    required this.bracketPosition,
    this.bracketType = 'WINNERS',
    this.team1,
    this.team2,
    this.winner,
    required this.isFinal,
    this.seriesId,
    this.seriesGame = 1,
    this.seriesLength = 1,
  });

  factory PlayoffMatchupDto.fromJson(Map<String, dynamic> json) {
    return PlayoffMatchupDto(
      matchupId: json['matchup_id'] as int,
      week: json['week'] as int,
      round: json['round'] as int,
      bracketPosition: json['bracket_position'] as int? ?? 0,
      bracketType: json['bracket_type'] as String? ?? 'WINNERS',
      team1: json['team1'] != null ? PlayoffTeamDto.fromJson(json['team1'] as Map<String, dynamic>) : null,
      team2: json['team2'] != null ? PlayoffTeamDto.fromJson(json['team2'] as Map<String, dynamic>) : null,
      winner: json['winner'] != null ? PlayoffTeamDto.fromJson(json['winner'] as Map<String, dynamic>) : null,
      isFinal: json['is_final'] as bool? ?? false,
      seriesId: json['series_id'] as String?,
      seriesGame: json['series_game'] as int? ?? 1,
      seriesLength: json['series_length'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchup_id': matchupId,
      'week': week,
      'round': round,
      'bracket_position': bracketPosition,
      'bracket_type': bracketType,
      'team1': team1?.toJson(),
      'team2': team2?.toJson(),
      'winner': winner?.toJson(),
      'is_final': isFinal,
      'series_id': seriesId,
      'series_game': seriesGame,
      'series_length': seriesLength,
    };
  }
}

class PlayoffTeamDto {
  final int rosterId;
  final int seed;
  final String teamName;
  final double? points;
  final String record;

  const PlayoffTeamDto({required this.rosterId, required this.seed, required this.teamName, this.points, required this.record});

  factory PlayoffTeamDto.fromJson(Map<String, dynamic> json) {
    return PlayoffTeamDto(
      rosterId: json['roster_id'] as int,
      seed: json['seed'] as int,
      teamName: json['team_name'] as String? ?? 'Team ${json['seed']}',
      points: (json['points'] as num?)?.toDouble(),
      record: json['record'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'roster_id': rosterId, 'seed': seed, 'team_name': teamName, 'points': points, 'record': record};
}

class PlayoffRoundDto {
  final int round;
  final int week;
  final int weekStart;
  final int weekEnd;
  final String name;
  final List<PlayoffMatchupDto> matchups;

  const PlayoffRoundDto({
    required this.round,
    required this.week,
    required this.weekStart,
    required this.weekEnd,
    required this.name,
    required this.matchups,
  });

  factory PlayoffRoundDto.fromJson(Map<String, dynamic> json) {
    final week = json['week'] as int;
    return PlayoffRoundDto(
      round: json['round'] as int,
      week: week,
      weekStart: json['week_start'] as int? ?? week,
      weekEnd: json['week_end'] as int? ?? week,
      name: json['name'] as String,
      matchups: (json['matchups'] as List<dynamic>).map((m) => PlayoffMatchupDto.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'week': week,
      'week_start': weekStart,
      'week_end': weekEnd,
      'name': name,
      'matchups': matchups.map((m) => m.toJson()).toList(),
    };
  }
}
