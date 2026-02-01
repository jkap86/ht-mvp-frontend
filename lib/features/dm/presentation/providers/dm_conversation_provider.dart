import 'dart:async';
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
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  DmConversationState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  DmConversationState copyWith({
    List<DirectMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return DmConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
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
  Timer? _markAsReadDebounce;

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
    // Refresh messages on socket reconnection only if disconnected long enough
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      // Only do full refresh if disconnected for more than 30 seconds
      // For brief disconnects, socket events should have kept us in sync
      if (needsFullRefresh) {
        loadMessages();
      }
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

      // Merge with existing messages (socket messages may have arrived during fetch)
      final existingIds = state.messages.map((m) => m.id).toSet();
      final newFromApi = fetchedMessages.where((m) => !existingIds.contains(m.id)).toList();
      final merged = [...state.messages, ...newFromApi];

      // Sort by timestamp (newest first) and dedupe
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final seen = <int>{};
      final deduped = merged.where((m) => seen.add(m.id)).toList();

      state = state.copyWith(
        messages: deduped,
        isLoading: false,
        hasMore: fetchedMessages.length >= _pageSize,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load older messages (pagination)
  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final oldestId = state.messages.last.id;
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

      state = state.copyWith(isLoadingMore: false, error: e.toString());
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

  void _markAsRead() {
    _markAsReadDebounce?.cancel();
    _markAsReadDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await _dmRepo.markAsRead(conversationId);

        // Update inbox provider to reflect read status
        _ref.read(dmInboxProvider.notifier).markConversationReadLocally(conversationId);
      } catch (e) {
        // Silent fail - not critical
      }
    });
  }

  @override
  void dispose() {
    _dmMessageDisposer?.call();
    _reconnectDisposer?.call();
    _markAsReadDebounce?.cancel();
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
