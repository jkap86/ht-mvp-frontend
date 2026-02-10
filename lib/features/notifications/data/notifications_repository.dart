import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/auth_provider.dart';
import '../domain/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  return NotificationsRepository(userId: authState.user?.id);
});

/// Repository for managing notification storage and retrieval.
/// Storage is scoped per-user to prevent cross-account data leakage.
class NotificationsRepository {
  static const String _legacyKey = 'app_notifications';
  static const int _maxNotifications = 50;

  final String? _userId;

  NotificationsRepository({String? userId}) : _userId = userId;

  /// User-scoped storage key. Null if no user context.
  String? get _storageKey =>
      _userId != null ? '$_legacyKey:$_userId' : null;

  /// Clear notification storage for a specific user (called during logout).
  /// Also removes the legacy global key.
  static Future<void> clearForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_legacyKey:$userId');
    await prefs.remove(_legacyKey);
  }

  /// Get all notifications from storage
  Future<List<AppNotification>> getNotifications() async {
    final key = _storageKey;
    if (key == null) return [];

    final prefs = await SharedPreferences.getInstance();

    // Migrate legacy global data to user-scoped key on first load
    await _migrateLegacyData(prefs, key);

    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  /// Save notifications to storage
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final key = _storageKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Keep only the most recent notifications
    final toSave = notifications.take(_maxNotifications).toList();
    final jsonList = toSave.map((n) => n.toJson()).toList();

    await prefs.setString(key, json.encode(jsonList));
  }

  /// Add a notification
  Future<void> addNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    await saveNotifications(notifications);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);

    if (index >= 0) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await saveNotifications(notifications);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    await saveNotifications(updated);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    await saveNotifications(notifications);
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    final key = _storageKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Migrate legacy global notifications into the user-scoped key, then delete.
  Future<void> _migrateLegacyData(SharedPreferences prefs, String scopedKey) async {
    final legacyData = prefs.getString(_legacyKey);
    if (legacyData == null) return;

    // Only migrate if user-scoped key doesn't already have data
    if (prefs.getString(scopedKey) == null) {
      await prefs.setString(scopedKey, legacyData);
    }
    await prefs.remove(_legacyKey);
  }
}
