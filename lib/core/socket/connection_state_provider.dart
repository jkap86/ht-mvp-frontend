import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_service.dart';

/// Represents the current socket connection state
enum SocketConnectionState {
  connected,
  disconnected,
  reconnecting,
}

/// Provider that exposes a reactive stream of socket connection state
final socketConnectionProvider = StreamProvider<SocketConnectionState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final controller = StreamController<SocketConnectionState>();

  // Emit initial state
  controller.add(socketService.isConnected
      ? SocketConnectionState.connected
      : SocketConnectionState.disconnected);

  // Listen for connect events (initial and reconnect)
  final unsubscribeConnect = socketService.onConnected(() {
    controller.add(SocketConnectionState.connected);
  });

  // Listen for disconnect events
  final unsubscribeDisconnect = socketService.onDisconnected(() {
    controller.add(SocketConnectionState.disconnected);
  });

  ref.onDispose(() {
    unsubscribeConnect();
    unsubscribeDisconnect();
    controller.close();
  });

  return controller.stream;
});

/// Simple boolean provider for quick connection status checks
final isSocketConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(socketConnectionProvider);
  return connectionState.when(
    data: (state) => state == SocketConnectionState.connected,
    loading: () => true, // Assume connected while loading
    error: (_, __) => false,
  );
});
