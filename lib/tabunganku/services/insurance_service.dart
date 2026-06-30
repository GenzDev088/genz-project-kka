import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/insurance_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final insuranceServiceProvider = Provider((ref) => MockInsuranceService());

class MockInsuranceService {
  static const String _storagePrefix = 'insurance_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<InsuranceModel>> _userInsurance = {};
  static final StreamController<List<InsuranceModel>> _streamController =
      StreamController<List<InsuranceModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userInsurance.containsKey(userId)) return;
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userInsurance[userId] = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userInsurance[userId] = decoded
            .whereType<Map>()
            .map(
              (item) =>
                  InsuranceModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        _userInsurance[userId] = [];
      }
    } catch (_) {
      _userInsurance[userId] = [];
    }
  }

  Future<void> _saveUserInsurance(String userId) async {
    final prefs = await _getPrefs();
    final list = _userInsurance[userId] ?? [];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitInsurance(String userId) async {
    await _ensureUserLoaded(userId);
    final list = _userInsurance[userId] ?? [];
    _streamController.add(List.unmodifiable(list));
  }

  Future<List<InsuranceModel>> getInsurance() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(_userInsurance[userId] ?? []);
  }

  Future<void> addInsurance(InsuranceModel ins) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userInsurance[userId]!.add(ins);
    await _saveUserInsurance(userId);
    await _emitInsurance(userId);
  }

  Future<void> updateInsurance(InsuranceModel ins) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = _userInsurance[userId]!;
    final index = list.indexWhere((i) => i.id == ins.id);
    if (index != -1) {
      list[index] = ins;
      await _saveUserInsurance(userId);
      await _emitInsurance(userId);
    }
  }

  Future<void> deleteInsurance(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userInsurance[userId]!.removeWhere((i) => i.id == id);
    await _saveUserInsurance(userId);
    await _emitInsurance(userId);
  }

  Stream<List<InsuranceModel>> watchInsurance() {
    return Stream<List<InsuranceModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(List.unmodifiable(_userInsurance[userId] ?? []));
      });
      final sub = _streamController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }
}
