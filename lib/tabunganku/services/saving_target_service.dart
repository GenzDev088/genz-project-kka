import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';

abstract class SavingTargetService {
  Future<List<SavingTargetModel>> getTargets();
  Future<void> addTarget(SavingTargetModel target);
  Future<void> updateTarget(SavingTargetModel target);
  Future<void> deleteTarget(String id);
  Stream<List<SavingTargetModel>> watchTargets();
}

class MockSavingTargetService implements SavingTargetService {
  static const String _storageKey = 'saving_targets_user_';
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<SavingTargetModel>> _userTargets = {};
  static final StreamController<List<SavingTargetModel>> _streamController =
      StreamController<List<SavingTargetModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {

    return 'default_user';
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userTargets.containsKey(userId)) {
      return;
    }

    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storageKey$userId');
    if (raw == null || raw.isEmpty) {
      _userTargets[userId] = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userTargets[userId] = decoded
            .whereType<Map>()
            .map(
              (item) =>
                  SavingTargetModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        _userTargets[userId] = [];
      }
    } catch (_) {
      _userTargets[userId] = [];
    }
  }

  Future<void> _saveUserTargets(String userId) async {
    final prefs = await _getPrefs();
    final list = _userTargets[userId] ?? const <SavingTargetModel>[];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storageKey$userId', raw);
  }

  Future<void> _emitTargets(String userId) async {
    await _ensureUserLoaded(userId);
    final targets = _userTargets[userId] ?? const <SavingTargetModel>[];
    _streamController.add(List.unmodifiable(targets));
  }

  Future<void> _checkAndRemoveExpiredTargets(String userId) async {
    final targets = _userTargets[userId] ?? [];
    if (targets.isEmpty) return;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final originalCount = targets.length;
    targets.removeWhere((t) => t.dueDate.isBefore(todayMidnight));

    if (targets.length != originalCount) {
      await _saveUserTargets(userId);
      _emitTargets(userId);
    }
  }

  @override
  Future<List<SavingTargetModel>> getTargets() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    await _checkAndRemoveExpiredTargets(userId);
    return List.unmodifiable(
      _userTargets[userId] ?? const <SavingTargetModel>[],
    );
  }

  @override
  Future<void> addTarget(SavingTargetModel target) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userTargets[userId]!.add(target);
    await _saveUserTargets(userId);
    await _checkAndRemoveExpiredTargets(userId);
    await _emitTargets(userId);
  }

  @override
  Future<void> updateTarget(SavingTargetModel target) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final targets = _userTargets[userId]!;
    final index = targets.indexWhere((t) => t.id == target.id);
    if (index != -1) {
      targets[index] = target;
      await _saveUserTargets(userId);
      await _checkAndRemoveExpiredTargets(userId);
      await _emitTargets(userId);
    }
  }

  @override
  Future<void> deleteTarget(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userTargets[userId]!.removeWhere((t) => t.id == id);
    await _saveUserTargets(userId);
    await _emitTargets(userId);
  }

  @override
  Stream<List<SavingTargetModel>> watchTargets() {
    return Stream<List<SavingTargetModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        await _checkAndRemoveExpiredTargets(userId);
        controller.add(
          List.unmodifiable(
            _userTargets[userId] ?? const <SavingTargetModel>[],
          ),
        );
      });
      final subscription = _streamController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}
