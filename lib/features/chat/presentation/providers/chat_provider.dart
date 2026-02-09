import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _chatRepo;
  final SocketService _socketService;
  final int leagueId;
  final String? _currentUserId;
  final String? _currentUsername;

  // Store disposer for proper cleanup - removes only this listener, not all listeners
  VoidCallback? _chatMessageDisposer;

  ChatNotifier(
    this._chatRepo,
    this._socketService,
    this.leagueId, {
    String? currentUserId,
    String? currentUsername,
  })  : _currentUserId = currentUserId,
        _currentUsername = currentUsername,
        super(ChatState()) {
    _setupSocketListeners();
    loadMessages();
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);

    _chatMessageDisposer = _socketService.onChatMessage((data) {
      if (!mounted) return;
      try {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        _addMessageWithDedupe(message);
      } catch (e) {
        // Log error but don't crash - malformed socket data should not break chat
        if (kDebugMode) {
          debugPrint('Failed to parse chat message from socket: $e');
        }
      }
    });
  }

  /// Adds a message to state with deduplication check
  void _addMessageWithDedupe(ChatMessage message) {
    final existingIds = state.messages.map((m) => m.id).toSet();
    if (existingIds.contains(message.id)) {
      return; // Already have this message - skip duplicate
    }
    state = state.copyWith(messages: [message, ...state.messages]);
  }

  static const int _pageSize = 50;

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _chatRepo.getMessages(leagueId, limit: _pageSize);

      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: messages.length >= _pageSize,
      );
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final oldestId = state.messages.last.id;
      final olderMessages = await _chatRepo.getMessages(
        leagueId,
        limit: _pageSize,
        before: oldestId,
      );

      // Check if disposed during async operations
      if (!mounted) return;

      // Dedupe in case of race conditions
      final existingIds = state.messages.map((m) => m.id).toSet();
      final newMessages = olderMessages.where((m) => !existingIds.contains(m.id)).toList();

      state = state.copyWith(
        messages: [...state.messages, ...newMessages],
        isLoadingMore: false,
        hasMore: olderMessages.length >= _pageSize,
      );
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<bool> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || state.isSending) return false;

    // Generate a temporary negative ID for optimistic message
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    // Create optimistic message if we have user info
    ChatMessage? optimisticMessage;
    if (_currentUserId != null) {
      optimisticMessage = ChatMessage(
        id: tempId,
        leagueId: leagueId,
        userId: _currentUserId,
        username: _currentUsername,
        message: trimmedText,
        messageType: MessageType.chat,
        metadata: null,
        createdAt: DateTime.now(),
      );

      // Add optimistic message immediately
      state = state.copyWith(
        messages: [optimisticMessage, ...state.messages],
        isSending: true,
      );
    } else {
      state = state.copyWith(isSending: true);
    }

    try {
      await _chatRepo.sendMessage(leagueId, trimmedText);

      // Check if disposed during async operations
      if (!mounted) return false;

      // If we used optimistic message, it will be replaced by socket echo
      // The dedupe logic will handle the socket message properly
      // We just need to remove the temp message if socket echo arrives with real ID
      if (optimisticMessage != null) {
        // Remove optimistic message - socket echo will add the real one
        // Give socket a moment to deliver, then clean up temp if still there
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          // Remove temp message if it's still there (socket should have replaced it)
          final hasTemp = state.messages.any((m) => m.id == tempId);
          if (hasTemp) {
            state = state.copyWith(
              messages: state.messages.where((m) => m.id != tempId).toList(),
            );
          }
        });
      }

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return false;

      // Remove optimistic message on failure
      if (optimisticMessage != null) {
        state = state.copyWith(
          messages: state.messages.where((m) => m.id != tempId).toList(),
          isSending: false,
        );
      } else {
        state = state.copyWith(isSending: false);
      }
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
  (ref, leagueId) {
    final authState = ref.watch(authStateProvider);
    return ChatNotifier(
      ref.watch(chatRepositoryProvider),
      ref.watch(socketServiceProvider),
      leagueId,
      currentUserId: authState.user?.id,
      currentUsername: authState.user?.username,
    );
  },
);
