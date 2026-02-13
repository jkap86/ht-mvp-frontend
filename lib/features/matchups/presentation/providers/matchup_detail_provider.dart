import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, VoidCallback, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../../core/socket/scoring_update_adapter.dart';
import '../../data/matchup_repository.dart';
import '../../domain/matchup.dart';

/// State for a single matchup detail view
class MatchupDetailState {
  final MatchupDetails? details;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  MatchupDetailState({
    this.details,
    this.isLoading = true,
    this.error,
    this.lastUpdated,
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Relative time string for display
  String get lastUpdatedDisplay {
    if (lastUpdated == null) return '';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }

  MatchupDetailState copyWith({
    MatchupDetails? details,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return MatchupDetailState(
      details: details ?? this.details,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for a single matchup detail screen with real-time socket updates
class MatchupDetailNotifier extends StateNotifier<MatchupDetailState> {
  final MatchupRepository _repo;
  final SocketService _socketService;
  final ScoringUpdateAdapter _scoringAdapter;
  final int leagueId;
  final int matchupId;

  VoidCallback? _reconnectDisposer;
  StreamSubscription<ScoringUpdate>? _scoringSubscription;

  /// Throttle: minimum interval between HTTP refreshes from scoring events.
  static const _throttleInterval = Duration(seconds: 5);
  DateTime? _lastRefreshAt;
  Timer? _throttleTimer;

  MatchupDetailNotifier(
    this._repo,
    this._socketService,
    this._scoringAdapter,
    this.leagueId,
    this.matchupId,
  ) : super(MatchupDetailState()) {
    // Join the league room to receive events
    _socketService.joinLeague(leagueId);

    // Setup listeners
    _setupScoringListener();
    _setupReconnectListener();

    // Load initial data
    loadData();
  }

  void _setupScoringListener() {
    _scoringSubscription = _scoringAdapter.updates
        .where((update) => update.leagueId == leagueId)
        .where((update) {
          // Match if: event has no week, or event week matches our matchup week
          final matchupWeek = state.details?.matchup.week;
          return update.week == null ||
              (matchupWeek != null && update.week == matchupWeek);
        })
        .listen((update) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('MatchupDetail($matchupId): Scoring update received: $update');
      }
      _throttledRefresh();
    });
  }

  void _setupReconnectListener() {
    // Resync on socket reconnection
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint('MatchupDetail($matchupId): Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }

      if (needsFullRefresh) {
        // Long disconnect - full reload with loading state
        loadData();
      } else {
        // Short disconnect - background refresh
        _refreshMatchup();
      }
    });
  }

  /// Throttled refresh: leading edge fires immediately if enough time has passed,
  /// trailing edge schedules a final refresh for any events arriving during cooldown.
  void _throttledRefresh() {
    final now = DateTime.now();
    if (_lastRefreshAt == null ||
        now.difference(_lastRefreshAt!) >= _throttleInterval) {
      // Leading edge: fire immediately
      _lastRefreshAt = now;
      _throttleTimer?.cancel();
      _throttleTimer = null;
      _refreshMatchup();
    } else {
      // During cooldown: schedule trailing edge
      if (_throttleTimer == null || !_throttleTimer!.isActive) {
        final remaining = _throttleInterval - now.difference(_lastRefreshAt!);
        _throttleTimer = Timer(remaining, () {
          if (!mounted) return;
          _lastRefreshAt = DateTime.now();
          _throttleTimer = null;
          _refreshMatchup();
        });
      }
    }
  }

  /// Load matchup data with loading state (for initial load and manual refresh)
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final details = await _repo.getMatchupWithLineups(leagueId, matchupId);
      if (mounted) {
        state = state.copyWith(
          details: details,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e, st) {
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to load matchup: ${e.toString()}',
          isLoading: false,
        );
      }
      if (kDebugMode) debugPrint('Failed to load matchup details: $e\n$st');
    }
  }

  /// Refresh matchup data in background (for socket events and auto-refresh)
  /// Does not show loading state, silently fails on error
  Future<void> _refreshMatchup() async {
    try {
      final details = await _repo.getMatchupWithLineups(leagueId, matchupId);
      if (mounted) {
        state = state.copyWith(
          details: details,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      // Silently fail on background refresh
      if (kDebugMode) debugPrint('Failed to refresh matchup: $e');
    }
  }

  @override
  void dispose() {
    _scoringSubscription?.cancel();
    _throttleTimer?.cancel();
    _reconnectDisposer?.call();

    // Leave the league room
    _socketService.leaveLeague(leagueId);

    super.dispose();
  }
}

/// Provider for matchup detail screen with real-time socket updates
final matchupDetailProvider = StateNotifierProvider.autoDispose
    .family<MatchupDetailNotifier, MatchupDetailState, ({int leagueId, int matchupId})>(
  (ref, key) => MatchupDetailNotifier(
    ref.watch(matchupRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(scoringUpdateAdapterProvider),
    key.leagueId,
    key.matchupId,
  ),
);
