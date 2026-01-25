/// Waiver priority model
class WaiverPriority {
  final int id;
  final int leagueId;
  final int rosterId;
  final int season;
  final int priority;
  final String teamName;
  final String username;
  final DateTime updatedAt;

  WaiverPriority({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.season,
    required this.priority,
    required this.teamName,
    required this.username,
    required this.updatedAt,
  });

  factory WaiverPriority.fromJson(Map<String, dynamic> json) {
    return WaiverPriority(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      season: json['season'] as int? ?? DateTime.now().year,
      priority: json['priority'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
