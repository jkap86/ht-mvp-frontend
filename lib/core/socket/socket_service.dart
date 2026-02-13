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

  /// Track active league rooms with reference counting.
  /// Key: leagueId, Value: number of active listeners.
  /// Only emits join/leave when count transitions to/from 0.
  final Map<int, int> _leagueRoomRefCount = {};

  /// Track active draft rooms with reference counting.
  /// Key: draftId, Value: number of active listeners.
  /// Only emits join/leave when count transitions to/from 0.
  final Map<int, int> _draftRoomRefCount = {};

  /// Temporarily store listeners during reconnect for re-registration
  Map<String, List<void Function(dynamic)>>? _listenersToRestore;

  /// Callbacks to notify when socket reconnects (receives needsFullRefresh flag)
  final List<void Function(bool needsFullRefresh)> _reconnectCallbacks = [];

  /// Callbacks to notify when socket connects (initial or reconnect)
  final List<VoidCallback> _connectCallbacks = [];

  /// Callbacks to notify when socket disconnects
  final List<VoidCallback> _disconnectCallbacks = [];

  /// Track when the socket was disconnected to determine refresh scope
  DateTime? _disconnectedAt;

  /// Duration threshold for determining if full data refresh is needed after reconnect
  static const reconnectRefreshThreshold = Duration(seconds: 30);

  /// Timeout for initial socket connection attempt
  static const connectionTimeout = Duration(seconds: 10);

  bool get isConnected => _socket?.connected ?? false;

  /// Get the active league room IDs (rooms with ref count > 0)
  Set<int> get activeLeagueRooms => Set.unmodifiable(_leagueRoomRefCount.keys.toSet());

  /// Get the active draft room IDs (rooms with ref count > 0)
  Set<int> get activeDraftRooms => Set.unmodifiable(_draftRoomRefCount.keys.toSet());

  /// Check if we were disconnected long enough to need a full refresh
  bool get needsFullRefresh {
    if (_disconnectedAt == null) return false;
    return DateTime.now().difference(_disconnectedAt!) > reconnectRefreshThreshold;
  }

  /// Register a callback to be called when socket reconnects.
  /// The callback receives a [needsFullRefresh] flag indicating whether the
  /// disconnection was long enough (>30s) to warrant a full data refresh.
  /// Returns a function to unregister the callback.
  VoidCallback onReconnected(void Function(bool needsFullRefresh) callback) {
    _reconnectCallbacks.add(callback);
    return () => _reconnectCallbacks.remove(callback);
  }

  /// Register a callback to be called when socket disconnects.
  /// Returns a function to unregister the callback.
  VoidCallback onDisconnected(VoidCallback callback) {
    _disconnectCallbacks.add(callback);
    return () => _disconnectCallbacks.remove(callback);
  }

  /// Register a callback for ANY connection (initial or reconnect).
  /// Returns a function to unregister the callback.
  VoidCallback onConnected(VoidCallback callback) {
    _connectCallbacks.add(callback);
    return () => _connectCallbacks.remove(callback);
  }

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
          .setReconnectionDelay(1000) // 1 second between reconnection attempts
          .setReconnectionDelayMax(5000) // Max 5 seconds between attempts
          .setTimeout(connectionTimeout.inMilliseconds) // Connection timeout
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('Socket connected');
      final wasDisconnected = _disconnectedAt != null;
      final shouldRefresh = needsFullRefresh;
      _applyPendingSubscriptions();
      _applyPendingEmits();
      _rejoinActiveRooms();

      // Notify reconnect callbacks if this was a reconnection
      if (wasDisconnected) {
        if (kDebugMode) debugPrint('Socket reconnected after ${_disconnectedAt != null ? DateTime.now().difference(_disconnectedAt!).inSeconds : 0}s, triggering ${_reconnectCallbacks.length} callbacks, needsFullRefresh: $shouldRefresh');
        _disconnectedAt = null;
        for (final callback in _reconnectCallbacks) {
          try {
            callback(shouldRefresh);
          } catch (e) {
            if (kDebugMode) debugPrint('Error in reconnect callback: $e');
          }
        }
      }

      // Notify connect callbacks for ALL connections (initial and reconnect)
      for (final callback in _connectCallbacks) {
        try {
          callback();
        } catch (e) {
          if (kDebugMode) debugPrint('Error in connect callback: $e');
        }
      }
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) debugPrint('Socket disconnected');
      _disconnectedAt = DateTime.now();
      // Notify disconnect callbacks
      for (final callback in _disconnectCallbacks) {
        try {
          callback();
        } catch (e) {
          if (kDebugMode) debugPrint('Error in disconnect callback: $e');
        }
      }
    });

    _socket!.onConnectError((error) {
      if (kDebugMode) debugPrint('Socket connection error: $error');
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

  /// Rejoin all active rooms and restore listeners after reconnection
  void _rejoinActiveRooms() {
    for (final leagueId in _leagueRoomRefCount.keys) {
      _socket?.emit(SocketEvents.leagueJoin, leagueId);
    }
    for (final draftId in _draftRoomRefCount.keys) {
      _socket?.emit(SocketEvents.draftJoin, draftId);
    }

    // Re-register preserved listeners from reconnect
    if (_listenersToRestore != null && _socket != null) {
      for (final entry in _listenersToRestore!.entries) {
        final event = entry.key;
        for (final callback in entry.value) {
          _socket!.on(event, callback);
          _activeSubscriptions.putIfAbsent(event, () => []).add(callback);
        }
      }
      if (kDebugMode) debugPrint('Restored ${_listenersToRestore!.length} event listener groups after reconnect');
      _listenersToRestore = null;
    }
  }

  void disconnect() {
    _pendingSubscriptions.clear();
    _pendingEmits.clear();
    _activeSubscriptions.clear();
    _leagueRoomRefCount.clear();
    _draftRoomRefCount.clear();
    _reconnectCallbacks.clear();
    _connectCallbacks.clear();
    _disconnectCallbacks.clear();
    _listenersToRestore = null;
    _disconnectedAt = null;
    _socket?.disconnect();
    _socket = null;
  }

  /// Reconnect with fresh token (used after token refresh).
  /// Disconnects existing socket and creates new connection with updated auth.
  /// Room tracking and listeners are preserved so they are automatically restored.
  Future<void> reconnect() async {
    if (kDebugMode) debugPrint('Socket reconnecting with fresh token...');

    // Preserve listener metadata for re-registration after reconnect
    _listenersToRestore = Map<String, List<void Function(dynamic)>>.from(
      _activeSubscriptions.map((event, callbacks) => MapEntry(event, List<void Function(dynamic)>.from(callbacks))),
    );

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

  // League room management with reference counting.
  // Multiple providers can join the same room; only the first join emits
  // the server event, and only the last leave emits the leave event.
  void joinLeague(int leagueId) {
    final currentCount = _leagueRoomRefCount[leagueId] ?? 0;
    _leagueRoomRefCount[leagueId] = currentCount + 1;
    if (kDebugMode) {
      debugPrint('Socket: joinLeague($leagueId) refCount $currentCount -> ${currentCount + 1}');
    }
    // Only emit join on first reference (0 -> 1)
    if (currentCount == 0) {
      _emit(SocketEvents.leagueJoin, leagueId);
    }
  }

  void leaveLeague(int leagueId) {
    final currentCount = _leagueRoomRefCount[leagueId] ?? 0;
    if (currentCount <= 0) {
      // Leave without matching join -- log warning and do nothing
      if (kDebugMode) {
        debugPrint('Socket: WARNING leaveLeague($leagueId) called with refCount 0 (no matching join)');
      }
      return;
    }
    final newCount = currentCount - 1;
    if (kDebugMode) {
      debugPrint('Socket: leaveLeague($leagueId) refCount $currentCount -> $newCount');
    }
    if (newCount == 0) {
      // Last reference, remove from map and emit leave
      _leagueRoomRefCount.remove(leagueId);
      if (_socket?.connected == true) {
        _socket?.emit(SocketEvents.leagueLeave, leagueId);
      }
    } else {
      // Other listeners still active, just decrement
      _leagueRoomRefCount[leagueId] = newCount;
    }
  }

  // Draft room management with reference counting.
  // Multiple providers can join the same room; only the first join emits
  // the server event, and only the last leave emits the leave event.
  void joinDraft(int draftId) {
    final currentCount = _draftRoomRefCount[draftId] ?? 0;
    _draftRoomRefCount[draftId] = currentCount + 1;
    if (kDebugMode) {
      debugPrint('Socket: joinDraft($draftId) refCount $currentCount -> ${currentCount + 1}');
    }
    // Only emit join on first reference (0 -> 1)
    if (currentCount == 0) {
      _emit(SocketEvents.draftJoin, draftId);
    }
  }

  void leaveDraft(int draftId) {
    final currentCount = _draftRoomRefCount[draftId] ?? 0;
    if (currentCount <= 0) {
      // Leave without matching join -- log warning and do nothing
      if (kDebugMode) {
        debugPrint('Socket: WARNING leaveDraft($draftId) called with refCount 0 (no matching join)');
      }
      return;
    }
    final newCount = currentCount - 1;
    if (kDebugMode) {
      debugPrint('Socket: leaveDraft($draftId) refCount $currentCount -> $newCount');
    }
    if (newCount == 0) {
      // Last reference, remove from map and emit leave
      _draftRoomRefCount.remove(draftId);
      if (_socket?.connected == true) {
        _socket?.emit(SocketEvents.draftLeave, draftId);
      }
    } else {
      // Other listeners still active, just decrement
      _draftRoomRefCount[draftId] = newCount;
    }
  }

  /// Debug helper: get current ref counts for league rooms.
  /// Only intended for debug/testing use.
  Map<int, int> get debugLeagueRefCounts => Map.unmodifiable(_leagueRoomRefCount);

  /// Debug helper: get current ref counts for draft rooms.
  /// Only intended for debug/testing use.
  Map<int, int> get debugDraftRefCounts => Map.unmodifiable(_draftRoomRefCount);

  /// Validate that a socket payload is a Map with expected structure
  bool _isValidPayload(dynamic data, {List<String>? requiredFields}) {
    if (data == null) return false;
    if (data is! Map<String, dynamic>) return false;

    // Check required fields if specified
    if (requiredFields != null) {
      for (final field in requiredFields) {
        if (!data.containsKey(field)) return false;
      }
    }

    return true;
  }

  /// Wrap callback with payload validation and context filtering
  void Function(dynamic) _wrapCallback(
    void Function(dynamic) callback, {
    int? expectedLeagueId,
    int? expectedDraftId,
    List<String>? requiredFields,
  }) {
    return (dynamic data) {
      // Validate payload structure
      if (!_isValidPayload(data, requiredFields: requiredFields)) {
        if (kDebugMode) {
          debugPrint('Socket: Invalid payload received, ignoring event');
        }
        return;
      }

      final payload = data as Map<String, dynamic>;

      // Filter by league context if specified
      if (expectedLeagueId != null) {
        final eventLeagueId = payload['league_id'] as int? ?? payload['leagueId'] as int?;
        if (eventLeagueId != null && eventLeagueId != expectedLeagueId) {
          if (kDebugMode) {
            debugPrint('Socket: Event from wrong league (expected $expectedLeagueId, got $eventLeagueId), ignoring');
          }
          return;
        }
      }

      // Filter by draft context if specified
      if (expectedDraftId != null) {
        final eventDraftId = payload['draft_id'] as int? ?? payload['draftId'] as int?;
        if (eventDraftId != null && eventDraftId != expectedDraftId) {
          if (kDebugMode) {
            debugPrint('Socket: Event from wrong draft (expected $expectedDraftId, got $eventDraftId), ignoring');
          }
          return;
        }
      }

      // Payload is valid and matches context, invoke callback
      callback(data);
    };
  }

  /// Generic event listener that returns a disposer function.
  /// If socket is not connected, queues the subscription for when it connects.
  /// Call the returned function to remove only this specific listener.
  VoidCallback on(String event, void Function(dynamic) callback, {
    int? expectedLeagueId,
    int? expectedDraftId,
    List<String>? requiredFields,
  }) {
    // Wrap callback with validation and context filtering
    final wrappedCallback = _wrapCallback(
      callback,
      expectedLeagueId: expectedLeagueId,
      expectedDraftId: expectedDraftId,
      requiredFields: requiredFields,
    );

    if (_socket != null && _socket!.connected) {
      // Socket is connected, register immediately
      _socket!.on(event, wrappedCallback);
      _activeSubscriptions.putIfAbsent(event, () => []).add(wrappedCallback);
    } else {
      // Socket not connected, queue for later
      _pendingSubscriptions.add(_PendingSubscription(event, wrappedCallback));
    }

    // Return a disposer that removes only this specific callback
    return () {
      // Remove from active subscriptions
      _activeSubscriptions[event]?.remove(wrappedCallback);
      // Remove from socket if connected
      _socket?.off(event, wrappedCallback);
      // Remove from pending queue if still there
      _pendingSubscriptions.removeWhere(
        (p) => p.event == event && p.callback == wrappedCallback,
      );
      // Also remove from listeners to restore (prevents restoring disposed callbacks during reconnect)
      _listenersToRestore?[event]?.remove(wrappedCallback);
    };
  }

  // Event listeners - all return disposers for proper cleanup
  // Call the returned function in dispose() to remove only your listener
  // Now always returns a non-null VoidCallback (subscriptions are queued if not connected)

  VoidCallback onDraftCreated(void Function(dynamic) callback) {
    return on(SocketEvents.draftCreated, callback);
  }

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

  VoidCallback onChatReactionAdded(void Function(dynamic) callback) {
    return on(SocketEvents.chatReactionAdded, callback);
  }

  VoidCallback onChatReactionRemoved(void Function(dynamic) callback) {
    return on(SocketEvents.chatReactionRemoved, callback);
  }

  /// Listen for direct messages
  VoidCallback onDmMessage(void Function(dynamic) callback) {
    return on(SocketEvents.dmMessage, callback);
  }

  /// Listen for DM read events (when other user marks messages as read)
  VoidCallback onDmRead(void Function(dynamic) callback) {
    return on(SocketEvents.dmRead, callback);
  }

  VoidCallback onDmReactionAdded(void Function(dynamic) callback) {
    return on(SocketEvents.dmReactionAdded, callback);
  }

  VoidCallback onDmReactionRemoved(void Function(dynamic) callback) {
    return on(SocketEvents.dmReactionRemoved, callback);
  }

  /// Listen for queue updates (player removed from queue when drafted)
  VoidCallback onQueueUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.draftQueueUpdated, callback);
  }

  /// Listen for autodraft toggle events
  VoidCallback onAutodraftToggled(void Function(dynamic) callback) {
    return on(SocketEvents.draftAutodraftToggled, callback);
  }

  /// Listen for draft pick traded events
  VoidCallback onDraftPickTraded(void Function(dynamic) callback) {
    return on(SocketEvents.draftPickTraded, callback);
  }

  /// Listen for draft settings updated events (commissioner changes)
  VoidCallback onDraftSettingsUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.draftSettingsUpdated, callback);
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

  /// Listen for nominator changes in fast auction mode
  VoidCallback onAuctionNominatorChanged(void Function(dynamic) callback) {
    return on(SocketEvents.auctionNominatorChanged, callback);
  }

  /// Listen for auction action errors (failed bids, nominations)
  VoidCallback onAuctionError(void Function(dynamic) callback) {
    return on(SocketEvents.auctionError, callback);
  }

  // Derby event listeners (draft order selection phase)

  /// Listen for full derby state updates
  VoidCallback onDerbyState(void Function(dynamic) callback) {
    return on(SocketEvents.derbyState, callback);
  }

  /// Listen for derby slot picked events
  VoidCallback onDerbySlotPicked(void Function(dynamic) callback) {
    return on(SocketEvents.derbySlotPicked, callback);
  }

  /// Listen for derby turn changed events (timeout policy applied)
  VoidCallback onDerbyTurnChanged(void Function(dynamic) callback) {
    return on(SocketEvents.derbyTurnChanged, callback);
  }

  /// Listen for derby phase transition events
  VoidCallback onDerbyPhaseTransition(void Function(dynamic) callback) {
    return on(SocketEvents.derbyPhaseTransition, callback);
  }

  // Overnight pause event listeners (snake/linear drafts)

  /// Listen for overnight pause started events
  VoidCallback onOvernightPauseStarted(void Function(dynamic) callback) {
    return on(SocketEvents.draftOvernightPauseStarted, callback);
  }

  /// Listen for overnight pause ended events
  VoidCallback onOvernightPauseEnded(void Function(dynamic) callback) {
    return on(SocketEvents.draftOvernightPauseEnded, callback);
  }

  // Trade event listeners
  VoidCallback onTradeProposed(void Function(dynamic) callback) {
    return on(SocketEvents.tradeProposed, callback);
  }

  VoidCallback onTradeAccepted(void Function(dynamic) callback) {
    return on(SocketEvents.tradeAccepted, callback);
  }

  VoidCallback onTradeRejected(void Function(dynamic) callback) {
    return on(SocketEvents.tradeRejected, callback);
  }

  VoidCallback onTradeCountered(void Function(dynamic) callback) {
    return on(SocketEvents.tradeCountered, callback);
  }

  VoidCallback onTradeCancelled(void Function(dynamic) callback) {
    return on(SocketEvents.tradeCancelled, callback);
  }

  VoidCallback onTradeExpired(void Function(dynamic) callback) {
    return on(SocketEvents.tradeExpired, callback);
  }

  VoidCallback onTradeCompleted(void Function(dynamic) callback) {
    return on(SocketEvents.tradeCompleted, callback);
  }

  VoidCallback onTradeVetoed(void Function(dynamic) callback) {
    return on(SocketEvents.tradeVetoed, callback);
  }

  VoidCallback onTradeVoteCast(void Function(dynamic) callback) {
    return on(SocketEvents.tradeVoteCast, callback);
  }

  VoidCallback onTradeInvalidated(void Function(dynamic) callback) {
    return on(SocketEvents.tradeInvalidated, callback);
  }

  // Waiver event listeners
  VoidCallback onWaiverClaimSubmitted(void Function(dynamic) callback) {
    return on(SocketEvents.waiverClaimSubmitted, callback);
  }

  VoidCallback onWaiverClaimCancelled(void Function(dynamic) callback) {
    return on(SocketEvents.waiverClaimCancelled, callback);
  }

  VoidCallback onWaiverClaimUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.waiverClaimUpdated, callback);
  }

  VoidCallback onWaiverClaimsReordered(void Function(dynamic) callback) {
    return on(SocketEvents.waiverClaimsReordered, callback);
  }

  VoidCallback onWaiverProcessed(void Function(dynamic) callback) {
    return on(SocketEvents.waiverProcessed, callback);
  }

  VoidCallback onWaiverClaimSuccessful(void Function(dynamic) callback) {
    return on(SocketEvents.waiverClaimSuccessful, callback);
  }

  VoidCallback onWaiverClaimFailed(void Function(dynamic) callback) {
    return on(SocketEvents.waiverClaimFailed, callback);
  }

  VoidCallback onWaiverPriorityUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.waiverPriorityUpdated, callback);
  }

  VoidCallback onWaiverBudgetUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.waiverBudgetUpdated, callback);
  }

  // Scoring event listeners
  VoidCallback onScoresUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.scoringScoresUpdated, callback);
  }

  VoidCallback onWeekFinalized(void Function(dynamic) callback) {
    return on(SocketEvents.scoringWeekFinalized, callback);
  }

  // Member event listeners
  VoidCallback onMemberKicked(void Function(dynamic) callback) {
    return on(SocketEvents.memberKicked, callback);
  }

  VoidCallback onMemberJoined(void Function(dynamic) callback) {
    return on(SocketEvents.memberJoined, callback);
  }

  VoidCallback onMemberBenched(void Function(dynamic) callback) {
    return on(SocketEvents.memberBenched, callback);
  }

  // League event listeners
  VoidCallback onLeagueSettingsUpdated(void Function(dynamic) callback) {
    return on(SocketEvents.leagueSettingsUpdated, callback);
  }

  VoidCallback onSeasonRolledOver(void Function(dynamic) callback) {
    return on(SocketEvents.seasonRolledOver, callback);
  }

  // Invitation event listeners
  VoidCallback onInvitationReceived(void Function(dynamic) callback) {
    return on(SocketEvents.invitationReceived, callback);
  }

  VoidCallback onInvitationAccepted(void Function(dynamic) callback) {
    return on(SocketEvents.invitationAccepted, callback);
  }

  VoidCallback onInvitationDeclined(void Function(dynamic) callback) {
    return on(SocketEvents.invitationDeclined, callback);
  }

  VoidCallback onInvitationCancelled(void Function(dynamic) callback) {
    return on(SocketEvents.invitationCancelled, callback);
  }
}
