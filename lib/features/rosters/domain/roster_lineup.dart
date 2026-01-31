/// Lineup slot positions
enum LineupSlot {
  qb('QB'),
  rb('RB'),
  wr('WR'),
  te('TE'),
  flex('FLEX'),
  superFlex('SUPER_FLEX'),
  recFlex('REC_FLEX'),
  k('K'),
  def('DEF'),
  dl('DL'),
  lb('LB'),
  db('DB'),
  idpFlex('IDP_FLEX'),
  bn('BN'),
  ir('IR'),
  taxi('TAXI');

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
      case LineupSlot.superFlex:
        return 'Super Flex';
      case LineupSlot.recFlex:
        return 'Rec Flex';
      case LineupSlot.k:
        return 'Kicker';
      case LineupSlot.def:
        return 'Defense/ST';
      case LineupSlot.dl:
        return 'Defensive Line';
      case LineupSlot.lb:
        return 'Linebacker';
      case LineupSlot.db:
        return 'Defensive Back';
      case LineupSlot.idpFlex:
        return 'IDP Flex';
      case LineupSlot.bn:
        return 'Bench';
      case LineupSlot.ir:
        return 'Injured Reserve';
      case LineupSlot.taxi:
        return 'Taxi Squad';
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
      case LineupSlot.superFlex:
        return ['QB', 'RB', 'WR', 'TE'].contains(pos);
      case LineupSlot.recFlex:
        return ['WR', 'TE'].contains(pos);
      case LineupSlot.k:
        return pos == 'K';
      case LineupSlot.def:
        return pos == 'DEF';
      case LineupSlot.dl:
        return pos == 'DL';
      case LineupSlot.lb:
        return pos == 'LB';
      case LineupSlot.db:
        return pos == 'DB';
      case LineupSlot.idpFlex:
        return ['DL', 'LB', 'DB'].contains(pos);
      case LineupSlot.bn:
      case LineupSlot.ir:
      case LineupSlot.taxi:
        return true; // Can hold any player
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
