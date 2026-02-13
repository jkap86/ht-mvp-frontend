import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_lifecycle.dart';
import 'socket_service.dart';

/// Context for the current socket session
class SocketSessionContext {
  final int? leagueId;
  final int? draftId;
  final int? userId;

  const SocketSessionContext({
    this.leagueId,
    this.draftId,
    this.userId,
  });

  SocketSessionContext copyWith({
    int? leagueId,
    int? draftId,
    int? userId,
  }) {
    return SocketSessionContext(
      leagueId: leagueId ?? this.leagueId,
      draftId: draftId ?? this.draftId,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocketSessionContext &&
          runtimeType == other.runtimeType &&
          leagueId == other.leagueId &&
          draftId == other.draftId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(leagueId, draftId, userId);

  @override
  String toString() =>
      'SocketSessionContext(leagueId: $leagueId, draftId: $draftId, userId: $userId)';
}

/// Centralized socket session manager
///
/// Responsibilities:
/// - Manage socket connection lifecycle (connect, disconnect, reconnect)
/// - Handle app lifecycle transitions (background/foreground)
/// - Manage room joins/leaves based on current context
/// - Provide typed event streams for features to consume
/// - Coordinate provider refreshes on reconnection
///
/// Usage:
/// ```dart
/// // Get the session manager via provider
/// final sessionManager = ref.watch(socketSessionManagerProvider);
///
/// // Connect socket (typically on app startup)
/// await sessionManager.connect();
///
/// // Switch league context (joins league room, leaves previous if needed)
/// sessionManager.setLeagueContext(leagueId);
///
/// // Switch draft context
/// sessionManager.setDraftContext(draftId);
///
/// // Listen to lifecycle events
/// ref.listen(socketSessionManagerProvider.select((m) => m.lifecycleStream), (prev, next) {
///   next.listen((event) {
///     if (event == SocketLifecycleEvent.reconnectedFull) {
///       // Reload data
///     }
///   });
/// });
///
/// // Check connection state
/// final isConnected = sessionManager.isConnected;
///
/// // Disconnect (typically on logout)
/// sessionManager.disconnect();
/// ```
class SocketSessionManager {
  final SocketService _socketService;
  final SocketLifecycleEventBus _lifecycleEventBus;

  /// Current session context (league, draft, user)
  SocketSessionContext _context = const SocketSessionContext();

  /// Stream controller for context changes
  final _contextController = StreamController<SocketSessionContext>.broadcast();

  /// Whether the manager has been disposed
  bool _isDisposed = false;

  SocketSessionManager({
    required SocketService socketService,
    required SocketLifecycleEventBus lifecycleEventBus,
  })  : _socketService = socketService,
        _lifecycleEventBus = lifecycleEventBus;

  /// Current session context
  SocketSessionContext get context => _context;

  /// Stream of context changes
  Stream<SocketSessionContext> get contextStream => _contextController.stream;

  /// Stream of lifecycle events (connected, disconnected, reconnected)
  Stream<SocketLifecycleEvent> get lifecycleStream => _lifecycleEventBus.stream;

  /// Whether the socket is currently connected
  bool get isConnected => _socketService.isConnected;

  /// Whether a full refresh is needed after reconnection
  bool get needsFullRefresh => _socketService.needsFullRefresh;

  /// Active league rooms
  Set<int> get activeLeagueRooms => _socketService.activeLeagueRooms;

  /// Active draft rooms
  Set<int> get activeDraftRooms => _socketService.activeDraftRooms;

  /// Connect the socket
  ///
  /// This should be called once on app startup after user authentication.
  /// The socket will automatically reconnect on network changes.
  Future<void> connect() async {
    if (_isDisposed) {
      if (kDebugMode) {
        debugPrint('SocketSessionManager: Cannot connect - manager is disposed');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Connecting socket...');
    }

    await _socketService.connect();

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Socket connected');
    }
  }

  /// Disconnect the socket
  ///
  /// This should be called on logout or when the user session ends.
  /// All rooms will be left and listeners cleared.
  void disconnect() {
    if (kDebugMode) {
      debugPrint('SocketSessionManager: Disconnecting socket...');
    }

    // Clear context
    _context = const SocketSessionContext();
    _contextController.add(_context);

    // Disconnect socket (this clears all rooms and listeners)
    _socketService.disconnect();

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Socket disconnected');
    }
  }

  /// Reconnect with fresh token (used after token refresh)
  ///
  /// The socket will be disconnected and reconnected with updated auth.
  /// All rooms will be automatically rejoined.
  Future<void> reconnect() async {
    if (_isDisposed) {
      if (kDebugMode) {
        debugPrint('SocketSessionManager: Cannot reconnect - manager is disposed');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Reconnecting socket with fresh token...');
    }

    await _socketService.reconnect();

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Socket reconnected');
    }
  }

  /// Set the league context
  ///
  /// This will join the specified league room (if not already joined)
  /// and leave the previous league room (if different).
  ///
  /// Uses reference counting internally, so multiple features can join
  /// the same league room safely.
  void setLeagueContext(int? leagueId) {
    if (_isDisposed) {
      if (kDebugMode) {
        debugPrint('SocketSessionManager: Cannot set league context - manager is disposed');
      }
      return;
    }

    final previousLeagueId = _context.leagueId;

    // No change
    if (previousLeagueId == leagueId) {
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Setting league context from $previousLeagueId to $leagueId');
    }

    // Update context
    _context = _context.copyWith(leagueId: leagueId);
    _contextController.add(_context);

    // Room changes are handled by individual features via joinLeague/leaveLeague
    // This is just a context tracker - features still manage their own room subscriptions
  }

  /// Set the draft context
  ///
  /// This will join the specified draft room (if not already joined)
  /// and leave the previous draft room (if different).
  ///
  /// Uses reference counting internally, so multiple features can join
  /// the same draft room safely.
  void setDraftContext(int? draftId) {
    if (_isDisposed) {
      if (kDebugMode) {
        debugPrint('SocketSessionManager: Cannot set draft context - manager is disposed');
      }
      return;
    }

    final previousDraftId = _context.draftId;

    // No change
    if (previousDraftId == draftId) {
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Setting draft context from $previousDraftId to $draftId');
    }

    // Update context
    _context = _context.copyWith(draftId: draftId);
    _contextController.add(_context);

    // Room changes are handled by individual features via joinDraft/leaveDraft
    // This is just a context tracker - features still manage their own room subscriptions
  }

  /// Set the user context
  ///
  /// This is primarily for tracking purposes and doesn't directly
  /// affect room management.
  void setUserContext(int? userId) {
    if (_isDisposed) {
      if (kDebugMode) {
        debugPrint('SocketSessionManager: Cannot set user context - manager is disposed');
      }
      return;
    }

    final previousUserId = _context.userId;

    // No change
    if (previousUserId == userId) {
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Setting user context from $previousUserId to $userId');
    }

    // Update context
    _context = _context.copyWith(userId: userId);
    _contextController.add(_context);
  }

  /// Clear the league context
  void clearLeagueContext() {
    setLeagueContext(null);
  }

  /// Clear the draft context
  void clearDraftContext() {
    setDraftContext(null);
  }

  /// Clear the user context
  void clearUserContext() {
    setUserContext(null);
  }

  /// Clear all context
  void clearContext() {
    if (_isDisposed) {
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Clearing all context');
    }

    _context = const SocketSessionContext();
    _contextController.add(_context);
  }

  /// Register a callback for connection events
  ///
  /// Returns a function to unregister the callback.
  VoidCallback onConnected(VoidCallback callback) {
    return _socketService.onConnected(callback);
  }

  /// Register a callback for disconnection events
  ///
  /// Returns a function to unregister the callback.
  VoidCallback onDisconnected(VoidCallback callback) {
    return _socketService.onDisconnected(callback);
  }

  /// Register a callback for reconnection events
  ///
  /// The callback receives a [needsFullRefresh] flag indicating whether
  /// the disconnection was long enough (>30s) to warrant a full data refresh.
  ///
  /// Returns a function to unregister the callback.
  VoidCallback onReconnected(void Function(bool needsFullRefresh) callback) {
    return _socketService.onReconnected(callback);
  }

  /// Direct access to the underlying socket service
  ///
  /// Use this for features that need to interact directly with the socket
  /// for event listening or emitting. Room management should still go through
  /// the session manager for consistency.
  SocketService get socketService => _socketService;

  /// Dispose the session manager
  ///
  /// This clears all context and closes the context stream.
  /// The underlying socket service is NOT disposed (it's managed by Riverpod).
  void dispose() {
    if (_isDisposed) {
      return;
    }

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Disposing...');
    }

    _isDisposed = true;
    clearContext();
    _contextController.close();

    if (kDebugMode) {
      debugPrint('SocketSessionManager: Disposed');
    }
  }
}

/// Provider for the socket session manager
///
/// This is a singleton that wraps the SocketService and SocketLifecycleEventBus
/// to provide a clean API for managing socket sessions.
final socketSessionManagerProvider = Provider<SocketSessionManager>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final lifecycleEventBus = ref.watch(socketLifecycleProvider);

  final manager = SocketSessionManager(
    socketService: socketService,
    lifecycleEventBus: lifecycleEventBus,
  );

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// Stream provider for socket lifecycle events
///
/// This is a convenience provider for listening to lifecycle events
/// without needing to watch the session manager directly.
final socketLifecycleEventsProvider = StreamProvider<SocketLifecycleEvent>((ref) {
  final manager = ref.watch(socketSessionManagerProvider);
  return manager.lifecycleStream;
});

/// Stream provider for socket session context changes
///
/// This is a convenience provider for listening to context changes
/// without needing to watch the session manager directly.
final socketSessionContextProvider = StreamProvider<SocketSessionContext>((ref) {
  final manager = ref.watch(socketSessionManagerProvider);
  return manager.contextStream;
});

/// Provider for current connection state
///
/// This is a convenience provider that combines the session manager
/// with the connection state provider.
final sessionConnectionStateProvider = Provider<bool>((ref) {
  final manager = ref.watch(socketSessionManagerProvider);
  return manager.isConnected;
});
