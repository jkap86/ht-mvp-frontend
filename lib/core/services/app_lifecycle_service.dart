import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../socket/socket_service.dart';
import 'sync_service.dart';

/// Callback type for providers that can refresh on app resume.
typedef RefreshCallback = Future<void> Function();

/// Service that handles app lifecycle events and triggers data refreshes.
///
/// When the app resumes from background:
/// - If backgrounded for > 30 seconds, triggers full data refresh
/// - Reconnects socket if needed
/// - Notifies registered providers to refresh their data
class AppLifecycleService with WidgetsBindingObserver {
  final SocketService _socketService;
  final SyncService _syncService;

  DateTime? _backgroundedAt;
  final List<RefreshCallback> _refreshCallbacks = [];

  /// Duration threshold for determining if data refresh is needed.
  /// If app was backgrounded longer than this, trigger refresh on resume.
  static const staleThreshold = Duration(seconds: 30);

  AppLifecycleService(this._socketService, this._syncService, Ref _) {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshCallbacks.clear();
  }

  /// Register a callback to be called when the app resumes and data needs refreshing.
  /// Returns a function to unregister the callback.
  VoidCallback registerRefreshCallback(RefreshCallback callback) {
    _refreshCallbacks.add(callback);
    return () => _refreshCallbacks.remove(callback);
  }

  /// Check if data should be considered stale based on time spent in background.
  bool get wasBackgroundedLongEnough {
    if (_backgroundedAt == null) return false;
    return DateTime.now().difference(_backgroundedAt!) > staleThreshold;
  }

  /// Duration the app was in the background.
  Duration get backgroundDuration {
    if (_backgroundedAt == null) return Duration.zero;
    return DateTime.now().difference(_backgroundedAt!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App is going to background - only set on paused (not inactive)
        // inactive fires for brief interruptions like permission dialogs
        _backgroundedAt = DateTime.now();
        break;
      case AppLifecycleState.inactive:
        // Brief interruptions (permission dialogs, etc.) - don't update timestamp
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        _onAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being destroyed or hidden
        break;
    }
  }

  void _onAppResumed() {
    final wasStale = wasBackgroundedLongEnough;
    final duration = backgroundDuration;
    _backgroundedAt = null;

    if (kDebugMode) {
      debugPrint('App resumed after ${duration.inSeconds}s, refreshing: $wasStale');
    }

    // Always try to ensure socket is connected
    if (!_socketService.isConnected) {
      _socketService.connect();
    }

    // Only refresh if we were backgrounded long enough
    if (wasStale) {
      _syncService.syncAll();
      _triggerRefreshCallbacks();
    }
  }

  Future<void> _triggerRefreshCallbacks() async {
    if (kDebugMode) {
      debugPrint('Triggering ${_refreshCallbacks.length} refresh callbacks');
    }
    for (final callback in _refreshCallbacks) {
      try {
        await callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in refresh callback: $e');
        }
      }
    }
  }

  /// Manually trigger a refresh of all registered providers.
  /// Useful for testing or forced refresh scenarios.
  Future<void> forceRefresh() async {
    await _triggerRefreshCallbacks();
  }
}

/// Provider for the app lifecycle service.
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  final service = AppLifecycleService(socketService, syncService, ref);
  ref.onDispose(() => service.dispose());
  return service;
});
