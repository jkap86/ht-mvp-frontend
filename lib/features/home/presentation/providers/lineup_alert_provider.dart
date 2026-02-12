import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leagues/domain/league.dart';
import '../../../rosters/data/roster_repository.dart';
import '../../../rosters/domain/roster_legality.dart';
import '../../../rosters/domain/roster_lineup.dart';
import '../../../rosters/domain/roster_player.dart';
import 'home_dashboard_provider.dart';

/// A single league's lineup alert summary.
class LeagueLineupAlert {
  final int leagueId;
  final String leagueName;
  final int? rosterId;

  /// Players starting who are on bye this week.
  final List<RosterPlayer> byeWeekStarters;

  /// Players starting who have a significant injury designation.
  final List<RosterPlayer> injuredStarters;

  /// True if the lineup has empty starter slots that could be filled.
  final bool hasEmptySlots;

  LeagueLineupAlert({
    required this.leagueId,
    required this.leagueName,
    this.rosterId,
    this.byeWeekStarters = const [],
    this.injuredStarters = const [],
    this.hasEmptySlots = false,
  });

  /// Whether this league needs the user's attention.
  bool get needsAttention =>
      byeWeekStarters.isNotEmpty ||
      injuredStarters.isNotEmpty ||
      hasEmptySlots;

  /// Total number of problematic starters.
  int get issueCount =>
      byeWeekStarters.length + injuredStarters.length + (hasEmptySlots ? 1 : 0);

  /// Human-readable summary of the issues.
  String get summary {
    final parts = <String>[];
    if (injuredStarters.isNotEmpty) {
      parts.add('${injuredStarters.length} injured');
    }
    if (byeWeekStarters.isNotEmpty) {
      parts.add('${byeWeekStarters.length} on bye');
    }
    if (hasEmptySlots) {
      parts.add('empty slots');
    }
    return parts.join(', ');
  }
}

/// Aggregated lineup alert state across all leagues.
class LineupAlertState {
  final List<LeagueLineupAlert> alerts;
  final bool isLoading;
  final String? error;

  LineupAlertState({
    this.alerts = const [],
    this.isLoading = true,
    this.error,
  });

  /// Only alerts that actually need attention.
  List<LeagueLineupAlert> get activeAlerts =>
      alerts.where((a) => a.needsAttention).toList();

  /// Total number of leagues needing attention.
  int get leaguesNeedingAttention => activeAlerts.length;

  /// Whether any league needs lineup attention.
  bool get hasAlerts => activeAlerts.isNotEmpty;

  LineupAlertState copyWith({
    List<LeagueLineupAlert>? alerts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LineupAlertState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LineupAlertNotifier extends StateNotifier<LineupAlertState> {
  final RosterRepository _rosterRepo;
  final HomeDashboardState _dashboardState;

  LineupAlertNotifier(this._rosterRepo, this._dashboardState)
      : super(LineupAlertState()) {
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    // Only check leagues where the user has a matchup and a roster
    final leaguesWithMatchups = _dashboardState.matchups
        .where((m) => m.userRosterId != null)
        .map((m) => (
              leagueId: m.leagueId,
              leagueName: m.leagueName,
              rosterId: m.userRosterId!,
            ))
        .toSet()
        .toList();

    if (leaguesWithMatchups.isEmpty) {
      state = LineupAlertState(alerts: [], isLoading: false);
      return;
    }

    // Also need league data for roster config and current week
    final leagueMap = <int, League>{};
    for (final league in _dashboardState.leagues) {
      leagueMap[league.id] = league;
    }

    final alertFutures = leaguesWithMatchups.map((entry) async {
      try {
        final league = leagueMap[entry.leagueId];
        if (league == null) return null;

        // Bestball leagues don't need lineup management
        if (league.isBestball) return null;

        final currentWeek = league.currentWeek;

        // Fetch roster players and lineup in parallel
        final results = await Future.wait([
          _rosterRepo.getRosterPlayers(entry.leagueId, entry.rosterId),
          _rosterRepo
              .getLineup(entry.leagueId, entry.rosterId, currentWeek)
              .catchError((_) => RosterLineup(
                    id: 0,
                    rosterId: entry.rosterId,
                    season: league.season,
                    week: currentWeek,
                    lineup: LineupSlots(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )),
        ]);

        final players = results[0] as List<RosterPlayer>;
        final lineup = results[1] as RosterLineup;

        // Use the existing legality validator to find issues
        const validator = RosterLegalityValidator();
        final configMap = league.settings['roster_config'];
        final config = configMap is Map<String, dynamic>
            ? RosterConfig.fromJson(configMap)
            : const RosterConfig();

        final warnings = validator.validateLineup(
          players: players,
          lineup: lineup,
          config: config,
          currentWeek: currentWeek,
        );

        // Categorize the warnings
        final byeStarters = <RosterPlayer>[];
        final injuredStarters = <RosterPlayer>[];
        var hasEmptySlots = false;

        for (final warning in warnings) {
          if (warning.level != LegalityLevel.warning) continue;

          if (warning.message.contains('bye week')) {
            final player = warning.playerId != null
                ? players
                    .where((p) => p.playerId == warning.playerId)
                    .firstOrNull
                : null;
            if (player != null) byeStarters.add(player);
          } else if (warning.message.contains('starting') &&
              (warning.message.contains('OUT') ||
                  warning.message.contains('IR') ||
                  warning.message.contains('DOUBTFUL') ||
                  warning.message.contains('PUP') ||
                  warning.message.contains('NFI') ||
                  warning.message.contains('SUS'))) {
            final player = warning.playerId != null
                ? players
                    .where((p) => p.playerId == warning.playerId)
                    .firstOrNull
                : null;
            if (player != null) injuredStarters.add(player);
          } else if (warning.message.contains('empty starting slots')) {
            hasEmptySlots = true;
          }
        }

        return LeagueLineupAlert(
          leagueId: entry.leagueId,
          leagueName: entry.leagueName,
          rosterId: entry.rosterId,
          byeWeekStarters: byeStarters,
          injuredStarters: injuredStarters,
          hasEmptySlots: hasEmptySlots,
        );
      } catch (_) {
        // If we can't fetch data for a league, skip it silently
        return null;
      }
    });

    final results = await Future.wait(alertFutures);
    if (!mounted) return;

    final alerts = results.whereType<LeagueLineupAlert>().toList();

    state = LineupAlertState(alerts: alerts, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadAlerts();
  }
}

final lineupAlertProvider =
    StateNotifierProvider.autoDispose<LineupAlertNotifier, LineupAlertState>(
  (ref) {
    final dashboardState = ref.watch(homeDashboardProvider);
    final rosterRepo = ref.watch(rosterRepositoryProvider);
    return LineupAlertNotifier(rosterRepo, dashboardState);
  },
);
