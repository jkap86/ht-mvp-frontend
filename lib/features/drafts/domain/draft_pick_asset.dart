/// Represents a draft pick asset that can be traded.
///
/// A pick asset is distinct from a DraftPick - it represents ownership
/// of a future or current draft slot, while DraftPick represents an
/// actual selection that has been made.
class DraftPickAsset {
  final int id;
  final int leagueId;
  final int draftId;
  final int season;
  final int round;
  final int originalRosterId;
  final int currentOwnerRosterId;
  final int? originalPickPosition;

  // Enriched fields from API (optional, for display purposes)
  final String? originalTeamName;
  final String? currentOwnerTeamName;
  final String? originalUsername;
  final String? currentOwnerUsername;

  // Indicates if this pick asset has been drafted in a vet draft
  final bool isDraftedInVetDraft;

  DraftPickAsset({
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

  /// Whether this pick has been traded away from its original owner
  bool get isTraded => originalRosterId != currentOwnerRosterId;

  /// Display name for UI (e.g., "2025 1.03" or "2025 1.03 (Team A's)")
  String get displayName {
    // For future picks without known position, show just round
    if (originalPickPosition == null) {
      final base = '$season Rd $round';
      if (isTraded && originalTeamName != null) {
        return "$base ($originalTeamName's)";
      }
      if (isTraded && originalUsername != null) {
        return "$base ($originalUsername's)";
      }
      return base;
    }

    // Format: "2025 1.03" where 1 is round, 03 is pick position
    final pickNum = originalPickPosition.toString().padLeft(2, '0');
    final base = '$season $round.$pickNum';
    if (isTraded && originalTeamName != null) {
      return "$base ($originalTeamName's)";
    }
    if (isTraded && originalUsername != null) {
      return "$base ($originalUsername's)";
    }
    return base;
  }

  /// Short display name without team info (e.g., "2025 Rd 1")
  String get shortDisplayName => '$season Rd $round';

  /// Description of pick origin for tooltips
  String? get originDescription {
    if (!isTraded) return null;
    if (originalTeamName != null) {
      return "Originally $originalTeamName's pick";
    }
    if (originalUsername != null) {
      return "Originally $originalUsername's pick";
    }
    return 'Traded pick';
  }

  /// Sort key for ordering pick assets by value (lower is better/earlier)
  /// Format: season * 100 + round (e.g., 2025 Rd 1 = 202501, 2025 Rd 2 = 202502)
  int get sortKey => season * 100 + round;

  factory DraftPickAsset.fromJson(Map<String, dynamic> json) {
    return DraftPickAsset(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? json['leagueId'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      season: json['season'] as int? ?? DateTime.now().year,
      round: json['round'] as int? ?? 1,
      originalRosterId: json['original_roster_id'] as int? ??
          json['originalRosterId'] as int? ?? 0,
      currentOwnerRosterId: json['current_owner_roster_id'] as int? ??
          json['currentOwnerRosterId'] as int? ?? 0,
      originalPickPosition: json['original_pick_position'] as int? ??
          json['originalPickPosition'] as int?,
      originalTeamName: json['original_team_name'] as String? ??
          json['originalTeamName'] as String?,
      currentOwnerTeamName: json['current_owner_team_name'] as String? ??
          json['currentOwnerTeamName'] as String?,
      originalUsername: json['original_username'] as String? ??
          json['originalUsername'] as String?,
      currentOwnerUsername: json['current_owner_username'] as String? ??
          json['currentOwnerUsername'] as String?,
      isDraftedInVetDraft: json['is_drafted_in_vet_draft'] as bool? ??
          json['isDraftedInVetDraft'] as bool? ?? false,
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

  DraftPickAsset copyWith({
    int? id,
    int? leagueId,
    int? draftId,
    int? season,
    int? round,
    int? originalRosterId,
    int? currentOwnerRosterId,
    int? originalPickPosition,
    String? originalTeamName,
    String? currentOwnerTeamName,
    String? originalUsername,
    String? currentOwnerUsername,
    bool? isDraftedInVetDraft,
  }) {
    return DraftPickAsset(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      draftId: draftId ?? this.draftId,
      season: season ?? this.season,
      round: round ?? this.round,
      originalRosterId: originalRosterId ?? this.originalRosterId,
      currentOwnerRosterId: currentOwnerRosterId ?? this.currentOwnerRosterId,
      originalPickPosition: originalPickPosition ?? this.originalPickPosition,
      originalTeamName: originalTeamName ?? this.originalTeamName,
      currentOwnerTeamName: currentOwnerTeamName ?? this.currentOwnerTeamName,
      originalUsername: originalUsername ?? this.originalUsername,
      currentOwnerUsername: currentOwnerUsername ?? this.currentOwnerUsername,
      isDraftedInVetDraft: isDraftedInVetDraft ?? this.isDraftedInVetDraft,
    );
  }

  @override
  String toString() {
    return 'DraftPickAsset(id: $id, season: $season, round: $round, isTraded: $isTraded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DraftPickAsset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
