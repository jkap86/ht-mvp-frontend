/// Weekly matchup between two teams
class Matchup {
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
  // Extended details (optional)
  final String? roster1TeamName;
  final String? roster2TeamName;
  // Live scores (for non-final matchups)
  final double? roster1PointsActual;
  final double? roster1PointsProjected;
  final double? roster2PointsActual;
  final double? roster2PointsProjected;

  Matchup({
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

  /// Get the winning roster ID (null if tie or not final)
  int? get winnerId {
    if (!isFinal || roster1Points == null || roster2Points == null) return null;
    if (roster1Points! > roster2Points!) return roster1Id;
    if (roster2Points! > roster1Points!) return roster2Id;
    return null; // Tie
  }

  /// Check if roster is the winner
  bool isWinner(int rosterId) => winnerId == rosterId;

  /// Get points for a specific roster
  double? pointsFor(int rosterId) {
    if (rosterId == roster1Id) return roster1Points;
    if (rosterId == roster2Id) return roster2Points;
    return null;
  }

  /// Get opponent's roster ID (null if rosterId not in matchup)
  int? opponentId(int rosterId) {
    if (rosterId == roster1Id) return roster2Id;
    if (rosterId == roster2Id) return roster1Id;
    return null;
  }

  /// Get the best available actual score for display during live games
  /// Returns final points if finalized, otherwise live actual points
  double? actualPointsFor(int rosterId) {
    if (isFinal) return pointsFor(rosterId);
    if (rosterId == roster1Id) return roster1PointsActual;
    if (rosterId == roster2Id) return roster2PointsActual;
    return null;
  }

  /// Get projected final points for a roster (live games only)
  double? projectedPointsFor(int rosterId) {
    if (isFinal) return null; // No projections needed for final matchups
    if (rosterId == roster1Id) return roster1PointsProjected;
    if (rosterId == roster2Id) return roster2PointsProjected;
    return null;
  }

  /// Check if this matchup has live scoring data
  bool get hasLiveData =>
      !isFinal &&
      (roster1PointsActual != null || roster2PointsActual != null);

  factory Matchup.fromJson(Map<String, dynamic> json) {
    return Matchup(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      season: json['season'] as int? ?? DateTime.now().year,
      week: json['week'] as int? ?? 1,
      roster1Id: json['roster1_id'] as int? ?? 0,
      roster2Id: json['roster2_id'] as int? ?? 0,
      roster1Points: (json['roster1_points'] as num?)?.toDouble(),
      roster2Points: (json['roster2_points'] as num?)?.toDouble(),
      isPlayoff: json['is_playoff'] as bool? ?? false,
      isFinal: json['is_final'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      roster1TeamName: json['roster1_team_name'] as String?,
      roster2TeamName: json['roster2_team_name'] as String?,
      // Live scores
      roster1PointsActual: (json['roster1_points_actual'] as num?)?.toDouble(),
      roster1PointsProjected: (json['roster1_points_projected'] as num?)?.toDouble(),
      roster2PointsActual: (json['roster2_points_actual'] as num?)?.toDouble(),
      roster2PointsProjected: (json['roster2_points_projected'] as num?)?.toDouble(),
    );
  }
}

/// Detailed matchup with lineup information
class MatchupDetails {
  final Matchup matchup;
  final MatchupTeam team1;
  final MatchupTeam team2;

  MatchupDetails({
    required this.matchup,
    required this.team1,
    required this.team2,
  });

  factory MatchupDetails.fromJson(Map<String, dynamic> json) {
    // Ensure we have proper structure - if matchup key exists, use it; otherwise treat json as matchup data
    final matchupData = json['matchup'] as Map<String, dynamic>?;
    return MatchupDetails(
      matchup: Matchup.fromJson(matchupData ?? json),
      team1: MatchupTeam.fromJson(json['team1'] as Map<String, dynamic>? ?? {}),
      team2: MatchupTeam.fromJson(json['team2'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Team information for matchup details
class MatchupTeam {
  final int rosterId;
  final String teamName;
  final double totalPoints;
  final List<MatchupPlayer> players;

  MatchupTeam({
    required this.rosterId,
    required this.teamName,
    required this.totalPoints,
    required this.players,
  });

  factory MatchupTeam.fromJson(Map<String, dynamic> json) {
    return MatchupTeam(
      rosterId: json['roster_id'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? 'Unknown',
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      players: ((json['players'] as List?) ?? [])
          .map((p) => MatchupPlayer.fromJson(p))
          .toList(),
    );
  }
}

/// Player information in matchup
class MatchupPlayer {
  final int playerId;
  final String fullName;
  final String? position;
  final String? team;
  final String slot;
  final double points;
  final bool isStarter;
  // Projection fields for live scoring
  final double? projectedPoints;
  final String? gameStatus;
  final double? remainingProjected;

  MatchupPlayer({
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

  factory MatchupPlayer.fromJson(Map<String, dynamic> json) {
    return MatchupPlayer(
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
}

/// League standings entry
class Standing {
  final int rosterId;
  final String teamName;
  final String? userId;
  // Total record (H2H + Median when league median is enabled)
  final int wins;
  final int losses;
  final int ties;
  // H2H breakdown
  final int h2hWins;
  final int h2hLosses;
  final int h2hTies;
  // Median breakdown (null if league doesn't use median)
  final int? medianWins;
  final int? medianLosses;
  final int? medianTies;
  // Other stats
  final double pointsFor;
  final double pointsAgainst;
  final String streak;
  final int rank;

  Standing({
    required this.rosterId,
    required this.teamName,
    this.userId,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.h2hWins,
    required this.h2hLosses,
    required this.h2hTies,
    this.medianWins,
    this.medianLosses,
    this.medianTies,
    required this.pointsFor,
    required this.pointsAgainst,
    required this.streak,
    required this.rank,
  });

  /// Whether this standing includes median scoring
  bool get hasMedianScoring => medianWins != null;

  /// Calculate win percentage
  double get winPercentage {
    final total = wins + losses + ties;
    if (total == 0) return 0;
    return (wins + (ties * 0.5)) / total;
  }

  /// Format total record as "W-L" or "W-L-T"
  String get record {
    if (ties > 0) return '$wins-$losses-$ties';
    return '$wins-$losses';
  }

  /// Format H2H record as "W-L" or "W-L-T"
  String get h2hRecord {
    if (h2hTies > 0) return '$h2hWins-$h2hLosses-$h2hTies';
    return '$h2hWins-$h2hLosses';
  }

  /// Format median record as "W-L" or "W-L-T" (null if not using median)
  String? get medianRecord {
    if (medianWins == null) return null;
    if (medianTies != null && medianTies! > 0) {
      return '$medianWins-$medianLosses-$medianTies';
    }
    return '$medianWins-$medianLosses';
  }

  /// Point differential
  double get pointDifferential => pointsFor - pointsAgainst;

  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      rosterId: json['roster_id'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? 'Unknown',
      userId: json['user_id'] as String?,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      ties: json['ties'] as int? ?? 0,
      h2hWins: json['h2h_wins'] as int? ?? json['wins'] as int? ?? 0,
      h2hLosses: json['h2h_losses'] as int? ?? json['losses'] as int? ?? 0,
      h2hTies: json['h2h_ties'] as int? ?? json['ties'] as int? ?? 0,
      medianWins: json['median_wins'] as int?,
      medianLosses: json['median_losses'] as int?,
      medianTies: json['median_ties'] as int?,
      pointsFor: (json['points_for'] as num?)?.toDouble() ?? 0,
      pointsAgainst: (json['points_against'] as num?)?.toDouble() ?? 0,
      streak: json['streak'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
    );
  }
}
