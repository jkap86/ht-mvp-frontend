export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show TradeItemType;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

/// Trade item model representing a player or draft pick being traded
class TradeItem {
  final int id;
  final int tradeId;
  final int fromRosterId;
  final int toRosterId;
  final TradeItemType itemType;

  // Player fields (used when itemType == player)
  final int playerId;
  final String playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String fullName;
  final String? position;
  final String? team;
  final String? status;

  // Draft pick fields (used when itemType == draftPick)
  final int? draftPickAssetId;
  final int? pickSeason;
  final int? pickRound;
  final String? pickOriginalTeam;
  final int? pickOriginalRosterId;

  TradeItem({
    required this.id,
    required this.tradeId,
    required this.fromRosterId,
    required this.toRosterId,
    this.itemType = TradeItemType.player,
    // Player fields
    this.playerId = 0,
    this.playerName = '',
    this.playerPosition,
    this.playerTeam,
    this.fullName = '',
    this.position,
    this.team,
    this.status,
    // Draft pick fields
    this.draftPickAssetId,
    this.pickSeason,
    this.pickRound,
    this.pickOriginalTeam,
    this.pickOriginalRosterId,
  });

  factory TradeItem.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'] as int?;
    final tradeId = json['trade_id'] as int?;
    final fromRosterId = json['from_roster_id'] as int?;
    final toRosterId = json['to_roster_id'] as int?;

    if (id == null || id <= 0) {
      throw FormatException('TradeItem missing required field: id');
    }
    if (tradeId == null || tradeId <= 0) {
      throw FormatException('TradeItem missing required field: trade_id');
    }
    if (fromRosterId == null || fromRosterId <= 0) {
      throw FormatException('TradeItem missing required field: from_roster_id');
    }
    if (toRosterId == null || toRosterId <= 0) {
      throw FormatException('TradeItem missing required field: to_roster_id');
    }

    final itemType = TradeItemType.fromString(json['item_type'] as String?);

    // For player items, validate player fields
    final playerId = json['player_id'] as int? ?? 0;
    if (itemType == TradeItemType.player && playerId <= 0) {
      throw FormatException('TradeItem of type player missing required field: player_id');
    }

    // For draft pick items, validate pick fields
    final draftPickAssetId = json['draft_pick_asset_id'] as int? ??
        json['draftPickAssetId'] as int?;
    if (itemType == TradeItemType.draftPick && (draftPickAssetId == null || draftPickAssetId <= 0)) {
      throw FormatException('TradeItem of type draft_pick missing required field: draft_pick_asset_id');
    }

    return TradeItem(
      id: id,
      tradeId: tradeId,
      fromRosterId: fromRosterId,
      toRosterId: toRosterId,
      itemType: itemType,
      // Player fields
      playerId: playerId,
      playerName: json['player_name'] as String? ?? '',
      playerPosition: json['player_position'] as String?,
      playerTeam: json['player_team'] as String?,
      fullName: json['full_name'] as String? ?? json['player_name'] as String? ?? '',
      position: json['position'] as String?,
      team: json['team'] as String?,
      status: json['status'] as String?,
      // Draft pick fields
      draftPickAssetId: draftPickAssetId,
      pickSeason: json['pick_season'] as int? ?? json['pickSeason'] as int?,
      pickRound: json['pick_round'] as int? ?? json['pickRound'] as int?,
      pickOriginalTeam: json['pick_original_team'] as String? ??
          json['pickOriginalTeam'] as String?,
      pickOriginalRosterId: json['pick_original_roster_id'] as int? ??
          json['pickOriginalRosterId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'from_roster_id': fromRosterId,
      'to_roster_id': toRosterId,
      'item_type': itemType.value,
      // Player fields
      'player_id': playerId,
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'full_name': fullName,
      'position': position,
      'team': team,
      'status': status,
      // Draft pick fields
      'draft_pick_asset_id': draftPickAssetId,
      'pick_season': pickSeason,
      'pick_round': pickRound,
      'pick_original_team': pickOriginalTeam,
      'pick_original_roster_id': pickOriginalRosterId,
    };
  }

  /// Get display position (prefer enriched position over snapshot)
  String get displayPosition => position ?? playerPosition ?? '?';

  /// Get display team (prefer enriched team over snapshot)
  String get displayTeam => team ?? playerTeam ?? '';

  /// Whether this item is a player
  bool get isPlayer => itemType == TradeItemType.player;

  /// Whether this item is a draft pick
  bool get isDraftPick => itemType == TradeItemType.draftPick;

  /// Display name for the trade item
  /// For players: returns the player name
  /// For draft picks: returns formatted pick name like "2025 Rd 1 (Team A's)"
  String get displayName {
    if (isDraftPick) {
      return pickDisplayName;
    }
    return fullName.isNotEmpty ? fullName : playerName;
  }

  /// Display name for draft picks (e.g., "2025 1" or "2025 1 (Team A's)")
  String get pickDisplayName {
    if (!isDraftPick) return '';
    final season = pickSeason ?? 0;
    final round = pickRound ?? 1;
    final base = '$season $round';

    // If original team differs from the from_roster, show the original owner
    if (pickOriginalTeam != null && pickOriginalTeam!.isNotEmpty) {
      return "$base ($pickOriginalTeam's)";
    }
    return base;
  }
}
