import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionDetailPage extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == TransactionType.expense;
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final accentColor = isExpense ? AppColors.error : AppColors.success;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => ref.read(appRouterProvider).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 20,
          ),
        ),
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF121212)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Text(
                    isExpense ? 'PENGELUARAN' : 'PEMASUKAN',
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatRupiah(transaction.amount),
                    style: GoogleFonts.comicNeue(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildDivider(isDarkMode),
                  const SizedBox(height: 32),
                  _buildReceiptRow(
                    'Waktu',
                    DateFormat(
                      'EEEE, dd MMMM yyyy • HH:mm',
                      'id_ID',
                    ).format(transaction.date),
                    isDarkMode,
                  ),
                  const SizedBox(height: 20),
                  _buildReceiptRow(
                    'Kategori',
                    transaction.category,
                    isDarkMode,
                  ),
                  const SizedBox(height: 20),
                  _buildReceiptRow('Keterangan', transaction.title, isDarkMode),
                  if (transaction.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildReceiptRow(
                      'Detail',
                      transaction.description,
                      isDarkMode,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),


            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(appRouterProvider).push('/transaction-entry', extra: transaction),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      'Edit Transaksi',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.background,
                      foregroundColor: isDarkMode
                          ? Colors.white
                          : AppColors.primary,
                      elevation: 0,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(transactionServiceProvider)
                          .deleteTransaction(transaction.id);
                      if (context.mounted) ref.read(appRouterProvider).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      'Hapus',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white24 : Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}
