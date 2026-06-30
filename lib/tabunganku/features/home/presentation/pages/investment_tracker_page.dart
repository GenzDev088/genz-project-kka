import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/models/investment_model.dart';
import 'package:otax/tabunganku/services/investment_service.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestmentTrackerPage extends ConsumerStatefulWidget {
  const InvestmentTrackerPage({super.key});

  @override
  ConsumerState<InvestmentTrackerPage> createState() =>
      _InvestmentTrackerPageState();
}

class _InvestmentTrackerPageState extends ConsumerState<InvestmentTrackerPage> {
  final _assetNameController = TextEditingController();
  final _investedController = TextEditingController();
  final _valuationController = TextEditingController();

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final investmentsAsync = ref
        .watch(investmentServiceProvider)
        .watchInvestments();
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
          'Portofolio Investasi',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<InvestmentModel>>(
        stream: investmentsAsync,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final totalInvested = items.fold(0.0, (s, i) => s + i.totalInvested);
          final currentVal = items.fold(0.0, (s, i) => s + i.currentValuation);
          final totalPL = currentVal - totalInvested;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  totalInvested,
                  currentVal,
                  totalPL,
                  isDarkMode,
                ),
                const SizedBox(height: 32),

                _buildInlineInputForm(isDarkMode),
                const SizedBox(height: 32),

                Text(
                  'ASET INVESTASI',
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: contentColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _buildEmptyState(isDarkMode)
                else
                  ...items.map((i) => _buildInvestmentItem(i, isDarkMode)),
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
          _buildHighVisInput(
            controller: _assetNameController,
            icon: Icons.category_rounded,
            label: 'Nama Aset',
            unit: '',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            hint: 'Masukkan Nama Aset',
          ),
          const SizedBox(height: 12),
          _buildHighVisInput(
            controller: _investedController,
            icon: Icons.account_balance_rounded,
            label: 'Modal',
            unit: 'Rp',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            isPremium: true,
          ),
          const SizedBox(height: 12),
          _buildHighVisInput(
            controller: _valuationController,
            icon: Icons.show_chart_rounded,
            label: 'Valuasi',
            unit: 'Rp',
            color: Colors.green,
            isDarkMode: isDarkMode,
            isPremium: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final invested =
                    double.tryParse(
                      _investedController.text.replaceAll('.', ''),
                    ) ??
                    0;
                final valuation =
                    double.tryParse(
                      _valuationController.text.replaceAll('.', ''),
                    ) ??
                    invested;
                if (_assetNameController.text.isNotEmpty && invested > 0) {
                  final item = InvestmentModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    assetName: _assetNameController.text,
                    totalInvested: invested,
                    currentValuation: valuation,
                    lastUpdated: DateTime.now(),
                  );
                  await ref.read(investmentServiceProvider).addInvestment(item);
                  _assetNameController.clear();
                  _investedController.clear();
                  _valuationController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Portofolio Berhasil Disimpan',
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Simpan Portofolio',
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
    );
  }

  Widget _buildHighVisInput({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String unit,
    required Color color,
    required bool isDarkMode,
    bool isPremium = false,
    String? hint,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return TextFormField(
      controller: controller,
      keyboardType: isPremium ? TextInputType.number : TextInputType.text,
      inputFormatters: isPremium ? [_RibuanFormatter()] : null,
      style: GoogleFonts.comicNeue(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: contentColor,
      ),
      decoration: InputDecoration(
        hintText: hint ?? '0',
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
              if (unit.isNotEmpty) ...[
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

  Widget _buildAddButton(bool isDarkMode) {
    return InkWell(
      onTap: () => _showAddInvestmentSheet(isDarkMode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Aset',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    double invested,
    double current,
    double pl,
    bool isDarkMode,
  ) {
    final isProfit = pl >= 0;
    final hexBg = isDarkMode ? AppColors.surfaceDark : Colors.white;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hexBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ESTIMASI NILAI ASET',
            style: GoogleFonts.comicNeue(
              color: contentColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatRupiah(current),
              style: GoogleFonts.comicNeue(
                color: current > 0
                    ? AppColors.primary
                    : contentColor.withValues(alpha: 0.1),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildMiniStat('Modal', invested, isDarkMode),
              Container(
                width: 1,
                height: 24,
                color: contentColor.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildMiniStat(
                'Profit/Loss',
                pl,
                isDarkMode,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    double val,
    bool isDarkMode, {
    Color? color,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 9,
              color: contentColor.withValues(alpha: 0.4),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatRupiah(val),
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color ?? contentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentItem(InvestmentModel item, bool isDarkMode) {
    final isProfit = item.profitLoss >= 0;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.assetName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: contentColor,
                  ),
                ),
              ),
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
                    _showEditInvestmentSheet(item, isDarkMode);
                  if (value == 'delete') {
                    ref
                        .read(investmentServiceProvider)
                        .deleteInvestment(item.id);
                  }
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
                          'Update Valuasi',
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactSubStat(
                'Modal',
                _formatRupiah(item.totalInvested),
                isDarkMode,
              ),
              _buildCompactSubStat(
                'Valuasi',
                _formatRupiah(item.currentValuation),
                isDarkMode,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PROFIT/LOSS',
                    style: GoogleFonts.comicNeue(
                      fontSize: 9,
                      color: isDarkMode ? Colors.white24 : Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isProfit ? Colors.green : Colors.red).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProfit
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isProfit ? Colors.green : Colors.red,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isProfit ? '+' : ''}${item.profitLossPercentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.comicNeue(
                            color: isProfit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSubStat(String label, String value, bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.comicNeue(
            fontSize: 9,
            color: isDarkMode ? Colors.white24 : Colors.black38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: contentColor,
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
              Icons.query_stats_rounded,
              size: 64,
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada portofolio investasi.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInvestmentSheet(bool isDarkMode) {
    final nameController = TextEditingController();
    final investedController = TextEditingController();
    final valuationController = TextEditingController();
    final modalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'TAMBAH ASET INVESTASI',
                style: GoogleFonts.comicNeue(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.teal.shade900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCompactInput(
              'Nama Aset / Instrumen',
              nameController,
              Icons.category_rounded,
              isDarkMode,
              isPremium: false,
            ),
            const SizedBox(height: 12),
            _buildCompactInput(
              'Total Modal Investasi',
              modalController,
              Icons.account_balance_wallet_rounded,
              isDarkMode,
              isPremium: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final amount =
                      double.tryParse(
                        modalController.text.replaceAll('.', ''),
                      ) ??
                      0;
                  if (nameController.text.isNotEmpty && amount > 0) {
                    final investment = InvestmentModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      assetName: nameController.text,
                      totalInvested: amount,
                      currentValuation: amount,
                      lastUpdated: DateTime.now(),
                    );
                    await ref
                        .read(investmentServiceProvider)
                        .addInvestment(investment);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Simpan Portofolio',
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
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditInvestmentSheet(InvestmentModel item, bool isDarkMode) {
    final valuationController = TextEditingController(
      text: item.currentValuation.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'UPDATE VALUASI',
                style: GoogleFonts.comicNeue(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.teal.shade900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                item.assetName,
                style: GoogleFonts.comicNeue(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCompactInput(
              'Nilai Valuasi Terbaru',
              valuationController,
              Icons.update_rounded,
              isDarkMode,
              isPremium: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(investmentServiceProvider)
                          .deleteInvestment(item.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newValuation =
                          double.tryParse(
                            valuationController.text.replaceAll('.', ''),
                          ) ??
                          0;
                      final updatedItem = item.copyWith(
                        currentValuation: newValuation,
                        lastUpdated: DateTime.now(),
                      );
                      await ref
                          .read(investmentServiceProvider)
                          .updateInvestment(updatedItem);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.update_rounded, size: 18),
                    label: Text(
                      'Update Nilai',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

  Widget _buildCompactInput(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDarkMode, {
    required bool isPremium,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
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
          keyboardType: isPremium ? TextInputType.number : TextInputType.text,
          inputFormatters: isPremium ? [_RibuanFormatter()] : null,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: contentColor,
          ),
          decoration: InputDecoration(
            hintText: isPremium ? '0' : 'Masukkan nama aset...',
            hintStyle: GoogleFonts.comicNeue(
              fontSize: 15,
              color: isDarkMode ? Colors.white10 : Colors.teal.shade50,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.primary, size: 18),
                  if (isPremium) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Rp',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
              vertical: 12,
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
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
