/// FAAB budget model
class FaabBudget {
  final int id;
  final int leagueId;
  final int rosterId;
  final int season;
  final int initialBudget;
  final int remainingBudget;
  final String teamName;
  final String username;
  final DateTime updatedAt;

  FaabBudget({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.season,
    required this.initialBudget,
    required this.remainingBudget,
    required this.teamName,
    required this.username,
    required this.updatedAt,
  });

  factory FaabBudget.fromJson(Map<String, dynamic> json) {
    return FaabBudget(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      season: json['season'] as int? ?? DateTime.now().year,
      initialBudget: json['initial_budget'] as int? ?? 100,
      remainingBudget: json['remaining_budget'] as int? ?? 100,
      teamName: json['team_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Percentage of budget remaining
  double get remainingPercent =>
      initialBudget > 0 ? (remainingBudget / initialBudget) * 100 : 0;

  /// Amount of budget spent
  int get spent => initialBudget - remainingBudget;
}
