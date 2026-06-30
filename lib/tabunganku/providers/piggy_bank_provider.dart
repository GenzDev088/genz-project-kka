import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final piggyBankProvider = StateNotifierProvider<PiggyBankNotifier, double>((
  ref,
) {
  return PiggyBankNotifier();
});

class PiggyBankNotifier extends StateNotifier<double> {
  PiggyBankNotifier() : super(0.0) {
    _loadBalance();
  }

  static const _key = 'piggy_bank_balance';

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 0.0;
  }

  Future<void> addAmount(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    state += amount;
    await prefs.setDouble(_key, state);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    state = 0.0;
    await prefs.setDouble(_key, state);
  }
}

final piggyBankHistoryProvider =
    StateNotifierProvider<PiggyBankHistoryNotifier, List<PiggyBankLog>>((ref) {
      return PiggyBankHistoryNotifier();
    });

class PiggyBankLog {
  final DateTime date;
  final double amount;

  PiggyBankLog({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory PiggyBankLog.fromJson(Map<String, dynamic> json) =>
      PiggyBankLog(date: DateTime.parse(json['date']), amount: json['amount']);
}

class PiggyBankHistoryNotifier extends StateNotifier<List<PiggyBankLog>> {
  PiggyBankHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const _key = 'piggy_bank_history';

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];


  }

  Future<void> addLog(double amount) async {
    final log = PiggyBankLog(date: DateTime.now(), amount: amount);
    state = [log, ...state];

  }
}
