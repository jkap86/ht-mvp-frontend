/// Types of notifications that can be received
enum NotificationType {
  tradePending('trade_pending', 'Trade awaiting your vote'),
  tradeAccepted('trade_accepted', 'Your trade was accepted'),
  tradeRejected('trade_rejected', 'Your trade was rejected'),
  tradeCompleted('trade_completed', 'Trade completed'),
  draftStarting('draft_starting', 'Draft begins soon'),
  draftStarted('draft_started', 'Draft has started'),
  draftPick('draft_pick', 'Your pick in draft'),
  waiverProcessed('waiver_processed', 'Waiver results available'),
  waiverSuccess('waiver_success', 'Waiver claim successful'),
  waiverFailed('waiver_failed', 'Waiver claim failed'),
  scoresUpdated('scores_updated', 'Player scores updated'),
  weekFinalized('week_finalized', 'Week finalized'),
  messageReceived('message_received', 'New league chat message'),
  leagueInvite('league_invite', 'League invitation received'),
  invitationReceived('invitation_received', 'League invitation received'),
  matchupResult('matchup_result', 'Matchup result');

  final String value;
  final String description;

  const NotificationType(this.value, this.description);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => NotificationType.messageReceived,
    );
  }
}

/// A notification to be displayed to the user
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final int? leagueId;
  final String? leagueName;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.leagueId,
    this.leagueName,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'message_received'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      leagueId: json['league_id'] as int?,
      leagueName: json['league_name'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'body': body,
      'league_id': leagueId,
      'league_name': leagueName,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    int? leagueId,
    String? leagueName,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      leagueId: leagueId ?? this.leagueId,
      leagueName: leagueName ?? this.leagueName,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get the navigation route for this notification
  String? get navigationRoute {
    if (leagueId == null) return null;

    switch (type) {
      case NotificationType.tradePending:
      case NotificationType.tradeAccepted:
      case NotificationType.tradeRejected:
      case NotificationType.tradeCompleted:
        final tradeId = data?['trade_id'];
        if (tradeId != null) {
          return '/leagues/$leagueId/trades/$tradeId';
        }
        return '/leagues/$leagueId/trades';

      case NotificationType.draftStarting:
      case NotificationType.draftStarted:
      case NotificationType.draftPick:
        final draftId = data?['draft_id'];
        if (draftId != null) {
          return '/leagues/$leagueId/drafts/$draftId';
        }
        return '/leagues/$leagueId';

      case NotificationType.waiverProcessed:
      case NotificationType.waiverSuccess:
      case NotificationType.waiverFailed:
        return '/leagues/$leagueId/team';

      case NotificationType.scoresUpdated:
      case NotificationType.weekFinalized:
        return '/leagues/$leagueId/matchups';

      case NotificationType.messageReceived:
        return '/leagues/$leagueId';

      case NotificationType.leagueInvite:
      case NotificationType.invitationReceived:
        return '/leagues';

      case NotificationType.matchupResult:
        final matchupId = data?['matchup_id'];
        if (matchupId != null) {
          return '/leagues/$leagueId/matchups/$matchupId';
        }
        return '/leagues/$leagueId/matchups';
    }
  }
}
