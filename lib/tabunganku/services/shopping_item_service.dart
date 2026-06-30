import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/shopping_item_model.dart';

abstract class ShoppingItemService {
  Future<List<ShoppingItem>> getItems();
  Future<void> addItem(ShoppingItem item);
  Future<void> updateItem(ShoppingItem item);
  Future<void> deleteItem(String id);
  Stream<List<ShoppingItem>> watchItems();
}

class MockShoppingItemService implements ShoppingItemService {
  static const String _storagePrefix = 'shopping_items_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<ShoppingItem>> _userItems = {};
  static final StreamController<List<ShoppingItem>> _streamController =
      StreamController<List<ShoppingItem>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userItems.containsKey(userId)) {
      return;
    }

    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userItems[userId] = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userItems[userId] = decoded
            .whereType<Map>()
            .map(
              (item) => ShoppingItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        _userItems[userId] = [];
      }
    } catch (_) {
      _userItems[userId] = [];
    }
  }

  Future<void> _saveUserItems(String userId) async {
    final prefs = await _getPrefs();
    final list = _userItems[userId] ?? const <ShoppingItem>[];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitItems(String userId) async {
    await _ensureUserLoaded(userId);
    final list = List<ShoppingItem>.from(_userItems[userId] ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _streamController.add(List.unmodifiable(list));
  }

  @override
  Future<List<ShoppingItem>> getItems() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = List<ShoppingItem>.from(_userItems[userId] ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> addItem(ShoppingItem item) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userItems[userId]!.add(item);
    await _saveUserItems(userId);
    await _emitItems(userId);
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final items = _userItems[userId]!;
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await _saveUserItems(userId);
      await _emitItems(userId);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userItems[userId]!.removeWhere((i) => i.id == id);
    await _saveUserItems(userId);
    await _emitItems(userId);
  }

  @override
  Stream<List<ShoppingItem>> watchItems() {
    return Stream<List<ShoppingItem>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        final list = List<ShoppingItem>.from(_userItems[userId] ?? [])
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(List.unmodifiable(list));
      });
      final subscription = _streamController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}
