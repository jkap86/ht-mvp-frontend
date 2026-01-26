// Playoff bracket models

enum PlayoffStatus {
  pending,
  active,
  completed;

  static PlayoffStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return PlayoffStatus.active;
      case 'completed':
        return PlayoffStatus.completed;
      default:
        return PlayoffStatus.pending;
    }
  }
}

class PlayoffBracket {
  final int id;
  final int leagueId;
  final int season;
  final int playoffTeams;
  final int totalRounds;
  final int startWeek;
  final int championshipWeek;
  final PlayoffStatus status;
  final int? championRosterId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayoffBracket({
    required this.id,
    required this.leagueId,
    required this.season,
    required this.playoffTeams,
    required this.totalRounds,
    required this.startWeek,
    required this.championshipWeek,
    required this.status,
    this.championRosterId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayoffBracket.fromJson(Map<String, dynamic> json) {
    return PlayoffBracket(
      id: json['id'] as int,
      leagueId: json['league_id'] as int,
      season: json['season'] as int,
      playoffTeams: json['playoff_teams'] as int,
      totalRounds: json['total_rounds'] as int,
      startWeek: json['start_week'] as int,
      championshipWeek: json['championship_week'] as int,
      status: PlayoffStatus.fromString(json['status'] as String?),
      championRosterId: json['champion_roster_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PlayoffSeed {
  final int id;
  final int bracketId;
  final int rosterId;
  final int seed;
  final String regularSeasonRecord;
  final double pointsFor;
  final bool hasBye;
  final String? teamName;
  final String? userId;

  PlayoffSeed({
    required this.id,
    required this.bracketId,
    required this.rosterId,
    required this.seed,
    required this.regularSeasonRecord,
    required this.pointsFor,
    required this.hasBye,
    this.teamName,
    this.userId,
  });

  factory PlayoffSeed.fromJson(Map<String, dynamic> json) {
    return PlayoffSeed(
      id: json['id'] as int,
      bracketId: json['bracket_id'] as int,
      rosterId: json['roster_id'] as int,
      seed: json['seed'] as int,
      regularSeasonRecord: json['regular_season_record'] as String? ?? '',
      pointsFor: (json['points_for'] as num?)?.toDouble() ?? 0.0,
      hasBye: json['has_bye'] as bool? ?? false,
      teamName: json['team_name'] as String?,
      userId: json['user_id'] as String?,
    );
  }
}

class PlayoffTeam {
  final int rosterId;
  final int seed;
  final String teamName;
  final double? points;
  final String record;

  PlayoffTeam({
    required this.rosterId,
    required this.seed,
    required this.teamName,
    this.points,
    required this.record,
  });

  factory PlayoffTeam.fromJson(Map<String, dynamic> json) {
    return PlayoffTeam(
      rosterId: json['roster_id'] as int,
      seed: json['seed'] as int,
      teamName: json['team_name'] as String? ?? 'Team ${json['seed']}',
      points: (json['points'] as num?)?.toDouble(),
      record: json['record'] as String? ?? '',
    );
  }
}

class PlayoffMatchup {
  final int matchupId;
  final int week;
  final int round;
  final int bracketPosition;
  final PlayoffTeam? team1;
  final PlayoffTeam? team2;
  final PlayoffTeam? winner;
  final bool isFinal;

  PlayoffMatchup({
    required this.matchupId,
    required this.week,
    required this.round,
    required this.bracketPosition,
    this.team1,
    this.team2,
    this.winner,
    required this.isFinal,
  });

  factory PlayoffMatchup.fromJson(Map<String, dynamic> json) {
    return PlayoffMatchup(
      matchupId: json['matchup_id'] as int,
      week: json['week'] as int,
      round: json['round'] as int,
      bracketPosition: json['bracket_position'] as int? ?? 0,
      team1: json['team1'] != null
          ? PlayoffTeam.fromJson(json['team1'] as Map<String, dynamic>)
          : null,
      team2: json['team2'] != null
          ? PlayoffTeam.fromJson(json['team2'] as Map<String, dynamic>)
          : null,
      winner: json['winner'] != null
          ? PlayoffTeam.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      isFinal: json['is_final'] as bool? ?? false,
    );
  }
}

class PlayoffRound {
  final int round;
  final int week;
  final String name;
  final List<PlayoffMatchup> matchups;

  PlayoffRound({
    required this.round,
    required this.week,
    required this.name,
    required this.matchups,
  });

  factory PlayoffRound.fromJson(Map<String, dynamic> json) {
    return PlayoffRound(
      round: json['round'] as int,
      week: json['week'] as int,
      name: json['name'] as String,
      matchups: (json['matchups'] as List<dynamic>)
          .map((m) => PlayoffMatchup.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlayoffBracketView {
  final PlayoffBracket? bracket;
  final List<PlayoffSeed> seeds;
  final List<PlayoffRound> rounds;
  final PlayoffTeam? champion;

  PlayoffBracketView({
    this.bracket,
    required this.seeds,
    required this.rounds,
    this.champion,
  });

  bool get hasPlayoffs => bracket != null;
  bool get isChampionshipDecided => champion != null;

  factory PlayoffBracketView.fromJson(Map<String, dynamic> json) {
    return PlayoffBracketView(
      bracket: json['bracket'] != null
          ? PlayoffBracket.fromJson(json['bracket'] as Map<String, dynamic>)
          : null,
      seeds: (json['seeds'] as List<dynamic>?)
              ?.map((s) => PlayoffSeed.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((r) => PlayoffRound.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      champion: json['champion'] != null
          ? PlayoffTeam.fromJson(json['champion'] as Map<String, dynamic>)
          : null,
    );
  }

  factory PlayoffBracketView.empty() {
    return PlayoffBracketView(
      bracket: null,
      seeds: [],
      rounds: [],
      champion: null,
    );
  }
}
