/// Lineup slot positions
enum LineupSlot {
  qb('QB'),
  rb('RB'),
  wr('WR'),
  te('TE'),
  flex('FLEX'),
  k('K'),
  def('DEF'),
  bn('BN');

  final String code;
  const LineupSlot(this.code);

  static LineupSlot? fromCode(String? code) {
    if (code == null) return null;
    return LineupSlot.values.where((s) => s.code == code.toUpperCase()).firstOrNull;
  }

  String get displayName {
    switch (this) {
      case LineupSlot.qb:
        return 'Quarterback';
      case LineupSlot.rb:
        return 'Running Back';
      case LineupSlot.wr:
        return 'Wide Receiver';
      case LineupSlot.te:
        return 'Tight End';
      case LineupSlot.flex:
        return 'Flex';
      case LineupSlot.k:
        return 'Kicker';
      case LineupSlot.def:
        return 'Defense/ST';
      case LineupSlot.bn:
        return 'Bench';
    }
  }

  /// Check if a player position can fill this slot
  bool canFill(String? position) {
    if (position == null) return false;
    final pos = position.toUpperCase();
    switch (this) {
      case LineupSlot.qb:
        return pos == 'QB';
      case LineupSlot.rb:
        return pos == 'RB';
      case LineupSlot.wr:
        return pos == 'WR';
      case LineupSlot.te:
        return pos == 'TE';
      case LineupSlot.flex:
        return ['RB', 'WR', 'TE'].contains(pos);
      case LineupSlot.k:
        return pos == 'K';
      case LineupSlot.def:
        return pos == 'DEF';
      case LineupSlot.bn:
        return true; // Bench can hold anyone
    }
  }
}

/// Lineup slots mapping player IDs to positions
class LineupSlots {
  final List<int> qb;
  final List<int> rb;
  final List<int> wr;
  final List<int> te;
  final List<int> flex;
  final List<int> k;
  final List<int> def;
  final List<int> bn;

  LineupSlots({
    this.qb = const [],
    this.rb = const [],
    this.wr = const [],
    this.te = const [],
    this.flex = const [],
    this.k = const [],
    this.def = const [],
    this.bn = const [],
  });

  /// Get all starter player IDs (non-bench)
  List<int> get starters => [...qb, ...rb, ...wr, ...te, ...flex, ...k, ...def];

  /// Get all player IDs
  List<int> get allPlayers => [...starters, ...bn];

  /// Check if a player is in the starting lineup
  bool isStarter(int playerId) => starters.contains(playerId);

  /// Check if a player is on the bench
  bool isBenched(int playerId) => bn.contains(playerId);

  /// Get the slot a player is in (null if not in lineup)
  LineupSlot? getPlayerSlot(int playerId) {
    if (qb.contains(playerId)) return LineupSlot.qb;
    if (rb.contains(playerId)) return LineupSlot.rb;
    if (wr.contains(playerId)) return LineupSlot.wr;
    if (te.contains(playerId)) return LineupSlot.te;
    if (flex.contains(playerId)) return LineupSlot.flex;
    if (k.contains(playerId)) return LineupSlot.k;
    if (def.contains(playerId)) return LineupSlot.def;
    if (bn.contains(playerId)) return LineupSlot.bn;
    return null;
  }

  factory LineupSlots.fromJson(Map<String, dynamic> json) {
    return LineupSlots(
      qb: (json['QB'] as List?)?.cast<int>() ?? [],
      rb: (json['RB'] as List?)?.cast<int>() ?? [],
      wr: (json['WR'] as List?)?.cast<int>() ?? [],
      te: (json['TE'] as List?)?.cast<int>() ?? [],
      flex: (json['FLEX'] as List?)?.cast<int>() ?? [],
      k: (json['K'] as List?)?.cast<int>() ?? [],
      def: (json['DEF'] as List?)?.cast<int>() ?? [],
      bn: (json['BN'] as List?)?.cast<int>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'QB': qb,
      'RB': rb,
      'WR': wr,
      'TE': te,
      'FLEX': flex,
      'K': k,
      'DEF': def,
      'BN': bn,
    };
  }

  LineupSlots copyWith({
    List<int>? qb,
    List<int>? rb,
    List<int>? wr,
    List<int>? te,
    List<int>? flex,
    List<int>? k,
    List<int>? def,
    List<int>? bn,
  }) {
    return LineupSlots(
      qb: qb ?? this.qb,
      rb: rb ?? this.rb,
      wr: wr ?? this.wr,
      te: te ?? this.te,
      flex: flex ?? this.flex,
      k: k ?? this.k,
      def: def ?? this.def,
      bn: bn ?? this.bn,
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
      season: json['season'] as int? ?? DateTime.now().year,
      week: json['week'] as int? ?? 1,
      lineup: LineupSlots.fromJson((json['lineup'] as Map<String, dynamic>?) ?? {}),
      totalPoints: (json['total_points'] as num?)?.toDouble(),
      isLocked: json['is_locked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
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
  final int k;
  final int def;
  final int bn;

  const RosterConfig({
    this.qb = 1,
    this.rb = 2,
    this.wr = 2,
    this.te = 1,
    this.flex = 1,
    this.k = 1,
    this.def = 1,
    this.bn = 6,
  });

  int get totalStarters => qb + rb + wr + te + flex + k + def;
  int get totalRosterSize => totalStarters + bn;

  factory RosterConfig.fromJson(Map<String, dynamic> json) {
    return RosterConfig(
      qb: json['QB'] as int? ?? 1,
      rb: json['RB'] as int? ?? 2,
      wr: json['WR'] as int? ?? 2,
      te: json['TE'] as int? ?? 1,
      flex: json['FLEX'] as int? ?? 1,
      k: json['K'] as int? ?? 1,
      def: json['DEF'] as int? ?? 1,
      bn: json['BN'] as int? ?? 6,
    );
  }
}
