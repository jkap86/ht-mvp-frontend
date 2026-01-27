import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/leagues/data/league_repository.dart';
import '../../features/leagues/domain/league.dart';

/// LeagueContext provides shared league information that multiple features need.
///
/// This provider allows features (matchups, standings, rosters, etc.) to access
/// league context without directly importing the league repository, reducing
/// cross-feature coupling.
class LeagueContext {
  final League league;
  final int? userRosterId;
  final bool isCommissioner;

  LeagueContext({
    required this.league,
    required this.userRosterId,
    required this.isCommissioner,
  });

  /// League ID shortcut
  int get leagueId => league.id;

  /// League name shortcut
  String get leagueName => league.name;

  /// League settings shortcut
  Map<String, dynamic> get settings => league.settings;

  /// Current season week
  int get currentWeek => league.currentWeek;

  /// Season status
  SeasonStatus get seasonStatus => league.seasonStatus;

  /// League mode (redraft/dynasty/keeper)
  String get mode => league.mode;

  /// Total roster slots
  int get totalRosters => league.totalRosters;
}

/// Provides league context for a specific league ID.
///
/// Usage:
/// ```dart
/// final context = await ref.watch(leagueContextProvider(leagueId).future);
/// if (context.isCommissioner) { ... }
/// ```
final leagueContextProvider = FutureProvider.family<LeagueContext, int>((ref, leagueId) async {
  final repo = ref.watch(leagueRepositoryProvider);
  final league = await repo.getLeague(leagueId);

  return LeagueContext(
    league: league,
    userRosterId: league.userRosterId,
    isCommissioner: league.userRosterId != null &&
                    league.userRosterId == league.commissionerRosterId,
  );
});

/// Auto-refreshing version that invalidates when league data changes.
/// Use this when you need the context to stay fresh during navigation.
final leagueContextAutoRefreshProvider = FutureProvider.family.autoDispose<LeagueContext, int>((ref, leagueId) async {
  final repo = ref.watch(leagueRepositoryProvider);
  final league = await repo.getLeague(leagueId);

  return LeagueContext(
    league: league,
    userRosterId: league.userRosterId,
    isCommissioner: league.userRosterId != null &&
                    league.userRosterId == league.commissionerRosterId,
  );
});
