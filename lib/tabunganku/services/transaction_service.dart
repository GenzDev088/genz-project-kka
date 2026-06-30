import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/services/challenge_service.dart';



abstract class TransactionService {

  Future<void> clearAllTransactions();
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> getTransaction(String id);
  Future<TransactionModel> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);



  Stream<List<TransactionModel>> watchTransactions([String? groupId]);
}


class MockTransactionService implements TransactionService {
  final ChallengeService? challengeService;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  MockTransactionService({this.challengeService});

  @override
  Future<void> clearAllTransactions() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    _userTransactions[userId] = [];
    await _saveUserTransactions(userId);
    await _emitTransactions(userId);
  }

  static const String _storagePrefix = 'transactions_user_';
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<SharedPreferences>? _prefsFuture;
  static final Map<String, List<TransactionModel>> _userTransactions = {};
  static final StreamController<List<TransactionModel>> _streamController =
      StreamController<List<TransactionModel>>.broadcast();

  Future<SharedPreferences> _getPrefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userTransactions.containsKey(userId)) {
      return;
    }

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
              (item) =>
                  TransactionModel.fromJson(Map<String, dynamic>.from(item)),
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
    final list = _userTransactions[userId] ?? const <TransactionModel>[];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_storagePrefix$userId', raw);
  }

  List<TransactionModel> _ordered(List<TransactionModel> items) {
    final ordered = List<TransactionModel>.from(items)
      ..sort((a, b) => b.date.compareTo(a.date));
    return ordered;
  }

  Future<void> _emitTransactions(String userId) async {
    await _ensureUserLoaded(userId);
    final ordered = _ordered(
      _userTransactions[userId] ?? const <TransactionModel>[],
    );
    _streamController.add(List.unmodifiable(ordered));
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final ordered = _ordered(
      _userTransactions[userId] ?? const <TransactionModel>[],
    );
    return List.unmodifiable(ordered);
  }

  @override
  Future<TransactionModel> getTransaction(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final transactions =
        _userTransactions[userId] ?? const <TransactionModel>[];
    return transactions.firstWhere((t) => t.id == id);
  }

  @override
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    final userId = await _getCurrentUserId();


    await _ensureUserLoaded(userId);
    _userTransactions[userId]!.add(transaction);
    await _saveUserTransactions(userId);
    await _emitTransactions(userId);


    if (transaction.groupId != null && transaction.groupId!.isNotEmpty) {
      try {
        await _firestore
            .collection('family_groups')
            .doc(transaction.groupId)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toJson());
      } catch (e) {
        print("ERROR: Gagal sinkronisasi transaksi ke Cloud: $e");
      }
    }


    if (challengeService != null) {
      await challengeService!.checkAndUpdateChallengeFromTransaction(
        transaction,
      );
    }

    return transaction;
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);
    final transactions = _userTransactions[userId]!;
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await _saveUserTransactions(userId);
      await _emitTransactions(userId);
    }


    if (transaction.groupId != null && transaction.groupId!.isNotEmpty) {
      try {

        bool isFirebaseReady = false;
        try {
          Firebase.app();
          isFirebaseReady = true;
        } catch (_) {}

        if (isFirebaseReady) {
          await _firestore
              .collection('family_groups')
              .doc(transaction.groupId)
              .collection('transactions')
              .doc(transaction.id)
              .update(transaction.toJson());
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final userId = await _getCurrentUserId();
    await _ensureUserLoaded(userId);


    final txToDelete = _userTransactions[userId]!.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception("Not found"),
    );
    final groupId = txToDelete.groupId;

    _userTransactions[userId]!.removeWhere((t) => t.id == id);
    await _saveUserTransactions(userId);
    await _emitTransactions(userId);


    if (groupId != null && groupId.isNotEmpty) {
      try {
        bool isFirebaseReady = false;
        try {
          Firebase.app();
          isFirebaseReady = true;
        } catch (_) {}

        if (isFirebaseReady) {
          await _firestore
              .collection('family_groups')
              .doc(groupId)
              .collection('transactions')
              .doc(id)
              .delete();
        }
      } catch (_) {}
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions([String? groupId]) {

    final controller = StreamController<List<TransactionModel>>.broadcast();


    StreamSubscription<List<TransactionModel>>? localSub;


    StreamSubscription<QuerySnapshot>? firestoreSub;


    List<TransactionModel> latestLocal = [];
    List<TransactionModel> latestCloud = [];

    void emitMerged() {

      final Map<String, TransactionModel> mergedMap = {};


      for (var tx in latestLocal) {
        mergedMap[tx.id] = tx;
      }




      for (var tx in latestCloud) {
        mergedMap[tx.id] = tx;
      }

      final mergedList = mergedMap.values.toList();
      if (!controller.isClosed) {
        controller.add(_ordered(mergedList));
      }
    }


    Future<void> init() async {
      final userId = await _getCurrentUserId();
      await _ensureUserLoaded(userId);
      latestLocal = _userTransactions[userId] ?? [];


      localSub = _streamController.stream.listen((newList) {
        latestLocal = newList;
        emitMerged();
      });


      if (groupId != null && groupId.isNotEmpty) {
        bool isFirebaseReady = false;
        try {
          Firebase.app();
          isFirebaseReady = true;
        } catch (_) {}

        if (isFirebaseReady) {
          firestoreSub = _firestore
              .collection('family_groups')
              .doc(groupId)
              .collection('transactions')
              .snapshots()
              .listen((snapshot) {
                latestCloud = snapshot.docs
                    .map((doc) => TransactionModel.fromJson(doc.data()))
                    .toList();
                emitMerged();
              }, onError: (e) => print("Firestore Stream Error: $e"));
        }
      }

      emitMerged();
    }

    init();

    controller.onCancel = () {
      localSub?.cancel();
      firestoreSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
