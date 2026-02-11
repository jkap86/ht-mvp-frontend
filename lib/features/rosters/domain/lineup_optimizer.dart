import '../domain/roster_player.dart';
import '../domain/roster_lineup.dart';

/// Configuration for a lineup slot
class SlotConfig {
  final String slotName;
  final List<String> eligiblePositions;
  final int count;

  const SlotConfig({
    required this.slotName,
    required this.eligiblePositions,
    required this.count,
  });
}

/// Result of lineup optimization
class OptimizedLineup {
  final LineupSlots slots;
  final double projectedPoints;

  const OptimizedLineup({
    required this.slots,
    required this.projectedPoints,
  });
}

/// Handles lineup optimization logic
class LineupOptimizer {
  /// Default slot configuration - standard fantasy football format
  static const defaultSlotOrder = [
    SlotConfig(slotName: 'QB', eligiblePositions: ['QB'], count: 1),
    SlotConfig(slotName: 'RB', eligiblePositions: ['RB'], count: 2),
    SlotConfig(slotName: 'WR', eligiblePositions: ['WR'], count: 2),
    SlotConfig(slotName: 'TE', eligiblePositions: ['TE'], count: 1),
    SlotConfig(slotName: 'K', eligiblePositions: ['K'], count: 1),
    SlotConfig(slotName: 'DEF', eligiblePositions: ['DEF'], count: 1),
    SlotConfig(slotName: 'FLEX', eligiblePositions: ['RB', 'WR', 'TE'], count: 1),
  ];

  final List<SlotConfig> slotOrder;

  const LineupOptimizer({this.slotOrder = defaultSlotOrder});

  /// Build optimizer from a league's RosterConfig.
  /// Slot order: specific positions first, then flex types from narrowest to widest.
  factory LineupOptimizer.fromConfig(RosterConfig config) {
    final slots = <SlotConfig>[];

    // Position-specific slots first (greedy fills these before flex)
    if (config.qb > 0) slots.add(SlotConfig(slotName: 'QB', eligiblePositions: const ['QB'], count: config.qb));
    if (config.rb > 0) slots.add(SlotConfig(slotName: 'RB', eligiblePositions: const ['RB'], count: config.rb));
    if (config.wr > 0) slots.add(SlotConfig(slotName: 'WR', eligiblePositions: const ['WR'], count: config.wr));
    if (config.te > 0) slots.add(SlotConfig(slotName: 'TE', eligiblePositions: const ['TE'], count: config.te));
    if (config.k > 0) slots.add(SlotConfig(slotName: 'K', eligiblePositions: const ['K'], count: config.k));
    if (config.def > 0) slots.add(SlotConfig(slotName: 'DEF', eligiblePositions: const ['DEF'], count: config.def));
    // IDP position-specific
    if (config.dl > 0) slots.add(SlotConfig(slotName: 'DL', eligiblePositions: const ['DL'], count: config.dl));
    if (config.lb > 0) slots.add(SlotConfig(slotName: 'LB', eligiblePositions: const ['LB'], count: config.lb));
    if (config.db > 0) slots.add(SlotConfig(slotName: 'DB', eligiblePositions: const ['DB'], count: config.db));

    // Flex slots last, narrowest to widest
    if (config.recFlex > 0) slots.add(SlotConfig(slotName: 'REC_FLEX', eligiblePositions: const ['WR', 'TE'], count: config.recFlex));
    if (config.idpFlex > 0) slots.add(SlotConfig(slotName: 'IDP_FLEX', eligiblePositions: const ['DL', 'LB', 'DB'], count: config.idpFlex));
    if (config.flex > 0) slots.add(SlotConfig(slotName: 'FLEX', eligiblePositions: const ['RB', 'WR', 'TE'], count: config.flex));
    if (config.superFlex > 0) slots.add(SlotConfig(slotName: 'SUPER_FLEX', eligiblePositions: const ['QB', 'RB', 'WR', 'TE'], count: config.superFlex));

    return LineupOptimizer(slotOrder: slots);
  }

  /// Calculate optimal projected points using greedy algorithm
  double calculateOptimalPoints(List<RosterPlayer> players) {
    if (players.isEmpty) return 0.0;

    final used = <int>{};
    var total = 0.0;

    for (final config in slotOrder) {
      final eligible = players
          .where((p) =>
              !used.contains(p.playerId) &&
              config.eligiblePositions.contains(p.position?.toUpperCase()))
          .toList()
        ..sort((a, b) =>
            (b.projectedPoints ?? 0).compareTo(a.projectedPoints ?? 0));

      for (var i = 0; i < config.count && i < eligible.length; i++) {
        used.add(eligible[i].playerId);
        total += eligible[i].projectedPoints ?? 0;
      }
    }

    return total;
  }

  /// Build an optimal lineup using greedy algorithm
  OptimizedLineup buildOptimalLineup(List<RosterPlayer> players) {
    final used = <int>{};
    final newLineup = <String, List<int>>{};
    // Initialize all slot types from the config
    for (final config in slotOrder) {
      newLineup[config.slotName] = [];
    }
    newLineup['BN'] = [];
    var totalPoints = 0.0;

    // Fill starter slots
    for (final config in slotOrder) {
      final eligible = players
          .where((p) =>
              !used.contains(p.playerId) &&
              config.eligiblePositions.contains(p.position?.toUpperCase()))
          .toList()
        ..sort((a, b) =>
            (b.projectedPoints ?? 0).compareTo(a.projectedPoints ?? 0));

      for (var i = 0; i < config.count && i < eligible.length; i++) {
        newLineup[config.slotName]!.add(eligible[i].playerId);
        used.add(eligible[i].playerId);
        totalPoints += eligible[i].projectedPoints ?? 0;
      }
    }

    // Put remaining players on bench
    for (final player in players) {
      if (!used.contains(player.playerId)) {
        newLineup['BN']!.add(player.playerId);
      }
    }

    return OptimizedLineup(
      slots: LineupSlots(
        qb: newLineup['QB'] ?? [],
        rb: newLineup['RB'] ?? [],
        wr: newLineup['WR'] ?? [],
        te: newLineup['TE'] ?? [],
        flex: newLineup['FLEX'] ?? [],
        superFlex: newLineup['SUPER_FLEX'] ?? [],
        recFlex: newLineup['REC_FLEX'] ?? [],
        k: newLineup['K'] ?? [],
        def: newLineup['DEF'] ?? [],
        dl: newLineup['DL'] ?? [],
        lb: newLineup['LB'] ?? [],
        db: newLineup['DB'] ?? [],
        idpFlex: newLineup['IDP_FLEX'] ?? [],
        bn: newLineup['BN']!,
      ),
      projectedPoints: totalPoints,
    );
  }

  /// Get the default slot count for a given slot type
  static int getSlotCount(LineupSlot slot) {
    switch (slot) {
      case LineupSlot.qb:
        return 1;
      case LineupSlot.rb:
        return 2;
      case LineupSlot.wr:
        return 2;
      case LineupSlot.te:
        return 1;
      case LineupSlot.flex:
        return 1;
      case LineupSlot.superFlex:
        return 0;
      case LineupSlot.recFlex:
        return 0;
      case LineupSlot.k:
        return 1;
      case LineupSlot.def:
        return 1;
      case LineupSlot.dl:
      case LineupSlot.lb:
      case LineupSlot.db:
      case LineupSlot.idpFlex:
        return 0;
      case LineupSlot.bn:
      case LineupSlot.ir:
      case LineupSlot.taxi:
        return 99; // unlimited
    }
  }
}
