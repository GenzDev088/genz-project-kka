import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
  });

  Achievement copyWith({bool? isUnlocked, double? progress}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
    );
  }
}

final achievementsProvider = Provider<List<Achievement>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.maybeWhen(
    data: (allTransactions) {

      final transactions = allTransactions
          .where((t) => t.groupId == null)
          .toList();


      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final currentBalance = totalIncome - totalExpense;


      int streak = 0;
      if (transactions.isNotEmpty) {
        final sortedDates =
            transactions
                .where((t) => t.type == TransactionType.income)
                .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));

        if (sortedDates.isNotEmpty) {
          DateTime current = DateTime.now();
          current = DateTime(current.year, current.month, current.day);


          if (sortedDates.first == current ||
              sortedDates.first == current.subtract(const Duration(days: 1))) {
            streak = 1;
            for (int i = 0; i < sortedDates.length - 1; i++) {
              if (sortedDates[i].difference(sortedDates[i + 1]).inDays == 1) {
                streak++;
              } else {
                break;
              }
            }
          }
        }
      }


      return [
        Achievement(
          id: 'first_deposit',
          title: 'Top Up Pertama',
          description: 'Berhasil melakukan pengisian saldo pertama.',
          icon: Icons.account_balance_wallet_rounded,
          isUnlocked: transactions.any((t) => t.type == TransactionType.income),
          progress: transactions.any((t) => t.type == TransactionType.income)
              ? 1.0
              : 0.0,
        ),
        Achievement(
          id: 'half_million',
          title: 'Hemat Pangkal Kaya',
          description: 'Memiliki saldo aktif di atas Rp 500.000.',
          icon: Icons.savings_rounded,
          isUnlocked: currentBalance >= 500000,
          progress: (currentBalance / 500000).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'millionaire',
          title: 'Millionaire',
          description: 'Total pemasukan mencapai Rp 1.000.000.',
          icon: Icons.stars_rounded,
          isUnlocked: totalIncome >= 1000000,
          progress: (totalIncome / 1000000).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'streak_master',
          title: 'Striker',
          description: 'Menabung selama 7 hari berturut-turut.',
          icon: Icons.bolt_rounded,
          isUnlocked: streak >= 7,
          progress: (streak / 7).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'sultan_muda',
          title: 'Sultan Muda',
          description: 'Memiliki saldo aktif di atas Rp 5.000.000.',
          icon: Icons.workspace_premium_rounded,
          isUnlocked: currentBalance >= 5000000,
          progress: (currentBalance / 5000000).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'disiplin_tinggi',
          title: 'Pahlawan Streak',
          description: 'Menabung selama 30 hari berturut-turut.',
          icon: Icons.local_fire_department_rounded,
          isUnlocked: streak >= 30,
          progress: (streak / 30).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'penabung_aktif',
          title: 'Penabung Konsisten',
          description: 'Melakukan lebih dari 20 kali pengisian saldo.',
          icon: Icons.assignment_turned_in_rounded,
          isUnlocked:
              transactions
                  .where((t) => t.type == TransactionType.income)
                  .length >=
              20,
          progress:
              (transactions
                          .where((t) => t.type == TransactionType.income)
                          .length /
                      20)
                  .clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'mulai_bijak',
          title: 'Mulai Bijak',
          description: 'Melakukan total 10 transaksi (pemasukan/pengeluaran).',
          icon: Icons.auto_awesome_rounded,
          isUnlocked: transactions.length >= 10,
          progress: (transactions.length / 10).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'level_pro',
          title: 'Level Pro',
          description: 'Total pemasukan mencapai Rp 10.000.000.',
          icon: Icons.military_tech_rounded,
          isUnlocked: totalIncome >= 10000000,
          progress: (totalIncome / 10000000).clamp(0.0, 1.0),
        ),
        Achievement(
          id: 'hemat_terus',
          title: 'Hemat Terus',
          description: 'Memiliki saldo aktif di atas Rp 2.500.000.',
          icon: Icons.account_balance_rounded,
          isUnlocked: currentBalance >= 2500000,
          progress: (currentBalance / 2500000).clamp(0.0, 1.0),
        ),
      ];
    },
    orElse: () => [],
  );
});
