import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/budget_model.dart';

abstract class BudgetService {
  Future<List<BudgetModel>> getBudgets();
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);
  Stream<List<BudgetModel>> watchBudgets();
}

class MockBudgetService implements BudgetService {
  static const String _storagePrefix = 'budgets_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<BudgetModel>> _userBudgets = {};
  static final StreamController<List<BudgetModel>> _streamController =
      StreamController<List<BudgetModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userBudgets.containsKey(userId)) {
      return;
    }

    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userBudgets[userId] = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userBudgets[userId] = decoded
            .whereType<Map>()
            .map(
              (item) => BudgetModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        _userBudgets[userId] = [];
      }
    } catch (_) {
      _userBudgets[userId] = [];
    }
  }

  Future<void> _saveUserBudgets(String userId) async {
    final prefs = await _getPrefs();
    final list = _userBudgets[userId] ?? const <BudgetModel>[];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitBudgets(String userId) async {
    await _ensureUserLoaded(userId);
    _streamController.add(List.unmodifiable(_userBudgets[userId] ?? []));
  }

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(_userBudgets[userId] ?? []);
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = _userBudgets[userId]!;
    final index = list.indexWhere(
      (b) =>
          b.id == budget.id ||
          (b.category == budget.category &&
              b.month == budget.month &&
              b.year == budget.year),
    );

    if (index != -1) {
      list[index] = budget;
    } else {
      list.add(budget);
    }

    await _saveUserBudgets(userId);
    await _emitBudgets(userId);
  }

  @override
  Future<void> deleteBudget(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userBudgets[userId]!.removeWhere((b) => b.id == id);
    await _saveUserBudgets(userId);
    await _emitBudgets(userId);
  }

  @override
  Stream<List<BudgetModel>> watchBudgets() {
    return Stream<List<BudgetModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(List.unmodifiable(_userBudgets[userId] ?? []));
      });
      final subscription = _streamController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}
