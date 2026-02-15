import '../../../core/utils/date_sentinel.dart';

class DraftPickPayload {
  final int id;
  final int draftId;
  final int pickNumber;
  final int round;
  final int pickInRound;
  final int rosterId;
  final int playerId;
  final bool isAutoPick;
  final DateTime pickedAt;
  final String? playerName;
  final String? playerPosition;
  final String? playerTeam;
  final String? username;

  const DraftPickPayload({
    required this.id,
    required this.draftId,
    required this.pickNumber,
    required this.round,
    required this.pickInRound,
    required this.rosterId,
    required this.playerId,
    required this.isAutoPick,
    required this.pickedAt,
    this.playerName,
    this.playerPosition,
    this.playerTeam,
    this.username,
  });

  factory DraftPickPayload.fromJson(Map<String, dynamic> json) {
    return DraftPickPayload(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      pickNumber: json['pick_number'] as int? ?? json['pickNumber'] as int? ?? 0,
      round: json['round'] as int? ?? 0,
      pickInRound: json['pick_in_round'] as int? ?? json['pickInRound'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? json['playerId'] as int? ?? 0,
      isAutoPick: json['is_auto_pick'] as bool? ?? json['isAutoPick'] as bool? ?? false,
      pickedAt: DateTime.tryParse(json['picked_at']?.toString() ?? json['pickedAt']?.toString() ?? '') ?? epochUtc(),
      playerName: json['player_name'] as String? ?? json['playerName'] as String?,
      playerPosition: json['player_position'] as String? ?? json['playerPosition'] as String?,
      playerTeam: json['player_team'] as String? ?? json['playerTeam'] as String?,
      username: json['username'] as String?,
    );
  }
}

class DraftStartedPayload {
  final Map<String, dynamic> draft;

  const DraftStartedPayload({required this.draft});

  factory DraftStartedPayload.fromJson(Map<String, dynamic> json) {
    return DraftStartedPayload(draft: json);
  }
}

class NextPickPayload {
  final int pickNumber;
  final int round;
  final int pickInRound;
  final int rosterId;
  final String? username;
  final String? teamName;
  final DateTime? pickDeadline;
  final int? timeRemainingMs;
  final Map<int, double>? chessClocks;

  const NextPickPayload({
    required this.pickNumber,
    required this.round,
    required this.pickInRound,
    required this.rosterId,
    this.username,
    this.teamName,
    this.pickDeadline,
    this.timeRemainingMs,
    this.chessClocks,
  });

  factory NextPickPayload.fromJson(Map<String, dynamic> json) {
    // Parse chess clocks map: { rosterId: remainingSeconds }
    Map<int, double>? chessClocks;
    final clocksRaw = json['chessClocks'] ?? json['chess_clocks'];
    if (clocksRaw is Map) {
      chessClocks = {};
      for (final entry in clocksRaw.entries) {
        final key = entry.key is int ? entry.key as int : int.tryParse(entry.key.toString());
        final value = entry.value is num ? (entry.value as num).toDouble() : double.tryParse(entry.value.toString());
        if (key != null && value != null) {
          chessClocks[key] = value;
        }
      }
    }

    return NextPickPayload(
      pickNumber: json['pickNumber'] as int? ?? json['pick_number'] as int? ?? 0,
      round: json['round'] as int? ?? 0,
      pickInRound: json['pickInRound'] as int? ?? json['pick_in_round'] as int? ?? 0,
      rosterId: json['rosterId'] as int? ?? json['roster_id'] as int? ?? 0,
      username: json['username'] as String?,
      teamName: json['teamName'] as String? ?? json['team_name'] as String?,
      pickDeadline: json['pickDeadline'] != null
          ? DateTime.tryParse(json['pickDeadline'].toString())
          : null,
      timeRemainingMs: json['timeRemainingMs'] as int? ?? json['time_remaining_ms'] as int?,
      chessClocks: chessClocks,
    );
  }
}

class PickUndonePayload {
  final Map<String, dynamic> pick;
  final Map<String, dynamic> draft;

  const PickUndonePayload({required this.pick, required this.draft});

  factory PickUndonePayload.fromJson(Map<String, dynamic> json) {
    return PickUndonePayload(
      pick: json['pick'] as Map<String, dynamic>? ?? {},
      draft: json['draft'] as Map<String, dynamic>? ?? {},
    );
  }
}

class DraftUserJoinedPayload {
  final String userId;
  final String username;

  const DraftUserJoinedPayload({required this.userId, required this.username});

  factory DraftUserJoinedPayload.fromJson(Map<String, dynamic> json) {
    return DraftUserJoinedPayload(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}

class DraftUserLeftPayload {
  final String userId;
  final String username;

  const DraftUserLeftPayload({required this.userId, required this.username});

  factory DraftUserLeftPayload.fromJson(Map<String, dynamic> json) {
    return DraftUserLeftPayload(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}

class DraftAutodraftToggledPayload {
  final int rosterId;
  final bool enabled;
  final bool forced;

  const DraftAutodraftToggledPayload({required this.rosterId, required this.enabled, this.forced = false});

  factory DraftAutodraftToggledPayload.fromJson(Map<String, dynamic> json) {
    return DraftAutodraftToggledPayload(
      rosterId: json['rosterId'] as int? ?? json['roster_id'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      forced: json['forced'] as bool? ?? false,
    );
  }
}

class OvernightPauseStartedPayload {
  final DateTime startTime;
  final DateTime resumeTime;
  final String reason;

  const OvernightPauseStartedPayload({required this.startTime, required this.resumeTime, required this.reason});

  factory OvernightPauseStartedPayload.fromJson(Map<String, dynamic> json) {
    return OvernightPauseStartedPayload(
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? epochUtc(),
      resumeTime: DateTime.tryParse(json['resumeTime']?.toString() ?? '') ?? epochUtc(),
      reason: json['reason'] as String? ?? '',
    );
  }
}

class OvernightPauseEndedPayload {
  final DateTime resumedAt;

  const OvernightPauseEndedPayload({required this.resumedAt});

  factory OvernightPauseEndedPayload.fromJson(Map<String, dynamic> json) {
    return OvernightPauseEndedPayload(
      resumedAt: DateTime.tryParse(json['resumedAt']?.toString() ?? '') ?? epochUtc(),
    );
  }
}

class DraftPickTradedPayload {
  final int pickAssetId;
  final int season;
  final int round;
  final int previousOwnerRosterId;
  final int newOwnerRosterId;
  final int tradeId;

  const DraftPickTradedPayload({
    required this.pickAssetId,
    required this.season,
    required this.round,
    required this.previousOwnerRosterId,
    required this.newOwnerRosterId,
    required this.tradeId,
  });

  factory DraftPickTradedPayload.fromJson(Map<String, dynamic> json) {
    return DraftPickTradedPayload(
      pickAssetId: json['pickAssetId'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      round: json['round'] as int? ?? 0,
      previousOwnerRosterId: json['previousOwnerRosterId'] as int? ?? 0,
      newOwnerRosterId: json['newOwnerRosterId'] as int? ?? 0,
      tradeId: json['tradeId'] as int? ?? 0,
    );
  }
}

// --- Derby payloads ---

class DerbySlotPickedPayload {
  final int rosterId;
  final int slotNumber;
  final int? nextPickerRosterId;
  final DateTime? deadline;
  final List<int> remainingSlots;

  const DerbySlotPickedPayload({
    required this.rosterId,
    required this.slotNumber,
    this.nextPickerRosterId,
    this.deadline,
    required this.remainingSlots,
  });

  factory DerbySlotPickedPayload.fromJson(Map<String, dynamic> json) {
    return DerbySlotPickedPayload(
      rosterId: json['rosterId'] as int? ?? 0,
      slotNumber: json['slotNumber'] as int? ?? 0,
      nextPickerRosterId: json['nextPickerRosterId'] as int?,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      remainingSlots: (json['remainingSlots'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }
}

class DerbyTurnChangedPayload {
  final int currentPickerRosterId;
  final DateTime deadline;
  final String reason;

  const DerbyTurnChangedPayload({
    required this.currentPickerRosterId,
    required this.deadline,
    required this.reason,
  });

  factory DerbyTurnChangedPayload.fromJson(Map<String, dynamic> json) {
    return DerbyTurnChangedPayload(
      currentPickerRosterId: json['currentPickerRosterId'] as int? ?? 0,
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ?? epochUtc(),
      reason: json['reason'] as String? ?? '',
    );
  }
}

class DerbyPhaseTransitionPayload {
  final String phase;
  final List<Map<String, dynamic>>? draftOrder;

  const DerbyPhaseTransitionPayload({required this.phase, this.draftOrder});

  factory DerbyPhaseTransitionPayload.fromJson(Map<String, dynamic> json) {
    return DerbyPhaseTransitionPayload(
      phase: json['phase'] as String? ?? '',
      draftOrder: (json['draftOrder'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
    );
  }
}
