import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:otax/tabunganku/main.dart' show flutterLocalNotificationsPlugin;
import 'package:otax/tabunganku/models/notification_model.dart';

abstract class NotificationService {
  Future<List<NotificationModel>> getNotifications();
  Future<void> addNotification(NotificationModel notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> clearAll();
  Future<int> getUnreadCount();
}

class MockNotificationService implements NotificationService {
  static const String _notificationsKey = 'user_notifications_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final key = '$_notificationsKey$userId';
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    final notifications = await getNotifications();


    notifications.add(notification);

    await _saveNotifications(notifications);


    await _showSystemNotification(notification);
  }

  Future<void> _showSystemNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'tabunganku_activity',
          'Aktivitas TabunganKu',
          channelDescription:
              'Notifikasi untuk pencapaian dan aktivitas menabung',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notification.id.hashCode, // Unique ID based on string hash
      notification.title,
      notification.message,
      platformDetails,
      payload: notification.actionData,
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);

    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await _saveNotifications(notifications);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications(updated);
  }

  @override
  Future<void> clearAll() async {
    await _saveNotifications([]);
  }

  @override
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> _saveNotifications(List<NotificationModel> notifications) async {
    final prefs = await _getPrefs();
    final userId = await _getCurrentUserId();
    final key = '$_notificationsKey$userId';
    final jsonString = jsonEncode(
      notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(key, jsonString);
  }
}
