/// Represents a pending league invitation
class LeagueInvitation {
  final int id;
  final int leagueId;
  final String leagueName;
  final String leagueSeason;
  final String leagueMode;
  final String invitedByUsername;
  final int memberCount;
  final int totalRosters;
  final String? message;
  final DateTime createdAt;
  final DateTime expiresAt;

  LeagueInvitation({
    required this.id,
    required this.leagueId,
    required this.leagueName,
    required this.leagueSeason,
    required this.leagueMode,
    required this.invitedByUsername,
    required this.memberCount,
    required this.totalRosters,
    this.message,
    required this.createdAt,
    required this.expiresAt,
  });

  factory LeagueInvitation.fromJson(Map<String, dynamic> json) {
    return LeagueInvitation(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      leagueName: json['league_name'] as String? ?? '',
      leagueSeason: json['league_season']?.toString() ?? '',
      leagueMode: json['league_mode'] as String? ?? 'redraft',
      invitedByUsername: json['invited_by_username'] as String? ?? 'Unknown',
      memberCount: json['member_count'] as int? ?? 0,
      totalRosters: json['total_rosters'] as int? ?? 12,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.utc(1970)
          : DateTime.utc(1970),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.utc(1970)
          : DateTime.utc(1970),
    );
  }

  /// Check if invitation is expiring within 24 hours
  bool get isExpiringSoon {
    final hoursUntilExpiry = expiresAt.difference(DateTime.now()).inHours;
    return hoursUntilExpiry <= 24 && hoursUntilExpiry > 0;
  }

  /// Check if invitation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get formatted member count string
  String get memberCountDisplay => '$memberCount/$totalRosters';

  /// Format expiry time
  String get expiryDisplay {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return 'Expires in ${diff.inDays}d';
    if (diff.inHours > 0) return 'Expires in ${diff.inHours}h';
    return 'Expires soon';
  }
}

/// Represents a user search result when inviting
class UserSearchResult {
  final String id;
  final String username;
  final bool hasPendingInvite;
  final bool isMember;

  UserSearchResult({
    required this.id,
    required this.username,
    required this.hasPendingInvite,
    required this.isMember,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      hasPendingInvite: json['has_pending_invite'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? false,
    );
  }

  /// Check if user can be invited
  bool get canInvite => !hasPendingInvite && !isMember;
}
