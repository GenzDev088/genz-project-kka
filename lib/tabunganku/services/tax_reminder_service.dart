import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/tax_reminder_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taxReminderServiceProvider = Provider((ref) => TaxReminderService());

final taxRemindersStreamProvider = StreamProvider<List<TaxReminderModel>>((
  ref,
) {
  return ref.watch(taxReminderServiceProvider).watchReminders();
});

class TaxReminderService {
  static const String _storagePrefix = 'tax_reminders_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<TaxReminderModel>> _userReminders = {};
  static final StreamController<List<TaxReminderModel>> _streamController =
      StreamController<List<TaxReminderModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userReminders.containsKey(userId)) return;
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userReminders[userId] = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userReminders[userId] = decoded
            .whereType<Map>()
            .map(
              (item) =>
                  TaxReminderModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        _userReminders[userId] = [];
      }
    } catch (_) {
      _userReminders[userId] = [];
    }
  }

  Future<void> _saveUserReminders(String userId) async {
    final prefs = await _getPrefs();
    final list = _userReminders[userId] ?? [];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitReminders(String userId) async {
    await _ensureUserLoaded(userId);
    final list = _userReminders[userId] ?? [];
    _streamController.add(List.unmodifiable(list));
  }

  Future<List<TaxReminderModel>> getReminders() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(_userReminders[userId] ?? []);
  }

  Future<void> addReminder(TaxReminderModel reminder) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userReminders[userId]!.add(reminder);
    await _saveUserReminders(userId);
    await _emitReminders(userId);
  }

  Future<void> updateReminder(TaxReminderModel reminder) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = _userReminders[userId]!;
    final index = list.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      list[index] = reminder;
      await _saveUserReminders(userId);
      await _emitReminders(userId);
    }
  }

  Future<void> deleteReminder(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userReminders[userId]!.removeWhere((r) => r.id == id);
    await _saveUserReminders(userId);
    await _emitReminders(userId);
  }

  Stream<List<TaxReminderModel>> watchReminders() {
    return Stream<List<TaxReminderModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(List.unmodifiable(_userReminders[userId] ?? []));
      });
      final sub = _streamController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }
}
