import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/widgets/transaction_tile.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _monthKey(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);


  bool _isHutangPiutang(TransactionModel t) =>
      t.category == 'Hutang' || t.category == 'Piutang';

  bool _isBelanja(TransactionModel t) => t.id.startsWith('shopping_');

  bool _isRegular(TransactionModel t) => !_isHutangPiutang(t) && !_isBelanja(t);


  Future<void> _generatePdf(List<TransactionModel> transactions) async {
    if (transactions.isEmpty) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Laporan Transaksi - $dateStr',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'TabunganKu',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Tanggal', 'Keterangan', 'Kategori', 'Tipe', 'Nominal'],
              data: transactions
                  .map(
                    (t) => [
                      DateFormat('dd/MM/yyyy').format(t.date),
                      t.title,
                      t.category,
                      t.type == TransactionType.income ? 'Masuk' : 'Keluar',
                      _formatCurrency(t.amount),
                    ],
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Pemasukan: ${_formatCurrency(transactions.where((t) => t.type == TransactionType.income).fold(0, (s, t) => s + t.amount.toInt()))}',
                    ),
                    pw.Text(
                      'Total Pengeluaran: ${_formatCurrency(transactions.where((t) => t.type == TransactionType.expense).fold(0, (s, t) => s + t.amount.toInt()))}',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Riwayat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        actions: [
          transactionsAsync.when(
            data: (t) => IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              onPressed: () => _generatePdf(t),
              tooltip: 'Unduh laporan PDF',
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDarkMode
              ? Colors.white38
              : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Pemasukan & Pengeluaran'),
            Tab(text: 'Hutang'),
            Tab(text: 'Belanja'),
          ],
        ),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {

          final sorted = [...allTransactions]
            ..sort((a, b) => b.date.compareTo(a.date));

          final regularList = sorted.where(_isRegular).toList();
          final hutangList = sorted.where(_isHutangPiutang).toList();
          final belanjaList = sorted.where(_isBelanja).toList();

          return TabBarView(
            controller: _tabController,
            children: [

              _buildRegularTab(sorted, regularList, isDarkMode),

              _buildHutangTab(hutangList, isDarkMode),

              _buildBelanjaTab(belanjaList, isDarkMode),
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




  Widget _buildRegularTab(
    List<TransactionModel> allSorted,
    List<TransactionModel> regularList,
    bool isDarkMode,
  ) {
    if (regularList.isEmpty) {
      return _buildEmptyState(
        isDarkMode,
        icon: Icons.receipt_long_outlined,
        label: 'Belum ada pemasukan atau pengeluaran',
      );
    }


    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in regularList) {
      final key = _monthKey(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }


    final Map<String, List<TransactionModel>> allGrouped = {};
    for (final t in allSorted) {
      final key = _monthKey(t.date);
      allGrouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: grouped.keys.length,
      itemBuilder: (context, i) {
        final monthKey = grouped.keys.elementAt(i);
        final monthTransactions = grouped[monthKey]!;
        final allMonthTx = allGrouped[monthKey] ?? monthTransactions;


        final totalIn = allMonthTx
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final totalOut = allMonthTx
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthKey,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (totalIn > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_downward_rounded,
                              size: 11,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatCurrency(totalIn),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      if (totalOut > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 11,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatCurrency(totalOut),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            ...monthTransactions.map((t) => TransactionTile(transaction: t)),
            Divider(
              height: 32,
              color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
            ),
          ],
        );
      },
    );
  }


  Widget _buildHutangTab(List<TransactionModel> list, bool isDarkMode) {
    if (list.isEmpty) {
      return _buildEmptyState(
        isDarkMode,
        icon: Icons.account_balance_wallet_outlined,
        label: 'Belum ada riwayat hutang/piutang',
        subtitle: 'Akan muncul saat kamu menandai hutang/piutang sebagai lunas',
      );
    }

    final hutangOnly = list.where((t) => t.category == 'Hutang').toList();
    final piutangOnly = list.where((t) => t.category == 'Piutang').toList();
    final totalHutang = hutangOnly.fold(0.0, (s, t) => s + t.amount);
    final totalPiutang = piutangOnly.fold(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [

        Container(
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
                child: _summaryItem(
                  isDarkMode,
                  label: 'HUTANG DIBAYAR',
                  amount: totalHutang,
                  icon: Icons.call_made_rounded,
                  color: Colors.red.shade400,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
              ),
              Expanded(
                child: _summaryItem(
                  isDarkMode,
                  label: 'PIUTANG DITERIMA',
                  amount: totalPiutang,
                  icon: Icons.call_received_rounded,
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (hutangOnly.isNotEmpty) ...[
          _groupHeader('HUTANG TERBAYAR', Colors.red.shade400, isDarkMode),
          const SizedBox(height: 10),
          ...hutangOnly.map((t) => _debtCard(t, isDarkMode)),
          const SizedBox(height: 20),
        ],
        if (piutangOnly.isNotEmpty) ...[
          _groupHeader('PIUTANG DITERIMA', Colors.green.shade400, isDarkMode),
          const SizedBox(height: 10),
          ...piutangOnly.map((t) => _debtCard(t, isDarkMode)),
        ],
      ],
    );
  }


  Widget _buildBelanjaTab(List<TransactionModel> list, bool isDarkMode) {
    if (list.isEmpty) {
      return _buildEmptyState(
        isDarkMode,
        icon: Icons.shopping_bag_outlined,
        label: 'Belum ada riwayat belanja',
        subtitle: 'Akan muncul saat kamu menandai item belanja sebagai dibeli',
      );
    }

    final total = list.fold(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: isDarkMode ? 0.12 : 0.06,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BELANJA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${list.length} item',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...list.map((t) => _shoppingCard(t, isDarkMode)),
      ],
    );
  }


  Widget _debtCard(TransactionModel t, bool isDarkMode) {
    final isHutang = t.category == 'Hutang';
    final color = isHutang ? Colors.red.shade400 : Colors.green.shade400;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isHutang ? Icons.call_made_rounded : Icons.call_received_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 13,
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
            _formatCurrency(t.amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shoppingCard(TransactionModel t, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 13,
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
            _formatCurrency(t.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    bool isDarkMode, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
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
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _groupHeader(String label, Color color, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDarkMode ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
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
              size: 60,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
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
}
