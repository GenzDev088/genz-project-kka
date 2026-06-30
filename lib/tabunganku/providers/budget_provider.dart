import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/budget_model.dart';
import 'package:otax/tabunganku/services/budget_service.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  return MockBudgetService();
});

final budgetsStreamProvider = StreamProvider.autoDispose<List<BudgetModel>>((
  ref,
) {
  final service = ref.watch(budgetServiceProvider);
  return service.watchBudgets();
});

final currentMonthBudgetsProvider = Provider.autoDispose<List<BudgetModel>>((
  ref,
) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final now = DateTime.now();
  return budgetsAsync.maybeWhen(
    data: (data) =>
        data.where((b) => b.month == now.month && b.year == now.year).toList(),
    orElse: () => <BudgetModel>[],
  );
});
