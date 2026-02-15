import '../common/enums.dart';

class LeagueDto {
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

  const LeagueDto({
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

  factory LeagueDto.fromJson(Map<String, dynamic> json) {
    return LeagueDto(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'season': season,
      'total_rosters': totalRosters,
      'commissioner_roster_id': commissionerRosterId,
      'user_roster_id': userRosterId,
      'settings': settings,
      'scoring_settings': scoringSettings,
      'league_settings': leagueSettings,
      'current_week': currentWeek,
      'season_status': seasonStatus.value,
      'is_public': isPublic,
      'mode': mode,
      'can_change_mode': canChangeMode,
    };
  }
}

class PublicLeagueDto {
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

  const PublicLeagueDto({
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

  factory PublicLeagueDto.fromJson(Map<String, dynamic> json) {
    return PublicLeagueDto(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'season': season,
      'mode': mode,
      'total_rosters': totalRosters,
      'member_count': memberCount,
      'is_public': isPublic,
      'has_dues': hasDues,
      'buy_in_amount': buyInAmount,
      'currency': currency,
      'paid_count': paidCount,
      'fill_status': fillStatus.value,
    };
  }
}

class RosterDto {
  final int id;
  final int leagueId;
  final String? userId;
  final int? rosterId;
  final String? teamName;
  final String username;
  final bool isBenched;

  const RosterDto({
    required this.id,
    required this.leagueId,
    this.userId,
    this.rosterId,
    this.teamName,
    required this.username,
    this.isBenched = false,
  });

  factory RosterDto.fromJson(Map<String, dynamic> json) {
    return RosterDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? 0,
      userId: json['user_id'] as String?,
      rosterId: json['roster_id'] as int?,
      teamName: json['team_name'] as String?,
      username: json['username'] as String? ?? 'Unknown',
      isBenched: json['is_benched'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'user_id': userId,
      'roster_id': rosterId,
      'team_name': teamName,
      'username': username,
      'is_benched': isBenched,
    };
  }
}
