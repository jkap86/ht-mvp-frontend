import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_sanitizer.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../chat/presentation/providers/unified_chat_provider.dart';
import '../../data/dm_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/direct_message.dart';

class DmInboxState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;
  final int totalUnreadCount;

  DmInboxState({
    this.conversations = const [],
    this.isLoading = true,
    this.error,
    this.totalUnreadCount = 0,
  });

  DmInboxState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? totalUnreadCount,
  }) {
    return DmInboxState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }
}

class DmInboxNotifier extends StateNotifier<DmInboxState> {
  final DmRepository _dmRepo;
  final SocketService _socketService;
  final Ref _ref;

  VoidCallback? _dmMessageDisposer;
  VoidCallback? _dmReadDisposer;
  VoidCallback? _reconnectDisposer;

  DmInboxNotifier(this._dmRepo, this._socketService, this._ref) : super(DmInboxState()) {
    _setupSocketListeners();
    loadConversations();
  }

  void _setupSocketListeners() {
    // Refresh conversations on socket reconnection only if disconnected long enough
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      // Only do full refresh if disconnected for more than 30 seconds
      // For brief disconnects, socket events should have kept us in sync
      if (needsFullRefresh) {
        loadConversations();
      }
    });

    // Listen for new DM messages to update inbox
    _dmMessageDisposer = _socketService.onDmMessage((data) {
      if (!mounted) return;

      final conversationId = data['conversationId'] as int?;
      final messageData = data['message'] as Map<String, dynamic>?;
      if (conversationId == null || messageData == null) return;

      final message = DirectMessage.fromJson(messageData);

      // Check if user is currently viewing this conversation
      final unifiedState = _ref.read(unifiedChatProvider);
      final isViewingThisConversation =
          unifiedState.dmViewMode == DmViewMode.conversation &&
          unifiedState.selectedConversationId == conversationId;

      // Update the conversation in the list
      final conversations = [...state.conversations];
      final index = conversations.indexWhere((c) => c.id == conversationId);

      if (index >= 0) {
        // Update existing conversation
        final updated = conversations[index].copyWith(
          lastMessage: message,
          // Don't increment unread if user is viewing this conversation
          unreadCount: isViewingThisConversation
              ? conversations[index].unreadCount
              : conversations[index].unreadCount + 1,
          updatedAt: message.createdAt,
        );
        conversations.removeAt(index);
        conversations.insert(0, updated); // Move to top
      } else {
        // Conversation not in list - fetch from API to add it
        loadConversations();
        return; // Let loadConversations handle the state update
      }

      // Update total unread count
      final totalUnread = conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.unreadCount,
      );

      state = state.copyWith(
        conversations: conversations,
        totalUnreadCount: totalUnread,
      );
    });

    // Listen for DM read events (when the OTHER user reads our messages)
    // Note: When WE read, we update locally via markConversationReadLocally
    // This event is when the other person reads our messages - doesn't affect OUR unread count
    _dmReadDisposer = _socketService.onDmRead((data) {
      if (!mounted) return;

      final conversationId = data['conversationId'] as int?;
      if (conversationId == null) return;

      // The read event doesn't affect OUR unread count - it's when THEY read OUR messages
      // No need to refresh all conversations. In the future, if we want to show
      // read receipts (e.g., "seen" indicator), we'd update that specific conversation here.
      // For now, we just acknowledge the event - no action needed.
    });
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conversations = await _dmRepo.getConversations();

      if (!mounted) return;

      // Calculate total unread count
      final totalUnread = conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.unreadCount,
      );

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        totalUnreadCount: totalUnread,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  /// Add a new conversation to the top of the inbox (called after creating a new conversation)
  void addConversationToTop(Conversation conversation) {
    // Check if already exists
    if (state.conversations.any((c) => c.id == conversation.id)) {
      return;
    }

    state = state.copyWith(
      conversations: [conversation, ...state.conversations],
    );
  }

  /// Mark a conversation's unread count as zero locally (called when opening conversation)
  void markConversationReadLocally(int conversationId) {
    final conversations = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    final totalUnread = conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );

    state = state.copyWith(
      conversations: conversations,
      totalUnreadCount: totalUnread,
    );
  }

  @override
  void dispose() {
    _dmMessageDisposer?.call();
    _dmReadDisposer?.call();
    _reconnectDisposer?.call();
    super.dispose();
  }
}

final dmInboxProvider = StateNotifierProvider.autoDispose<DmInboxNotifier, DmInboxState>(
  (ref) => DmInboxNotifier(
    ref.watch(dmRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref,
  ),
);

/// Provider for just the total unread count (for badge display)
final dmUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(dmInboxProvider.select((state) => state.totalUnreadCount));
});
