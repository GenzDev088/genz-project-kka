import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/investment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final investmentServiceProvider = Provider((ref) => MockInvestmentService());

class MockInvestmentService {
  static const String _storagePrefix = 'investments_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<InvestmentModel>> _userInvestments = {};
  static final StreamController<List<InvestmentModel>> _streamController =
      StreamController<List<InvestmentModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userInvestments.containsKey(userId)) return;
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userInvestments[userId] = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userInvestments[userId] = decoded
            .whereType<Map>()
            .map(
              (item) =>
                  InvestmentModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        _userInvestments[userId] = [];
      }
    } catch (_) {
      _userInvestments[userId] = [];
    }
  }

  Future<void> _saveUserInvestments(String userId) async {
    final prefs = await _getPrefs();
    final list = _userInvestments[userId] ?? [];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitInvestments(String userId) async {
    await _ensureUserLoaded(userId);
    final list = _userInvestments[userId] ?? [];
    _streamController.add(List.unmodifiable(list));
  }

  Future<List<InvestmentModel>> getInvestments() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(_userInvestments[userId] ?? []);
  }

  Future<void> addInvestment(InvestmentModel inv) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userInvestments[userId]!.add(inv);
    await _saveUserInvestments(userId);
    await _emitInvestments(userId);
  }

  Future<void> updateInvestment(InvestmentModel inv) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = _userInvestments[userId]!;
    final index = list.indexWhere((i) => i.id == inv.id);
    if (index != -1) {
      list[index] = inv;
      await _saveUserInvestments(userId);
      await _emitInvestments(userId);
    }
  }

  Future<void> deleteInvestment(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userInvestments[userId]!.removeWhere((i) => i.id == id);
    await _saveUserInvestments(userId);
    await _emitInvestments(userId);
  }

  Stream<List<InvestmentModel>> watchInvestments() {
    return Stream<List<InvestmentModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(List.unmodifiable(_userInvestments[userId] ?? []));
      });
      final sub = _streamController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }
}
