import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active tab in the unified chat widget
enum ChatTab { dm, league }

/// View mode within the DM tab
enum DmViewMode { inbox, conversation, newConversation }

/// State for the unified floating chat widget
class UnifiedChatState {
  final ChatTab activeTab;
  final DmViewMode dmViewMode;
  final int? selectedConversationId;
  final String? selectedConversationUsername;

  const UnifiedChatState({
    this.activeTab = ChatTab.dm,
    this.dmViewMode = DmViewMode.inbox,
    this.selectedConversationId,
    this.selectedConversationUsername,
  });

  UnifiedChatState copyWith({
    ChatTab? activeTab,
    DmViewMode? dmViewMode,
    int? selectedConversationId,
    String? selectedConversationUsername,
    bool clearSelectedConversation = false,
  }) {
    return UnifiedChatState(
      activeTab: activeTab ?? this.activeTab,
      dmViewMode: dmViewMode ?? this.dmViewMode,
      selectedConversationId: clearSelectedConversation
          ? null
          : (selectedConversationId ?? this.selectedConversationId),
      selectedConversationUsername: clearSelectedConversation
          ? null
          : (selectedConversationUsername ?? this.selectedConversationUsername),
    );
  }
}

/// Notifier for managing unified chat widget state
class UnifiedChatNotifier extends StateNotifier<UnifiedChatState> {
  UnifiedChatNotifier() : super(const UnifiedChatState());

  /// Switch to a specific tab
  void setTab(ChatTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  /// Select a DM conversation to view
  void selectConversation(int conversationId, String username) {
    state = state.copyWith(
      dmViewMode: DmViewMode.conversation,
      selectedConversationId: conversationId,
      selectedConversationUsername: username,
    );
  }

  /// Go back to the DM inbox
  void backToInbox() {
    state = state.copyWith(
      dmViewMode: DmViewMode.inbox,
      clearSelectedConversation: true,
    );
  }

  /// Start new conversation (show user search)
  void startNewConversation() {
    state = state.copyWith(dmViewMode: DmViewMode.newConversation);
  }

  /// Reset to initial state (e.g., when widget is closed)
  void reset() {
    state = const UnifiedChatState();
  }
}

/// Provider for unified chat widget state
final unifiedChatProvider =
    StateNotifierProvider<UnifiedChatNotifier, UnifiedChatState>(
  (ref) => UnifiedChatNotifier(),
);
