class ScoringRuleDto {
  final String stat;
  final double multiplier;

  const ScoringRuleDto({required this.stat, required this.multiplier});

  factory ScoringRuleDto.fromJson(Map<String, dynamic> json) {
    return ScoringRuleDto(
      stat: json['stat'] as String? ?? '',
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'stat': stat, 'multiplier': multiplier};
}

class PlayerScoreDto {
  final int playerId;
  final int rosterId;
  final double actualPoints;
  final double projectedPoints;
  final String status;
  final DateTime? lastUpdated;

  const PlayerScoreDto({
    required this.playerId,
    required this.rosterId,
    required this.actualPoints,
    required this.projectedPoints,
    required this.status,
    this.lastUpdated,
  });

  factory PlayerScoreDto.fromJson(Map<String, dynamic> json) {
    return PlayerScoreDto(
      playerId: json['player_id'] as int? ?? json['playerId'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      actualPoints: (json['actual_points'] as num? ?? json['actualPoints'] as num?)?.toDouble() ?? 0,
      projectedPoints: (json['projected_points'] as num? ?? json['projectedPoints'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'not_started',
      lastUpdated: json['last_updated'] != null ? DateTime.tryParse(json['last_updated'].toString()) : json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'player_id': playerId,
    'roster_id': rosterId,
    'actual_points': actualPoints,
    'projected_points': projectedPoints,
    'status': status,
    if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
  };
}
