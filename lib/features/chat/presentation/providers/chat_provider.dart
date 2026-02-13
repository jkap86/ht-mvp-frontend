import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_message.dart';
import 'chat_socket_handler.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isForbidden;

  // Search state
  final String? searchQuery;
  final List<ChatMessage> searchResults;
  final int searchTotal;
  final bool isSearching;
  final int currentSearchIndex;

  // Filter state (league chat only)
  final Set<String> hiddenUserIds;
  final bool hideSystemMessages;
  final int? highlightedMessageId; // For date jump navigation

  ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isForbidden = false,
    this.searchQuery,
    this.searchResults = const [],
    this.searchTotal = 0,
    this.isSearching = false,
    this.currentSearchIndex = 0,
    this.hiddenUserIds = const {},
    this.hideSystemMessages = false,
    this.highlightedMessageId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isForbidden,
    bool clearError = false,
    String? searchQuery,
    bool clearSearch = false,
    List<ChatMessage>? searchResults,
    int? searchTotal,
    bool? isSearching,
    int? currentSearchIndex,
    Set<String>? hiddenUserIds,
    bool? hideSystemMessages,
    int? highlightedMessageId,
    bool clearHighlight = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      isForbidden: isForbidden ?? this.isForbidden,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      searchResults: clearSearch ? [] : (searchResults ?? this.searchResults),
      searchTotal: clearSearch ? 0 : (searchTotal ?? this.searchTotal),
      isSearching: isSearching ?? this.isSearching,
      currentSearchIndex: clearSearch ? 0 : (currentSearchIndex ?? this.currentSearchIndex),
      hiddenUserIds: hiddenUserIds ?? this.hiddenUserIds,
      hideSystemMessages: hideSystemMessages ?? this.hideSystemMessages,
      highlightedMessageId: clearHighlight ? null : (highlightedMessageId ?? this.highlightedMessageId),
    );
  }

  // Computed: Get filtered messages based on active filters
  List<ChatMessage> get filteredMessages {
    if (hiddenUserIds.isEmpty && !hideSystemMessages) {
      return messages;
    }

    return messages.where((msg) {
      // Hide system messages if filter is active
      if (hideSystemMessages && msg.messageType != MessageType.chat) {
        return false;
      }

      // Hide messages from filtered users
      if (msg.userId != null && hiddenUserIds.contains(msg.userId)) {
        return false;
      }

      return true;
    }).toList();
  }
}

class ChatNotifier extends StateNotifier<ChatState> implements ChatSocketCallbacks {
  final ChatRepository _chatRepo;
  final SocketService _socketService;
  final SyncService _syncService;
  final int leagueId;
  final String? _currentUserId;
  final String? _currentUsername;

  // Socket handler for managing subscriptions
  ChatSocketHandler? _socketHandler;
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
    _socketHandler = ChatSocketHandler(
      socketService: _socketService,
      leagueId: leagueId,
      callbacks: this,
    );
    _socketHandler!.setupListeners();
  }

  @override
  void onChatMessageReceived(ChatMessage message) {
    if (!mounted) return;
    _addMessageWithDedupe(message);
  }

  @override
  void onReactionAddedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    _handleReactionSocket(data, added: true);
  }

  @override
  void onReactionRemovedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    _handleReactionSocket(data, added: false);
  }

  @override
  void onReconnectedReceived(bool needsFullRefresh) {
    if (!mounted) return;
    // Always reload messages on reconnect to avoid stale chat state.
    // Short disconnects may have missed socket events.
    loadMessages();
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
          ...state.messages.where((m) => !(m.id < 0 &&
              m.userId == message.userId &&
              m.message == message.message))
        ],
      );
    } else {
      // Add new message normally
      state = state.copyWith(messages: [message, ...state.messages]);
    }
  }

  /// Handle a reaction added/removed socket event.
  void _handleReactionSocket(dynamic data, {required bool added}) {
    if (data is! Map) return;
    final messageId = data['messageId'] as int?;
    final userId = data['userId'] as String?;
    final emoji = data['emoji'] as String?;
    if (messageId == null || userId == null || emoji == null) return;

    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final msg = state.messages[idx];
    final reactions = List<ReactionGroup>.from(msg.reactions);

    if (added) {
      final existingIdx = reactions.indexWhere((r) => r.emoji == emoji);
      if (existingIdx >= 0) {
        final existing = reactions[existingIdx];
        if (!existing.users.contains(userId)) {
          reactions[existingIdx] = existing.copyWith(
            count: existing.count + 1,
            users: [...existing.users, userId],
          );
        }
      } else {
        reactions.add(ReactionGroup(emoji: emoji, count: 1, users: [userId]));
      }
    } else {
      final existingIdx = reactions.indexWhere((r) => r.emoji == emoji);
      if (existingIdx >= 0) {
        final existing = reactions[existingIdx];
        final newUsers = existing.users.where((u) => u != userId).toList();
        if (newUsers.isEmpty) {
          reactions.removeAt(existingIdx);
        } else {
          reactions[existingIdx] = existing.copyWith(
            count: newUsers.length,
            users: newUsers,
          );
        }
      }
    }

    final updatedMessages = [...state.messages];
    updatedMessages[idx] = msg.copyWith(reactions: reactions);
    state = state.copyWith(messages: updatedMessages);
  }

  /// Toggle a reaction on a message (add if not present, remove if present).
  Future<void> toggleReaction(int messageId, String emoji) async {
    if (_currentUserId == null) return;

    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final msg = state.messages[idx];
    final existingReaction =
        msg.reactions.where((r) => r.emoji == emoji).firstOrNull;
    final hasReacted = existingReaction != null &&
        existingReaction.users.contains(_currentUserId);

    // Optimistic update
    final previousMessages = state.messages;
    final reactions = List<ReactionGroup>.from(msg.reactions);

    if (hasReacted) {
      final rIdx = reactions.indexWhere((r) => r.emoji == emoji);
      if (rIdx >= 0) {
        final existing = reactions[rIdx];
        final newUsers =
            existing.users.where((u) => u != _currentUserId).toList();
        if (newUsers.isEmpty) {
          reactions.removeAt(rIdx);
        } else {
          reactions[rIdx] =
              existing.copyWith(count: newUsers.length, users: newUsers);
        }
      }
    } else {
      final rIdx = reactions.indexWhere((r) => r.emoji == emoji);
      if (rIdx >= 0) {
        final existing = reactions[rIdx];
        reactions[rIdx] = existing.copyWith(
          count: existing.count + 1,
          users: [...existing.users, _currentUserId],
        );
      } else {
        reactions.add(
            ReactionGroup(emoji: emoji, count: 1, users: [_currentUserId]));
      }
    }

    final updatedMessages = [...state.messages];
    updatedMessages[idx] = msg.copyWith(reactions: reactions);
    state = state.copyWith(messages: updatedMessages);

    try {
      if (hasReacted) {
        await _chatRepo.removeReaction(leagueId, messageId, emoji);
      } else {
        await _chatRepo.addReaction(leagueId, messageId, emoji);
      }
    } catch (_) {
      // Revert optimistic update on error
      if (mounted) {
        state = state.copyWith(messages: previousMessages);
      }
    }
  }

  static const int _pageSize = 50;

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _chatRepo.getMessages(leagueId, limit: _pageSize);

      // Check if disposed during async operations
      if (!mounted) return;

      // Preserve any pending/failed optimistic messages (negative IDs)
      final optimisticMessages = state.messages
          .where((m) => m.isOptimistic)
          .toList();

      state = state.copyWith(
        messages: [...optimisticMessages, ...messages],
        isLoading: false,
        hasMore: messages.length >= _pageSize,
      );
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(isForbidden: true, isLoading: false, messages: []);
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state =
          state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) return;

    // Find the oldest real (non-optimistic) message ID for pagination cursor
    final realMessages = state.messages.where((m) => !m.isOptimistic);
    if (realMessages.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final oldestId = realMessages.last.id;
      final olderMessages = await _chatRepo.getMessages(
        leagueId,
        limit: _pageSize,
        before: oldestId,
      );

      // Check if disposed during async operations
      if (!mounted) return;

      // Dedupe in case of race conditions
      final existingIds = state.messages.map((m) => m.id).toSet();
      final newMessages =
          olderMessages.where((m) => !existingIds.contains(m.id)).toList();

      state = state.copyWith(
        messages: [...state.messages, ...newMessages],
        isLoadingMore: false,
        hasMore: olderMessages.length >= _pageSize,
      );
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(
          isLoadingMore: false, error: ErrorSanitizer.sanitize(e));
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
        sendStatus: MessageSendStatus.sending,
        idempotencyKey: idempotencyKey,
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
      await _chatRepo.sendMessage(leagueId, trimmedText,
          idempotencyKey: idempotencyKey);

      // Check if disposed during async operations
      if (!mounted) return false;

      // If we used optimistic message, it will be replaced by socket echo
      // The dedupe logic in _addMessageWithDedupe will handle replacement
      if (optimisticMessage != null) {
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

      // Mark the optimistic message as failed instead of removing it
      if (optimisticMessage != null) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == tempId) {
              return m.copyWith(sendStatus: MessageSendStatus.failed);
            }
            return m;
          }).toList(),
          isSending: false,
        );
      } else {
        state = state.copyWith(isSending: false);
      }
      return false;
    }
  }

  /// Retry sending a previously failed message.
  Future<bool> retryMessage(int tempId) async {
    final failedMessage = state.messages.where((m) => m.id == tempId).firstOrNull;
    if (failedMessage == null || failedMessage.sendStatus != MessageSendStatus.failed) {
      return false;
    }

    // Mark as sending again
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(sendStatus: MessageSendStatus.sending);
        }
        return m;
      }).toList(),
    );

    try {
      await _chatRepo.sendMessage(leagueId, failedMessage.message,
          idempotencyKey: failedMessage.idempotencyKey);

      if (!mounted) return false;

      // Give socket a moment to deliver, then clean up temp if still there
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final hasTemp = state.messages.any((m) => m.id == tempId);
        if (hasTemp) {
          state = state.copyWith(
            messages: state.messages.where((m) => m.id != tempId).toList(),
          );
        }
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      // Mark as failed again
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == tempId) {
            return m.copyWith(sendStatus: MessageSendStatus.failed);
          }
          return m;
        }).toList(),
      );
      return false;
    }
  }

  /// Remove a failed message from the list (dismiss).
  void dismissFailedMessage(int tempId) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != tempId).toList(),
    );
  }

  /// Search messages with the given query
  Future<void> searchMessages(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = state.copyWith(clearSearch: true);
      return;
    }

    state = state.copyWith(
      searchQuery: trimmedQuery,
      isSearching: true,
    );

    try {
      final result = await _chatRepo.searchMessages(leagueId, trimmedQuery);

      if (!mounted) return;

      state = state.copyWith(
        searchResults: result['messages'] as List<ChatMessage>,
        searchTotal: result['total'] as int,
        isSearching: false,
        currentSearchIndex: 0,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isSearching: false,
        error: ErrorSanitizer.sanitize(e),
      );
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(clearSearch: true);
  }

  /// Navigate to next search result
  void nextSearchResult() {
    if (state.searchResults.isEmpty) return;
    final newIndex = (state.currentSearchIndex + 1) % state.searchResults.length;
    state = state.copyWith(currentSearchIndex: newIndex);
  }

  /// Navigate to previous search result
  void previousSearchResult() {
    if (state.searchResults.isEmpty) return;
    final newIndex = state.currentSearchIndex == 0
        ? state.searchResults.length - 1
        : state.currentSearchIndex - 1;
    state = state.copyWith(currentSearchIndex: newIndex);
  }

  /// Jump to a specific date/time in chat history
  Future<void> jumpToTimestamp(DateTime timestamp) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _chatRepo.getMessages(
        leagueId,
        limit: _pageSize,
        aroundTimestamp: timestamp,
      );

      if (!mounted) return;

      // Find the message closest to the timestamp to highlight
      int? highlightId;
      if (messages.isNotEmpty) {
        highlightId = messages.reduce((a, b) {
          final aDiff = a.createdAt.difference(timestamp).abs();
          final bDiff = b.createdAt.difference(timestamp).abs();
          return aDiff < bDiff ? a : b;
        }).id;
      }

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: messages.length >= _pageSize,
        highlightedMessageId: highlightId,
      );

      // Clear highlight after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(clearHighlight: true);
        }
      });
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  /// Toggle user filter (show/hide messages from a specific user)
  void toggleUserFilter(String userId) {
    final newHiddenUsers = Set<String>.from(state.hiddenUserIds);
    if (newHiddenUsers.contains(userId)) {
      newHiddenUsers.remove(userId);
    } else {
      newHiddenUsers.add(userId);
    }
    state = state.copyWith(hiddenUserIds: newHiddenUsers);
  }

  /// Toggle system messages visibility
  void toggleSystemMessages() {
    state = state.copyWith(hideSystemMessages: !state.hideSystemMessages);
  }

  /// Clear all filters
  void clearAllFilters() {
    state = state.copyWith(
      hiddenUserIds: {},
      hideSystemMessages: false,
    );
  }

  @override
  void dispose() {
    _socketHandler?.dispose();
    _syncDisposer?.call();
    super.dispose();
  }
}

final chatProvider =
    StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, int>(
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
