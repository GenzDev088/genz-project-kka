import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/core/services/export_service.dart';

class ExportReportPage extends ConsumerStatefulWidget {
  final List<TransactionModel> transactions;
  final String monthLabel;

  const ExportReportPage({
    super.key,
    required this.transactions,
    required this.monthLabel,
  });

  @override
  ConsumerState<ExportReportPage> createState() => _ExportReportPageState();
}

class _ExportReportPageState extends ConsumerState<ExportReportPage> {
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

    final income = widget.transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = widget.transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFC),
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
        title: Text(
          'Ekspor Laporan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Ringkasan Bulan ${widget.monthLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'PEMASUKAN',
                        income,
                        Colors.green,
                        isDarkMode,
                      ),
                      _buildDivider(isDarkMode),
                      _buildStatItem(
                        'PENGELUARAN',
                        expense,
                        Colors.red,
                        isDarkMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'SALDO AKHIR',
                    balance,
                    balance >= 0 ? AppColors.primary : Colors.red,
                    isDarkMode,
                    large: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Text(
              'Opsi Ekspor Laporan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildExportTile(
              context,
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.red,
              title: 'Simpan sebagai PDF',
              subtitle: 'Laporan rapi siap cetak atau dibagikan',
              onTap: () => _handleExport(context, asPdf: true),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildExportTile(
              context,
              icon: Icons.table_chart_rounded,
              color: Colors.green,
              title: 'Ekspor ke Excel / CSV',
              subtitle: 'Terbaik untuk olah data di spreadsheet',
              onTap: () => _handleExport(context, asPdf: false),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 60),
            Center(
              child: Text(
                'Total ${widget.transactions.length} transaksi akan diekspor.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    double amount,
    Color color,
    bool isDarkMode, {
    bool large = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatRupiah(amount),
          style: GoogleFonts.plusJakartaSans(
            fontSize: large ? 20 : 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Container(
      width: 1,
      height: 40,
      color: isDarkMode
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.shade100,
    );
  }

  Widget _buildExportTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              size: 20,
              color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  void _handleExport(BuildContext context, {required bool asPdf}) async {
    try {
      await ExportService.shareMonthlyReport(
        context: context,
        transactions: widget.transactions,
        monthLabel: widget.monthLabel,
        asPdf: asPdf,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengekspor laporan: $e')));
    }
  }
}
