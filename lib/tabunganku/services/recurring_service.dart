import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otax/tabunganku/core/security/secure_storage_service.dart';
import 'package:otax/tabunganku/models/recurring_transaction_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/services/transaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';

final recurringServiceProvider = Provider<RecurringService>((ref) {
  return RecurringService(ref.watch(transactionServiceProvider));
});

class RecurringService {
  final TransactionService _transactionService;
  static const String _storagePrefix = 'recurring_transactions_user_';
  final SecureStorageService _secureStorage = SecureStorageService();
  SharedPreferences? _prefs;

  RecurringService(this._transactionService);

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    return (userId == null || userId.isEmpty) ? 'default_user' : userId;
  }

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    await _init();
    final userId = await _getCurrentUserId();
    final raw = _prefs!.getString('$_storagePrefix$userId');
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map(
            (item) => RecurringTransactionModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecurringTransactions(
    List<RecurringTransactionModel> items,
  ) async {
    await _init();
    final userId = await _getCurrentUserId();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs!.setString('$_storagePrefix$userId', raw);
  }

  Future<void> addRecurring(RecurringTransactionModel model) async {
    final items = await getRecurringTransactions();
    items.add(model);
    await saveRecurringTransactions(items);
  }

  Future<void> deleteRecurring(String id) async {
    final items = await getRecurringTransactions();
    items.removeWhere((item) => item.id == id);
    await saveRecurringTransactions(items);
  }


  Future<int> processRecurring() async {
    final items = await getRecurringTransactions();
    final now = DateTime.now();
    int processedCount = 0;
    List<RecurringTransactionModel> updatedItems = [];

    for (var item in items) {
      if (!item.isActive) {
        updatedItems.add(item);
        continue;
      }

      var lastProcessed = item.lastProcessedDate;
      var currentItem = item;
      bool changed = false;

      while (true) {
        DateTime nextDate;
        switch (currentItem.frequency) {
          case RecurringFrequency.daily:
            nextDate = lastProcessed.add(const Duration(days: 1));
            break;
          case RecurringFrequency.weekly:
            nextDate = lastProcessed.add(const Duration(days: 7));
            break;
          case RecurringFrequency.monthly:

            nextDate = DateTime(
              lastProcessed.year,
              lastProcessed.month + 1,
              lastProcessed.day,
            );

            if (nextDate.month == (lastProcessed.month + 2) % 12) {
              nextDate = DateTime(
                lastProcessed.year,
                lastProcessed.month + 1,
                0,
              );
            }
            break;
        }


        if (nextDate.isBefore(now) ||
            (nextDate.year == now.year &&
                nextDate.month == now.month &&
                nextDate.day == now.day)) {

          final tx = TransactionModel(
            id: 'auto_${currentItem.id}_${nextDate.millisecondsSinceEpoch}',
            title: currentItem.title,
            description: 'Otomatis (Rutin)',
            amount: currentItem.amount,
            type: currentItem.type,
            date: nextDate,
            category: currentItem.category,
          );

          await _transactionService.addTransaction(tx);
          lastProcessed = nextDate;
          changed = true;
          processedCount++;
        } else {
          break;
        }
      }

      if (changed) {
        updatedItems.add(
          currentItem.copyWith(lastProcessedDate: lastProcessed),
        );
      } else {
        updatedItems.add(currentItem);
      }
    }

    if (processedCount > 0) {
      await saveRecurringTransactions(updatedItems);
    }

    return processedCount;
  }
}
