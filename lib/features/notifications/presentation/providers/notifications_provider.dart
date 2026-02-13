import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../leagues/data/league_repository.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_model.dart';

/// State for notifications
class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Group notifications by date
  Map<String, List<AppNotification>> get groupedByDate {
    final grouped = <String, List<AppNotification>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      String key;
      if (notificationDate == today) {
        key = 'Today';
      } else if (notificationDate == yesterday) {
        key = 'Yesterday';
      } else if (now.difference(notificationDate).inDays < 7) {
        key = 'This Week';
      } else {
        key = 'Earlier';
      }

      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  final SocketService _socketService;
  final Set<int> _userRosterIds;
  final String? _currentUserId;
  final int? Function() _getActiveLeagueChat;
  final List<VoidCallback> _disposers = [];

  NotificationsNotifier(
    this._repository,
    this._socketService, {
    required Set<int> userRosterIds,
    required String? currentUserId,
    required int? Function() getActiveLeagueChat,
  })  : _userRosterIds = userRosterIds,
        _currentUserId = currentUserId,
        _getActiveLeagueChat = getActiveLeagueChat,
        super(NotificationsState()) {
    _setupSocketListeners();
    loadNotifications();
  }

  void _setupSocketListeners() {
    // Listen for trade events
    _disposers.add(_socketService.onTradeProposed((data) {
      _addNotificationFromSocket(
        type: NotificationType.tradePending,
        title: 'New Trade Proposal',
        body: 'You have received a trade offer',
        data: data,
      );
    }));

    _disposers.add(_socketService.onTradeAccepted((data) {
      _addNotificationFromSocket(
        type: NotificationType.tradeAccepted,
        title: 'Trade Accepted',
        body: 'Your trade has been accepted',
        data: data,
      );
    }));

    _disposers.add(_socketService.onTradeRejected((data) {
      _addNotificationFromSocket(
        type: NotificationType.tradeRejected,
        title: 'Trade Rejected',
        body: 'Your trade has been rejected',
        data: data,
      );
    }));

    _disposers.add(_socketService.onTradeCompleted((data) {
      _addNotificationFromSocket(
        type: NotificationType.tradeCompleted,
        title: 'Trade Completed',
        body: 'A trade has been completed',
        data: data,
      );
    }));

    // Listen for draft events
    _disposers.add(_socketService.onDraftStarted((data) {
      _addNotificationFromSocket(
        type: NotificationType.draftStarted,
        title: 'Draft Started',
        body: 'A draft is now live!',
        data: data,
      );
    }));

    _disposers.add(_socketService.onNextPick((data) {
      // Only notify if it's the user's turn
      if (data is Map<String, dynamic>) {
        final currentRosterId = data['currentRosterId'] as int?;
        if (currentRosterId == null || !_userRosterIds.contains(currentRosterId)) {
          return;
        }
      }
      _addNotificationFromSocket(
        type: NotificationType.draftPick,
        title: 'Your Turn to Pick',
        body: 'You are on the clock!',
        data: data,
      );
    }));

    // Listen for chat messages
    _disposers.add(_socketService.onChatMessage((data) {
      if (data is Map<String, dynamic>) {
        // Skip if user sent this message
        final senderId = data['senderId'] as String? ?? data['sender_id'] as String?;
        if (senderId != null && senderId == _currentUserId) return;

        // Skip if user is currently viewing this league's chat
        final leagueId = data['leagueId'] as int? ?? data['league_id'] as int?;
        final activeChat = _getActiveLeagueChat();
        if (leagueId != null && leagueId == activeChat) return;

        final senderName = data['senderName'] as String? ?? data['sender_name'] as String?;
        final body = (data['content'] as String?)
            ?? (data['message'] is String ? data['message'] as String : null)
            ?? 'You have a new message';

        _addNotificationFromSocket(
          type: NotificationType.messageReceived,
          title: senderName != null ? 'Message from $senderName' : 'New Message',
          body: body,
          data: data,
        );
      }
    }));

    // Listen for invitation events
    _disposers.add(_socketService.onInvitationReceived((data) {
      _addNotificationFromSocket(
        type: NotificationType.invitationReceived,
        title: 'League Invitation',
        body: 'You have been invited to join a league',
        data: data,
      );
    }));

    // Listen for waiver events
    _disposers.add(_socketService.onWaiverClaimSuccessful((data) {
      _addNotificationFromSocket(
        type: NotificationType.waiverSuccess,
        title: 'Waiver Claim Successful',
        body: 'Your waiver claim was successful',
        data: data,
      );
    }));

    _disposers.add(_socketService.onWaiverClaimFailed((data) {
      _addNotificationFromSocket(
        type: NotificationType.waiverFailed,
        title: 'Waiver Claim Failed',
        body: 'Your waiver claim was not successful',
        data: data,
      );
    }));

    _disposers.add(_socketService.onWaiverProcessed((data) {
      _addNotificationFromSocket(
        type: NotificationType.waiverProcessed,
        title: 'Waivers Processed',
        body: 'Waiver claims have been processed',
        data: data,
      );
    }));

    // Listen for scoring events (only week finalized — scores:updated is too noisy)
    _disposers.add(_socketService.onWeekFinalized((data) {
      _addNotificationFromSocket(
        type: NotificationType.weekFinalized,
        title: 'Week Finalized',
        body: 'The weekly matchups have been finalized',
        data: data,
      );
    }));
  }

  /// Generate a deterministic notification ID to prevent duplicates.
  String _generateNotificationId(NotificationType type, Map<String, dynamic> data) {
    // Prefer server-provided ID
    final eventId = data['eventId'] ?? data['id'];
    if (eventId != null) return '${type.value}_$eventId';

    // Derive from type + entity IDs
    final entityId = data['tradeId'] ?? data['draftId'] ?? data['claimId'] ?? data['leagueId'];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${type.value}_${entityId ?? ''}_$timestamp';
  }

  void _addNotificationFromSocket({
    required NotificationType type,
    required String title,
    required String body,
    dynamic data,
  }) {
    if (!mounted) return;
    final dataMap = data is Map<String, dynamic> ? data : <String, dynamic>{};

    final id = _generateNotificationId(type, dataMap);

    final notification = AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      leagueId: dataMap['leagueId'] as int? ?? dataMap['league_id'] as int?,
      leagueName: dataMap['leagueName'] as String? ?? dataMap['league_name'] as String?,
      data: dataMap,
      createdAt: DateTime.now(),
    );

    addNotification(notification);
  }

  Future<void> loadNotifications() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final notifications = await _repository.getNotifications();
      if (!mounted) return;
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    if (!mounted) return;

    // Skip if duplicate (same ID already exists)
    if (state.notifications.any((n) => n.id == notification.id)) return;

    // Add to state immediately
    final updated = [notification, ...state.notifications];
    state = state.copyWith(notifications: updated);

    // Persist
    await _repository.addNotification(notification);
  }

  Future<void> markAsRead(String notificationId) async {
    if (!mounted) return;
    final index = state.notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final updated = [...state.notifications];
      updated[index] = updated[index].copyWith(isRead: true);
      state = state.copyWith(notifications: updated);
      await _repository.markAsRead(notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    if (!mounted) return;
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    await _repository.markAllAsRead();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (!mounted) return;
    final updated = state.notifications.where((n) => n.id != notificationId).toList();
    state = state.copyWith(notifications: updated);
    await _repository.deleteNotification(notificationId);
  }

  Future<void> clearAll() async {
    if (!mounted) return;
    state = state.copyWith(notifications: []);
    await _repository.clearAll();
  }

  @override
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
    super.dispose();
  }
}

/// Tracks which league chat the user is currently viewing.
/// Set when entering a chat screen, cleared on exit.
final activeLeagueChatProvider = StateProvider<int?>((ref) => null);

/// Set of roster IDs belonging to the current user across all leagues.
final userRosterIdsProvider = Provider<Set<int>>((ref) {
  final leaguesState = ref.watch(myLeaguesProvider);
  return leaguesState.leagues
      .where((l) => l.userRosterId != null)
      .map((l) => l.userRosterId!)
      .toSet();
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final userRosterIds = ref.watch(userRosterIdsProvider);
  final currentUserId = ref.watch(authStateProvider).user?.id;

  return NotificationsNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(socketServiceProvider),
    userRosterIds: userRosterIds,
    currentUserId: currentUserId,
    getActiveLeagueChat: () => ref.read(activeLeagueChatProvider),
  );
});

/// Provider for just the unread count (more efficient for badge)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
