import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../../drafts/domain/draft_status.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../../matchups/data/matchup_repository.dart';
import '../../../matchups/domain/matchup.dart';
import '../../../trades/data/trade_repository.dart';
import '../../../trades/domain/trade.dart';
import '../../../trades/domain/trade_status.dart';

/// Aggregated data for the home dashboard
class HomeDashboardState {
  final List<League> leagues;
  final List<DashboardMatchup> matchups;
  final List<DashboardTrade> pendingTrades;
  final List<DashboardDraft> upcomingDrafts;
  final bool isLoading;
  final String? error;

  HomeDashboardState({
    this.leagues = const [],
    this.matchups = const [],
    this.pendingTrades = const [],
    this.upcomingDrafts = const [],
    this.isLoading = true,
    this.error,
  });

  HomeDashboardState copyWith({
    List<League>? leagues,
    List<DashboardMatchup>? matchups,
    List<DashboardTrade>? pendingTrades,
    List<DashboardDraft>? upcomingDrafts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HomeDashboardState(
      leagues: leagues ?? this.leagues,
      matchups: matchups ?? this.matchups,
      pendingTrades: pendingTrades ?? this.pendingTrades,
      upcomingDrafts: upcomingDrafts ?? this.upcomingDrafts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// A matchup with league context for dashboard display
class DashboardMatchup {
  final int leagueId;
  final String leagueName;
  final Matchup matchup;
  final int? userRosterId;

  DashboardMatchup({
    required this.leagueId,
    required this.leagueName,
    required this.matchup,
    this.userRosterId,
  });

  bool get isUserMatchup {
    return userRosterId != null &&
        (matchup.roster1Id == userRosterId || matchup.roster2Id == userRosterId);
  }

  String get opponentName {
    if (!isUserMatchup) return '';
    if (matchup.roster1Id == userRosterId) {
      return matchup.roster2TeamName ?? 'Opponent';
    }
    return matchup.roster1TeamName ?? 'Opponent';
  }

  double? get userScore {
    if (!isUserMatchup) return null;
    if (matchup.roster1Id == userRosterId) {
      return matchup.roster1Points;
    }
    return matchup.roster2Points;
  }

  double? get opponentScore {
    if (!isUserMatchup) return null;
    if (matchup.roster1Id == userRosterId) {
      return matchup.roster2Points;
    }
    return matchup.roster1Points;
  }
}

/// A trade requiring user action for dashboard display
class DashboardTrade {
  final int leagueId;
  final String leagueName;
  final Trade trade;

  DashboardTrade({
    required this.leagueId,
    required this.leagueName,
    required this.trade,
  });

  String get summary {
    final giving = trade.proposerGiving.length;
    final receiving = trade.recipientGiving.length;
    return 'Give $giving, Get $receiving';
  }
}

/// An upcoming draft for dashboard display
class DashboardDraft {
  final int leagueId;
  final String leagueName;
  final Draft draft;

  DashboardDraft({
    required this.leagueId,
    required this.leagueName,
    required this.draft,
  });

  /// Check if draft is ready to start (created but not started)
  bool get isReadyToStart {
    return draft.status == DraftStatus.notStarted;
  }

  bool get isInProgress {
    return draft.status == DraftStatus.inProgress;
  }
}

class HomeDashboardNotifier extends StateNotifier<HomeDashboardState> {
  final LeagueRepository _leagueRepo;
  final MatchupRepository _matchupRepo;
  final TradeRepository _tradeRepo;

  HomeDashboardNotifier(
    this._leagueRepo,
    this._matchupRepo,
    this._tradeRepo,
  ) : super(HomeDashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // First, get all user's leagues
      final leagues = await _leagueRepo.getMyLeagues();

      if (leagues.isEmpty) {
        state = state.copyWith(leagues: [], isLoading: false);
        return;
      }

      // Collect data from all leagues in parallel
      final matchupsFutures = <Future<List<DashboardMatchup>>>[];
      final tradesFutures = <Future<List<DashboardTrade>>>[];
      final draftsFutures = <Future<List<DashboardDraft>>>[];

      for (final league in leagues) {
        // Get matchups for current week
        matchupsFutures.add(_getLeagueMatchups(league));

        // Get pending trades
        tradesFutures.add(_getLeagueTrades(league));

        // Get drafts (already have them from league data)
        draftsFutures.add(_getLeagueDrafts(league));
      }

      final matchupsResults = await Future.wait(matchupsFutures);
      if (!mounted) return; // Early exit if disposed
      final tradesResults = await Future.wait(tradesFutures);
      if (!mounted) return; // Early exit if disposed
      final draftsResults = await Future.wait(draftsFutures);
      if (!mounted) return; // Early exit if disposed

      // Flatten results
      final allMatchups = matchupsResults.expand((m) => m).toList();
      final allTrades = tradesResults.expand((t) => t).toList();
      final allDrafts = draftsResults.expand((d) => d).toList();

      // Filter to only user's matchups
      final userMatchups = allMatchups.where((m) => m.isUserMatchup).toList();

      // Filter to pending trades that need action
      final actionableTrades = allTrades.where((t) => t.trade.status.isPending).toList();

      // Filter to upcoming/active drafts
      final upcomingDrafts = allDrafts
          .where((d) => d.isInProgress || d.isReadyToStart)
          .toList();

      state = state.copyWith(
        leagues: leagues,
        matchups: userMatchups,
        pendingTrades: actionableTrades,
        upcomingDrafts: upcomingDrafts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  Future<List<DashboardMatchup>> _getLeagueMatchups(League league) async {
    try {
      final matchups = await _matchupRepo.getMatchups(
        league.id,
        week: league.currentWeek,
      );
      return matchups
          .map((m) => DashboardMatchup(
                leagueId: league.id,
                leagueName: league.name,
                matchup: m,
                userRosterId: league.userRosterId,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DashboardTrade>> _getLeagueTrades(League league) async {
    try {
      final trades = await _tradeRepo.getTrades(league.id);
      return trades
          .where((t) => t.status == TradeStatus.pending || t.status == TradeStatus.inReview)
          .map((t) => DashboardTrade(
                leagueId: league.id,
                leagueName: league.name,
                trade: t,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DashboardDraft>> _getLeagueDrafts(League league) async {
    try {
      final drafts = await _leagueRepo.getLeagueDrafts(league.id);
      return drafts
          .map((d) => DashboardDraft(
                leagueId: league.id,
                leagueName: league.name,
                draft: d,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final homeDashboardProvider =
    StateNotifierProvider.autoDispose<HomeDashboardNotifier, HomeDashboardState>(
  (ref) => HomeDashboardNotifier(
    ref.watch(leagueRepositoryProvider),
    ref.watch(matchupRepositoryProvider),
    ref.watch(tradeRepositoryProvider),
  ),
);
