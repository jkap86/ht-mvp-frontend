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

enum ConsolationType {
  none,
  consolation;

  static ConsolationType fromString(String? value) {
    switch (value) {
      case 'CONSOLATION':
        return ConsolationType.consolation;
      default:
        return ConsolationType.none;
    }
  }

  String toApiValue() {
    switch (this) {
      case ConsolationType.consolation:
        return 'CONSOLATION';
      case ConsolationType.none:
        return 'NONE';
    }
  }
}

class PlayoffSettings {
  final bool enableThirdPlaceGame;
  final ConsolationType consolationType;
  final int? consolationTeams;
  final List<int>? weeksByRound; // [1, 2, 2] = R1:1wk, R2:2wk, R3:2wk

  PlayoffSettings({
    this.enableThirdPlaceGame = false,
    this.consolationType = ConsolationType.none,
    this.consolationTeams,
    this.weeksByRound,
  });

  factory PlayoffSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlayoffSettings();
    return PlayoffSettings(
      enableThirdPlaceGame: json['enable_third_place_game'] as bool? ?? false,
      consolationType:
          ConsolationType.fromString(json['consolation_type'] as String?),
      consolationTeams: json['consolation_teams'] as int?,
      weeksByRound: (json['weeks_by_round'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }
}

class ConsolationSeed {
  final int rosterId;
  final int standingsPosition;
  final String teamName;
  final String record;

  ConsolationSeed({
    required this.rosterId,
    required this.standingsPosition,
    required this.teamName,
    required this.record,
  });

  factory ConsolationSeed.fromJson(Map<String, dynamic> json) {
    return ConsolationSeed(
      rosterId: json['roster_id'] as int,
      standingsPosition: json['standings_position'] as int,
      teamName: json['team_name'] as String? ?? 'Team',
      record: json['record'] as String? ?? '',
    );
  }
}

class ConsolationBracket {
  final List<ConsolationSeed> seeds;
  final List<PlayoffRound> rounds;

  ConsolationBracket({
    required this.seeds,
    required this.rounds,
  });

  factory ConsolationBracket.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ConsolationBracket(seeds: [], rounds: []);
    }
    return ConsolationBracket(
      seeds: (json['seeds'] as List<dynamic>?)
              ?.map((s) => ConsolationSeed.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((r) => PlayoffRound.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
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
  final List<int>? weeksByRound; // [1, 2, 2] = R1:1wk, R2:2wk, R3:2wk
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
    this.weeksByRound,
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
      weeksByRound: (json['weeks_by_round'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
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
  final String bracketType;
  final PlayoffTeam? team1;
  final PlayoffTeam? team2;
  final PlayoffTeam? winner;
  final bool isFinal;
  // Multi-week series fields
  final String? seriesId;
  final int seriesGame; // 1 or 2
  final int seriesLength; // 1 or 2

  PlayoffMatchup({
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

  /// Whether this is a multi-week series matchup
  bool get isMultiWeekSeries => seriesLength > 1;

  /// Label for the series game (e.g., "Game 1 of 2")
  String get gameLabel =>
      seriesLength > 1 ? 'Game $seriesGame of $seriesLength' : '';

  factory PlayoffMatchup.fromJson(Map<String, dynamic> json) {
    return PlayoffMatchup(
      matchupId: json['matchup_id'] as int,
      week: json['week'] as int,
      round: json['round'] as int,
      bracketPosition: json['bracket_position'] as int? ?? 0,
      bracketType: json['bracket_type'] as String? ?? 'WINNERS',
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
      seriesId: json['series_id'] as String?,
      seriesGame: json['series_game'] as int? ?? 1,
      seriesLength: json['series_length'] as int? ?? 1,
    );
  }
}

class PlayoffRound {
  final int round;
  final int week; // Start week (backward compatible)
  final int weekStart;
  final int weekEnd;
  final String name;
  final List<PlayoffMatchup> matchups;

  PlayoffRound({
    required this.round,
    required this.week,
    int? weekStart,
    int? weekEnd,
    required this.name,
    required this.matchups,
  })  : weekStart = weekStart ?? week,
        weekEnd = weekEnd ?? week;

  /// Whether this round spans multiple weeks
  bool get isMultiWeek => weekStart != weekEnd;

  /// Label for the week range (e.g., "Week 15" or "Weeks 15-16")
  String get weekLabel =>
      isMultiWeek ? 'Weeks $weekStart-$weekEnd' : 'Week $weekStart';

  factory PlayoffRound.fromJson(Map<String, dynamic> json) {
    final week = json['week'] as int;
    return PlayoffRound(
      round: json['round'] as int,
      week: week,
      weekStart: json['week_start'] as int? ?? week,
      weekEnd: json['week_end'] as int? ?? week,
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
  final PlayoffMatchup? thirdPlaceGame;
  final ConsolationBracket? consolation;
  final PlayoffSettings? settings;

  PlayoffBracketView({
    this.bracket,
    required this.seeds,
    required this.rounds,
    this.champion,
    this.thirdPlaceGame,
    this.consolation,
    this.settings,
  });

  bool get hasPlayoffs => bracket != null;
  bool get isChampionshipDecided => champion != null;
  bool get hasThirdPlaceGame => thirdPlaceGame != null;
  bool get hasConsolation =>
      consolation != null && consolation!.rounds.isNotEmpty;

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
      thirdPlaceGame: json['third_place'] != null &&
              json['third_place']['matchup'] != null
          ? PlayoffMatchup.fromJson(
              json['third_place']['matchup'] as Map<String, dynamic>)
          : null,
      consolation: json['consolation'] != null
          ? ConsolationBracket.fromJson(
              json['consolation'] as Map<String, dynamic>)
          : null,
      settings: PlayoffSettings.fromJson(
          json['settings'] as Map<String, dynamic>?),
    );
  }

  factory PlayoffBracketView.empty() {
    return PlayoffBracketView(
      bracket: null,
      seeds: [],
      rounds: [],
      champion: null,
      thirdPlaceGame: null,
      consolation: null,
      settings: PlayoffSettings(),
    );
  }
}
