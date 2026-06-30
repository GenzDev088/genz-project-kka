import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/services/transaction_service.dart';
import 'package:otax/tabunganku/providers/challenge_provider.dart';
import 'package:otax/tabunganku/providers/family_group_provider.dart';


final transactionServiceProvider = Provider<TransactionService>((ref) {
  final challengeService = ref.watch(challengeServiceProvider);
  return MockTransactionService(challengeService: challengeService);
});


final addTransactionProvider = Provider((ref) {
  return (TransactionModel transaction) async {
    final transactionService = ref.read(transactionServiceProvider);
    final challengeService = ref.read(challengeServiceProvider);


    final result = await transactionService.addTransaction(transaction);


    await challengeService.checkAndUpdateChallengeFromTransaction(transaction);


    ref.invalidate(transactionsProvider);
    ref.invalidate(activeChallengesProvider);

    return result;
  };
});


final transactionsProvider = FutureProvider.autoDispose<List<TransactionModel>>(
  (ref) async {
    final service = ref.watch(transactionServiceProvider);
    return service.getTransactions();
  },
);


final transactionsStreamProvider =
    StreamProvider.autoDispose<List<TransactionModel>>((ref) {
      final service = ref.watch(transactionServiceProvider);

      final groupId = ref.watch(userGroupIdProvider);
      return service.watchTransactions(groupId);
    });


final transactionsByGroupProvider = Provider.autoDispose
    .family<List<TransactionModel>, String?>((ref, groupId) {
      final transactionsAsync = ref.watch(transactionsStreamProvider);
      return transactionsAsync.maybeWhen(
        data: (data) => data.where((t) => t.groupId == groupId).toList(),
        orElse: () => <TransactionModel>[],
      );
    });


final transactionProvider = FutureProvider.autoDispose
    .family<TransactionModel, String>((ref, id) async {
      final service = ref.watch(transactionServiceProvider);
      return service.getTransaction(id);
    });
