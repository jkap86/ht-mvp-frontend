class PlayerDto {
  final int id;
  final String? sleeperId;
  final String? firstName;
  final String? lastName;
  final List<String> fantasyPositions;
  final int? yearsExp;
  final int? age;
  final String? team;
  final String? position;
  final String? number;
  final String? status;
  final String? injuryStatus;
  final bool active;
  final double? priorSeasonPts;
  final double? seasonToDatePts;
  final double? remainingProjectedPts;
  final String? cfbdId;
  final String? college;
  final String? height;
  final String? weight;
  final String? homeCity;
  final String? homeState;

  const PlayerDto({
    required this.id,
    this.sleeperId,
    this.firstName,
    this.lastName,
    this.fantasyPositions = const [],
    this.yearsExp,
    this.age,
    this.team,
    this.position,
    this.number,
    this.status,
    this.injuryStatus,
    this.active = true,
    this.priorSeasonPts,
    this.seasonToDatePts,
    this.remainingProjectedPts,
    this.cfbdId,
    this.college,
    this.height,
    this.weight,
    this.homeCity,
    this.homeState,
  });

  factory PlayerDto.fromJson(Map<String, dynamic> json) {
    return PlayerDto(
      id: json['id'] as int? ?? 0,
      sleeperId: json['sleeper_id'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fantasyPositions: (json['fantasy_positions'] as List<dynamic>?)?.cast<String>() ?? [],
      yearsExp: json['years_exp'] as int?,
      age: json['age'] as int?,
      team: json['team'] as String?,
      position: json['position'] as String?,
      number: json['number'] as String?,
      status: json['status'] as String?,
      injuryStatus: json['injury_status'] as String?,
      active: json['active'] as bool? ?? true,
      priorSeasonPts: (json['prior_season_pts'] as num?)?.toDouble(),
      seasonToDatePts: (json['season_to_date_pts'] as num?)?.toDouble(),
      remainingProjectedPts: (json['remaining_projected_pts'] as num?)?.toDouble(),
      cfbdId: json['cfbd_id'] as String?,
      college: json['college'] as String?,
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      homeCity: json['home_city'] as String?,
      homeState: json['home_state'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (sleeperId != null) 'sleeper_id': sleeperId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'fantasy_positions': fantasyPositions,
      if (yearsExp != null) 'years_exp': yearsExp,
      if (age != null) 'age': age,
      if (team != null) 'team': team,
      if (position != null) 'position': position,
      if (number != null) 'number': number,
      if (status != null) 'status': status,
      if (injuryStatus != null) 'injury_status': injuryStatus,
      'active': active,
      if (priorSeasonPts != null) 'prior_season_pts': priorSeasonPts,
      if (seasonToDatePts != null) 'season_to_date_pts': seasonToDatePts,
      if (remainingProjectedPts != null) 'remaining_projected_pts': remainingProjectedPts,
    };
  }
}

class PlayerNewsDto {
  final int playerId;
  final String title;
  final String? body;
  final DateTime publishedAt;

  const PlayerNewsDto({required this.playerId, required this.title, this.body, required this.publishedAt});

  factory PlayerNewsDto.fromJson(Map<String, dynamic> json) {
    return PlayerNewsDto(
      playerId: json['player_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? '') ?? DateTime.utc(1970),
    );
  }
}

class PlayerStatsDto {
  final int playerId;
  final int season;
  final int week;
  final double points;
  final Map<String, dynamic> stats;

  const PlayerStatsDto({required this.playerId, required this.season, required this.week, required this.points, required this.stats});

  factory PlayerStatsDto.fromJson(Map<String, dynamic> json) {
    return PlayerStatsDto(
      playerId: json['player_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 0,
      points: (json['points'] as num?)?.toDouble() ?? 0,
      stats: (json['stats'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class PlayerProjectionDto {
  final int playerId;
  final int season;
  final int week;
  final double projectedPoints;

  const PlayerProjectionDto({required this.playerId, required this.season, required this.week, required this.projectedPoints});

  factory PlayerProjectionDto.fromJson(Map<String, dynamic> json) {
    return PlayerProjectionDto(
      playerId: json['player_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 0,
      projectedPoints: (json['projected_points'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NflStateDto {
  final int season;
  final int week;
  final String seasonType;
  final bool isOffseason;

  const NflStateDto({required this.season, required this.week, required this.seasonType, required this.isOffseason});

  factory NflStateDto.fromJson(Map<String, dynamic> json) {
    return NflStateDto(
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      seasonType: json['season_type'] as String? ?? 'regular',
      isOffseason: json['is_offseason'] as bool? ?? false,
    );
  }
}
