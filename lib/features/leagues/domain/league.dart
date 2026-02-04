import '../../drafts/domain/auction_settings.dart';
import '../../drafts/domain/draft_status.dart';
import '../../drafts/domain/draft_type.dart';

enum SeasonStatus {
  preSeason,
  regularSeason,
  playoffs,
  offseason;

  static SeasonStatus fromString(String? value) {
    switch (value) {
      case 'regular_season':
        return SeasonStatus.regularSeason;
      case 'playoffs':
        return SeasonStatus.playoffs;
      case 'offseason':
        return SeasonStatus.offseason;
      default:
        return SeasonStatus.preSeason;
    }
  }

  String get displayName {
    switch (this) {
      case SeasonStatus.preSeason:
        return 'Pre-Season';
      case SeasonStatus.regularSeason:
        return 'Regular Season';
      case SeasonStatus.playoffs:
        return 'Playoffs';
      case SeasonStatus.offseason:
        return 'Offseason';
    }
  }
}

class League {
  final int id;
  final String name;
  final String status;
  final int season;
  final int totalRosters;
  final String? inviteCode;
  final int? commissionerRosterId;
  final int? userRosterId;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> leagueSettings;
  final int currentWeek;
  final SeasonStatus seasonStatus;
  final bool isPublic;
  final String mode;
  final bool canChangeMode;

  League({
    required this.id,
    required this.name,
    required this.status,
    required this.season,
    required this.totalRosters,
    this.inviteCode,
    this.commissionerRosterId,
    this.userRosterId,
    required this.settings,
    this.leagueSettings = const {},
    this.currentWeek = 1,
    this.seasonStatus = SeasonStatus.preSeason,
    this.isPublic = false,
    this.mode = 'redraft',
    this.canChangeMode = true,
  });

  String get scoringType {
    final rec = settings['scoring_settings']?['rec'];
    if (rec == null) return 'PPR';
    if (rec == 0.0) return 'Standard';
    if (rec == 0.5) return 'Half-PPR';
    return 'PPR';
  }

  /// Get the roster type (lineup or bestball)
  String get rosterType {
    final type = leagueSettings['rosterType'];
    return type ?? 'lineup';
  }

  /// Display name for roster type
  String get rosterTypeDisplay {
    return rosterType == 'bestball' ? 'Bestball' : 'Lineup';
  }

  /// Display name for league mode
  String get modeDisplay {
    switch (mode) {
      case 'redraft':
        return 'Redraft';
      case 'dynasty':
        return 'Dynasty';
      case 'keeper':
        return 'Keeper';
      case 'devy':
        return 'Devy';
      default:
        return mode;
    }
  }

  /// Total weeks in the season (regular season + playoffs)
  /// Defaults to 18 (NFL standard)
  int get totalWeeks {
    final weeks = settings['total_weeks'];
    if (weeks is int) return weeks;
    return 18; // NFL regular season + playoffs default
  }

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      season: int.tryParse(json['season']?.toString() ?? '') ?? DateTime.now().year,
      totalRosters: json['total_rosters'] as int? ?? 12,
      inviteCode: json['invite_code'] as String?,
      commissionerRosterId: json['commissioner_roster_id'] as int?,
      userRosterId: json['user_roster_id'] as int?,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      leagueSettings: (json['league_settings'] as Map<String, dynamic>?) ?? {},
      currentWeek: json['current_week'] as int? ?? 1,
      seasonStatus: SeasonStatus.fromString(json['season_status'] as String?),
      isPublic: json['is_public'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'redraft',
      canChangeMode: json['can_change_mode'] as bool? ?? true,
    );
  }
}

/// Fill status for a public league
enum FillStatus {
  open,
  waitingPayment,
  filled;

  static FillStatus fromString(String? value) {
    switch (value) {
      case 'open':
        return FillStatus.open;
      case 'waiting_payment':
        return FillStatus.waitingPayment;
      case 'filled':
        return FillStatus.filled;
      default:
        return FillStatus.open;
    }
  }

  String get displayName {
    switch (this) {
      case FillStatus.open:
        return 'Open';
      case FillStatus.waitingPayment:
        return 'Waiting for Payment';
      case FillStatus.filled:
        return 'Full';
    }
  }
}

/// Represents a public league available for discovery
class PublicLeague {
  final int id;
  final String name;
  final String season;
  final String mode;
  final int totalRosters;
  final int memberCount;
  final bool isPublic;
  final bool hasDues;
  final double? buyInAmount;
  final String? currency;
  final int paidCount;
  final FillStatus fillStatus;

  PublicLeague({
    required this.id,
    required this.name,
    required this.season,
    required this.mode,
    required this.totalRosters,
    required this.memberCount,
    this.isPublic = true,
    this.hasDues = false,
    this.buyInAmount,
    this.currency,
    this.paidCount = 0,
    this.fillStatus = FillStatus.open,
  });

  factory PublicLeague.fromJson(Map<String, dynamic> json) {
    return PublicLeague(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      season: json['season']?.toString() ?? '',
      mode: json['mode'] as String? ?? 'redraft',
      totalRosters: json['total_rosters'] as int? ?? 12,
      memberCount: json['member_count'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      hasDues: json['has_dues'] as bool? ?? false,
      buyInAmount: (json['buy_in_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      paidCount: json['paid_count'] as int? ?? 0,
      fillStatus: FillStatus.fromString(json['fill_status'] as String?),
    );
  }

  /// Check if the league is completely full (no joining possible)
  bool get isFull => fillStatus == FillStatus.filled;

  /// Check if user can join as bench (paid league at capacity but not all paid)
  bool get canJoinAsBench => fillStatus == FillStatus.waitingPayment;

  /// Get formatted member count string
  String get memberCountDisplay => '$memberCount/$totalRosters';

  /// Get formatted buy-in display
  String get buyInDisplay {
    if (!hasDues || buyInAmount == null) return 'Free';
    final currencySymbol = currency == 'USD' ? '\$' : currency ?? '';
    return '$currencySymbol${buyInAmount!.toStringAsFixed(buyInAmount! == buyInAmount!.truncate() ? 0 : 2)}';
  }

  /// Get status display text
  String get statusDisplay {
    switch (fillStatus) {
      case FillStatus.open:
        return 'Open';
      case FillStatus.waitingPayment:
        return 'Waiting for Payment';
      case FillStatus.filled:
        return 'Full';
    }
  }
}

class Roster {
  final int id;
  final int leagueId;
  final String? userId;
  final int? rosterId;
  final String? teamName;
  final String username;
  final bool isBenched;

  Roster({
    required this.id,
    required this.leagueId,
    this.userId,
    this.rosterId,
    this.teamName,
    required this.username,
    this.isBenched = false,
  });

  factory Roster.fromJson(Map<String, dynamic> json) {
    return Roster(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      userId: json['user_id'] as String?,
      rosterId: json['roster_id'] as int?,
      teamName: json['team_name'] as String?,
      username: json['username'] as String? ?? 'Unknown',
      isBenched: json['is_benched'] as bool? ?? false,
    );
  }
}

class Draft {
  final int id;
  final int leagueId;
  final DraftType draftType;
  final DraftStatus status;
  final int rounds;
  final int pickTimeSeconds;
  final int? currentPick;
  final int? currentRound;
  final int? currentRosterId;
  final DateTime? pickDeadline;
  final DateTime? scheduledStart;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final AuctionSettings? settings;
  final Map<String, dynamic>? rawSettings; // Preserves full settings including playerPool
  final bool orderConfirmed;
  final String? label; // Computed label like "Veteran Draft", "Rookie Draft"

  Draft({
    required this.id,
    required this.leagueId,
    required this.draftType,
    required this.status,
    required this.rounds,
    required this.pickTimeSeconds,
    this.currentPick,
    this.currentRound,
    this.currentRosterId,
    this.pickDeadline,
    this.scheduledStart,
    this.startedAt,
    this.completedAt,
    this.settings,
    this.rawSettings,
    this.orderConfirmed = false,
    this.label,
  });

  /// Display name - uses label if available, falls back to "Draft #id"
  String get displayName => label ?? 'Draft #$id';

  /// Check if this is an auction draft
  bool get isAuction => draftType.isAuction;

  factory Draft.fromJson(Map<String, dynamic> json) {
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    return Draft(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      draftType: DraftType.fromString(json['draft_type'] as String?),
      status: DraftStatus.fromString(json['status'] as String?),
      rounds: json['rounds'] as int? ?? 15,
      pickTimeSeconds: json['pick_time_seconds'] as int? ?? 90,
      currentPick: json['current_pick'] as int?,
      currentRound: json['current_round'] as int?,
      currentRosterId: json['current_roster_id'] as int?,
      pickDeadline: json['pick_deadline'] != null
          ? DateTime.tryParse(json['pick_deadline'].toString())
          : null,
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.tryParse(json['scheduled_start'].toString())
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      settings: settingsJson != null && settingsJson.isNotEmpty
          ? AuctionSettings.fromJson(settingsJson)
          : null,
      rawSettings: settingsJson,
      orderConfirmed: json['order_confirmed'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  Draft copyWith({
    int? id,
    int? leagueId,
    DraftType? draftType,
    DraftStatus? status,
    int? rounds,
    int? pickTimeSeconds,
    int? currentPick,
    int? currentRound,
    int? currentRosterId,
    DateTime? pickDeadline,
    DateTime? scheduledStart,
    DateTime? startedAt,
    DateTime? completedAt,
    AuctionSettings? settings,
    Map<String, dynamic>? rawSettings,
    bool? orderConfirmed,
    String? label,
    bool clearCurrentPick = false,
    bool clearCurrentRound = false,
    bool clearCurrentRosterId = false,
    bool clearPickDeadline = false,
    bool clearScheduledStart = false,
    bool clearSettings = false,
  }) {
    return Draft(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      draftType: draftType ?? this.draftType,
      status: status ?? this.status,
      rounds: rounds ?? this.rounds,
      pickTimeSeconds: pickTimeSeconds ?? this.pickTimeSeconds,
      currentPick: clearCurrentPick ? null : (currentPick ?? this.currentPick),
      currentRound: clearCurrentRound ? null : (currentRound ?? this.currentRound),
      currentRosterId: clearCurrentRosterId ? null : (currentRosterId ?? this.currentRosterId),
      pickDeadline: clearPickDeadline ? null : (pickDeadline ?? this.pickDeadline),
      scheduledStart: clearScheduledStart ? null : (scheduledStart ?? this.scheduledStart),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      settings: clearSettings ? null : (settings ?? this.settings),
      rawSettings: clearSettings ? null : (rawSettings ?? this.rawSettings),
      orderConfirmed: orderConfirmed ?? this.orderConfirmed,
      label: label ?? this.label,
    );
  }
}
