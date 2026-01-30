import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
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
  final List<VoidCallback> _disposers = [];

  NotificationsNotifier(this._repository, this._socketService) : super(NotificationsState()) {
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
      // Only notify if it's the user's turn (data should contain current picker info)
      _addNotificationFromSocket(
        type: NotificationType.draftPick,
        title: 'Draft Update',
        body: 'A new pick is on the clock',
        data: data,
      );
    }));

    // Listen for chat messages
    _disposers.add(_socketService.onChatMessage((data) {
      if (data is Map<String, dynamic>) {
        _addNotificationFromSocket(
          type: NotificationType.messageReceived,
          title: 'New Message',
          body: data['message'] as String? ?? 'You have a new message',
          data: data,
        );
      }
    }));
  }

  void _addNotificationFromSocket({
    required NotificationType type,
    required String title,
    required String body,
    dynamic data,
  }) {
    if (!mounted) return;
    final dataMap = data is Map<String, dynamic> ? data : <String, dynamic>{};

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    if (!mounted) return;
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

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(socketServiceProvider),
  );
});

/// Provider for just the unread count (more efficient for badge)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
