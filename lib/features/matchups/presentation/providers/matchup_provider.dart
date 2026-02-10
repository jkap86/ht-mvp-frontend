import 'package:flutter/foundation.dart' show kDebugMode, VoidCallback, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
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
  final DateTime? lastUpdated;
  final int? maxScheduledWeek; // Maximum week with scheduled matchups

  MatchupState({
    this.league,
    this.matchups = const [],
    this.currentWeek = 1,
    this.myRosterId,
    this.isLoading = true,
    this.error,
    this.lastUpdated,
    this.maxScheduledWeek,
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Get the current user's matchup
  Matchup? get myMatchup {
    if (myRosterId == null) return null;
    return matchups.where((m) =>
        m.roster1Id == myRosterId || m.roster2Id == myRosterId).firstOrNull;
  }

  /// Get all matchups for the current week
  List<Matchup> get weekMatchups => matchups;

  /// Check if user is on a BYE week (has roster but no matchup)
  bool get isOnBye => myRosterId != null && myMatchup == null;

  MatchupState copyWith({
    League? league,
    List<Matchup>? matchups,
    int? currentWeek,
    int? myRosterId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
    int? maxScheduledWeek,
  }) {
    return MatchupState(
      league: league ?? this.league,
      matchups: matchups ?? this.matchups,
      currentWeek: currentWeek ?? this.currentWeek,
      myRosterId: myRosterId ?? this.myRosterId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      maxScheduledWeek: maxScheduledWeek ?? this.maxScheduledWeek,
    );
  }
}

class MatchupNotifier extends StateNotifier<MatchupState> {
  final MatchupRepository _matchupRepo;
  final LeagueRepository _leagueRepo;
  final SocketService _socketService;
  final InvalidationService _invalidationService;
  final SyncService _syncService;
  final int leagueId;

  final List<VoidCallback> _socketDisposers = [];
  VoidCallback? _invalidationDisposer;
  VoidCallback? _reconnectDisposer;
  VoidCallback? _syncDisposer;

  MatchupNotifier(
    this._matchupRepo,
    this._leagueRepo,
    this._socketService,
    this._invalidationService,
    this._syncService,
    this.leagueId,
  ) : super(MatchupState()) {
    _setupSocketListeners();
    _registerInvalidationCallback();
    _syncDisposer = _syncService.registerLeagueSync(leagueId, loadData);
    loadData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.matchups,
      leagueId,
      loadData,
    );
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

    // Resync matchups on socket reconnection
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      if (needsFullRefresh) {
        if (kDebugMode) debugPrint('Matchups: Socket reconnected after long disconnect, reloading');
        loadData();
      } else {
        // Short disconnect - scores may have changed, do background refresh
        _refreshMatchups();
      }
    });
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
      if (kDebugMode) debugPrint('Failed to refresh matchups: $e');
    }
  }

  @override
  void dispose() {
    for (final disposer in _socketDisposers) {
      disposer();
    }
    _socketDisposers.clear();
    _invalidationDisposer?.call();
    _reconnectDisposer?.call();
    _syncDisposer?.call();
    super.dispose();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch league and max scheduled week in parallel
      final league = await _leagueRepo.getLeague(leagueId);
      final currentWeek = league.currentWeek;

      final results = await Future.wait([
        _matchupRepo.getMatchups(leagueId, week: currentWeek),
        _matchupRepo.getMaxScheduledWeek(leagueId),
      ]);

      final matchups = results[0] as List<Matchup>;
      final maxScheduledWeek = results[1] as int;

      state = state.copyWith(
        league: league,
        matchups: matchups,
        currentWeek: currentWeek,
        myRosterId: league.userRosterId,
        isLoading: false,
        lastUpdated: DateTime.now(),
        maxScheduledWeek: maxScheduledWeek,
      );
    } catch (e) {
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
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
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final matchupProvider = StateNotifierProvider.autoDispose.family<MatchupNotifier, MatchupState, int>(
  (ref, leagueId) => MatchupNotifier(
    ref.watch(matchupRepositoryProvider),
    ref.watch(leagueRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(invalidationServiceProvider),
    ref.watch(syncServiceProvider),
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
