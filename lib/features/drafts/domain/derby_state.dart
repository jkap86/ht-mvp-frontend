import 'draft_phase.dart';

/// Timeout policy options for derby phase
enum DerbyTimeoutPolicy {
  autoRandomSlot('AUTO_RANDOM_SLOT'),
  pushBackOne('PUSH_BACK_ONE'),
  pushToEnd('PUSH_TO_END');

  final String value;
  const DerbyTimeoutPolicy(this.value);

  static DerbyTimeoutPolicy fromString(String? policy) {
    if (policy == null) return DerbyTimeoutPolicy.autoRandomSlot;
    return DerbyTimeoutPolicy.values.firstWhere(
      (p) => p.value == policy,
      orElse: () => DerbyTimeoutPolicy.autoRandomSlot,
    );
  }

  String get displayName {
    switch (this) {
      case DerbyTimeoutPolicy.autoRandomSlot:
        return 'Auto-assign random slot';
      case DerbyTimeoutPolicy.pushBackOne:
        return 'Move back one position';
      case DerbyTimeoutPolicy.pushToEnd:
        return 'Move to end of order';
    }
  }
}

/// State for derby draft order mode
class DerbyState {
  final DraftPhase phase;
  final List<int> turnOrder;
  final int currentTurnIndex;
  final int currentPickerRosterId;
  final DateTime? slotPickDeadline;
  final Map<int, int> claimedSlots; // slotNumber -> rosterId
  final List<int> availableSlots;
  final DerbyTimeoutPolicy timeoutPolicy;
  final int slotPickTimeSeconds;
  final int teamCount;

  const DerbyState({
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

  factory DerbyState.fromJson(Map<String, dynamic> json) {
    // Parse claimed slots with type safety
    final rawClaimedSlots = json['claimedSlots'] ?? json['claimed_slots'] ?? {};
    final Map<int, int> claimedSlots = {};
    if (rawClaimedSlots is Map) {
      for (final entry in rawClaimedSlots.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = entry.value is int ? entry.value : int.tryParse(entry.value.toString());
        if (key != null && value != null) {
          claimedSlots[key] = value;
        }
      }
    }

    // Parse turn order
    final rawTurnOrder = json['turnOrder'] ?? json['turn_order'] ?? [];
    final List<int> turnOrder = [];
    if (rawTurnOrder is List) {
      for (final item in rawTurnOrder) {
        final value = item is int ? item : int.tryParse(item.toString());
        if (value != null) {
          turnOrder.add(value);
        }
      }
    }

    // Parse available slots
    final rawAvailableSlots = json['availableSlots'] ?? json['available_slots'] ?? [];
    final List<int> availableSlots = [];
    if (rawAvailableSlots is List) {
      for (final item in rawAvailableSlots) {
        final value = item is int ? item : int.tryParse(item.toString());
        if (value != null) {
          availableSlots.add(value);
        }
      }
    }

    // Parse deadline
    DateTime? deadline;
    final rawDeadline = json['slotPickDeadline'] ?? json['slot_pick_deadline'];
    if (rawDeadline != null && rawDeadline is String && rawDeadline.isNotEmpty) {
      deadline = DateTime.tryParse(rawDeadline);
    }

    return DerbyState(
      phase: DraftPhase.fromString(json['phase'] as String?),
      turnOrder: turnOrder,
      currentTurnIndex: json['currentTurnIndex'] ?? json['current_turn_index'] ?? 0,
      currentPickerRosterId: json['currentPickerRosterId'] ?? json['current_picker_roster_id'] ?? 0,
      slotPickDeadline: deadline,
      claimedSlots: claimedSlots,
      availableSlots: availableSlots,
      timeoutPolicy: DerbyTimeoutPolicy.fromString(
        json['timeoutPolicy'] ?? json['timeout_policy'],
      ),
      slotPickTimeSeconds: json['slotPickTimeSeconds'] ?? json['slot_pick_time_seconds'] ?? 60,
      teamCount: json['teamCount'] ?? json['team_count'] ?? turnOrder.length,
    );
  }

  /// Check if derby is complete (all slots claimed)
  bool get isComplete => claimedSlots.length >= teamCount;

  /// Get the roster ID that claimed a specific slot
  int? getRosterForSlot(int slotNumber) => claimedSlots[slotNumber];

  /// Check if a specific slot is available
  bool isSlotAvailable(int slotNumber) => availableSlots.contains(slotNumber);

  /// Check if a specific roster has already claimed a slot
  bool hasRosterClaimed(int rosterId) => claimedSlots.values.contains(rosterId);

  /// Get the slot claimed by a specific roster (if any)
  int? getSlotForRoster(int rosterId) {
    for (final entry in claimedSlots.entries) {
      if (entry.value == rosterId) {
        return entry.key;
      }
    }
    return null;
  }

  DerbyState copyWith({
    DraftPhase? phase,
    List<int>? turnOrder,
    int? currentTurnIndex,
    int? currentPickerRosterId,
    DateTime? slotPickDeadline,
    Map<int, int>? claimedSlots,
    List<int>? availableSlots,
    DerbyTimeoutPolicy? timeoutPolicy,
    int? slotPickTimeSeconds,
    int? teamCount,
  }) {
    return DerbyState(
      phase: phase ?? this.phase,
      turnOrder: turnOrder ?? this.turnOrder,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      currentPickerRosterId: currentPickerRosterId ?? this.currentPickerRosterId,
      slotPickDeadline: slotPickDeadline ?? this.slotPickDeadline,
      claimedSlots: claimedSlots ?? this.claimedSlots,
      availableSlots: availableSlots ?? this.availableSlots,
      timeoutPolicy: timeoutPolicy ?? this.timeoutPolicy,
      slotPickTimeSeconds: slotPickTimeSeconds ?? this.slotPickTimeSeconds,
      teamCount: teamCount ?? this.teamCount,
    );
  }
}
