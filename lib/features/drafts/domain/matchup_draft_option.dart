/// Represents a week/opponent combination available for selection in a matchups draft.
///
/// In matchups drafts, managers draft which week they play which opponent,
/// instead of drafting players. This model represents one such option.
class MatchupDraftOption {
  /// The week number (1-based, corresponding to draft rounds)
  final int week;

  /// The roster ID of the opponent
  final int opponentRosterId;

  /// The team name of the opponent
  final String opponentTeamName;

  /// The opponent's logo URL (optional)
  final String? opponentLogoUrl;

  /// How many times the current picker has already played this opponent
  final int currentFrequency;

  /// Maximum allowed times a team can play the same opponent
  final int maxFrequency;

  const MatchupDraftOption({
    required this.week,
    required this.opponentRosterId,
    required this.opponentTeamName,
    this.opponentLogoUrl,
    required this.currentFrequency,
    required this.maxFrequency,
  });

  /// Whether this matchup is available to be picked
  /// (False if frequency limit reached)
  bool get isAvailable => currentFrequency < maxFrequency;

  /// Display label for frequency (e.g., "1/2")
  String get frequencyLabel => '$currentFrequency/$maxFrequency';

  factory MatchupDraftOption.fromJson(Map<String, dynamic> json) {
    return MatchupDraftOption(
      week: json['week'] as int? ?? 0,
      opponentRosterId: json['opponentRosterId'] as int? ??
          json['opponent_roster_id'] as int? ??
          0,
      opponentTeamName: json['opponentTeamName'] as String? ??
          json['opponent_team_name'] as String? ??
          'Unknown Team',
      opponentLogoUrl: json['opponentLogoUrl'] as String? ??
          json['opponent_logo_url'] as String?,
      currentFrequency: json['currentFrequency'] as int? ??
          json['current_frequency'] as int? ??
          0,
      maxFrequency: json['maxFrequency'] as int? ??
          json['max_frequency'] as int? ??
          1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week,
      'opponent_roster_id': opponentRosterId,
      'opponent_team_name': opponentTeamName,
      'opponent_logo_url': opponentLogoUrl,
      'current_frequency': currentFrequency,
      'max_frequency': maxFrequency,
    };
  }

  @override
  String toString() {
    return 'MatchupDraftOption(week: $week, opponent: $opponentTeamName, freq: $frequencyLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchupDraftOption &&
        other.week == week &&
        other.opponentRosterId == opponentRosterId;
  }

  @override
  int get hashCode => Object.hash(week, opponentRosterId);
}
