import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_config.dart';
import '../constants/socket_events.dart';

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());

class SocketService {
  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // League room management
  void joinLeague(int leagueId) {
    _socket?.emit(SocketEvents.leagueJoin, leagueId);
  }

  void leaveLeague(int leagueId) {
    _socket?.emit(SocketEvents.leagueLeave, leagueId);
  }

  // Draft room management
  void joinDraft(int draftId) {
    _socket?.emit(SocketEvents.draftJoin, draftId);
  }

  void leaveDraft(int draftId) {
    _socket?.emit(SocketEvents.draftLeave, draftId);
  }

  /// Generic event listener that returns a disposer function.
  /// Call the returned function to remove only this specific listener.
  /// This prevents the bug where one consumer's dispose removes another's listeners.
  VoidCallback? on(String event, void Function(dynamic) callback) {
    if (_socket == null) return null;
    _socket!.on(event, callback);
    // Return a disposer that removes only this specific callback
    return () => _socket?.off(event, callback);
  }

  // Event listeners - all return disposers for proper cleanup
  // Call the returned function in dispose() to remove only your listener

  VoidCallback? onDraftStarted(void Function(dynamic) callback) {
    return on(SocketEvents.draftStarted, callback);
  }

  VoidCallback? onDraftPick(void Function(dynamic) callback) {
    return on(SocketEvents.draftPickMade, callback);
  }

  VoidCallback? onNextPick(void Function(dynamic) callback) {
    return on(SocketEvents.draftNextPick, callback);
  }

  VoidCallback? onDraftCompleted(void Function(dynamic) callback) {
    return on(SocketEvents.draftCompleted, callback);
  }

  VoidCallback? onUserJoinedDraft(void Function(dynamic) callback) {
    return on(SocketEvents.draftUserJoined, callback);
  }

  VoidCallback? onUserLeftDraft(void Function(dynamic) callback) {
    return on(SocketEvents.draftUserLeft, callback);
  }

  VoidCallback? onChatMessage(void Function(dynamic) callback) {
    return on(SocketEvents.chatMessage, callback);
  }
}
