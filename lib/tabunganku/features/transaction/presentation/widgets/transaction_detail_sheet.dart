import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';

class TransactionDetailSheet extends ConsumerWidget {
  final TransactionModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    TransactionModel transaction, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TransactionDetailSheet(
        transaction: transaction,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == TransactionType.expense;
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    String formatRupiah(double amount) {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),


          Text(
            isExpense ? 'PENGELUARAN' : 'PEMASUKAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: isExpense
                  ? (isDarkMode ? Colors.redAccent.shade100 : Colors.red)
                  : (isDarkMode ? Colors.greenAccent.shade400 : Colors.green),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatRupiah(transaction.amount),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.teal.shade900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),


          Row(
            children: List.generate(
              30,
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
          ),
          const SizedBox(height: 32),


          _buildReceiptRow(
            context,
            ref,
            'ID Transaksi',
            '#${transaction.id.toUpperCase().substring(0, 10)}',
          ),
          const SizedBox(height: 16),
          _buildReceiptRow(
            context,
            ref,
            'Waktu',
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(transaction.date),
          ),
          const SizedBox(height: 16),
          _buildReceiptRow(
            context,
            ref,
            'Jam',
            DateFormat('HH:mm:ss', 'id_ID').format(transaction.date),
          ),
          const SizedBox(height: 16),
          _buildReceiptRow(context, ref, 'Kategori', transaction.category),
          const SizedBox(height: 16),
          _buildReceiptRow(context, ref, 'Keterangan', transaction.title),
          const SizedBox(height: 48),


          if (onEdit != null || onDelete != null)
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit?.call();
                      },
                      icon: const Icon(Icons.edit_document, size: 18),
                      label: const Text('Edit Nominal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                            : Colors.blue.shade50,
                        foregroundColor: isDarkMode
                            ? Colors.blue.shade200
                            : Colors.blue.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 12),
                if (onDelete != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.red.shade900.withValues(alpha: 0.3)
                            : Colors.red.shade50,
                        foregroundColor: isDarkMode
                            ? Colors.red.shade200
                            : Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value, {
    String? subValue,
  }) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white38 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 4),
                Text(
                  subValue,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
