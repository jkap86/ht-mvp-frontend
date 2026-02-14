/// Represents a single pick made during a fantasy draft.
class DraftPick {
  final int id;
  final int draftId;
  final int pickNumber;
  final int round;
  final int pickInRound;
  final int rosterId;
  final int? playerId;  // Nullable: null for pick asset selections
  final bool isAutoPick;
  final String? autoPickReason; // 'timeout', 'autodraft', 'empty_roster'
  final DateTime? pickedAt;
  final String? playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String? username;

  // Pick asset fields (for vet drafts selecting rookie draft picks)
  final int? draftPickAssetId;
  final int? pickAssetSeason;
  final int? pickAssetRound;
  final String? pickAssetOriginalTeam;
  final bool isPickAsset;

  DraftPick({
    required this.id,
    required this.draftId,
    required this.pickNumber,
    required this.round,
    required this.pickInRound,
    required this.rosterId,
    this.playerId,  // Now optional
    this.isAutoPick = false,
    this.autoPickReason,
    this.pickedAt,
    this.playerName,
    this.playerPosition,
    this.playerTeam,
    this.username,
    this.draftPickAssetId,
    this.pickAssetSeason,
    this.pickAssetRound,
    this.pickAssetOriginalTeam,
    this.isPickAsset = false,
  });

  factory DraftPick.fromJson(Map<String, dynamic> json) {
    return DraftPick(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      pickNumber: json['pick_number'] as int? ?? json['pickNumber'] as int? ?? 0,
      round: json['round'] as int? ?? 1,
      pickInRound: json['pick_in_round'] as int? ?? json['pickInRound'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? json['playerId'] as int?,  // No default to 0
      isAutoPick: json['is_auto_pick'] as bool? ?? json['isAutoPick'] as bool? ?? false,
      autoPickReason: json['auto_pick_reason'] as String? ?? json['autoPickReason'] as String?,
      pickedAt: json['picked_at'] != null
          ? DateTime.tryParse(json['picked_at'].toString())
          : json['pickedAt'] != null
              ? DateTime.tryParse(json['pickedAt'].toString())
              : null,
      playerName: json['player_name'] as String? ?? json['playerName'] as String?,
      playerPosition: json['player_position'] as String? ?? json['playerPosition'] as String?,
      playerTeam: json['player_team'] as String? ?? json['playerTeam'] as String?,
      username: json['username'] as String?,
      draftPickAssetId: json['draft_pick_asset_id'] as int? ?? json['draftPickAssetId'] as int?,
      pickAssetSeason: json['pick_asset_season'] as int? ?? json['pickAssetSeason'] as int?,
      pickAssetRound: json['pick_asset_round'] as int? ?? json['pickAssetRound'] as int?,
      pickAssetOriginalTeam: json['pick_asset_original_team'] as String? ?? json['pickAssetOriginalTeam'] as String?,
      isPickAsset: json['is_pick_asset'] as bool? ?? json['isPickAsset'] as bool? ?? false,
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
      'auto_pick_reason': autoPickReason,
      'picked_at': pickedAt?.toIso8601String(),
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'username': username,
      'draft_pick_asset_id': draftPickAssetId,
      'pick_asset_season': pickAssetSeason,
      'pick_asset_round': pickAssetRound,
      'pick_asset_original_team': pickAssetOriginalTeam,
      'is_pick_asset': isPickAsset,
    };
  }

  @override
  String toString() {
    if (isPickAsset) {
      return 'DraftPick(id: $id, pickNumber: $pickNumber, round: $round, isPickAsset: true, pickAssetSeason: $pickAssetSeason, pickAssetRound: $pickAssetRound)';
    }
    return 'DraftPick(id: $id, pickNumber: $pickNumber, round: $round, playerId: $playerId, playerName: $playerName)';
  }
}
