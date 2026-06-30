import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/bill_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final billsServiceProvider = Provider((ref) => MockBillsService());

class MockBillsService {
  static const String _storagePrefix = 'bills_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<BillModel>> _userBills = {};
  static final StreamController<List<BillModel>> _streamController =
      StreamController<List<BillModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userBills.containsKey(userId)) return;
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userBills[userId] = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userBills[userId] = decoded
            .whereType<Map>()
            .map((item) => BillModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _userBills[userId] = [];
      }
    } catch (_) {
      _userBills[userId] = [];
    }
  }

  Future<void> _saveUserBills(String userId) async {
    final prefs = await _getPrefs();
    final list = _userBills[userId] ?? [];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitBills(String userId) async {
    await _ensureUserLoaded(userId);
    final list = _userBills[userId] ?? [];
    _streamController.add(List.unmodifiable(list));
  }

  Future<List<BillModel>> getBills() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(_userBills[userId] ?? []);
  }

  Future<void> addBill(BillModel bill) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userBills[userId]!.add(bill);
    await _saveUserBills(userId);
    await _emitBills(userId);
  }

  Future<void> updateBill(BillModel bill) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = _userBills[userId]!;
    final index = list.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      list[index] = bill;
      await _saveUserBills(userId);
      await _emitBills(userId);
    }
  }

  Future<void> deleteBill(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userBills[userId]!.removeWhere((b) => b.id == id);
    await _saveUserBills(userId);
    await _emitBills(userId);
  }

  Stream<List<BillModel>> watchBills() {
    return Stream<List<BillModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(List.unmodifiable(_userBills[userId] ?? []));
      });
      final sub = _streamController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }
}
