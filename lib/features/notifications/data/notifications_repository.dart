import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

/// Repository for managing notification storage and retrieval.
/// Uses local storage for now, can be extended to use a backend API.
class NotificationsRepository {
  static const String _storageKey = 'app_notifications';
  static const int _maxNotifications = 50;

  /// Get all notifications from storage
  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

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
    final prefs = await SharedPreferences.getInstance();

    // Keep only the most recent notifications
    final toSave = notifications.take(_maxNotifications).toList();
    final jsonList = toSave.map((n) => n.toJson()).toList();

    await prefs.setString(_storageKey, json.encode(jsonList));
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }
}
