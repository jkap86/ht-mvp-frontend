// Example: How to use SocketSessionManager in providers
//
// This file demonstrates common patterns for using the session manager
// in your feature providers.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_lifecycle.dart';
import 'socket_session_manager.dart';

// ============================================================================
// EXAMPLE 1: Basic provider using session manager for lifecycle events
// ============================================================================

class MyFeatureState {
  final bool isLoading;
  final List<String> items;
  final String? error;

  MyFeatureState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  MyFeatureState copyWith({
    bool? isLoading,
    List<String>? items,
    String? error,
  }) {
    return MyFeatureState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }
}

class MyFeatureNotifier extends StateNotifier<MyFeatureState> {
  final SocketSessionManager _sessionManager;
  StreamSubscription<SocketLifecycleEvent>? _lifecycleSubscription;

  MyFeatureNotifier(this._sessionManager) : super(MyFeatureState()) {
    _setupLifecycleListener();
    _loadInitialData();
  }

  void _setupLifecycleListener() {
    // Listen to lifecycle events from session manager
    _lifecycleSubscription = _sessionManager.lifecycleStream.listen((event) {
      switch (event) {
        case SocketLifecycleEvent.connected:
          // Initial connection - data already loaded in constructor
          break;

        case SocketLifecycleEvent.disconnected:
          // Lost connection - could show offline banner
          // (handled by app-level UI typically)
          break;

        case SocketLifecycleEvent.reconnectedLight:
          // Brief disconnect (<30s) - just refresh latest
          _refreshLatestData();
          break;

        case SocketLifecycleEvent.reconnectedFull:
          // Long disconnect (>30s) - reload everything
          _loadInitialData();
          break;

        case SocketLifecycleEvent.reconnectFailed:
          // Reconnection failed - show error
          state = state.copyWith(error: 'Connection failed');
          break;
      }
    });
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load data from API...
      final items = await _fetchItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> _refreshLatestData() async {
    try {
      // Fetch just the latest updates...
      final latestItems = await _fetchLatestItems();
      state = state.copyWith(items: [...latestItems, ...state.items]);
    } catch (e) {
      // Silently fail refresh - don't show error for background refresh
    }
  }

  Future<List<String>> _fetchItems() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return ['Item 1', 'Item 2', 'Item 3'];
  }

  Future<List<String>> _fetchLatestItems() async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));
    return ['New Item'];
  }

  @override
  void dispose() {
    _lifecycleSubscription?.cancel();
    super.dispose();
  }
}

final myFeatureProvider =
    StateNotifierProvider<MyFeatureNotifier, MyFeatureState>((ref) {
  final sessionManager = ref.watch(socketSessionManagerProvider);
  return MyFeatureNotifier(sessionManager);
});

// ============================================================================
// EXAMPLE 2: League-scoped provider with context tracking
// ============================================================================

class LeagueFeatureState {
  final int leagueId;
  final List<String> data;

  LeagueFeatureState({
    required this.leagueId,
    this.data = const [],
  });
}

class LeagueFeatureNotifier extends StateNotifier<LeagueFeatureState> {
  final SocketSessionManager _sessionManager;
  final int _leagueId;

  LeagueFeatureNotifier(this._sessionManager, this._leagueId)
      : super(LeagueFeatureState(leagueId: _leagueId)) {
    // Set league context on init
    _sessionManager.setLeagueContext(_leagueId);
    _loadData();
  }

  Future<void> _loadData() async {
    // Load league-specific data...
  }

  @override
  void dispose() {
    // Clear league context on dispose
    // (only if this was the context we set)
    if (_sessionManager.context.leagueId == _leagueId) {
      _sessionManager.clearLeagueContext();
    }
    super.dispose();
  }
}

// Provider factory for league-scoped features
final leagueFeatureProvider = StateNotifierProvider.family<
    LeagueFeatureNotifier, LeagueFeatureState, int>((ref, leagueId) {
  final sessionManager = ref.watch(socketSessionManagerProvider);
  return LeagueFeatureNotifier(sessionManager, leagueId);
});

// ============================================================================
// EXAMPLE 3: Using old callback pattern (still supported)
// ============================================================================

class LegacyFeatureNotifier extends StateNotifier<MyFeatureState> {
  final SocketSessionManager _sessionManager;
  VoidCallback? _reconnectDisposer;

  LegacyFeatureNotifier(this._sessionManager) : super(MyFeatureState()) {
    // Old pattern using callbacks still works
    _reconnectDisposer = _sessionManager.onReconnected((needsFullRefresh) {
      if (needsFullRefresh) {
        _loadInitialData();
      } else {
        _refreshLatestData();
      }
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load data...
  }

  Future<void> _refreshLatestData() async {
    // Refresh data...
  }

  @override
  void dispose() {
    _reconnectDisposer?.call();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 4: Monitoring connection state in UI
// ============================================================================

// Simple boolean provider for connection state
final isConnectedProvider = Provider<bool>((ref) {
  final sessionManager = ref.watch(socketSessionManagerProvider);
  return sessionManager.isConnected;
});

// Or use the built-in provider
// final isConnected = ref.watch(sessionConnectionStateProvider);

// ============================================================================
// EXAMPLE 5: Watching context changes
// ============================================================================

class ContextAwareNotifier extends StateNotifier<String> {
  final SocketSessionManager _sessionManager;
  StreamSubscription<SocketSessionContext>? _contextSubscription;

  ContextAwareNotifier(this._sessionManager) : super('No context') {
    _contextSubscription = _sessionManager.contextStream.listen((context) {
      // React to context changes
      if (context.leagueId != null) {
        state = 'In league ${context.leagueId}';
      } else if (context.draftId != null) {
        state = 'In draft ${context.draftId}';
      } else {
        state = 'No context';
      }
    });
  }

  @override
  void dispose() {
    _contextSubscription?.cancel();
    super.dispose();
  }
}
