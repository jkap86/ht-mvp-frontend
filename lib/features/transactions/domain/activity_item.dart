export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show ActivityType;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

import '../../../core/utils/date_sentinel.dart';

extension ActivityTypeUI on ActivityType {
  String get label => switch (this) {
    ActivityType.trade => 'Trade',
    ActivityType.waiver => 'Waiver Claim',
    ActivityType.add => 'Free Agency',
    ActivityType.drop => 'Drop',
    ActivityType.draft => 'Draft',
  };
}

/// Unified activity feed item from the backend
class ActivityItem {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final int leagueId;
  final int? week;
  final String? season;
  final Map<String, dynamic> data;

  ActivityItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.leagueId,
    this.week,
    this.season,
    required this.data,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String? ?? '',
      type: ActivityType.fromString(json['type'] as String?),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? epochUtc(),
      leagueId: json['leagueId'] as int? ?? json['league_id'] as int? ?? 0,
      week: json['week'] as int?,
      season: json['season']?.toString(),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  // --- Trade accessors ---

  String? get tradeProposerTeamName => data['proposerTeamName'] as String?;
  String? get tradeRecipientTeamName => data['recipientTeamName'] as String?;
  int get tradePlayerCount => data['playerCount'] as int? ?? 0;
  int get tradePickCount => data['pickCount'] as int? ?? 0;
  String? get tradeStatus => data['status'] as String?;

  // --- Waiver accessors ---

  String? get waiverTeamName => data['teamName'] as String?;
  Map<String, dynamic>? get waiverPlayerAdded =>
      data['playerAdded'] as Map<String, dynamic>?;
  Map<String, dynamic>? get waiverPlayerDropped =>
      data['playerDropped'] as Map<String, dynamic>?;
  int? get waiverBidAmount => data['bidAmount'] as int?;
  int? get waiverPriority => data['priority'] as int?;
  bool get waiverSuccessful => data['successful'] as bool? ?? false;

  // --- Add/Drop accessors ---

  String? get addDropTeamName => data['teamName'] as String?;
  Map<String, dynamic>? get addDropPlayer =>
      data['player'] as Map<String, dynamic>?;
  bool get isAdd => data['isAdd'] as bool? ?? true;

  // --- Draft accessors ---

  String? get draftTeamName => data['teamName'] as String?;
  Map<String, dynamic>? get draftPlayer =>
      data['player'] as Map<String, dynamic>?;
  int get draftPickNumber => data['pickNumber'] as int? ?? 0;
  int get draftRound => data['round'] as int? ?? 0;
  bool get draftIsAutoPick => data['isAutoPick'] as bool? ?? false;

  /// Get the primary team name for display
  String get teamName {
    switch (type) {
      case ActivityType.trade:
        return tradeProposerTeamName ?? 'Unknown';
      case ActivityType.waiver:
        return waiverTeamName ?? 'Unknown';
      case ActivityType.add:
      case ActivityType.drop:
        return addDropTeamName ?? 'Unknown';
      case ActivityType.draft:
        return draftTeamName ?? 'Unknown';
    }
  }

  /// Get the primary player name for display
  String get playerName {
    switch (type) {
      case ActivityType.trade:
        return '$tradePlayerCount player(s)';
      case ActivityType.waiver:
        return waiverPlayerAdded?['name'] as String? ?? 'Unknown';
      case ActivityType.add:
      case ActivityType.drop:
        return addDropPlayer?['name'] as String? ?? 'Unknown';
      case ActivityType.draft:
        return draftPlayer?['name'] as String? ?? 'Unknown';
    }
  }

  /// Get the primary player position for display
  String? get playerPosition {
    switch (type) {
      case ActivityType.trade:
        return null;
      case ActivityType.waiver:
        return waiverPlayerAdded?['position'] as String?;
      case ActivityType.add:
      case ActivityType.drop:
        return addDropPlayer?['position'] as String?;
      case ActivityType.draft:
        return draftPlayer?['position'] as String?;
    }
  }

  /// Get a short summary of the activity
  String get summary {
    switch (type) {
      case ActivityType.trade:
        return '${tradeProposerTeamName ?? "?"} traded with ${tradeRecipientTeamName ?? "?"}';
      case ActivityType.waiver:
        final added = waiverPlayerAdded?['name'] ?? '?';
        final dropped = waiverPlayerDropped?['name'];
        if (dropped != null) {
          return '$teamName claimed $added, dropped $dropped';
        }
        return '$teamName claimed $added';
      case ActivityType.add:
        return '$teamName added ${addDropPlayer?['name'] ?? '?'}';
      case ActivityType.drop:
        return '$teamName dropped ${addDropPlayer?['name'] ?? '?'}';
      case ActivityType.draft:
        final player = draftPlayer?['name'] ?? '?';
        return '$teamName drafted $player (Rd $draftRound, Pick $draftPickNumber)';
    }
  }
}
