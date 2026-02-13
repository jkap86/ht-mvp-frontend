import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_service.dart';

/// Thin provider wrapping socket reconnect so widgets never touch SocketService directly.
final socketReconnectProvider = Provider<Future<void> Function()>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return () => socketService.reconnect();
});
