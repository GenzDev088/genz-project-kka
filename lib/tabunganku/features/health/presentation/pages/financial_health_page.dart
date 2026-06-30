import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/providers/debt_provider.dart';

class FinancialHealthPage extends ConsumerStatefulWidget {
  const FinancialHealthPage({super.key});

  @override
  ConsumerState<FinancialHealthPage> createState() =>
      _FinancialHealthPageState();
}

class _FinancialHealthPageState extends ConsumerState<FinancialHealthPage> {
  String _activeMetric = 'Ringkasan';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    final transactions = ref.watch(transactionsByGroupProvider(null));
    final debts = ref.watch(debtsStreamProvider).valueOrNull ?? [];


    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final lastMonthTransactions = transactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    final monthlyIncome = lastMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final monthlyExpense = lastMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalBalance = transactions.fold<double>(
      0,
      (sum, t) =>
          sum + (t.type == TransactionType.income ? t.amount : -t.amount),
    );

    final totalDebt = debts
        .where((d) => !d.isPaid)
        .fold<double>(0, (sum, d) => sum + d.amount);

    double savingRatio = monthlyIncome > 0
        ? ((monthlyIncome - monthlyExpense) / monthlyIncome).clamp(0.0, 1.0)
        : 0;
    double avgMonthlyExpense = monthlyExpense > 0 ? monthlyExpense : 1000000;
    double emergencyFundScore = (totalBalance / (avgMonthlyExpense * 3)).clamp(
      0.0,
      1.0,
    );
    double debtScore = monthlyIncome > 0
        ? (1.0 - (totalDebt / monthlyIncome / 0.6)).clamp(0.0, 1.0)
        : 1.0;

    double totalScore =
        (savingRatio * 0.4 + emergencyFundScore * 0.4 + debtScore * 0.2) * 100;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: contentColor,
            size: 20,
          ),
        ),
        title: Text(
          'Kesehatan Keuangan',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),

            Text(
              'DETAIL ANALISIS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: contentColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCompactTypeCard(
                  'Tabungan',
                  Icons.savings_rounded,
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildCompactTypeCard(
                  'Darurat',
                  Icons.health_and_safety_rounded,
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildCompactTypeCard(
                  'Utang',
                  Icons.money_off_rounded,
                  isDarkMode,
                ),
              ],
            ),

            const SizedBox(height: 32),
            if (_activeMetric == 'Tabungan')
              _buildMetricDetailCard(
                'Rasio Menabung',
                '${(savingRatio * 100).toInt()}%',
                'Target: > 20%',
                savingRatio,
                Colors.blue,
                isDarkMode,
              ),
            if (_activeMetric == 'Darurat')
              _buildMetricDetailCard(
                'Dana Darurat',
                '${(emergencyFundScore * 100).toInt()}%',
                'Target: 3x Pengeluaran',
                emergencyFundScore,
                Colors.orange,
                isDarkMode,
              ),
            if (_activeMetric == 'Utang')
              _buildMetricDetailCard(
                'Rasio Utang',
                totalDebt == 0
                    ? '0%'
                    : '${(totalDebt / (monthlyIncome > 0 ? monthlyIncome : 1) * 100).toInt()}%',
                'Target: < 30%',
                debtScore,
                Colors.red,
                isDarkMode,
              ),

            if (_activeMetric == 'Ringkasan') ...[
              _buildResultCard(totalScore, isDarkMode),
              const SizedBox(height: 24),
              _buildAdviceCard(totalScore, isDarkMode),
            ],

            if (_activeMetric != 'Ringkasan')
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _activeMetric = 'Ringkasan'),
                  child: Text(
                    'Kembali ke Ringkasan',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Skor kesehatan dihitung berdasarkan rasio menabung, dana darurat, dan beban utangmu.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTypeCard(String type, IconData icon, bool isDarkMode) {
    final isSelected = _activeMetric == type;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMetric = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: isSelected ? Colors.white : contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricDetailCard(
    String title,
    String value,
    String target,
    double progress,
    Color color,
    bool isDarkMode,
  ) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: contentColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            target,
            style: TextStyle(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(double score, bool isDarkMode) {
    final scoreColor = _getColorForRatio(score / 100);
    final status = score >= 80
        ? 'Sangat Sehat'
        : score >= 60
        ? 'Cukup Sehat'
        : 'Perlu Perhatian';
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'SKOR KESEHATAN FINANSIAL',
            style: TextStyle(
              color: contentColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: scoreColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                score.toInt().toString(),
                style: GoogleFonts.comicNeue(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: contentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: scoreColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(double score, bool isDarkMode) {
    String advice = score >= 80
        ? 'Luar biasa! Pertahankan kebiasaan baikmu.'
        : score >= 60
        ? 'Bagus! Coba kurangi pengeluaran non-esensial.'
        : 'Fokus utama kamu adalah membangun dana darurat.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        advice,
        textAlign: TextAlign.center,
        style: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Color _getColorForRatio(double ratio) {
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
