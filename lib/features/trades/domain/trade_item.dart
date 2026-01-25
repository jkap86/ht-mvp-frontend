/// Trade item model representing a player being traded
class TradeItem {
  final int id;
  final int tradeId;
  final int playerId;
  final int fromRosterId;
  final int toRosterId;
  final String playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String fullName;
  final String? position;
  final String? team;
  final String? status;

  TradeItem({
    required this.id,
    required this.tradeId,
    required this.playerId,
    required this.fromRosterId,
    required this.toRosterId,
    required this.playerName,
    this.playerPosition,
    this.playerTeam,
    required this.fullName,
    this.position,
    this.team,
    this.status,
  });

  factory TradeItem.fromJson(Map<String, dynamic> json) {
    return TradeItem(
      id: json['id'] as int? ?? 0,
      tradeId: json['trade_id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      fromRosterId: json['from_roster_id'] as int? ?? 0,
      toRosterId: json['to_roster_id'] as int? ?? 0,
      playerName: json['player_name'] as String? ?? '',
      playerPosition: json['player_position'] as String?,
      playerTeam: json['player_team'] as String?,
      fullName: json['full_name'] as String? ?? json['player_name'] as String? ?? '',
      position: json['position'] as String?,
      team: json['team'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'player_id': playerId,
      'from_roster_id': fromRosterId,
      'to_roster_id': toRosterId,
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'full_name': fullName,
      'position': position,
      'team': team,
      'status': status,
    };
  }

  /// Get display position (prefer enriched position over snapshot)
  String get displayPosition => position ?? playerPosition ?? '?';

  /// Get display team (prefer enriched team over snapshot)
  String get displayTeam => team ?? playerTeam ?? '';
}
