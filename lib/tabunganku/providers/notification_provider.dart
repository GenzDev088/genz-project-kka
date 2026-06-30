import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/notification_model.dart';
import 'package:otax/tabunganku/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return MockNotificationService();
});

final allNotificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotifications();
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);

  ref.watch(allNotificationsProvider);
  return service.getUnreadCount();
});

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationService _service;
  final Ref _ref;

  NotificationNotifier(this._service, this._ref)
    : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _service.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _service.addNotification(notification);
    await loadNotifications();
    _ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    await loadNotifications();
    _ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    await loadNotifications();
    _ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    await loadNotifications();
    _ref.invalidate(unreadNotificationsCountProvider);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<
      NotificationNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      final service = ref.watch(notificationServiceProvider);
      return NotificationNotifier(service, ref);
    });
