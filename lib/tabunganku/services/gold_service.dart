import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/gold_investment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goldServiceProvider = Provider((ref) => MockGoldService());

final goldPriceProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(goldServiceProvider).watchPrices();
});

class MockGoldService {
  static const String _storagePrefix = 'gold_transactions_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<GoldTransactionModel>> _userTransactions = {};
  static final StreamController<List<GoldTransactionModel>> _streamController =
      StreamController<List<GoldTransactionModel>>.broadcast();


  final String _primaryApiUrl = 'https://api.gold-api.com/price/XAU';
  final String _secondaryApiUrl = 'https://www.gold-feed.com/prices/gold.json';
  final double _usdToIdr = 16350.0;
  final double _ozToGram = 31.1035;

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userTransactions.containsKey(userId)) return;
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) {
      _userTransactions[userId] = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userTransactions[userId] = decoded
            .whereType<Map>()
            .map(
              (item) => GoldTransactionModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _userTransactions[userId] = [];
      }
    } catch (_) {
      _userTransactions[userId] = [];
    }
  }

  Future<void> _saveUserTransactions(String userId) async {
    final prefs = await _getPrefs();
    final list = _userTransactions[userId] ?? [];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  Future<void> _emitTransactions(String userId) async {
    await _ensureUserLoaded(userId);
    final list = _userTransactions[userId] ?? [];
    _streamController.add(List.unmodifiable(list));
  }

  Future<List<GoldTransactionModel>> getTransactions() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    return List.unmodifiable(_userTransactions[userId] ?? []);
  }

  Future<void> addTransaction(GoldTransactionModel tx) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userTransactions[userId]!.add(tx);
    await _saveUserTransactions(userId);
    await _emitTransactions(userId);
  }

  Future<void> updateTransaction(GoldTransactionModel tx) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final list = _userTransactions[userId]!;
    final index = list.indexWhere((i) => i.id == tx.id);
    if (index != -1) {
      list[index] = tx;
      await _saveUserTransactions(userId);
      await _emitTransactions(userId);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userTransactions[userId]!.removeWhere((i) => i.id == id);
    await _saveUserTransactions(userId);
    await _emitTransactions(userId);
  }

  Stream<List<GoldTransactionModel>> watchTransactions() {
    return Stream<List<GoldTransactionModel>>.multi((controller) {
      Future<void>(() async {
        final userId = await _getCurrentUserId();
        await _ensureUserLoaded(userId);
        controller.add(List.unmodifiable(_userTransactions[userId] ?? []));
      });
      final sub = _streamController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  double calculateTotalGrams(List<GoldTransactionModel> txs) {
    return txs.fold(
      0.0,
      (sum, tx) =>
          sum + (tx.type == GoldTransactionType.buy ? tx.grams : -tx.grams),
    );
  }

  double calculateAveragePrice(List<GoldTransactionModel> txs) {
    final buyTxs = txs
        .where((tx) => tx.type == GoldTransactionType.buy)
        .toList();
    if (buyTxs.isEmpty) return 0;
    final totalSpent = buyTxs.fold(
      0.0,
      (sum, tx) => sum + (tx.grams * tx.pricePerGram),
    );
    final totalGrams = buyTxs.fold(0.0, (sum, tx) => sum + tx.grams);
    return totalGrams > 0 ? totalSpent / totalGrams : 0;
  }

  Stream<Map<String, double>> watchPrices() async* {

    yield await _fetchRealPrices();


    yield* Stream.periodic(
      const Duration(minutes: 1),
      (_) => _fetchRealPrices(),
    ).asyncMap((event) => event);
  }

  Future<Map<String, double>> _fetchRealPrices() async {

    try {
      final response = await http
          .get(Uri.parse(_primaryApiUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('price')) {
          final goldPriceUsdOz = double.parse(data['price'].toString());
          final goldPriceIdrGram = (goldPriceUsdOz * _usdToIdr) / _ozToGram;
          return {
            'buy': goldPriceIdrGram,
            'sell': goldPriceIdrGram * 0.95,
            'change': 0.85,
          };
        }
      }
    } catch (e) {
      print('Primary Gold API failed: $e');
    }


    try {
      final response = await http
          .get(Uri.parse(_secondaryApiUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('gold_price_usd_ounce')) {
          final goldPriceUsdOz = double.parse(
            data['gold_price_usd_ounce'].toString(),
          );
          final goldPriceIdrGram = (goldPriceUsdOz * _usdToIdr) / _ozToGram;
          return {
            'buy': goldPriceIdrGram,
            'sell': goldPriceIdrGram * 0.95,
            'change': 0.85,
          };
        }
      }
    } catch (e) {
      print('Secondary Gold API failed: $e');
    }


    return {'buy': 1238500.0, 'sell': 1176500.0, 'change': 0.85};
  }
}
