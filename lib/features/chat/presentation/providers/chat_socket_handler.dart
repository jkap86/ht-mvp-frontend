import 'package:flutter/foundation.dart' show VoidCallback, kDebugMode, debugPrint;

import '../../../../core/constants/socket_events.dart';
import '../../../../core/socket/socket_service.dart';
import '../../domain/chat_message.dart';

/// Callbacks for chat socket events
abstract class ChatSocketCallbacks {
  void onChatMessageReceived(ChatMessage message);
  void onReactionAddedReceived(Map<String, dynamic> data);
  void onReactionRemovedReceived(Map<String, dynamic> data);
  void onReconnectedReceived(bool needsFullRefresh);
}

/// Handles all socket event subscriptions for league chat
class ChatSocketHandler {
  final SocketService _socketService;
  final int leagueId;
  final ChatSocketCallbacks _callbacks;

  // Store disposers for proper cleanup
  final List<VoidCallback> _disposers = [];

  ChatSocketHandler({
    required SocketService socketService,
    required this.leagueId,
    required ChatSocketCallbacks callbacks,
  })  : _socketService = socketService,
        _callbacks = callbacks;

  /// Set up all socket listeners
  void setupListeners() {
    _socketService.joinLeague(leagueId);

    _addDisposer(_socketService.on(SocketEvents.chatReactionAdded, (data) {
      if (data is! Map) return;
      try {
        _callbacks.onReactionAddedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to handle chat reaction added: $e');
      }
    }));

    _addDisposer(_socketService.on(SocketEvents.chatReactionRemoved, (data) {
      if (data is! Map) return;
      try {
        _callbacks.onReactionRemovedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to handle chat reaction removed: $e');
      }
    }));

    _addDisposer(_socketService.onChatMessage((data) {
      if (data is! Map) return;
      try {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        _callbacks.onChatMessageReceived(message);
      } catch (e) {
        // Log error but don't crash - malformed socket data should not break chat
        if (kDebugMode) debugPrint('Failed to parse chat message from socket: $e');
      }
    }));

    // Resync messages on socket reconnection (both short and long disconnects)
    _addDisposer(_socketService.onReconnected((needsFullRefresh) {
      if (kDebugMode) {
        debugPrint('Chat: Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      _callbacks.onReconnectedReceived(needsFullRefresh);
    }));
  }

  void _addDisposer(VoidCallback disposer) {
    _disposers.add(disposer);
  }

  /// Clean up all socket listeners
  void dispose() {
    _socketService.leaveLeague(leagueId);
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }
}
