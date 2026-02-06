/// Dashboard summary returned from the API
class DashboardSummary {
  final DraftInfo draft;
  final AuctionInfo auction;
  final WaiverInfo waivers;
  final MatchupInfo? matchup;
  final int pendingTrades;
  final int activeWaiverClaims;
  final int unreadChatMessages;
  final List<Announcement> announcements;

  DashboardSummary({
    required this.draft,
    required this.auction,
    required this.waivers,
    this.matchup,
    required this.pendingTrades,
    required this.activeWaiverClaims,
    required this.unreadChatMessages,
    required this.announcements,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      draft: DraftInfo.fromJson(json['draft'] ?? {}),
      auction: AuctionInfo.fromJson(json['auction'] ?? {}),
      waivers: WaiverInfo.fromJson(json['waivers'] ?? {}),
      matchup: json['matchup'] != null ? MatchupInfo.fromJson(json['matchup']) : null,
      pendingTrades: json['pendingTrades'] ?? 0,
      activeWaiverClaims: json['activeWaiverClaims'] ?? 0,
      unreadChatMessages: json['unreadChatMessages'] ?? 0,
      announcements: (json['announcements'] as List<dynamic>?)
              ?.map((a) => Announcement.fromJson(a))
              .toList() ??
          [],
    );
  }
}

/// Draft status info for dashboard
class DraftInfo {
  final int? id;
  final DashboardDraftStatus? status;
  final DateTime? scheduledStart;
  final int? currentPick;
  final int? totalPicks;
  final String? draftType;

  DraftInfo({
    this.id,
    this.status,
    this.scheduledStart,
    this.currentPick,
    this.totalPicks,
    this.draftType,
  });

  factory DraftInfo.fromJson(Map<String, dynamic> json) {
    return DraftInfo(
      id: json['id'],
      status: json['status'] != null ? DashboardDraftStatus.fromString(json['status']) : null,
      scheduledStart: json['scheduledStart'] != null
          ? DateTime.parse(json['scheduledStart'])
          : null,
      currentPick: json['currentPick'],
      totalPicks: json['totalPicks'],
      draftType: json['draftType'],
    );
  }

  bool get hasActiveDraft => id != null && status != null && status != DashboardDraftStatus.complete;
  bool get isLive => status == DashboardDraftStatus.live;
  bool get isScheduled => status == DashboardDraftStatus.scheduled && scheduledStart != null;
  bool get isPaused => status == DashboardDraftStatus.paused;

  String get progressText {
    if (currentPick != null && totalPicks != null) {
      return 'Pick $currentPick/$totalPicks';
    }
    return '';
  }
}

enum DashboardDraftStatus {
  scheduled,
  live,
  paused,
  complete;

  static DashboardDraftStatus? fromString(String? value) {
    switch (value) {
      case 'scheduled':
        return DashboardDraftStatus.scheduled;
      case 'live':
        return DashboardDraftStatus.live;
      case 'paused':
        return DashboardDraftStatus.paused;
      case 'complete':
        return DashboardDraftStatus.complete;
      default:
        return null;
    }
  }
}

/// Auction status info for dashboard
class AuctionInfo {
  final int activeLots;
  final int endingSoonCount;
  final int userLeadingCount;
  final int userOutbidCount;

  AuctionInfo({
    required this.activeLots,
    required this.endingSoonCount,
    required this.userLeadingCount,
    required this.userOutbidCount,
  });

  factory AuctionInfo.fromJson(Map<String, dynamic> json) {
    return AuctionInfo(
      activeLots: json['activeLots'] ?? 0,
      endingSoonCount: json['endingSoonCount'] ?? 0,
      userLeadingCount: json['userLeadingCount'] ?? 0,
      userOutbidCount: json['userOutbidCount'] ?? 0,
    );
  }

  bool get hasActiveAuction => activeLots > 0;
}

/// Waiver status info for dashboard
class WaiverInfo {
  final DateTime? nextProcessingTime;
  final int userClaimsCount;

  WaiverInfo({
    this.nextProcessingTime,
    required this.userClaimsCount,
  });

  factory WaiverInfo.fromJson(Map<String, dynamic> json) {
    return WaiverInfo(
      nextProcessingTime: json['nextProcessingTime'] != null
          ? DateTime.parse(json['nextProcessingTime'])
          : null,
      userClaimsCount: json['userClaimsCount'] ?? 0,
    );
  }
}

/// Current matchup info for dashboard
class MatchupInfo {
  final int week;
  final String opponentTeamName;
  final int opponentRosterId;

  MatchupInfo({
    required this.week,
    required this.opponentTeamName,
    required this.opponentRosterId,
  });

  factory MatchupInfo.fromJson(Map<String, dynamic> json) {
    return MatchupInfo(
      week: json['week'] ?? 0,
      opponentTeamName: json['opponentTeamName'] ?? 'Unknown',
      opponentRosterId: json['opponentRosterId'] ?? 0,
    );
  }
}

/// Commissioner announcement
class Announcement {
  final int id;
  final String message;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

