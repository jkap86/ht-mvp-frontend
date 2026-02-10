import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
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
  final SyncService _syncService;
  final int leagueId;
  final String? _currentUserId;
  final String? _currentUsername;

  // Store disposers for proper cleanup
  VoidCallback? _chatMessageDisposer;
  VoidCallback? _reconnectDisposer;
  VoidCallback? _syncDisposer;

  ChatNotifier(
    this._chatRepo,
    this._socketService,
    this._syncService,
    this.leagueId, {
    String? currentUserId,
    String? currentUsername,
  })  : _currentUserId = currentUserId,
        _currentUsername = currentUsername,
        super(ChatState()) {
    _setupSocketListeners();
    _syncDisposer = _syncService.registerLeagueSync(leagueId, loadMessages);
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

    // Resync messages on socket reconnection
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      if (needsFullRefresh) {
        if (kDebugMode) debugPrint('Chat: Socket reconnected after long disconnect, reloading messages');
        loadMessages();
      }
    });
  }

  /// Adds a message to state with deduplication check
  void _addMessageWithDedupe(ChatMessage message) {
    // Check for exact ID match
    final existingIds = state.messages.map((m) => m.id).toSet();
    if (existingIds.contains(message.id)) {
      return; // Already have this message - skip duplicate
    }

    // Check for optimistic message that should be replaced
    // Optimistic messages have negative IDs and match on userId + content + recent timestamp
    final hasOptimistic = message.id > 0 && // Real message from server
        state.messages.any((m) =>
            m.id < 0 && // Optimistic temp message
            m.userId == message.userId &&
            m.message == message.message &&
            message.createdAt.difference(m.createdAt).inSeconds.abs() < 30);

    if (hasOptimistic) {
      // Replace optimistic message with real one
      state = state.copyWith(
        messages: [
          message,
          ...state.messages.where((m) => !(m.id < 0 && m.userId == message.userId && m.message == message.message))
        ],
      );
    } else {
      // Add new message normally
      state = state.copyWith(messages: [message, ...state.messages]);
    }
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

      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
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

      state = state.copyWith(isLoadingMore: false, error: ErrorSanitizer.sanitize(e));
    }
  }

  Future<bool> sendMessage(String text, {String? idempotencyKey}) async {
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
      await _chatRepo.sendMessage(leagueId, trimmedText, idempotencyKey: idempotencyKey);

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
    _chatMessageDisposer?.call();
    _reconnectDisposer?.call();
    _syncDisposer?.call();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, int>(
  (ref, leagueId) {
    final authState = ref.watch(authStateProvider);
    return ChatNotifier(
      ref.watch(chatRepositoryProvider),
      ref.watch(socketServiceProvider),
      ref.watch(syncServiceProvider),
      leagueId,
      currentUserId: authState.user?.id,
      currentUsername: authState.user?.username,
    );
  },
);
