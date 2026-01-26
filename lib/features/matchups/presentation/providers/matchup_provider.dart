import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../data/matchup_repository.dart';
import '../../domain/matchup.dart';

class MatchupState {
  final League? league;
  final List<Matchup> matchups;
  final int currentWeek;
  final int? myRosterId;
  final bool isLoading;
  final String? error;

  MatchupState({
    this.league,
    this.matchups = const [],
    this.currentWeek = 1,
    this.myRosterId,
    this.isLoading = true,
    this.error,
  });

  /// Get the current user's matchup
  Matchup? get myMatchup {
    if (myRosterId == null) return null;
    return matchups.where((m) =>
        m.roster1Id == myRosterId || m.roster2Id == myRosterId).firstOrNull;
  }

  /// Get all matchups for the current week
  List<Matchup> get weekMatchups => matchups;

  MatchupState copyWith({
    League? league,
    List<Matchup>? matchups,
    int? currentWeek,
    int? myRosterId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MatchupState(
      league: league ?? this.league,
      matchups: matchups ?? this.matchups,
      currentWeek: currentWeek ?? this.currentWeek,
      myRosterId: myRosterId ?? this.myRosterId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MatchupNotifier extends StateNotifier<MatchupState> {
  final MatchupRepository _matchupRepo;
  final LeagueRepository _leagueRepo;
  final SocketService _socketService;
  final int leagueId;

  final List<VoidCallback> _socketDisposers = [];

  MatchupNotifier(
    this._matchupRepo,
    this._leagueRepo,
    this._socketService,
    this.leagueId,
  ) : super(MatchupState()) {
    _setupSocketListeners();
    loadData();
  }

  void _setupSocketListeners() {
    // Listen for score updates from stats sync
    _socketDisposers.add(_socketService.onScoresUpdated((data) {
      final week = data['week'] as int?;
      // Refresh if the update is for the current week we're viewing
      if (week == null || week == state.currentWeek) {
        _refreshMatchups();
      }
    }));

    // Listen for week finalized events
    _socketDisposers.add(_socketService.onWeekFinalized((data) {
      final week = data['week'] as int?;
      if (week == null || week == state.currentWeek) {
        _refreshMatchups();
      }
    }));
  }

  /// Refresh matchups without showing loading state (background refresh)
  Future<void> _refreshMatchups() async {
    try {
      final matchups = await _matchupRepo.getMatchups(leagueId, week: state.currentWeek);
      if (mounted) {
        state = state.copyWith(matchups: matchups);
      }
    } catch (e) {
      // Silently fail on background refresh
      debugPrint('Failed to refresh matchups: $e');
    }
  }

  @override
  void dispose() {
    for (final disposer in _socketDisposers) {
      disposer();
    }
    _socketDisposers.clear();
    super.dispose();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final league = await _leagueRepo.getLeague(leagueId);
      final currentWeek = league.currentWeek;
      final matchups = await _matchupRepo.getMatchups(leagueId, week: currentWeek);

      state = state.copyWith(
        league: league,
        matchups: matchups,
        currentWeek: currentWeek,
        myRosterId: league.userRosterId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> changeWeek(int week) async {
    if (week == state.currentWeek) return;

    state = state.copyWith(isLoading: true, currentWeek: week);

    try {
      final matchups = await _matchupRepo.getMatchups(leagueId, week: week);
      state = state.copyWith(
        matchups: matchups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final matchupProvider = StateNotifierProvider.family<MatchupNotifier, MatchupState, int>(
  (ref, leagueId) => MatchupNotifier(
    ref.watch(matchupRepositoryProvider),
    ref.watch(leagueRepositoryProvider),
    ref.watch(socketServiceProvider),
    leagueId,
  ),
);

/// Provider for matchup details (single matchup with lineups)
final matchupDetailsProvider = FutureProvider.family<MatchupDetails, ({int leagueId, int matchupId})>(
  (ref, key) async {
    final repo = ref.watch(matchupRepositoryProvider);
    return repo.getMatchupWithLineups(key.leagueId, key.matchupId);
  },
);
