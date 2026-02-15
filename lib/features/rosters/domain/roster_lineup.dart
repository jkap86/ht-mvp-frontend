export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show LineupSlot;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension LineupSlotUI on LineupSlot {
  String get displayName => switch (this) {
    LineupSlot.qb => 'Quarterback',
    LineupSlot.rb => 'Running Back',
    LineupSlot.wr => 'Wide Receiver',
    LineupSlot.te => 'Tight End',
    LineupSlot.flex => 'Flex',
    LineupSlot.superFlex => 'Super Flex',
    LineupSlot.recFlex => 'Rec Flex',
    LineupSlot.k => 'Kicker',
    LineupSlot.def => 'Defense/ST',
    LineupSlot.dl => 'Defensive Line',
    LineupSlot.lb => 'Linebacker',
    LineupSlot.db => 'Defensive Back',
    LineupSlot.idpFlex => 'IDP Flex',
    LineupSlot.bn => 'Bench',
    LineupSlot.ir => 'Injured Reserve',
    LineupSlot.taxi => 'Taxi Squad',
  };

  /// Check if a player position can fill this slot
  bool canFill(String? position) {
    if (position == null) return false;
    final pos = position.toUpperCase();
    return switch (this) {
      LineupSlot.qb => pos == 'QB',
      LineupSlot.rb => pos == 'RB',
      LineupSlot.wr => pos == 'WR',
      LineupSlot.te => pos == 'TE',
      LineupSlot.flex => ['RB', 'WR', 'TE'].contains(pos),
      LineupSlot.superFlex => ['QB', 'RB', 'WR', 'TE'].contains(pos),
      LineupSlot.recFlex => ['WR', 'TE'].contains(pos),
      LineupSlot.k => pos == 'K',
      LineupSlot.def => pos == 'DEF',
      LineupSlot.dl => pos == 'DL',
      LineupSlot.lb => pos == 'LB',
      LineupSlot.db => pos == 'DB',
      LineupSlot.idpFlex => ['DL', 'LB', 'DB'].contains(pos),
      LineupSlot.bn || LineupSlot.ir || LineupSlot.taxi => true,
    };
  }
}

/// Lineup slots mapping player IDs to positions
class LineupSlots {
  final List<int> qb;
  final List<int> rb;
  final List<int> wr;
  final List<int> te;
  final List<int> flex;
  final List<int> superFlex;
  final List<int> recFlex;
  final List<int> k;
  final List<int> def;
  final List<int> dl;
  final List<int> lb;
  final List<int> db;
  final List<int> idpFlex;
  final List<int> bn;
  final List<int> ir;
  final List<int> taxi;

  LineupSlots({
    this.qb = const [],
    this.rb = const [],
    this.wr = const [],
    this.te = const [],
    this.flex = const [],
    this.superFlex = const [],
    this.recFlex = const [],
    this.k = const [],
    this.def = const [],
    this.dl = const [],
    this.lb = const [],
    this.db = const [],
    this.idpFlex = const [],
    this.bn = const [],
    this.ir = const [],
    this.taxi = const [],
  });

  /// Get all starter player IDs (non-bench, non-reserve)
  List<int> get starters => [
    ...qb, ...rb, ...wr, ...te,
    ...flex, ...superFlex, ...recFlex,
    ...k, ...def,
    ...dl, ...lb, ...db, ...idpFlex,
  ];

  /// Get all player IDs
  List<int> get allPlayers => [...starters, ...bn, ...ir, ...taxi];

  /// Check if a player is in the starting lineup
  bool isStarter(int playerId) => starters.contains(playerId);

  /// Check if a player is on the bench
  bool isBenched(int playerId) => bn.contains(playerId);

  /// Check if a player is on IR
  bool isOnIR(int playerId) => ir.contains(playerId);

  /// Check if a player is on taxi squad
  bool isOnTaxi(int playerId) => taxi.contains(playerId);

  /// Get the slot a player is in (null if not in lineup)
  LineupSlot? getPlayerSlot(int playerId) {
    if (qb.contains(playerId)) return LineupSlot.qb;
    if (rb.contains(playerId)) return LineupSlot.rb;
    if (wr.contains(playerId)) return LineupSlot.wr;
    if (te.contains(playerId)) return LineupSlot.te;
    if (flex.contains(playerId)) return LineupSlot.flex;
    if (superFlex.contains(playerId)) return LineupSlot.superFlex;
    if (recFlex.contains(playerId)) return LineupSlot.recFlex;
    if (k.contains(playerId)) return LineupSlot.k;
    if (def.contains(playerId)) return LineupSlot.def;
    if (dl.contains(playerId)) return LineupSlot.dl;
    if (lb.contains(playerId)) return LineupSlot.lb;
    if (db.contains(playerId)) return LineupSlot.db;
    if (idpFlex.contains(playerId)) return LineupSlot.idpFlex;
    if (bn.contains(playerId)) return LineupSlot.bn;
    if (ir.contains(playerId)) return LineupSlot.ir;
    if (taxi.contains(playerId)) return LineupSlot.taxi;
    return null;
  }

  factory LineupSlots.fromJson(Map<String, dynamic> json) {
    return LineupSlots(
      qb: (json['QB'] as List?)?.cast<int>() ?? [],
      rb: (json['RB'] as List?)?.cast<int>() ?? [],
      wr: (json['WR'] as List?)?.cast<int>() ?? [],
      te: (json['TE'] as List?)?.cast<int>() ?? [],
      flex: (json['FLEX'] as List?)?.cast<int>() ?? [],
      superFlex: (json['SUPER_FLEX'] as List?)?.cast<int>() ?? [],
      recFlex: (json['REC_FLEX'] as List?)?.cast<int>() ?? [],
      k: (json['K'] as List?)?.cast<int>() ?? [],
      def: (json['DEF'] as List?)?.cast<int>() ?? [],
      dl: (json['DL'] as List?)?.cast<int>() ?? [],
      lb: (json['LB'] as List?)?.cast<int>() ?? [],
      db: (json['DB'] as List?)?.cast<int>() ?? [],
      idpFlex: (json['IDP_FLEX'] as List?)?.cast<int>() ?? [],
      bn: (json['BN'] as List?)?.cast<int>() ?? [],
      ir: (json['IR'] as List?)?.cast<int>() ?? [],
      taxi: (json['TAXI'] as List?)?.cast<int>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'QB': qb,
      'RB': rb,
      'WR': wr,
      'TE': te,
      'FLEX': flex,
      'SUPER_FLEX': superFlex,
      'REC_FLEX': recFlex,
      'K': k,
      'DEF': def,
      'DL': dl,
      'LB': lb,
      'DB': db,
      'IDP_FLEX': idpFlex,
      'BN': bn,
      'IR': ir,
      'TAXI': taxi,
    };
  }

  /// Get the player list for a given slot
  List<int> _getSlotList(LineupSlot slot) {
    switch (slot) {
      case LineupSlot.qb: return qb;
      case LineupSlot.rb: return rb;
      case LineupSlot.wr: return wr;
      case LineupSlot.te: return te;
      case LineupSlot.flex: return flex;
      case LineupSlot.superFlex: return superFlex;
      case LineupSlot.recFlex: return recFlex;
      case LineupSlot.k: return k;
      case LineupSlot.def: return def;
      case LineupSlot.dl: return dl;
      case LineupSlot.lb: return lb;
      case LineupSlot.db: return db;
      case LineupSlot.idpFlex: return idpFlex;
      case LineupSlot.bn: return bn;
      case LineupSlot.ir: return ir;
      case LineupSlot.taxi: return taxi;
    }
  }

  /// Return a copy of the slot list with the given update applied
  List<int>? _updatedList(LineupSlot target, LineupSlot slot, List<int> newList) {
    return target == slot ? newList : null;
  }

  /// Returns a new LineupSlots with [playerId] removed from [from] and added to [to].
  LineupSlots withPlayerMoved(int playerId, LineupSlot from, LineupSlot to) {
    final fromList = List<int>.from(_getSlotList(from))..remove(playerId);
    final toList = List<int>.from(_getSlotList(to))..add(playerId);

    return copyWith(
      qb: _updatedList(LineupSlot.qb, from, fromList) ?? _updatedList(LineupSlot.qb, to, toList),
      rb: _updatedList(LineupSlot.rb, from, fromList) ?? _updatedList(LineupSlot.rb, to, toList),
      wr: _updatedList(LineupSlot.wr, from, fromList) ?? _updatedList(LineupSlot.wr, to, toList),
      te: _updatedList(LineupSlot.te, from, fromList) ?? _updatedList(LineupSlot.te, to, toList),
      flex: _updatedList(LineupSlot.flex, from, fromList) ?? _updatedList(LineupSlot.flex, to, toList),
      superFlex: _updatedList(LineupSlot.superFlex, from, fromList) ?? _updatedList(LineupSlot.superFlex, to, toList),
      recFlex: _updatedList(LineupSlot.recFlex, from, fromList) ?? _updatedList(LineupSlot.recFlex, to, toList),
      k: _updatedList(LineupSlot.k, from, fromList) ?? _updatedList(LineupSlot.k, to, toList),
      def: _updatedList(LineupSlot.def, from, fromList) ?? _updatedList(LineupSlot.def, to, toList),
      dl: _updatedList(LineupSlot.dl, from, fromList) ?? _updatedList(LineupSlot.dl, to, toList),
      lb: _updatedList(LineupSlot.lb, from, fromList) ?? _updatedList(LineupSlot.lb, to, toList),
      db: _updatedList(LineupSlot.db, from, fromList) ?? _updatedList(LineupSlot.db, to, toList),
      idpFlex: _updatedList(LineupSlot.idpFlex, from, fromList) ?? _updatedList(LineupSlot.idpFlex, to, toList),
      bn: _updatedList(LineupSlot.bn, from, fromList) ?? _updatedList(LineupSlot.bn, to, toList),
      ir: _updatedList(LineupSlot.ir, from, fromList) ?? _updatedList(LineupSlot.ir, to, toList),
      taxi: _updatedList(LineupSlot.taxi, from, fromList) ?? _updatedList(LineupSlot.taxi, to, toList),
    );
  }

  /// Returns a new LineupSlots with two players swapped between their slots.
  LineupSlots withSwap(int player1Id, LineupSlot slot1, int player2Id, LineupSlot slot2) {
    if (slot1 == slot2) {
      // Same slot type — just swap within the list
      final list = List<int>.from(_getSlotList(slot1));
      final idx1 = list.indexOf(player1Id);
      final idx2 = list.indexOf(player2Id);
      if (idx1 != -1 && idx2 != -1) {
        list[idx1] = player2Id;
        list[idx2] = player1Id;
      }
      return copyWith(
        qb: slot1 == LineupSlot.qb ? list : null,
        rb: slot1 == LineupSlot.rb ? list : null,
        wr: slot1 == LineupSlot.wr ? list : null,
        te: slot1 == LineupSlot.te ? list : null,
        flex: slot1 == LineupSlot.flex ? list : null,
        superFlex: slot1 == LineupSlot.superFlex ? list : null,
        recFlex: slot1 == LineupSlot.recFlex ? list : null,
        k: slot1 == LineupSlot.k ? list : null,
        def: slot1 == LineupSlot.def ? list : null,
        dl: slot1 == LineupSlot.dl ? list : null,
        lb: slot1 == LineupSlot.lb ? list : null,
        db: slot1 == LineupSlot.db ? list : null,
        idpFlex: slot1 == LineupSlot.idpFlex ? list : null,
        bn: slot1 == LineupSlot.bn ? list : null,
        ir: slot1 == LineupSlot.ir ? list : null,
        taxi: slot1 == LineupSlot.taxi ? list : null,
      );
    }

    // Different slot types — remove each from their slot, add to the other
    var list1 = List<int>.from(_getSlotList(slot1));
    var list2 = List<int>.from(_getSlotList(slot2));
    list1.remove(player1Id);
    list1.add(player2Id);
    list2.remove(player2Id);
    list2.add(player1Id);

    return copyWith(
      qb: _updatedList(LineupSlot.qb, slot1, list1) ?? _updatedList(LineupSlot.qb, slot2, list2),
      rb: _updatedList(LineupSlot.rb, slot1, list1) ?? _updatedList(LineupSlot.rb, slot2, list2),
      wr: _updatedList(LineupSlot.wr, slot1, list1) ?? _updatedList(LineupSlot.wr, slot2, list2),
      te: _updatedList(LineupSlot.te, slot1, list1) ?? _updatedList(LineupSlot.te, slot2, list2),
      flex: _updatedList(LineupSlot.flex, slot1, list1) ?? _updatedList(LineupSlot.flex, slot2, list2),
      superFlex: _updatedList(LineupSlot.superFlex, slot1, list1) ?? _updatedList(LineupSlot.superFlex, slot2, list2),
      recFlex: _updatedList(LineupSlot.recFlex, slot1, list1) ?? _updatedList(LineupSlot.recFlex, slot2, list2),
      k: _updatedList(LineupSlot.k, slot1, list1) ?? _updatedList(LineupSlot.k, slot2, list2),
      def: _updatedList(LineupSlot.def, slot1, list1) ?? _updatedList(LineupSlot.def, slot2, list2),
      dl: _updatedList(LineupSlot.dl, slot1, list1) ?? _updatedList(LineupSlot.dl, slot2, list2),
      lb: _updatedList(LineupSlot.lb, slot1, list1) ?? _updatedList(LineupSlot.lb, slot2, list2),
      db: _updatedList(LineupSlot.db, slot1, list1) ?? _updatedList(LineupSlot.db, slot2, list2),
      idpFlex: _updatedList(LineupSlot.idpFlex, slot1, list1) ?? _updatedList(LineupSlot.idpFlex, slot2, list2),
      bn: _updatedList(LineupSlot.bn, slot1, list1) ?? _updatedList(LineupSlot.bn, slot2, list2),
      ir: _updatedList(LineupSlot.ir, slot1, list1) ?? _updatedList(LineupSlot.ir, slot2, list2),
      taxi: _updatedList(LineupSlot.taxi, slot1, list1) ?? _updatedList(LineupSlot.taxi, slot2, list2),
    );
  }

  LineupSlots copyWith({
    List<int>? qb,
    List<int>? rb,
    List<int>? wr,
    List<int>? te,
    List<int>? flex,
    List<int>? superFlex,
    List<int>? recFlex,
    List<int>? k,
    List<int>? def,
    List<int>? dl,
    List<int>? lb,
    List<int>? db,
    List<int>? idpFlex,
    List<int>? bn,
    List<int>? ir,
    List<int>? taxi,
  }) {
    return LineupSlots(
      qb: qb ?? this.qb,
      rb: rb ?? this.rb,
      wr: wr ?? this.wr,
      te: te ?? this.te,
      flex: flex ?? this.flex,
      superFlex: superFlex ?? this.superFlex,
      recFlex: recFlex ?? this.recFlex,
      k: k ?? this.k,
      def: def ?? this.def,
      dl: dl ?? this.dl,
      lb: lb ?? this.lb,
      db: db ?? this.db,
      idpFlex: idpFlex ?? this.idpFlex,
      bn: bn ?? this.bn,
      ir: ir ?? this.ir,
      taxi: taxi ?? this.taxi,
    );
  }
}

/// A roster's lineup for a specific week
class RosterLineup {
  final int id;
  final int rosterId;
  final int season;
  final int week;
  final LineupSlots lineup;
  final double? totalPoints;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  RosterLineup({
    required this.id,
    required this.rosterId,
    required this.season,
    required this.week,
    required this.lineup,
    this.totalPoints,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RosterLineup.fromJson(Map<String, dynamic> json) {
    return RosterLineup(
      id: json['id'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      week: json['week'] as int? ?? 1,
      lineup: LineupSlots.fromJson((json['lineup'] as Map<String, dynamic>?) ?? {}),
      totalPoints: (json['total_points'] as num?)?.toDouble(),
      isLocked: json['is_locked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.utc(1970),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.utc(1970),
    );
  }

  RosterLineup copyWith({
    int? id,
    int? rosterId,
    int? season,
    int? week,
    LineupSlots? lineup,
    double? totalPoints,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RosterLineup(
      id: id ?? this.id,
      rosterId: rosterId ?? this.rosterId,
      season: season ?? this.season,
      week: week ?? this.week,
      lineup: lineup ?? this.lineup,
      totalPoints: totalPoints ?? this.totalPoints,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Default roster configuration
class RosterConfig {
  final int qb;
  final int rb;
  final int wr;
  final int te;
  final int flex;
  final int superFlex;
  final int recFlex;
  final int k;
  final int def;
  final int dl;
  final int lb;
  final int db;
  final int idpFlex;
  final int bn;
  final int ir;
  final int taxi;

  const RosterConfig({
    this.qb = 1,
    this.rb = 2,
    this.wr = 2,
    this.te = 1,
    this.flex = 1,
    this.superFlex = 0,
    this.recFlex = 0,
    this.k = 1,
    this.def = 1,
    this.dl = 0,
    this.lb = 0,
    this.db = 0,
    this.idpFlex = 0,
    this.bn = 6,
    this.ir = 0,
    this.taxi = 0,
  });

  int get totalStarters => qb + rb + wr + te + flex + superFlex + recFlex + k + def + dl + lb + db + idpFlex;
  int get totalRosterSize => totalStarters + bn + ir + taxi;

  factory RosterConfig.fromJson(Map<String, dynamic> json) {
    return RosterConfig(
      qb: json['QB'] as int? ?? 1,
      rb: json['RB'] as int? ?? 2,
      wr: json['WR'] as int? ?? 2,
      te: json['TE'] as int? ?? 1,
      flex: json['FLEX'] as int? ?? 1,
      superFlex: json['SUPER_FLEX'] as int? ?? 0,
      recFlex: json['REC_FLEX'] as int? ?? 0,
      k: json['K'] as int? ?? 1,
      def: json['DEF'] as int? ?? 1,
      dl: json['DL'] as int? ?? 0,
      lb: json['LB'] as int? ?? 0,
      db: json['DB'] as int? ?? 0,
      idpFlex: json['IDP_FLEX'] as int? ?? 0,
      bn: json['BN'] as int? ?? 6,
      ir: json['IR'] as int? ?? 0,
      taxi: json['TAXI'] as int? ?? 0,
    );
  }
}
