import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../data/dm_repository.dart';
import '../../domain/direct_message.dart';
import 'dm_inbox_provider.dart';

class DmConversationState {
  final List<DirectMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  DmConversationState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.error,
  });

  DmConversationState copyWith({
    List<DirectMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return DmConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DmConversationNotifier extends StateNotifier<DmConversationState> {
  final DmRepository _dmRepo;
  final SocketService _socketService;
  final int conversationId;
  final Ref _ref;

  VoidCallback? _dmMessageDisposer;
  VoidCallback? _reconnectDisposer;

  DmConversationNotifier(
    this._dmRepo,
    this._socketService,
    this.conversationId,
    this._ref,
  ) : super(DmConversationState()) {
    _setupSocketListeners();
    loadMessages();
    _markAsRead();
  }

  void _setupSocketListeners() {
    // Refresh messages on socket reconnection to sync state
    _reconnectDisposer = _socketService.onReconnected(() {
      if (!mounted) return;
      loadMessages();
    });

    _dmMessageDisposer = _socketService.onDmMessage((data) {
      if (!mounted) return;

      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;

      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) return;

      final message = DirectMessage.fromJson(messageData);

      // Add to messages list (prepend since newest first)
      state = state.copyWith(messages: [message, ...state.messages]);

      // Mark as read since user is viewing this conversation
      _markAsRead();
    });
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _dmRepo.getMessages(conversationId);

      if (!mounted) return;

      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return false;

    state = state.copyWith(isSending: true);

    try {
      final message = await _dmRepo.sendMessage(conversationId, text.trim());

      if (!mounted) return false;

      // Add message to the list
      state = state.copyWith(
        messages: [message, ...state.messages],
        isSending: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(isSending: false, error: e.toString());
      return false;
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _dmRepo.markAsRead(conversationId);

      // Update inbox provider to reflect read status
      _ref.read(dmInboxProvider.notifier).markConversationReadLocally(conversationId);
    } catch (e) {
      // Silent fail - not critical
    }
  }

  @override
  void dispose() {
    _dmMessageDisposer?.call();
    _reconnectDisposer?.call();
    super.dispose();
  }
}

final dmConversationProvider = StateNotifierProvider.family<
    DmConversationNotifier, DmConversationState, int>(
  (ref, conversationId) => DmConversationNotifier(
    ref.watch(dmRepositoryProvider),
    ref.watch(socketServiceProvider),
    conversationId,
    ref,
  ),
);
