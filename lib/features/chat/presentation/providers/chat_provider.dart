import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _chatRepo;
  final SocketService _socketService;
  final int leagueId;

  // Store disposer for proper cleanup - removes only this listener, not all listeners
  VoidCallback? _chatMessageDisposer;

  ChatNotifier(this._chatRepo, this._socketService, this.leagueId) : super(ChatState()) {
    _setupSocketListeners();
    loadMessages();
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);

    _chatMessageDisposer = _socketService.onChatMessage((data) {
      if (!mounted) return;
      try {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        state = state.copyWith(messages: [message, ...state.messages]);
      } catch (e) {
        // Log error but don't crash - malformed socket data should not break chat
        // ignore: avoid_print
        print('Failed to parse chat message from socket: $e');
      }
    });
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _chatRepo.getMessages(leagueId);

      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return false;

    state = state.copyWith(isSending: true);

    try {
      await _chatRepo.sendMessage(leagueId, text.trim());

      // Check if disposed during async operations
      if (!mounted) return false;

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return false;

      state = state.copyWith(isSending: false);
      return false;
    }
  }

  @override
  void dispose() {
    _socketService.leaveLeague(leagueId);
    _chatMessageDisposer?.call(); // Remove only this listener, not all chat listeners
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, int>(
  (ref, leagueId) => ChatNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(socketServiceProvider),
    leagueId,
  ),
);
