import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../data/matchup_repository.dart';
import '../../domain/matchup.dart';

class StandingsState {
  final League? league;
  final List<Standing> standings;
  final int? myRosterId;
  final bool isLoading;
  final String? error;
  final bool isForbidden;
  final DateTime? lastUpdated;

  StandingsState({
    this.league,
    this.standings = const [],
    this.myRosterId,
    this.isLoading = true,
    this.error,
    this.isForbidden = false,
    this.lastUpdated,
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Get the current user's standing
  Standing? get myStanding {
    if (myRosterId == null) return null;
    return standings.where((s) => s.rosterId == myRosterId).firstOrNull;
  }

  /// Get my rank
  int? get myRank => myStanding?.rank;

  StandingsState copyWith({
    League? league,
    List<Standing>? standings,
    int? myRosterId,
    bool? isLoading,
    String? error,
    bool? isForbidden,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return StandingsState(
      league: league ?? this.league,
      standings: standings ?? this.standings,
      myRosterId: myRosterId ?? this.myRosterId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isForbidden: isForbidden ?? this.isForbidden,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class StandingsNotifier extends StateNotifier<StandingsState> {
  final MatchupRepository _matchupRepo;
  final LeagueRepository _leagueRepo;
  final InvalidationService _invalidationService;
  final int leagueId;

  VoidCallback? _invalidationDisposer;

  StandingsNotifier(
    this._matchupRepo,
    this._leagueRepo,
    this._invalidationService,
    this.leagueId,
  ) : super(StandingsState()) {
    _registerInvalidationCallback();
    loadData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.standings,
      leagueId,
      loadData,
    );
  }

  @override
  void dispose() {
    _invalidationDisposer?.call();
    super.dispose();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _leagueRepo.getLeague(leagueId),
        _matchupRepo.getStandings(leagueId),
      ]);

      final league = results[0] as League;
      final standings = results[1] as List<Standing>;

      state = state.copyWith(
        league: league,
        standings: standings,
        myRosterId: league.userRosterId,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } on ForbiddenException {
      state = state.copyWith(isForbidden: true, isLoading: false, standings: []);
    } catch (e) {
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final standingsProvider = StateNotifierProvider.autoDispose.family<StandingsNotifier, StandingsState, int>(
  (ref, leagueId) => StandingsNotifier(
    ref.watch(matchupRepositoryProvider),
    ref.watch(leagueRepositoryProvider),
    ref.watch(invalidationServiceProvider),
    leagueId,
  ),
);
