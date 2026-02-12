import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback, kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/socket_events.dart';
import '../../../../core/utils/error_sanitizer.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../chat/domain/chat_message.dart' show MessageSendStatus, ReactionGroup;
import '../../data/dm_repository.dart';
import '../../domain/direct_message.dart';
import 'dm_inbox_provider.dart';

class DmConversationState {
  final List<DirectMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isForbidden;

  // Search state
  final String? searchQuery;
  final List<DirectMessage> searchResults;
  final int searchTotal;
  final bool isSearching;
  final int currentSearchIndex;
  final int? highlightedMessageId; // For date jump navigation

  DmConversationState({
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
    this.highlightedMessageId,
  });

  DmConversationState copyWith({
    List<DirectMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isForbidden,
    bool clearError = false,
    String? searchQuery,
    bool clearSearch = false,
    List<DirectMessage>? searchResults,
    int? searchTotal,
    bool? isSearching,
    int? currentSearchIndex,
    int? highlightedMessageId,
    bool clearHighlight = false,
  }) {
    return DmConversationState(
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
      highlightedMessageId: clearHighlight ? null : (highlightedMessageId ?? this.highlightedMessageId),
    );
  }
}

class DmConversationNotifier extends StateNotifier<DmConversationState> {
  final DmRepository _dmRepo;
  final SocketService _socketService;
  final int conversationId;
  final Ref _ref;
  final String? _currentUserId;
  final String? _currentUsername;

  VoidCallback? _dmMessageDisposer;
  VoidCallback? _reconnectDisposer;
  VoidCallback? _reactionAddedDisposer;
  VoidCallback? _reactionRemovedDisposer;
  Timer? _markAsReadDebounce;

  DmConversationNotifier(
    this._dmRepo,
    this._socketService,
    this.conversationId,
    this._ref, {
    String? currentUserId,
    String? currentUsername,
  })  : _currentUserId = currentUserId,
        _currentUsername = currentUsername,
        super(DmConversationState()) {
    _setupSocketListeners();
    loadMessages();
    _markAsRead();
  }

  void _setupSocketListeners() {
    // Refresh messages on socket reconnection (both short and long disconnects)
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('DmConversation($conversationId): Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      // Always reload messages on reconnect to ensure no gaps.
      // Short disconnects may have missed incoming messages.
      loadMessages();
    });

    _reactionAddedDisposer = _socketService.on(SocketEvents.dmReactionAdded, (data) {
      if (!mounted) return;
      if (data is! Map) return;
      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;
      _handleReactionSocket(data, added: true);
    });

    _reactionRemovedDisposer = _socketService.on(SocketEvents.dmReactionRemoved, (data) {
      if (!mounted) return;
      if (data is! Map) return;
      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;
      _handleReactionSocket(data, added: false);
    });

    _dmMessageDisposer = _socketService.onDmMessage((data) {
      if (!mounted) return;

      final msgConvId = data['conversationId'] as int?;
      if (msgConvId != conversationId) return;

      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) return;

      final message = DirectMessage.fromJson(messageData);

      // Insert message in correct position (sorted by timestamp)
      final messages = [...state.messages, message];
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Deduplicate by ID (in case message received via both REST and socket)
      final seen = <int>{};
      final deduped = messages.where((m) => seen.add(m.id)).toList();

      state = state.copyWith(messages: deduped);

      // Mark as read since user is viewing this conversation
      _markAsRead();
    });
  }

  static const int _pageSize = 50;

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final fetchedMessages = await _dmRepo.getMessages(conversationId, limit: _pageSize);

      if (!mounted) return;

      // Preserve any pending/failed optimistic messages (negative IDs)
      final optimisticMessages = state.messages
          .where((m) => m.isOptimistic)
          .toList();

      // Merge optimistic messages with fetched messages and existing socket messages
      final existingIds = state.messages.map((m) => m.id).toSet();
      final newFromApi = fetchedMessages.where((m) => !existingIds.contains(m.id)).toList();
      // Include non-optimistic existing messages that were from socket + new from API + optimistic
      final nonOptimisticExisting = state.messages.where((m) => !m.isOptimistic).toList();
      final merged = [...optimisticMessages, ...nonOptimisticExisting, ...newFromApi];

      // Sort by timestamp (newest first) and dedupe
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final seen = <int>{};
      final deduped = merged.where((m) => seen.add(m.id)).toList();

      state = state.copyWith(
        messages: deduped,
        isLoading: false,
        hasMore: fetchedMessages.length >= _pageSize,
      );
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(isForbidden: true, isLoading: false, messages: []);
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  /// Load older messages (pagination)
  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) return;

    // Find the oldest real (non-optimistic) message ID for pagination cursor
    final realMessages = state.messages.where((m) => !m.isOptimistic);
    if (realMessages.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final oldestId = realMessages.last.id;
      final olderMessages = await _dmRepo.getMessages(
        conversationId,
        limit: _pageSize,
        before: oldestId,
      );

      if (!mounted) return;

      // Merge and dedupe
      final merged = [...state.messages, ...olderMessages];
      final seen = <int>{};
      final deduped = merged.where((m) => seen.add(m.id)).toList();
      deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        messages: deduped,
        isLoadingMore: false,
        hasMore: olderMessages.length >= _pageSize,
      );
    } catch (e) {
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
    DirectMessage? optimisticMessage;
    if (_currentUserId != null) {
      optimisticMessage = DirectMessage(
        id: tempId,
        conversationId: conversationId,
        senderId: _currentUserId,
        senderUsername: _currentUsername ?? 'You',
        message: trimmedText,
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
      final message = await _dmRepo.sendMessage(conversationId, trimmedText, idempotencyKey: idempotencyKey);

      if (!mounted) return false;

      // Replace optimistic message with the real one from the server
      if (optimisticMessage != null) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == tempId) return message;
            return m;
          }).toList(),
          isSending: false,
        );
      } else {
        // Add message to the list
        state = state.copyWith(
          messages: [message, ...state.messages],
          isSending: false,
        );
      }
      return true;
    } catch (e) {
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
        state = state.copyWith(isSending: false, error: ErrorSanitizer.sanitize(e));
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
      final message = await _dmRepo.sendMessage(
        conversationId,
        failedMessage.message,
        idempotencyKey: failedMessage.idempotencyKey,
      );

      if (!mounted) return false;

      // Replace temp with real message
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == tempId) return message;
          return m;
        }).toList(),
      );
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
      final result = await _dmRepo.searchMessages(conversationId, trimmedQuery);

      if (!mounted) return;

      state = state.copyWith(
        searchResults: result['messages'] as List<DirectMessage>,
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

  /// Jump to a specific date/time in conversation history
  Future<void> jumpToTimestamp(DateTime timestamp) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await _dmRepo.getMessages(
        conversationId,
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

  void _markAsRead() {
    _markAsReadDebounce?.cancel();
    _markAsReadDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await _dmRepo.markAsRead(conversationId);

        // Only update local state AFTER successful API call to prevent desync
        if (mounted) {
          _ref.read(dmInboxProvider.notifier).markConversationReadLocally(conversationId);
        }
      } catch (e) {
        // Silent fail - not critical, but don't update local state
      }
    });
  }

  /// Handle a reaction socket event for DM messages.
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

  /// Toggle a reaction on a DM message (add if not present, remove if present).
  Future<void> toggleReaction(int messageId, String emoji, String currentUserId) async {
    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final msg = state.messages[idx];
    final existingReaction = msg.reactions.where((r) => r.emoji == emoji).firstOrNull;
    final hasReacted = existingReaction != null &&
        existingReaction.users.contains(currentUserId);

    // Optimistic update
    final previousMessages = state.messages;
    final reactions = List<ReactionGroup>.from(msg.reactions);

    if (hasReacted) {
      final rIdx = reactions.indexWhere((r) => r.emoji == emoji);
      if (rIdx >= 0) {
        final existing = reactions[rIdx];
        final newUsers = existing.users.where((u) => u != currentUserId).toList();
        if (newUsers.isEmpty) {
          reactions.removeAt(rIdx);
        } else {
          reactions[rIdx] = existing.copyWith(count: newUsers.length, users: newUsers);
        }
      }
    } else {
      final rIdx = reactions.indexWhere((r) => r.emoji == emoji);
      if (rIdx >= 0) {
        final existing = reactions[rIdx];
        reactions[rIdx] = existing.copyWith(
          count: existing.count + 1,
          users: [...existing.users, currentUserId],
        );
      } else {
        reactions.add(ReactionGroup(emoji: emoji, count: 1, users: [currentUserId]));
      }
    }

    final updatedMessages = [...state.messages];
    updatedMessages[idx] = msg.copyWith(reactions: reactions);
    state = state.copyWith(messages: updatedMessages);

    try {
      if (hasReacted) {
        await _dmRepo.removeReaction(conversationId, messageId, emoji);
      } else {
        await _dmRepo.addReaction(conversationId, messageId, emoji);
      }
    } catch (_) {
      // Revert optimistic update on error
      if (mounted) {
        state = state.copyWith(messages: previousMessages);
      }
    }
  }

  @override
  void dispose() {
    _dmMessageDisposer?.call();
    _reconnectDisposer?.call();
    _reactionAddedDisposer?.call();
    _reactionRemovedDisposer?.call();
    _markAsReadDebounce?.cancel();
    super.dispose();
  }
}

final dmConversationProvider = StateNotifierProvider.autoDispose.family<
    DmConversationNotifier, DmConversationState, int>(
  (ref, conversationId) {
    // Import auth state for optimistic messages
    final authState = ref.watch(authStateProvider);
    return DmConversationNotifier(
      ref.watch(dmRepositoryProvider),
      ref.watch(socketServiceProvider),
      conversationId,
      ref,
      currentUserId: authState.user?.id,
      currentUsername: authState.user?.username,
    );
  },
);
