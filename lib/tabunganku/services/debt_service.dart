import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/debt_model.dart';

abstract class DebtService {
  Future<List<DebtModel>> getDebts();
  Future<void> addDebt(DebtModel debt);
  Future<void> updateDebt(DebtModel debt);
  Future<void> deleteDebt(String id);
  Stream<List<DebtModel>> watchDebts();
}

class MockDebtService implements DebtService {
  static const String _storagePrefix = 'debts_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<DebtModel>> _userDebts = {};
  static final StreamController<List<DebtModel>> _streamController =
      StreamController<List<DebtModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userDebts.containsKey(userId)) {
      return;
    }

    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userDebts[userId] = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userDebts[userId] = decoded
            .whereType<Map>()
            .map((item) => DebtModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _userDebts[userId] = [];
      }
    } catch (_) {
      _userDebts[userId] = [];
    }
  }

  Future<void> _saveUserDebts(String userId) async {
    final prefs = await _getPrefs();
    final list = _userDebts[userId] ?? const <DebtModel>[];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitDebts(String userId) async {
    await _ensureUserLoaded(userId);
    final list = List<DebtModel>.from(_userDebts[userId] ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _streamController.add(List.unmodifiable(list));
  }

  @override
  Future<List<DebtModel>> getDebts() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = List<DebtModel>.from(_userDebts[userId] ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> addDebt(DebtModel debt) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userDebts[userId]!.add(debt);
    await _saveUserDebts(userId);
    await _emitDebts(userId);
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final debts = _userDebts[userId]!;
    final index = debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      debts[index] = debt;
      await _saveUserDebts(userId);
      await _emitDebts(userId);
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userDebts[userId]!.removeWhere((d) => d.id == id);
    await _saveUserDebts(userId);
    await _emitDebts(userId);
  }

  @override
  Stream<List<DebtModel>> watchDebts() {
    return Stream<List<DebtModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        final list = List<DebtModel>.from(_userDebts[userId] ?? [])
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(List.unmodifiable(list));
      });
      final subscription = _streamController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}
