/// Weekly player statistics
class PlayerStats {
  final int id;
  final int playerId;
  final int season;
  final int week;
  // Passing
  final int passYards;
  final int passTd;
  final int passInt;
  // Rushing
  final int rushYards;
  final int rushTd;
  // Receiving
  final int receptions;
  final int recYards;
  final int recTd;
  // Misc
  final int fumblesLost;
  final int twoPtConversions;
  // Kicking
  final int fgMade;
  final int fgMissed;
  final int patMade;
  final int patMissed;
  // Defense
  final int defTd;
  final int defInt;
  final double defSacks;
  final int defFumbleRec;
  final int defSafety;
  final int defPointsAllowed;

  PlayerStats({
    required this.id,
    required this.playerId,
    required this.season,
    required this.week,
    this.passYards = 0,
    this.passTd = 0,
    this.passInt = 0,
    this.rushYards = 0,
    this.rushTd = 0,
    this.receptions = 0,
    this.recYards = 0,
    this.recTd = 0,
    this.fumblesLost = 0,
    this.twoPtConversions = 0,
    this.fgMade = 0,
    this.fgMissed = 0,
    this.patMade = 0,
    this.patMissed = 0,
    this.defTd = 0,
    this.defInt = 0,
    this.defSacks = 0,
    this.defFumbleRec = 0,
    this.defSafety = 0,
    this.defPointsAllowed = 0,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      id: json['id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      passYards: json['pass_yards'] as int? ?? 0,
      passTd: json['pass_td'] as int? ?? 0,
      passInt: json['pass_int'] as int? ?? 0,
      rushYards: json['rush_yards'] as int? ?? 0,
      rushTd: json['rush_td'] as int? ?? 0,
      receptions: json['receptions'] as int? ?? 0,
      recYards: json['rec_yards'] as int? ?? 0,
      recTd: json['rec_td'] as int? ?? 0,
      fumblesLost: json['fumbles_lost'] as int? ?? 0,
      twoPtConversions: json['two_pt_conversions'] as int? ?? 0,
      fgMade: json['fg_made'] as int? ?? 0,
      fgMissed: json['fg_missed'] as int? ?? 0,
      patMade: json['pat_made'] as int? ?? 0,
      patMissed: json['pat_missed'] as int? ?? 0,
      defTd: json['def_td'] as int? ?? 0,
      defInt: json['def_int'] as int? ?? 0,
      defSacks: (json['def_sacks'] as num?)?.toDouble() ?? 0,
      defFumbleRec: json['def_fumble_rec'] as int? ?? 0,
      defSafety: json['def_safety'] as int? ?? 0,
      defPointsAllowed: json['def_points_allowed'] as int? ?? 0,
    );
  }
}

/// Scoring rules configuration
class ScoringRules {
  // Passing
  final double passYards;
  final double passTd;
  final double passInt;
  // Rushing
  final double rushYards;
  final double rushTd;
  // Receiving
  final double receptions;
  final double recYards;
  final double recTd;
  // Misc
  final double fumblesLost;
  final double twoPtConversions;
  // Kicking
  final double fgMade;
  final double fgMissed;
  final double patMade;
  final double patMissed;

  ScoringRules({
    this.passYards = 0.04,
    this.passTd = 4,
    this.passInt = -2,
    this.rushYards = 0.1,
    this.rushTd = 6,
    this.receptions = 1,
    this.recYards = 0.1,
    this.recTd = 6,
    this.fumblesLost = -2,
    this.twoPtConversions = 2,
    this.fgMade = 3,
    this.fgMissed = -1,
    this.patMade = 1,
    this.patMissed = -1,
  });

  factory ScoringRules.ppr() => ScoringRules(receptions: 1);
  factory ScoringRules.halfPpr() => ScoringRules(receptions: 0.5);
  factory ScoringRules.standard() => ScoringRules(receptions: 0);

  factory ScoringRules.fromJson(Map<String, dynamic> json) {
    return ScoringRules(
      passYards: (json['pass_yards'] as num?)?.toDouble() ?? 0.04,
      passTd: (json['pass_td'] as num?)?.toDouble() ?? 4,
      passInt: (json['pass_int'] as num?)?.toDouble() ?? -2,
      rushYards: (json['rush_yards'] as num?)?.toDouble() ?? 0.1,
      rushTd: (json['rush_td'] as num?)?.toDouble() ?? 6,
      receptions: (json['receptions'] as num?)?.toDouble() ?? 1,
      recYards: (json['rec_yards'] as num?)?.toDouble() ?? 0.1,
      recTd: (json['rec_td'] as num?)?.toDouble() ?? 6,
      fumblesLost: (json['fumbles_lost'] as num?)?.toDouble() ?? -2,
      twoPtConversions: (json['two_pt_conversions'] as num?)?.toDouble() ?? 2,
      fgMade: (json['fg_made'] as num?)?.toDouble() ?? 3,
      fgMissed: (json['fg_missed'] as num?)?.toDouble() ?? -1,
      patMade: (json['pat_made'] as num?)?.toDouble() ?? 1,
      patMissed: (json['pat_missed'] as num?)?.toDouble() ?? -1,
    );
  }

  /// Calculate points for player stats
  double calculatePoints(PlayerStats stats) {
    return (stats.passYards * passYards) +
        (stats.passTd * passTd) +
        (stats.passInt * passInt) +
        (stats.rushYards * rushYards) +
        (stats.rushTd * rushTd) +
        (stats.receptions * receptions) +
        (stats.recYards * recYards) +
        (stats.recTd * recTd) +
        (stats.fumblesLost * fumblesLost) +
        (stats.twoPtConversions * twoPtConversions) +
        (stats.fgMade * fgMade) +
        (stats.fgMissed * fgMissed) +
        (stats.patMade * patMade) +
        (stats.patMissed * patMissed);
  }
}
