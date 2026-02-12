import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_service.dart';

/// Lifecycle events emitted by the socket connection.
///
/// Feature providers subscribe to these events to coordinate their
/// state refresh logic in one place, rather than each provider
/// independently wiring up reconnect handlers.
enum SocketLifecycleEvent {
  /// Socket has connected (initial connection).
  connected,

  /// Socket has disconnected (network loss, server restart, etc.).
  disconnected,

  /// Socket has reconnected after a brief disconnect (<30s).
  /// Providers should do a lightweight resync (e.g., refresh latest state).
  reconnectedLight,

  /// Socket has reconnected after a long disconnect (>30s).
  /// Providers should do a full data reload.
  reconnectedFull,

  /// Socket reconnection has failed after exhausting retries.
  reconnectFailed,
}

/// Centralized event bus for socket lifecycle events.
///
/// This provides a single stream that feature providers can subscribe to
/// instead of each one independently calling `socketService.onReconnected`.
///
/// Benefits:
/// - Single source of truth for lifecycle state
/// - Stream-based API works naturally with Riverpod
/// - `reconnectedLight` vs `reconnectedFull` distinction is pre-computed
/// - Supports `reconnectFailed` event for error UI
///
/// Usage in a StateNotifier provider:
/// ```dart
/// _lifecycleDisposer = ref.listen(socketLifecycleProvider, (prev, next) {
///   next.whenData((event) {
///     if (event == SocketLifecycleEvent.reconnectedFull) {
///       loadAllData();
///     } else if (event == SocketLifecycleEvent.reconnectedLight) {
///       refreshLatestState();
///     }
///   });
/// });
/// ```
class SocketLifecycleEventBus {
  final SocketService _socketService;
  final _controller = StreamController<SocketLifecycleEvent>.broadcast();

  VoidCallback? _connectDisposer;
  VoidCallback? _disconnectDisposer;
  VoidCallback? _reconnectDisposer;

  /// Whether we have seen the initial connection yet.
  /// Used to distinguish initial connect from reconnect in the onConnected callback.
  bool _hasConnectedOnce = false;

  SocketLifecycleEventBus(this._socketService) {
    _wireSocketCallbacks();
  }

  /// The broadcast stream of lifecycle events.
  /// Multiple listeners can subscribe to this stream simultaneously.
  Stream<SocketLifecycleEvent> get stream => _controller.stream;

  void _wireSocketCallbacks() {
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      final event = needsFullRefresh
          ? SocketLifecycleEvent.reconnectedFull
          : SocketLifecycleEvent.reconnectedLight;
      if (kDebugMode) {
        debugPrint('SocketLifecycle: $event');
      }
      _controller.add(event);
    });

    _connectDisposer = _socketService.onConnected(() {
      if (!_hasConnectedOnce) {
        _hasConnectedOnce = true;
        if (kDebugMode) {
          debugPrint('SocketLifecycle: connected (initial)');
        }
        _controller.add(SocketLifecycleEvent.connected);
      }
      // Reconnect events are handled by onReconnected above
    });

    _disconnectDisposer = _socketService.onDisconnected(() {
      if (kDebugMode) {
        debugPrint('SocketLifecycle: disconnected');
      }
      _controller.add(SocketLifecycleEvent.disconnected);
    });
  }

  /// Manually emit a reconnectFailed event.
  /// Called by the socket service or app-level error handler when
  /// reconnection attempts are exhausted.
  void emitReconnectFailed() {
    if (kDebugMode) {
      debugPrint('SocketLifecycle: reconnectFailed');
    }
    _controller.add(SocketLifecycleEvent.reconnectFailed);
  }

  void dispose() {
    _connectDisposer?.call();
    _disconnectDisposer?.call();
    _reconnectDisposer?.call();
    _controller.close();
  }
}

/// Provides the socket lifecycle event bus as a singleton.
///
/// The event bus wires itself to the SocketService's connect/disconnect/reconnect
/// callbacks and re-emits them as a typed stream.
final socketLifecycleProvider = Provider<SocketLifecycleEventBus>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final bus = SocketLifecycleEventBus(socketService);

  ref.onDispose(() {
    bus.dispose();
  });

  return bus;
});

/// Stream provider for reacting to socket lifecycle events in widgets/providers.
///
/// Usage with ref.listen:
/// ```dart
/// ref.listen(socketLifecycleStreamProvider, (prev, next) {
///   next.whenData((event) {
///     if (event == SocketLifecycleEvent.reconnectedFull) {
///       loadData();
///     }
///   });
/// });
/// ```
final socketLifecycleStreamProvider = StreamProvider<SocketLifecycleEvent>((ref) {
  final bus = ref.watch(socketLifecycleProvider);
  return bus.stream;
});
