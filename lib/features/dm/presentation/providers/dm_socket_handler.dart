import 'package:flutter/foundation.dart' show VoidCallback, kDebugMode, debugPrint;

import '../../../../core/constants/socket_events.dart';
import '../../../../core/socket/socket_service.dart';
import '../../domain/direct_message.dart';

/// Callbacks for DM socket events
abstract class DmSocketCallbacks {
  void onDmMessageReceived(DirectMessage message, int conversationId);
  void onReactionAddedReceived(Map<String, dynamic> data);
  void onReactionRemovedReceived(Map<String, dynamic> data);
  void onReconnectedReceived(bool needsFullRefresh);
}

/// Handles all socket event subscriptions for DM conversations
class DmSocketHandler {
  final SocketService _socketService;
  final int conversationId;
  final DmSocketCallbacks _callbacks;

  // Store disposers for proper cleanup
  final List<VoidCallback> _disposers = [];

  DmSocketHandler({
    required SocketService socketService,
    required this.conversationId,
    required DmSocketCallbacks callbacks,
  })  : _socketService = socketService,
        _callbacks = callbacks;

  /// Set up all socket listeners
  void setupListeners() {
    // Note: DM conversations don't join a specific room like leagues/drafts

    _addDisposer(_socketService.on(SocketEvents.dmReactionAdded, (data) {
      if (data is! Map) return;
      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;
      try {
        _callbacks.onReactionAddedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to handle DM reaction added: $e');
      }
    }));

    _addDisposer(_socketService.on(SocketEvents.dmReactionRemoved, (data) {
      if (data is! Map) return;
      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;
      try {
        _callbacks.onReactionRemovedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to handle DM reaction removed: $e');
      }
    }));

    _addDisposer(_socketService.onDmMessage((data) {
      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;

      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) return;

      try {
        final message = DirectMessage.fromJson(messageData);
        _callbacks.onDmMessageReceived(message, conversationId);
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to parse DM message from socket: $e');
      }
    }));

    // Refresh messages on socket reconnection (both short and long disconnects)
    _addDisposer(_socketService.onReconnected((needsFullRefresh) {
      if (kDebugMode) {
        debugPrint('DmConversation($conversationId): Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      _callbacks.onReconnectedReceived(needsFullRefresh);
    }));
  }

  void _addDisposer(VoidCallback disposer) {
    _disposers.add(disposer);
  }

  /// Clean up all socket listeners
  void dispose() {
    // Note: DM conversations don't have a leave method like leagues/drafts
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }
}
