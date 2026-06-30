import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/models/gold_investment_model.dart';
import 'package:otax/tabunganku/services/gold_service.dart';
import 'package:google_fonts/google_fonts.dart';

class GoldSavingsPage extends ConsumerStatefulWidget {
  const GoldSavingsPage({super.key});

  @override
  ConsumerState<GoldSavingsPage> createState() => _GoldSavingsPageState();
}

class _GoldSavingsPageState extends ConsumerState<GoldSavingsPage> {
  final _amountController = TextEditingController();
  GoldTransactionType _selectedType = GoldTransactionType.buy;


  double buyPrice = 1250000;
  double sellPrice = 1185000;
  double priceChange = 1.25;

  double get currentGoldPrice =>
      _selectedType == GoldTransactionType.sell ? sellPrice : buyPrice;

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref
        .watch(goldServiceProvider)
        .watchTransactions();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: contentColor,
            size: 20,
          ),
        ),
        title: Text(
          'Tabungan Emas',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GoldTransactionModel>>(
        stream: transactionsAsync,
        builder: (context, snapshot) {
          final txs = snapshot.data ?? [];
          final totalGrams = ref
              .read(goldServiceProvider)
              .calculateTotalGrams(txs);
          final avgPrice = ref
              .read(goldServiceProvider)
              .calculateAveragePrice(txs);
          final currentValue = totalGrams * currentGoldPrice;
          final totalInvestment = totalGrams * avgPrice;
          final profitLoss = currentValue - totalInvestment;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPortfolioCard(
                  totalGrams,
                  currentValue,
                  profitLoss,
                  isDarkMode,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'HARGA EMAS HARI INI',
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: contentColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRealtimePriceCard(isDarkMode),
                const SizedBox(height: 32),
                _buildInlineInputForm(isDarkMode),
                const SizedBox(height: 32),
                Text(
                  'HISTORY TRANSAKSI',
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: contentColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                if (txs.isEmpty)
                  _buildEmptyState(isDarkMode)
                else
                  ...txs.reversed.map(
                    (tx) => _buildTransactionItem(tx, isDarkMode),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInlineInputForm(bool isDarkMode) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCompactTypeToggle(
                GoldTransactionType.buy,
                'Beli',
                Icons.add_shopping_cart_rounded,
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildCompactTypeToggle(
                GoldTransactionType.sell,
                'Jual',
                Icons.sell_rounded,
                isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              _buildHighVisInput(
                controller: _amountController,
                icon: Icons.payments_rounded,
                label: 'Nominal Transaksi',
                unit: 'Rp',
                color: _selectedType == GoldTransactionType.buy
                    ? Colors.green
                    : Colors.red,
                isDarkMode: isDarkMode,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountController,
                builder: (context, value, child) {
                  final amount =
                      double.tryParse(value.text.replaceAll('.', '')) ?? 0;
                  final estGrams = amount / currentGoldPrice;
                  final accentColor = _selectedType == GoldTransactionType.buy
                      ? Colors.green
                      : Colors.red;
                  if (amount <= 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.scale_rounded, size: 14, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Estimasi Emas: ${estGrams.toStringAsFixed(4)} gram',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : accentColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(
                          _amountController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (amount > 0) {
                      final grams = amount / currentGoldPrice;
                      final tx = GoldTransactionModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        grams: grams,
                        pricePerGram: currentGoldPrice,
                        date: DateTime.now(),
                        type: _selectedType,
                      );
                      await ref.read(goldServiceProvider).addTransaction(tx);
                      _amountController.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Transaksi Berhasil Disimpan',
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.amber,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'Simpan Transaksi',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTypeToggle(
    GoldTransactionType type,
    String label,
    IconData icon,
    bool isDarkMode,
  ) {
    final isSelected = _selectedType == type;
    final accentColor = type == GoldTransactionType.buy
        ? Colors.green
        : Colors.red;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDarkMode ? Colors.white10 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? accentColor : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? accentColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighVisInput({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String unit,
    required Color color,
    required bool isDarkMode,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_RibuanFormatter()],
      style: GoogleFonts.comicNeue(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: contentColor,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: GoogleFonts.comicNeue(
          fontSize: 16,
          color: isDarkMode ? Colors.white10 : Colors.black38,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                unit,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(
    double grams,
    double value,
    double pl,
    bool isDarkMode,
  ) {
    final isProfit = pl >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDAA520).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL SALDO EMAS',
            style: GoogleFonts.comicNeue(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${grams.toStringAsFixed(3)} g',
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatRupiah(value),
            style: GoogleFonts.comicNeue(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfit
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isProfit ? 'Profit' : 'Loss'}: ${_formatRupiah(pl.abs())}',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimePriceCard(bool isDarkMode) {
    final priceAsync = ref.watch(goldPriceProvider);
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return priceAsync.when(
      data: (prices) {

        buyPrice = prices['buy'] ?? buyPrice;
        sellPrice = prices['sell'] ?? sellPrice;
        priceChange = prices['change'] ?? priceChange;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: isDarkMode
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HARGA EMAS TERKINI',
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: contentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${priceChange > 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                      style: GoogleFonts.comicNeue(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceInfo(
                      'HARGA BELI',
                      buyPrice,
                      Colors.green,
                      isDarkMode,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  ),
                  Expanded(
                    child: _buildPriceInfo(
                      'HARGA JUAL',
                      sellPrice,
                      Colors.red,
                      isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildPriceLoading(isDarkMode),
      error: (_, __) => _buildPriceLoading(isDarkMode),
    );
  }

  Widget _buildPriceInfo(
    String label,
    double price,
    Color color,
    bool isDarkMode,
  ) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: contentColor.withValues(alpha: 0.3),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatRupiah(price),
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceLoading(bool isDarkMode) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  void _deleteGoldTransaction(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Transaksi?',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Data transaksi emas ini akan dihapus secara permanen.',
          style: GoogleFonts.comicNeue(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.comicNeue(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.comicNeue(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(goldServiceProvider).deleteTransaction(id);
    }
  }

  void _showEditGoldTransactionSheet(GoldTransactionModel tx, bool isDarkMode) {
    final initialAmount = (tx.grams * tx.pricePerGram).toInt();
    final amountController = TextEditingController(
      text: NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      ).format(initialAmount).trim(),
    );
    GoldTransactionType type = tx.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'UBAH TRANSAKSI EMAS',
                  style: GoogleFonts.comicNeue(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.teal.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      GoldTransactionType.buy,
                      'Beli',
                      Icons.add_circle_outline_rounded,
                      type,
                      (v) => setSheetState(() => type = v),
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      GoldTransactionType.sell,
                      'Jual',
                      Icons.remove_circle_outline_rounded,
                      type,
                      (v) => setSheetState(() => type = v),
                      isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCompactInput(
                'Nominal Transaksi (Rp)',
                amountController,
                Icons.payments_rounded,
                isDarkMode,
                'Rp',
                color: type == GoldTransactionType.buy
                    ? Colors.green
                    : Colors.red,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: amountController,
                builder: (context, value, child) {
                  final amount =
                      double.tryParse(value.text.replaceAll('.', '')) ?? 0;
                  final estGrams = amount / currentGoldPrice;
                  if (amount <= 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'Estimasi: ${estGrams.toStringAsFixed(4)} gram',
                        style: GoogleFonts.comicNeue(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white38
                              : Colors.teal.shade900.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(
                          amountController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (amount > 0) {
                      final grams = amount / currentGoldPrice;
                      final updatedTx = tx.copyWith(grams: grams, type: type);
                      await ref
                          .read(goldServiceProvider)
                          .updateTransaction(updatedTx);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == GoldTransactionType.buy
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan Perubahan',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(GoldTransactionModel tx, bool isDarkMode) {
    final isBuy = tx.type == GoldTransactionType.buy;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isBuy ? Colors.amber : Colors.orange).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isBuy ? Icons.add_shopping_cart_rounded : Icons.sell_rounded,
              color: isBuy ? Colors.amber : Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBuy ? 'Beli Emas' : 'Jual Emas',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: contentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isBuy ? '+' : '-'}${tx.grams.toStringAsFixed(3)} g',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isBuy ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRupiah(tx.grams * tx.pricePerGram),
                  style: GoogleFonts.comicNeue(
                    color: contentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(tx.date),
                  style: GoogleFonts.comicNeue(
                    color: isDarkMode ? Colors.white24 : Colors.black38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: contentColor.withValues(alpha: 0.3),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'edit')
                _showEditGoldTransactionSheet(tx, isDarkMode);
              if (value == 'delete') _deleteGoldTransaction(tx.id);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hapus',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSubStat(
    String label,
    String value,
    bool isDarkMode, {
    Color? color,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.comicNeue(
            fontSize: 8,
            color: isDarkMode ? Colors.white24 : Colors.black38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: color ?? contentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada riwayat transaksi.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    GoldTransactionType value,
    String label,
    IconData icon,
    GoldTransactionType selected,
    Function(GoldTransactionType) onTap,
    bool isDarkMode,
  ) {
    final isSelected = value == selected;
    final accentColor = value == GoldTransactionType.buy
        ? Colors.green
        : Colors.red;
    return InkWell(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.background),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInput(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDarkMode,
    String unit, {
    Color? color,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    final accentColor = color ?? AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white24 : Colors.black38,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [_RibuanFormatter()],
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: contentColor,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: GoogleFonts.comicNeue(
              fontSize: 15,
              color: isDarkMode ? Colors.white10 : Colors.teal.shade50,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    unit,
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final intValue = int.tryParse(newValue.text.replaceAll('.', ''));
    if (intValue == null) return oldValue;
    final newText = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(intValue).trim();
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
