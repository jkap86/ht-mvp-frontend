class TradeBlockItem {
  final int id;
  final int leagueId;
  final int rosterId;
  final int playerId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fullName;
  final String position;
  final String team;
  final String teamName;
  final String username;

  TradeBlockItem({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.playerId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.fullName,
    required this.position,
    required this.team,
    required this.teamName,
    required this.username,
  });

  factory TradeBlockItem.fromJson(Map<String, dynamic> json) {
    return TradeBlockItem(
      id: json['id'] as int,
      leagueId: json['league_id'] as int,
      rosterId: json['roster_id'] as int,
      playerId: json['player_id'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      fullName: json['full_name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      team: json['team'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}
