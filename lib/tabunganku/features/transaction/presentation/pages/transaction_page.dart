import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/widgets/transaction_tile.dart';
import 'package:otax/tabunganku/features/transaction/presentation/widgets/transaction_detail_sheet.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  String _filter = 'semua'; // semua, income, expense, Hutang, Piutang

  @override
  void initState() {
    super.initState();
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Riwayat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 20,
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {

          final income = allTransactions
              .where((t) => t.type == TransactionType.income)
              .fold<double>(0, (s, t) => s + t.amount);
          final expense = allTransactions
              .where((t) => t.type == TransactionType.expense)
              .fold<double>(0, (s, t) => s + t.amount);


          final filteredList = allTransactions.where((t) {
            if (_filter == 'income')
              return t.type == TransactionType.income &&
                  t.category != 'Piutang';
            if (_filter == 'expense')
              return t.type == TransactionType.expense &&
                  t.category != 'Hutang' &&
                  !t.id.startsWith('shopping_');
            if (_filter == 'Hutang') return t.category == 'Hutang';
            if (_filter == 'Piutang') return t.category == 'Piutang';
            return true;
          }).toList();

          return Column(
            children: [
              _buildSummaryBar(isDarkMode, income: income, expense: expense),


              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Semua',
                      'semua',
                      _filter,
                      Icons.receipt_long_rounded,
                      (val) => setState(() => _filter = val),
                      isDarkMode,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Pemasukan',
                      'income',
                      _filter,
                      Icons.arrow_downward_rounded,
                      (val) => setState(() => _filter = val),
                      isDarkMode,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Pengeluaran',
                      'expense',
                      _filter,
                      Icons.arrow_upward_rounded,
                      (val) => setState(() => _filter = val),
                      isDarkMode,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Hutang',
                      'Hutang',
                      _filter,
                      Icons.call_made_rounded,
                      (val) => setState(() => _filter = val),
                      isDarkMode,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Piutang',
                      'Piutang',
                      _filter,
                      Icons.call_received_rounded,
                      (val) => setState(() => _filter = val),
                      isDarkMode,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState(
                        isDarkMode,
                        icon: Icons.filter_list_off_rounded,
                        label: 'Tidak ada data yang cocok',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final t = filteredList[index];
                          if (t.category == 'Hutang' ||
                              t.category == 'Piutang') {
                            return _buildDebtTile(context, ref, t, isDarkMode);
                          }
                          if (t.id.startsWith('shopping_')) {
                            return _buildShoppingTile(
                              context,
                              ref,
                              t,
                              isDarkMode,
                            );
                          }
                          return InkWell(
                            onTap: () => TransactionDetailSheet.show(
                              context,
                              ref,
                              t,
                              onEdit: () {},
                              onDelete: () => _deleteTransaction(
                                context,
                                ref,
                                t,
                                isDarkMode,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: TransactionTile(transaction: t),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }




  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    IconData icon,
    Function(String) onSelected,
    bool isDarkMode,
  ) {
    final isSelected = currentValue == value;
    const activeColor = Color(0xFF00BFA5); // Teal from image

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(30), // Stadium shape
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? activeColor
                  : (isDarkMode ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDarkMode ? Colors.white : activeColor)
                    : (isDarkMode ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(
    bool isDarkMode, {
    required double income,
    required double expense,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSumItem(
              isDarkMode,
              label: 'PEMASUKAN',
              amount: income,
              color: Colors.green.shade400,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
          ),
          Expanded(
            child: _buildSumItem(
              isDarkMode,
              label: 'PENGELUARAN',
              amount: expense,
              color: Colors.red.shade400,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSumItem(
    bool isDarkMode, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDarkMode ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatRupiah(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtTile(
    BuildContext context,
    WidgetRef ref,
    TransactionModel t,
    bool isDarkMode,
  ) {
    final isHutang = t.category == 'Hutang';
    final color = isHutang ? Colors.red.shade400 : Colors.green.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isHutang ? Icons.call_made_rounded : Icons.call_received_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (t.description.isNotEmpty)
                  Text(
                    t.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatRupiah(t.amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingTile(
    BuildContext context,
    WidgetRef ref,
    TransactionModel t,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (t.description.isNotEmpty)
                  Text(
                    t.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatRupiah(t.amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDarkMode, {
    required IconData icon,
    required String label,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionModel t,
    bool isDarkMode,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Hapus Riwayat?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Hapus "${t.title}"?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(transactionServiceProvider).deleteTransaction(t.id);
    }
  }
}
