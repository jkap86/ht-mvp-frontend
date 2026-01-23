/// Represents a single pick made during a fantasy draft.
class DraftPick {
  final int id;
  final int draftId;
  final int pickNumber;
  final int round;
  final int pickInRound;
  final int rosterId;
  final int playerId;
  final bool isAutoPick;
  final DateTime? pickedAt;
  final String? playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String? username;

  DraftPick({
    required this.id,
    required this.draftId,
    required this.pickNumber,
    required this.round,
    required this.pickInRound,
    required this.rosterId,
    required this.playerId,
    this.isAutoPick = false,
    this.pickedAt,
    this.playerName,
    this.playerPosition,
    this.playerTeam,
    this.username,
  });

  factory DraftPick.fromJson(Map<String, dynamic> json) {
    return DraftPick(
      id: json['id'] as int,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int,
      pickNumber: json['pick_number'] as int? ?? json['pickNumber'] as int,
      round: json['round'] as int,
      pickInRound: json['pick_in_round'] as int? ?? json['pickInRound'] as int,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int,
      playerId: json['player_id'] as int? ?? json['playerId'] as int,
      isAutoPick: json['is_auto_pick'] as bool? ?? json['isAutoPick'] as bool? ?? false,
      pickedAt: json['picked_at'] != null
          ? DateTime.tryParse(json['picked_at'].toString())
          : json['pickedAt'] != null
              ? DateTime.tryParse(json['pickedAt'].toString())
              : null,
      playerName: json['player_name'] as String? ?? json['playerName'] as String?,
      playerPosition: json['player_position'] as String? ?? json['playerPosition'] as String?,
      playerTeam: json['player_team'] as String? ?? json['playerTeam'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'draft_id': draftId,
      'pick_number': pickNumber,
      'round': round,
      'pick_in_round': pickInRound,
      'roster_id': rosterId,
      'player_id': playerId,
      'is_auto_pick': isAutoPick,
      'picked_at': pickedAt?.toIso8601String(),
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'username': username,
    };
  }

  @override
  String toString() {
    return 'DraftPick(id: $id, pickNumber: $pickNumber, round: $round, playerId: $playerId, playerName: $playerName)';
  }
}
