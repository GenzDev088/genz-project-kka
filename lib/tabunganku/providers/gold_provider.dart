import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/gold_investment_model.dart';
import 'package:otax/tabunganku/services/gold_service.dart';

final goldTransactionsStreamProvider =
    StreamProvider.autoDispose<List<GoldTransactionModel>>((ref) {
      final service = ref.watch(goldServiceProvider);
      return service.watchTransactions();
    });
