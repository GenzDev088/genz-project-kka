import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';

class CompoundInterestPage extends ConsumerStatefulWidget {
  const CompoundInterestPage({super.key});

  @override
  ConsumerState<CompoundInterestPage> createState() =>
      _CompoundInterestPageState();
}

class _CompoundInterestPageState extends ConsumerState<CompoundInterestPage> {
  final TextEditingController _initialAmountController =
      TextEditingController();
  final TextEditingController _monthlyContributionController =
      TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();

  double _finalBalance = 0;
  double _totalContributions = 0;
  double _totalInterest = 0;

  void _calculate() {
    final double p =
        double.tryParse(
          _initialAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final double pmt =
        double.tryParse(
          _monthlyContributionController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final double r =
        (double.tryParse(_interestRateController.text) ?? 0) / 100 / 12;
    final int t = (int.tryParse(_yearsController.text) ?? 0) * 12;

    if (t <= 0) {
      setState(() {
        _finalBalance = p;
        _totalContributions = p;
        _totalInterest = 0;
      });
      return;
    }

    double balance = p;
    double totalContributed = p;
    for (int i = 1; i <= t; i++) {
      balance = balance * (1 + r) + pmt;
      totalContributed += pmt;
    }

    setState(() {
      _finalBalance = balance;
      _totalContributions = totalContributed;
      _totalInterest = max(0, balance - totalContributed);
    });
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
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

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
          'Simulasi Bunga Majemuk',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),

            _buildAlignedInput(
              'MODAL AWAL',
              _initialAmountController,
              (_) => _calculate(),
              Icons.account_balance_rounded,
              isDarkMode,
              isCurrency: true,
            ),
            const SizedBox(height: 20),

            _buildAlignedInput(
              'TABUNGAN BULANAN',
              _monthlyContributionController,
              (_) => _calculate(),
              Icons.add_circle_outline_rounded,
              isDarkMode,
              isCurrency: true,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildAlignedInput(
                    'BUNGA (%)',
                    _interestRateController,
                    (_) => _calculate(),
                    Icons.percent_rounded,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAlignedInput(
                    'DURASI (THN)',
                    _yearsController,
                    (_) => _calculate(),
                    Icons.calendar_today_rounded,
                    isDarkMode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildResultCard(isDarkMode),
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
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Simulasi ini membantu Anda memproyeksikan pertumbuhan investasi Anda seiring waktu.',
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

  Widget _buildAlignedInput(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    IconData icon,
    bool isDarkMode, {
    bool isCurrency = false,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: contentColor.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: isCurrency ? [_RibuanFormatter()] : [],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white10 : Colors.black38,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  if (isCurrency) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Rp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
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
              borderRadius: BorderRadius.circular(16),
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

  Widget _buildResultCard(bool isDarkMode) {
    final hexBg = isDarkMode ? AppColors.surfaceDark : Colors.white;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ESTIMASI SALDO AKHIR',
            style: TextStyle(
              color: contentColor.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatRupiah(_finalBalance),
              style: GoogleFonts.comicNeue(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _finalBalance > 0
                    ? AppColors.primary
                    : contentColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniBreakdown(
                'MODAL',
                _formatRupiah(_totalContributions),
                isDarkMode,
              ),
              _buildMiniBreakdown(
                'BUNGA',
                _formatRupiah(_totalInterest),
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBreakdown(String label, String value, bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: contentColor.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: contentColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
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
