import '../common/enums.dart';

class DraftDto {
  final int id;
  final int leagueId;
  final DraftType draftType;
  final DraftStatus status;
  final DraftPhase phase;
  final int rounds;
  final int pickTimeSeconds;
  final int? currentPick;
  final int? currentRound;
  final int? currentRosterId;
  final DateTime? pickDeadline;
  final DateTime? scheduledStart;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? settings;
  final bool orderConfirmed;
  final String? label;
  final bool overnightPauseEnabled;
  final String? overnightPauseStart;
  final String? overnightPauseEnd;

  const DraftDto({
    required this.id,
    required this.leagueId,
    required this.draftType,
    required this.status,
    this.phase = DraftPhase.setup,
    required this.rounds,
    required this.pickTimeSeconds,
    this.currentPick,
    this.currentRound,
    this.currentRosterId,
    this.pickDeadline,
    this.scheduledStart,
    this.startedAt,
    this.completedAt,
    this.settings,
    this.orderConfirmed = false,
    this.label,
    this.overnightPauseEnabled = false,
    this.overnightPauseStart,
    this.overnightPauseEnd,
  });

  factory DraftDto.fromJson(Map<String, dynamic> json) {
    return DraftDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      draftType: DraftType.fromString(json['draft_type'] as String?),
      status: DraftStatus.fromString(json['status'] as String?),
      phase: DraftPhase.fromString(json['phase'] as String?),
      rounds: json['rounds'] as int? ?? 15,
      pickTimeSeconds: json['pick_time_seconds'] as int? ?? 90,
      currentPick: json['current_pick'] as int?,
      currentRound: json['current_round'] as int?,
      currentRosterId: json['current_roster_id'] as int?,
      pickDeadline: json['pick_deadline'] != null ? DateTime.tryParse(json['pick_deadline'].toString()) : null,
      scheduledStart: json['scheduled_start'] != null ? DateTime.tryParse(json['scheduled_start'].toString()) : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      settings: json['settings'] as Map<String, dynamic>?,
      orderConfirmed: json['order_confirmed'] as bool? ?? false,
      label: json['label'] as String?,
      overnightPauseEnabled: json['overnight_pause_enabled'] as bool? ?? false,
      overnightPauseStart: json['overnight_pause_start'] as String?,
      overnightPauseEnd: json['overnight_pause_end'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'draft_type': draftType.value,
      'status': status.value,
      'phase': phase.value,
      'rounds': rounds,
      'pick_time_seconds': pickTimeSeconds,
      'current_pick': currentPick,
      'current_round': currentRound,
      'current_roster_id': currentRosterId,
      'pick_deadline': pickDeadline?.toIso8601String(),
      'scheduled_start': scheduledStart?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'settings': settings,
      'order_confirmed': orderConfirmed,
      'label': label,
      'overnight_pause_enabled': overnightPauseEnabled,
      'overnight_pause_start': overnightPauseStart,
      'overnight_pause_end': overnightPauseEnd,
    };
  }
}

class DraftPickDto {
  final int id;
  final int draftId;
  final int pickNumber;
  final int round;
  final int pickInRound;
  final int rosterId;
  final int? playerId;
  final bool isAutoPick;
  final DateTime? pickedAt;
  final String? playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String? username;
  final int? draftPickAssetId;
  final int? pickAssetSeason;
  final int? pickAssetRound;
  final String? pickAssetOriginalTeam;
  final bool isPickAsset;

  const DraftPickDto({
    required this.id,
    required this.draftId,
    required this.pickNumber,
    required this.round,
    required this.pickInRound,
    required this.rosterId,
    this.playerId,
    this.isAutoPick = false,
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

  factory DraftPickDto.fromJson(Map<String, dynamic> json) {
    return DraftPickDto(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      pickNumber: json['pick_number'] as int? ?? json['pickNumber'] as int? ?? 0,
      round: json['round'] as int? ?? 1,
      pickInRound: json['pick_in_round'] as int? ?? json['pickInRound'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? json['playerId'] as int?,
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
}

class DraftPickAssetDto {
  final int id;
  final int leagueId;
  final int draftId;
  final int season;
  final int round;
  final int originalRosterId;
  final int currentOwnerRosterId;
  final int? originalPickPosition;
  final String? originalTeamName;
  final String? currentOwnerTeamName;
  final String? originalUsername;
  final String? currentOwnerUsername;
  final bool isDraftedInVetDraft;

  const DraftPickAssetDto({
    required this.id,
    required this.leagueId,
    required this.draftId,
    required this.season,
    required this.round,
    required this.originalRosterId,
    required this.currentOwnerRosterId,
    this.originalPickPosition,
    this.originalTeamName,
    this.currentOwnerTeamName,
    this.originalUsername,
    this.currentOwnerUsername,
    this.isDraftedInVetDraft = false,
  });

  factory DraftPickAssetDto.fromJson(Map<String, dynamic> json) {
    return DraftPickAssetDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? json['leagueId'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      round: json['round'] as int? ?? 1,
      originalRosterId: json['original_roster_id'] as int? ?? json['originalRosterId'] as int? ?? 0,
      currentOwnerRosterId: json['current_owner_roster_id'] as int? ?? json['currentOwnerRosterId'] as int? ?? 0,
      originalPickPosition: json['original_pick_position'] as int? ?? json['originalPickPosition'] as int?,
      originalTeamName: json['original_team_name'] as String? ?? json['originalTeamName'] as String?,
      currentOwnerTeamName: json['current_owner_team_name'] as String? ?? json['currentOwnerTeamName'] as String?,
      originalUsername: json['original_username'] as String? ?? json['originalUsername'] as String?,
      currentOwnerUsername: json['current_owner_username'] as String? ?? json['currentOwnerUsername'] as String?,
      isDraftedInVetDraft: json['is_drafted_in_vet_draft'] as bool? ?? json['isDraftedInVetDraft'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'draft_id': draftId,
      'season': season,
      'round': round,
      'original_roster_id': originalRosterId,
      'current_owner_roster_id': currentOwnerRosterId,
      'original_pick_position': originalPickPosition,
      'original_team_name': originalTeamName,
      'current_owner_team_name': currentOwnerTeamName,
      'original_username': originalUsername,
      'current_owner_username': currentOwnerUsername,
      'is_drafted_in_vet_draft': isDraftedInVetDraft,
    };
  }
}

class DraftOrderEntryDto {
  final int id;
  final int draftId;
  final int rosterId;
  final int draftPosition;
  final String username;
  final String? userId;
  final bool isAutodraftEnabled;

  const DraftOrderEntryDto({
    required this.id,
    required this.draftId,
    required this.rosterId,
    required this.draftPosition,
    required this.username,
    this.userId,
    this.isAutodraftEnabled = false,
  });

  factory DraftOrderEntryDto.fromJson(Map<String, dynamic> json) {
    return DraftOrderEntryDto(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      draftPosition: json['draft_position'] as int? ?? json['draftPosition'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unknown',
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      isAutodraftEnabled: json['is_autodraft_enabled'] as bool? ?? json['isAutodraftEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'draft_id': draftId,
      'roster_id': rosterId,
      'draft_position': draftPosition,
      'username': username,
      'user_id': userId,
      'is_autodraft_enabled': isAutodraftEnabled,
    };
  }
}

class DerbyStateDto {
  final DraftPhase phase;
  final List<int> turnOrder;
  final int currentTurnIndex;
  final int currentPickerRosterId;
  final DateTime? slotPickDeadline;
  final Map<String, int> claimedSlots;
  final List<int> availableSlots;
  final DerbyTimeoutPolicy timeoutPolicy;
  final int slotPickTimeSeconds;
  final int teamCount;

  const DerbyStateDto({
    required this.phase,
    required this.turnOrder,
    required this.currentTurnIndex,
    required this.currentPickerRosterId,
    this.slotPickDeadline,
    required this.claimedSlots,
    required this.availableSlots,
    required this.timeoutPolicy,
    required this.slotPickTimeSeconds,
    required this.teamCount,
  });

  factory DerbyStateDto.fromJson(Map<String, dynamic> json) {
    final rawClaimedSlots = json['claimedSlots'] ?? json['claimed_slots'] ?? {};
    final claimedSlots = <String, int>{};
    if (rawClaimedSlots is Map) {
      for (final entry in rawClaimedSlots.entries) {
        final value = entry.value is int ? entry.value : int.tryParse(entry.value.toString());
        if (value != null) {
          claimedSlots[entry.key.toString()] = value;
        }
      }
    }

    final rawTurnOrder = json['turnOrder'] ?? json['turn_order'] ?? [];
    final turnOrder = <int>[];
    if (rawTurnOrder is List) {
      for (final item in rawTurnOrder) {
        final value = item is int ? item : int.tryParse(item.toString());
        if (value != null) turnOrder.add(value);
      }
    }

    final rawAvailableSlots = json['availableSlots'] ?? json['available_slots'] ?? [];
    final availableSlots = <int>[];
    if (rawAvailableSlots is List) {
      for (final item in rawAvailableSlots) {
        final value = item is int ? item : int.tryParse(item.toString());
        if (value != null) availableSlots.add(value);
      }
    }

    DateTime? deadline;
    final rawDeadline = json['slotPickDeadline'] ?? json['slot_pick_deadline'];
    if (rawDeadline != null && rawDeadline is String && rawDeadline.isNotEmpty) {
      deadline = DateTime.tryParse(rawDeadline);
    }

    return DerbyStateDto(
      phase: DraftPhase.fromString(json['phase'] as String?),
      turnOrder: turnOrder,
      currentTurnIndex: json['currentTurnIndex'] ?? json['current_turn_index'] ?? 0,
      currentPickerRosterId: json['currentPickerRosterId'] ?? json['current_picker_roster_id'] ?? 0,
      slotPickDeadline: deadline,
      claimedSlots: claimedSlots,
      availableSlots: availableSlots,
      timeoutPolicy: DerbyTimeoutPolicy.fromString(json['timeoutPolicy'] ?? json['timeout_policy']),
      slotPickTimeSeconds: json['slotPickTimeSeconds'] ?? json['slot_pick_time_seconds'] ?? 60,
      teamCount: json['teamCount'] ?? json['team_count'] ?? turnOrder.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.value,
      'turnOrder': turnOrder,
      'currentTurnIndex': currentTurnIndex,
      'currentPickerRosterId': currentPickerRosterId,
      'slotPickDeadline': slotPickDeadline?.toIso8601String(),
      'claimedSlots': claimedSlots,
      'availableSlots': availableSlots,
      'timeoutPolicy': timeoutPolicy.value,
      'slotPickTimeSeconds': slotPickTimeSeconds,
      'teamCount': teamCount,
    };
  }
}

class QueueItemDto {
  final int id;
  final int draftId;
  final int rosterId;
  final int? playerId;
  final int queuePosition;
  final String? playerName;
  final String? playerPosition;
  final String? playerTeam;
  final int? pickAssetId;
  final int? pickAssetSeason;
  final int? pickAssetRound;
  final String? pickAssetDisplayName;

  const QueueItemDto({
    required this.id,
    required this.draftId,
    required this.rosterId,
    this.playerId,
    required this.queuePosition,
    this.playerName,
    this.playerPosition,
    this.playerTeam,
    this.pickAssetId,
    this.pickAssetSeason,
    this.pickAssetRound,
    this.pickAssetDisplayName,
  });

  factory QueueItemDto.fromJson(Map<String, dynamic> json) {
    return QueueItemDto(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? json['playerId'] as int?,
      queuePosition: json['queue_position'] as int? ?? json['queuePosition'] as int? ?? 0,
      playerName: json['player_name'] as String? ?? json['playerName'] as String?,
      playerPosition: json['player_position'] as String? ?? json['playerPosition'] as String?,
      playerTeam: json['player_team'] as String? ?? json['playerTeam'] as String?,
      pickAssetId: json['pick_asset_id'] as int? ?? json['pickAssetId'] as int?,
      pickAssetSeason: json['pick_asset_season'] as int? ?? json['pickAssetSeason'] as int?,
      pickAssetRound: json['pick_asset_round'] as int? ?? json['pickAssetRound'] as int?,
      pickAssetDisplayName: json['pick_asset_display_name'] as String? ?? json['pickAssetDisplayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'draft_id': draftId,
      'roster_id': rosterId,
      'player_id': playerId,
      'queue_position': queuePosition,
      'player_name': playerName,
      'player_position': playerPosition,
      'player_team': playerTeam,
      'pick_asset_id': pickAssetId,
      'pick_asset_season': pickAssetSeason,
      'pick_asset_round': pickAssetRound,
      'pick_asset_display_name': pickAssetDisplayName,
    };
  }
}
