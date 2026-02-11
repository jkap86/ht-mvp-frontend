import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback type for sync operations.
typedef SyncCallback = Future<void> Function();

/// Service to coordinate data refresh across providers.
///
/// This service provides a centralized way to:
/// - Trigger refresh for specific league data
/// - Trigger refresh for specific draft data
/// - Trigger a full refresh of all active providers
///
/// Providers register themselves with the sync service and are notified
/// when a sync is requested.
class SyncService {
  final Ref _ref;

  /// Map of leagueId -> list of sync callbacks
  final Map<int, List<SyncCallback>> _leagueSyncCallbacks = {};

  /// Map of draftId -> list of sync callbacks
  final Map<int, List<SyncCallback>> _draftSyncCallbacks = {};

  /// List of callbacks for global sync
  final List<SyncCallback> _globalSyncCallbacks = [];

  SyncService(this._ref);

  /// Register a callback to be called when league data should be synced.
  /// Returns a function to unregister the callback.
  VoidCallback registerLeagueSync(int leagueId, SyncCallback callback) {
    _leagueSyncCallbacks.putIfAbsent(leagueId, () => []).add(callback);
    return () {
      _leagueSyncCallbacks[leagueId]?.remove(callback);
      if (_leagueSyncCallbacks[leagueId]?.isEmpty ?? false) {
        _leagueSyncCallbacks.remove(leagueId);
      }
    };
  }

  /// Register a callback to be called when draft data should be synced.
  /// Returns a function to unregister the callback.
  VoidCallback registerDraftSync(int draftId, SyncCallback callback) {
    _draftSyncCallbacks.putIfAbsent(draftId, () => []).add(callback);
    return () {
      _draftSyncCallbacks[draftId]?.remove(callback);
      if (_draftSyncCallbacks[draftId]?.isEmpty ?? false) {
        _draftSyncCallbacks.remove(draftId);
      }
    };
  }

  /// Register a callback to be called on global sync.
  /// Returns a function to unregister the callback.
  VoidCallback registerGlobalSync(SyncCallback callback) {
    _globalSyncCallbacks.add(callback);
    return () => _globalSyncCallbacks.remove(callback);
  }

  /// Sync all data for a specific league.
  Future<void> syncLeagueData(int leagueId) async {
    final callbacks = _leagueSyncCallbacks[leagueId];
    if (callbacks == null || callbacks.isEmpty) {
      if (kDebugMode) {
        debugPrint('SyncService: No callbacks registered for league $leagueId');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('SyncService: Syncing ${callbacks.length} callbacks for league $leagueId');
    }
    // Copy list to prevent concurrent modification if callbacks dispose providers
    for (final callback in List<SyncCallback>.from(callbacks)) {
      try {
        await callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SyncService: Error syncing league $leagueId: $e');
        }
      }
    }
  }

  /// Sync all data for a specific draft.
  Future<void> syncDraftData(int draftId) async {
    final callbacks = _draftSyncCallbacks[draftId];
    if (callbacks == null || callbacks.isEmpty) {
      if (kDebugMode) {
        debugPrint('SyncService: No callbacks registered for draft $draftId');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('SyncService: Syncing ${callbacks.length} callbacks for draft $draftId');
    }
    // Copy list to prevent concurrent modification if callbacks dispose providers
    for (final callback in List<SyncCallback>.from(callbacks)) {
      try {
        await callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SyncService: Error syncing draft $draftId: $e');
        }
      }
    }
  }

  /// Sync all registered providers globally.
  Future<void> syncAll() async {
    if (kDebugMode) {
      debugPrint('SyncService: Starting global sync');
    }

    // Sync all leagues
    for (final leagueId in _leagueSyncCallbacks.keys.toList()) {
      await syncLeagueData(leagueId);
    }

    // Sync all drafts
    for (final draftId in _draftSyncCallbacks.keys.toList()) {
      await syncDraftData(draftId);
    }

    // Copy list to prevent concurrent modification if callbacks dispose providers
    for (final callback in List<SyncCallback>.from(_globalSyncCallbacks)) {
      try {
        await callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SyncService: Error in global sync callback: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('SyncService: Global sync complete');
    }
  }

  /// Get list of active league IDs with registered sync callbacks.
  Set<int> get activeLeagueIds => _leagueSyncCallbacks.keys.toSet();

  /// Get list of active draft IDs with registered sync callbacks.
  Set<int> get activeDraftIds => _draftSyncCallbacks.keys.toSet();
}

/// Provider for the sync service.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
