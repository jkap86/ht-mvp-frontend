import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_config.dart';
import '../constants/socket_events.dart';

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());

/// Represents a pending event subscription to be applied when socket connects.
class _PendingSubscription {
  final String event;
  final void Function(dynamic) callback;
  _PendingSubscription(this.event, this.callback);
}

/// Represents a pending emit to be sent when socket connects.
class _PendingEmit {
  final String event;
  final dynamic data;
  _PendingEmit(this.event, this.data);
}

class SocketService {
  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Queue of subscriptions waiting for socket to connect
  final List<_PendingSubscription> _pendingSubscriptions = [];

  /// Queue of emits waiting for socket to connect
  final List<_PendingEmit> _pendingEmits = [];

  /// Track active subscriptions for proper disposer handling
  final Map<String, List<void Function(dynamic)>> _activeSubscriptions = {};

  /// Track active league rooms for automatic rejoin on reconnect
  final Set<int> _activeLeagueRooms = {};

  /// Track active draft rooms for automatic rejoin on reconnect
  final Set<int> _activeDraftRooms = {};

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storage.read(key: AppConfig.accessTokenKey);
    if (token == null) return;

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
      _applyPendingSubscriptions();
      _applyPendingEmits();
      _rejoinActiveRooms();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
    });

    _socket!.connect();
  }

  /// Apply any subscriptions that were registered before socket connected
  void _applyPendingSubscriptions() {
    if (_socket == null) return;
    for (final pending in _pendingSubscriptions) {
      _socket!.on(pending.event, pending.callback);
      _activeSubscriptions.putIfAbsent(pending.event, () => []).add(pending.callback);
    }
    _pendingSubscriptions.clear();
  }

  /// Apply any emits that were queued before socket connected
  void _applyPendingEmits() {
    if (_socket == null) return;
    for (final pending in _pendingEmits) {
      _socket!.emit(pending.event, pending.data);
    }
    _pendingEmits.clear();
  }

  /// Rejoin all active rooms after reconnection
  void _rejoinActiveRooms() {
    for (final leagueId in _activeLeagueRooms) {
      _socket?.emit(SocketEvents.leagueJoin, leagueId);
    }
    for (final draftId in _activeDraftRooms) {
      _socket?.emit(SocketEvents.draftJoin, draftId);
    }
  }

  void disconnect() {
    _pendingSubscriptions.clear();
    _pendingEmits.clear();
    _activeSubscriptions.clear();
    _activeLeagueRooms.clear();
    _activeDraftRooms.clear();
    _socket?.disconnect();
    _socket = null;
  }

  /// Reconnect with fresh token (used after token refresh).
  /// Disconnects existing socket and creates new connection with updated auth.
  /// Room tracking is preserved so rooms are automatically rejoined.
  Future<void> reconnect() async {
    debugPrint('Socket reconnecting with fresh token...');
    // Clear pending queues but preserve room tracking
    _pendingSubscriptions.clear();
    _pendingEmits.clear();
    _activeSubscriptions.clear();
    _socket?.disconnect();
    _socket = null;
    await connect();
  }

  /// Queue-aware emit: sends immediately if connected, otherwise queues for later
  void _emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      _pendingEmits.add(_PendingEmit(event, data));
    }
  }

  // League room management
  void joinLeague(int leagueId) {
    _activeLeagueRooms.add(leagueId);
    _emit(SocketEvents.leagueJoin, leagueId);
  }

  void leaveLeague(int leagueId) {
    _activeLeagueRooms.remove(leagueId);
    // Leave events should only fire if connected (no point queueing leave)
    if (_socket?.connected == true) {
      _socket?.emit(SocketEvents.leagueLeave, leagueId);
    }
  }

  // Draft room management
  void joinDraft(int draftId) {
    _activeDraftRooms.add(draftId);
    _emit(SocketEvents.draftJoin, draftId);
  }

  void leaveDraft(int draftId) {
    _activeDraftRooms.remove(draftId);
    // Leave events should only fire if connected (no point queueing leave)
    if (_socket?.connected == true) {
      _socket?.emit(SocketEvents.draftLeave, draftId);
    }
  }

  /// Generic event listener that returns a disposer function.
  /// If socket is not connected, queues the subscription for when it connects.
  /// Call the returned function to remove only this specific listener.
  VoidCallback on(String event, void Function(dynamic) callback) {
    if (_socket != null && _socket!.connected) {
      // Socket is connected, register immediately
      _socket!.on(event, callback);
      _activeSubscriptions.putIfAbsent(event, () => []).add(callback);
    } else {
      // Socket not connected, queue for later
      _pendingSubscriptions.add(_PendingSubscription(event, callback));
    }

    // Return a disposer that removes only this specific callback
    return () {
      // Remove from active subscriptions
      _activeSubscriptions[event]?.remove(callback);
      // Remove from socket if connected
      _socket?.off(event, callback);
      // Remove from pending queue if still there
      _pendingSubscriptions.removeWhere(
        (p) => p.event == event && p.callback == callback,
      );
    };
  }

  // Event listeners - all return disposers for proper cleanup
  // Call the returned function in dispose() to remove only your listener
  // Now always returns a non-null VoidCallback (subscriptions are queued if not connected)

  VoidCallback onDraftStarted(void Function(dynamic) callback) {
    return on(SocketEvents.draftStarted, callback);
  }

  VoidCallback onDraftPaused(void Function(dynamic) callback) {
    return on(SocketEvents.draftPaused, callback);
  }

  VoidCallback onDraftResumed(void Function(dynamic) callback) {
    return on(SocketEvents.draftResumed, callback);
  }

  VoidCallback onDraftPick(void Function(dynamic) callback) {
    return on(SocketEvents.draftPickMade, callback);
  }

  VoidCallback onNextPick(void Function(dynamic) callback) {
    return on(SocketEvents.draftNextPick, callback);
  }

  VoidCallback onDraftCompleted(void Function(dynamic) callback) {
    return on(SocketEvents.draftCompleted, callback);
  }

  /// Listen for pick undone events (commissioner undoing a pick)
  VoidCallback onPickUndone(void Function(dynamic) callback) {
    return on(SocketEvents.draftPickUndone, callback);
  }

  VoidCallback onUserJoinedDraft(void Function(dynamic) callback) {
    return on(SocketEvents.draftUserJoined, callback);
  }

  VoidCallback onUserLeftDraft(void Function(dynamic) callback) {
    return on(SocketEvents.draftUserLeft, callback);
  }

  VoidCallback onChatMessage(void Function(dynamic) callback) {
    return on(SocketEvents.chatMessage, callback);
  }

  /// Listen for queue updates (player removed from queue when drafted)
  VoidCallback onQueueUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.draftQueueUpdated, callback);
  }

  /// Listen for server-side errors (e.g., authorization failures)
  VoidCallback onAppError(void Function(dynamic) callback) {
    return on(SocketEvents.appError, callback);
  }

  // Slow Auction event listeners
  VoidCallback onAuctionLotCreated(void Function(dynamic) callback) {
    return on(SocketEvents.auctionLotCreated, callback);
  }

  VoidCallback onAuctionLotUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.auctionLotUpdated, callback);
  }

  VoidCallback onAuctionLotWon(void Function(dynamic) callback) {
    return on(SocketEvents.auctionLotWon, callback);
  }

  VoidCallback onAuctionLotPassed(void Function(dynamic) callback) {
    return on(SocketEvents.auctionLotPassed, callback);
  }

  VoidCallback onAuctionOutbid(void Function(dynamic) callback) {
    return on(SocketEvents.auctionOutbid, callback);
  }
}
