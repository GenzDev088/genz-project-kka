import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/debt_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/debt_provider.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/features/transaction/presentation/widgets/debt_form_sheet.dart';

class DebtListPage extends ConsumerStatefulWidget {
  const DebtListPage({super.key});

  @override
  ConsumerState<DebtListPage> createState() => _DebtListPageState();
}

class _DebtListPageState extends ConsumerState<DebtListPage> {
  String _filter = 'Hutang'; // Hutang, Piutang

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
    final debtsAsync = ref.watch(debtsStreamProvider);
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Catatan Pinjaman',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 20,
          ),
        ),
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
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
            child: debtsAsync.when(
              data: (debts) {
                final filteredDebts = debts.where((d) {
                  if (_filter == 'Hutang') return d.type == DebtType.hutang;
                  return d.type == DebtType.piutang;
                }).toList();

                if (filteredDebts.isEmpty) {
                  return _buildEmptyState(context, isDarkMode);
                }

                final unpaidDebts = filteredDebts
                    .where((d) => !d.isPaid)
                    .toList();
                final paidDebts = filteredDebts.where((d) => d.isPaid).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  children: [
                    if (unpaidDebts.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Belum Lunas',
                        AppColors.primary,
                        isDarkMode,
                      ),
                      const SizedBox(height: 8),
                      ...unpaidDebts.map(
                        (d) => _buildDebtTile(context, ref, d, isDarkMode),
                      ),
                    ],
                    if (paidDebts.isNotEmpty) ...[
                      if (unpaidDebts.isNotEmpty) const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Sudah Lunas',
                        AppColors.primary,
                        isDarkMode,
                      ),
                      const SizedBox(height: 8),
                      ...paidDebts.map(
                        (d) => _buildDebtTile(context, ref, d, isDarkMode),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          DebtFormSheet.show(
            context,
            initialType: _filter == 'Piutang'
                ? DebtType.piutang
                : DebtType.hutang,
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Catatan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
    const activeColor = Color(0xFF00BFA5);

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
          borderRadius: BorderRadius.circular(30),
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

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: isDarkMode ? 0.05 : 0.05,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada catatan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white60 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Catat semua hutang & piutangmu\nagar keuangan lebih teratur!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white54 : Colors.black38,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtTile(
    BuildContext context,
    WidgetRef ref,
    DebtModel debt,
    bool isDarkMode,
  ) {
    final isHutang = debt.type == DebtType.hutang;
    final color = isHutang ? const Color(0xFFE53935) : AppColors.primary;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showOptions(context, ref, debt, isDarkMode),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isHutang
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.contactName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          decoration: debt.isPaid
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        debt.title,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      if (debt.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: 11,
                              color: isDarkMode ? Colors.white : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(debt.dueDate!),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatRupiah(debt.amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: debt.isPaid
                            ? (isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade400)
                            : color,
                      ),
                    ),
                    if (debt.isPaid)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LUNAS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    WidgetRef ref,
    DebtModel debt,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
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
            if (!debt.isPaid)
              _buildOptionTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Tandai Sudah Lunas',
                color: AppColors.primary,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  _markAsPaid(context, ref, debt);
                },
              ),
            _buildOptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Catatan',
              color: AppColors.primary,
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.pop(context);
                DebtFormSheet.show(context, debt: debt);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Hapus Catatan',
              color: const Color(0xFFE53935),
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.pop(context);
                _deleteDebt(context, ref, debt);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _markAsPaid(BuildContext context, WidgetRef ref, DebtModel debt) async {
    final updatedDebt = debt.copyWith(isPaid: true);
    await ref.read(debtServiceProvider).updateDebt(updatedDebt);


    final isHutang = debt.type == DebtType.hutang;
    final title = isHutang
        ? 'Pembayaran Hutang ke ${debt.contactName}'
        : 'Pembayaran Piutang dari ${debt.contactName}';

    final transaction = TransactionModel(
      id: 'paid_debt_${debt.id}', // Gunakan ID yang deterministik agar bisa dihapus sinkron
      title: title,
      description: debt.title.isNotEmpty
          ? debt.title
          : (isHutang ? 'Hutang' : 'Piutang'),
      amount: debt.amount,
      type: isHutang ? TransactionType.expense : TransactionType.income,
      date: DateTime.now(),
      category: isHutang ? 'Hutang' : 'Piutang',
    );
    await ref.read(transactionServiceProvider).addTransaction(transaction);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${isHutang ? 'Hutang' : 'Piutang'} lunas & tercatat di Riwayat',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteDebt(BuildContext context, WidgetRef ref, DebtModel debt) async {

    try {
      await ref
          .read(transactionServiceProvider)
          .deleteTransaction('paid_debt_${debt.id}');
    } catch (_) {}

    await ref.read(debtServiceProvider).deleteDebt(debt.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
