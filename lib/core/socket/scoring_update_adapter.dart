import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/socket_events.dart';
import 'socket_service.dart';

/// Type of scoring update received from the socket.
enum ScoringUpdateType {
  scoresUpdated,
  weekFinalized,
}

/// A scoring update event from the socket, normalized for consumers.
class ScoringUpdate {
  final int leagueId;
  final int? week;
  final ScoringUpdateType type;
  final DateTime receivedAt;

  ScoringUpdate({
    required this.leagueId,
    required this.week,
    required this.type,
    required this.receivedAt,
  });

  @override
  String toString() =>
      'ScoringUpdate(league=$leagueId, week=$week, type=$type)';
}

/// Central adapter that subscribes to scoring socket events and emits
/// debounced [ScoringUpdate]s on a broadcast stream.
///
/// - `scoresUpdated` events are debounced: max 1 emit per [debounceDuration]
///   per unique (leagueId, week) key (trailing edge).
/// - `weekFinalized` events bypass debounce entirely (infrequent + high-priority).
///
/// Multiple consumers (MatchupNotifier, MatchupDetailNotifier, etc.) subscribe
/// to [updates] instead of wiring socket listeners independently.
class ScoringUpdateAdapter {
  final SocketService _socketService;

  final _controller = StreamController<ScoringUpdate>.broadcast();

  /// Debounce timers keyed by "leagueId:week" (or "leagueId:all" for null week).
  final Map<String, Timer> _debounceTimers = {};

  /// Pending updates waiting to be emitted after debounce expires.
  final Map<String, ScoringUpdate> _pendingUpdates = {};

  final List<VoidCallback> _disposers = [];

  /// Duration of trailing-edge debounce for scoresUpdated events.
  static const debounceDuration = Duration(seconds: 2);

  ScoringUpdateAdapter(this._socketService) {
    _wireListeners();
  }

  /// Broadcast stream of debounced scoring updates.
  Stream<ScoringUpdate> get updates => _controller.stream;

  void _wireListeners() {
    // scoring:scores_updated
    _disposers.add(_socketService.onScoresUpdated((data) {
      _handleScoresUpdated(data);
    }));

    // scoring:scores_updated_v2 (future backend support)
    _disposers.add(_socketService.on(
      SocketEvents.scoringScoresUpdatedV2,
      (data) {
        _handleScoresUpdated(data);
      },
    ));

    // scoring:week_finalized — no debounce
    _disposers.add(_socketService.onWeekFinalized((data) {
      _handleWeekFinalized(data);
    }));
  }

  void _handleScoresUpdated(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    final leagueId = data['league_id'] as int? ?? data['leagueId'] as int?;
    if (leagueId == null) return;

    final week = data['week'] as int?;
    final update = ScoringUpdate(
      leagueId: leagueId,
      week: week,
      type: ScoringUpdateType.scoresUpdated,
      receivedAt: DateTime.now(),
    );

    final key = '$leagueId:${week ?? 'all'}';

    // Store the latest update and reset the debounce timer
    _pendingUpdates[key] = update;
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(debounceDuration, () {
      final pending = _pendingUpdates.remove(key);
      _debounceTimers.remove(key);
      if (pending != null && !_controller.isClosed) {
        if (kDebugMode) {
          debugPrint('ScoringAdapter: emitting $pending');
        }
        _controller.add(pending);
      }
    });
  }

  void _handleWeekFinalized(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    final leagueId = data['league_id'] as int? ?? data['leagueId'] as int?;
    if (leagueId == null) return;

    final week = data['week'] as int?;
    final update = ScoringUpdate(
      leagueId: leagueId,
      week: week,
      type: ScoringUpdateType.weekFinalized,
      receivedAt: DateTime.now(),
    );

    if (!_controller.isClosed) {
      if (kDebugMode) {
        debugPrint('ScoringAdapter: emitting (immediate) $update');
      }
      _controller.add(update);
    }
  }

  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingUpdates.clear();

    _controller.close();
  }
}

/// Singleton provider for the scoring update adapter.
final scoringUpdateAdapterProvider = Provider<ScoringUpdateAdapter>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final adapter = ScoringUpdateAdapter(socketService);

  ref.onDispose(() {
    adapter.dispose();
  });

  return adapter;
});
