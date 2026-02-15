import '../../drafts/domain/auction_settings.dart';
import '../../drafts/domain/draft_type.dart';

export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show SeasonStatus, FillStatus;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension SeasonStatusUI on SeasonStatus {
  String get displayName => switch (this) {
    SeasonStatus.preSeason => 'Pre-Season',
    SeasonStatus.regularSeason => 'Regular Season',
    SeasonStatus.playoffs => 'Playoffs',
    SeasonStatus.offseason => 'Offseason',
  };
}

class League {
  final int id;
  final String name;
  final String status;
  final int season;
  final int totalRosters;
  final int? commissionerRosterId;
  final int? userRosterId;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> scoringSettings;
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
    this.commissionerRosterId,
    this.userRosterId,
    required this.settings,
    this.scoringSettings = const {},
    this.leagueSettings = const {},
    this.currentWeek = 1,
    this.seasonStatus = SeasonStatus.preSeason,
    this.isPublic = false,
    this.mode = 'redraft',
    this.canChangeMode = true,
  });

  String get scoringType {
    final rec = scoringSettings['rec'];
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

  /// Check if this is a bestball league
  bool get isBestball => rosterType == 'bestball';

  /// Display name for roster type
  String get rosterTypeDisplay {
    return isBestball ? 'Bestball' : 'Lineup';
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
      season: int.tryParse(json['season']?.toString() ?? '') ?? 0,
      totalRosters: json['total_rosters'] as int? ?? 12,
      commissionerRosterId: json['commissioner_roster_id'] as int?,
      userRosterId: json['user_roster_id'] as int?,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      scoringSettings: (json['scoring_settings'] as Map<String, dynamic>?) ?? {},
      leagueSettings: (json['league_settings'] as Map<String, dynamic>?) ?? {},
      currentWeek: json['current_week'] as int? ?? 1,
      seasonStatus: SeasonStatus.fromString(json['season_status'] as String?),
      isPublic: json['is_public'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'redraft',
      canChangeMode: json['can_change_mode'] as bool? ?? true,
    );
  }
}

extension FillStatusUI on FillStatus {
  String get displayName => switch (this) {
    FillStatus.open => 'Open',
    FillStatus.waitingPayment => 'Waiting for Payment',
    FillStatus.filled => 'Full',
  };
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
  final DraftPhase phase;
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
  // Overnight pause settings (snake/linear drafts only)
  final bool overnightPauseEnabled;
  final String? overnightPauseStart; // HH:MM format (UTC)
  final String? overnightPauseEnd; // HH:MM format (UTC)
  // Chess clock settings
  final String timerMode; // 'per_pick' or 'chess_clock'
  final int? chessClockTotalSeconds;
  final int? chessClockMinPickSeconds;

  Draft({
    required this.id,
    required this.leagueId,
    required this.draftType,
    required this.status,
    this.phase = DraftPhase.setup,
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
    this.overnightPauseEnabled = false,
    this.overnightPauseStart,
    this.overnightPauseEnd,
    this.timerMode = 'per_pick',
    this.chessClockTotalSeconds,
    this.chessClockMinPickSeconds,
  });

  /// Display name - uses label if available, falls back to "Draft #id"
  String get displayName => label ?? 'Draft #$id';

  /// Check if this is an auction draft
  bool get isAuction => draftType.isAuction;

  /// Check if this draft uses chess clock mode
  bool get isChessClockMode => timerMode == 'chess_clock';

  /// Check if this is a rookie-only draft
  bool get isRookieDraft {
    final pool = rawSettings?['playerPool'] as List?;
    if (pool == null || pool.length != 1) return false;
    return pool[0] == 'rookie';
  }

  factory Draft.fromJson(Map<String, dynamic> json) {
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    return Draft(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      draftType: DraftType.fromString(json['draft_type'] as String?),
      status: DraftStatus.fromString(json['status'] as String?),
      phase: DraftPhase.fromString(json['phase'] as String?),
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
      overnightPauseEnabled: json['overnight_pause_enabled'] as bool? ?? false,
      overnightPauseStart: json['overnight_pause_start'] as String?,
      overnightPauseEnd: json['overnight_pause_end'] as String?,
      timerMode: settingsJson?['timerMode'] as String? ?? 'per_pick',
      chessClockTotalSeconds: settingsJson?['chessClockTotalSeconds'] as int?,
      chessClockMinPickSeconds: settingsJson?['chessClockMinPickSeconds'] as int?,
    );
  }

  Draft copyWith({
    int? id,
    int? leagueId,
    DraftType? draftType,
    DraftStatus? status,
    DraftPhase? phase,
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
    bool? overnightPauseEnabled,
    String? overnightPauseStart,
    String? overnightPauseEnd,
    String? timerMode,
    int? chessClockTotalSeconds,
    int? chessClockMinPickSeconds,
    bool clearCurrentPick = false,
    bool clearCurrentRound = false,
    bool clearCurrentRosterId = false,
    bool clearPickDeadline = false,
    bool clearScheduledStart = false,
    bool clearSettings = false,
    bool clearOvernightPauseStart = false,
    bool clearOvernightPauseEnd = false,
  }) {
    return Draft(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      draftType: draftType ?? this.draftType,
      status: status ?? this.status,
      phase: phase ?? this.phase,
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
      overnightPauseEnabled: overnightPauseEnabled ?? this.overnightPauseEnabled,
      overnightPauseStart: clearOvernightPauseStart ? null : (overnightPauseStart ?? this.overnightPauseStart),
      overnightPauseEnd: clearOvernightPauseEnd ? null : (overnightPauseEnd ?? this.overnightPauseEnd),
      timerMode: timerMode ?? this.timerMode,
      chessClockTotalSeconds: chessClockTotalSeconds ?? this.chessClockTotalSeconds,
      chessClockMinPickSeconds: chessClockMinPickSeconds ?? this.chessClockMinPickSeconds,
    );
  }
}
