import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_config.dart';

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
    _socket?.emit('join:league', leagueId);
  }

  void leaveLeague(int leagueId) {
    _socket?.emit('leave:league', leagueId);
  }

  // Draft room management
  void joinDraft(int draftId) {
    _socket?.emit('join:draft', draftId);
  }

  void leaveDraft(int draftId) {
    _socket?.emit('leave:draft', draftId);
  }

  // Event listeners
  void onDraftStarted(void Function(dynamic) callback) {
    _socket?.on('draft:started', callback);
  }

  void onDraftPick(void Function(dynamic) callback) {
    _socket?.on('draft:pick_made', callback);
  }

  void onNextPick(void Function(dynamic) callback) {
    _socket?.on('draft:next_pick', callback);
  }

  void onDraftCompleted(void Function(dynamic) callback) {
    _socket?.on('draft:completed', callback);
  }

  void onUserJoinedDraft(void Function(dynamic) callback) {
    _socket?.on('draft:user_joined', callback);
  }

  void onUserLeftDraft(void Function(dynamic) callback) {
    _socket?.on('draft:user_left', callback);
  }

  void onChatMessage(void Function(dynamic) callback) {
    _socket?.on('chat:message', callback);
  }

  // Remove listeners
  void offDraftStarted() {
    _socket?.off('draft:started');
  }

  void offDraftPick() {
    _socket?.off('draft:pick_made');
  }

  void offNextPick() {
    _socket?.off('draft:next_pick');
  }

  void offDraftCompleted() {
    _socket?.off('draft:completed');
  }

  void offChatMessage() {
    _socket?.off('chat:message');
  }

  void offAll() {
    offDraftStarted();
    offDraftPick();
    offNextPick();
    offDraftCompleted();
    offChatMessage();
    _socket?.off('draft:user_joined');
    _socket?.off('draft:user_left');
  }
}
