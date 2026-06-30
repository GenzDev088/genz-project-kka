import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/models/shopping_item_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/shopping_item_provider.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import '../widgets/shopping_form_sheet.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingItemsAsync = ref.watch(shoppingItemsStreamProvider);
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Catatan Belanja',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: shoppingItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context, isDarkMode);
          }

          final activeItems = items.where((i) => !i.isBought).toList();
          final boughtItems = items.where((i) => i.isBought).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (activeItems.isNotEmpty) ...[
                _buildSectionHeader(
                  'Daftar Rencana',
                  AppColors.primary,
                  isDarkMode,
                ),
                const SizedBox(height: 12),
                ...activeItems.map(
                  (item) => _buildShoppingTile(context, ref, item, isDarkMode),
                ),
              ],
              if (boughtItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Sudah Dibeli',
                  AppColors.primary,
                  isDarkMode,
                ),
                const SizedBox(height: 12),
                ...boughtItems.map(
                  (item) => _buildShoppingTile(context, ref, item, isDarkMode),
                ),
              ],
              const SizedBox(height: 24),
              _buildSummaryCard(items, isDarkMode),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ShoppingFormSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Rencana',
          style: TextStyle(fontWeight: FontWeight.bold),
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
              Icons.shopping_basket_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada rencana belanja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white60 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Catat semua kebutuhan & keinginanmu\nagar pengeluaran lebih terencana!',
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
          title,
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingTile(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
    bool isDarkMode,
  ) {
    const color = AppColors.primary;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isBought
            ? (isDarkMode
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.shade50)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
        boxShadow: item.isBought
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.2 : 0.02,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showOptions(context, ref, item, isDarkMode),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: isDarkMode ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                          item.imagePath != null && item.imagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(item.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.shopping_bag_rounded,
                                      color: color,
                                      size: 20,
                                    ),
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_rounded,
                              color: color,
                              size: 20,
                            ),
                    ),
                    if (item.isBought)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.isBought
                              ? (isDarkMode ? Colors.white24 : Colors.black26)
                              : (isDarkMode ? Colors.white : Colors.black87),
                          decoration: item.isBought
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            DateFormat('dd MMM').format(item.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.white24 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatRupiah(item.estimatedPrice),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.isBought
                            ? (isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade400)
                            : color,
                      ),
                    ),
                    Text(
                      '${item.quantity.toString().replaceAll('.0', '')} ${item.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade400,
                      ),
                    ),
                    if (item.isBought)
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
                          'DIBELI',
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
    ShoppingItem item,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: item.isBought
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              label: item.isBought
                  ? 'Tandai Belum Dibeli'
                  : 'Tandai Sudah Dibeli',
              color: AppColors.primary,
              isDarkMode: isDarkMode,
              onTap: () async {
                Navigator.pop(context);
                final nowBought = !item.isBought;
                final txId = 'shopping_${item.id}';

                if (nowBought) {

                  final transaction = TransactionModel(
                    id: txId,
                    title: item.name,
                    description:
                        item.category != null && item.category!.isNotEmpty
                        ? item.category!
                        : 'Catatan Belanja',
                    amount: item.estimatedPrice,
                    type: TransactionType.expense,
                    date: DateTime.now(),
                    category: 'Belanja Bulanan',
                  );
                  await ref
                      .read(transactionServiceProvider)
                      .addTransaction(transaction);
                } else {

                  try {
                    await ref
                        .read(transactionServiceProvider)
                        .deleteTransaction(txId);
                  } catch (_) {}
                }

                final updated = item.copyWith(
                  isBought: nowBought,
                  linkedTransactionId: nowBought ? txId : null,
                );
                await ref.read(shoppingItemServiceProvider).updateItem(updated);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Rencana',
              color: AppColors.primary,
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.pop(context);
                ShoppingFormSheet.show(context, item: item);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Hapus Rencana',
              color: const Color(0xFFE53935),
              isDarkMode: isDarkMode,
              onTap: () async {
                Navigator.pop(context);

                try {
                  await ref
                      .read(transactionServiceProvider)
                      .deleteTransaction('shopping_${item.id}');
                } catch (_) {}

                await ref.read(shoppingItemServiceProvider).deleteItem(item.id);
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

  Widget _buildSummaryCard(List<ShoppingItem> items, bool isDarkMode) {
    final totalEstimated = items.fold<double>(
      0,
      (sum, item) => sum + item.estimatedPrice,
    );
    final totalBought = items
        .where((i) => i.isBought)
        .fold<double>(0, (sum, item) => sum + item.estimatedPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDarkMode ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMASI TOTAL',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white38 : Colors.black26,
                ),
              ),
              Text(
                _formatRupiah(totalEstimated),
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'DIBELI',
                style: GoogleFonts.comicNeue(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.primaryDark.withValues(alpha: 0.4),
                ),
              ),
              Text(
                _formatRupiah(totalBought),
                style: GoogleFonts.comicNeue(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
