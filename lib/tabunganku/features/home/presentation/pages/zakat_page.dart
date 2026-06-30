import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';

class ZakatPage extends ConsumerStatefulWidget {
  const ZakatPage({super.key});

  @override
  ConsumerState<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends ConsumerState<ZakatPage>
    with TickerProviderStateMixin {
  String _activeType = 'Profesi'; // Profesi, Maal, Fitrah

  final TextEditingController _profesiController = TextEditingController();
  final TextEditingController _maalController = TextEditingController();
  final TextEditingController _fitrahController = TextEditingController();
  final TextEditingController _infaqController = TextEditingController();

  double _profesiAmount = 0;
  double _maalAmount = 0;
  double _fitrahAmount = 0;
  double _infaqAmount = 0;

  final double _hargaEmasPerGram = 1200000;
  double get _nishabMaal => 85 * _hargaEmasPerGram;

  @override
  void dispose() {
    _profesiController.dispose();
    _maalController.dispose();
    _fitrahController.dispose();
    _infaqController.dispose();
    super.dispose();
  }

  void _calculateProfesi() {
    final text = _profesiController.text.replaceAll('.', '');
    final amount = double.tryParse(text) ?? 0;
    setState(() {
      _profesiAmount = amount * 0.025;
    });
  }

  void _calculateMaal() {
    final text = _maalController.text.replaceAll('.', '');
    final amount = double.tryParse(text) ?? 0;
    setState(() {
      _maalAmount = (amount >= _nishabMaal) ? amount * 0.025 : 0;
    });
  }

  void _recordTransaction(String title, double amount, String category) async {
    if (amount <= 0) return;
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: 'Pembayaran $title melaui Zakat Calculator',
      amount: amount,
      type: TransactionType.expense,
      date: DateTime.now(),
      category: category,
    );
    await ref.read(transactionServiceProvider).addTransaction(transaction);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title berhasil dicatat!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
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
          'Zakat & Infaq',
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

            Text(
              'TIPE ZAKAT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: contentColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCompactTypeCard(
                  'Profesi',
                  'Profesi',
                  Icons.payments_rounded,
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildCompactTypeCard(
                  'Maal',
                  'Harta/Maal',
                  Icons.account_balance_wallet_rounded,
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildCompactTypeCard(
                  'Fitrah',
                  'Fitrah/Infaq',
                  Icons.favorite_rounded,
                  isDarkMode,
                ),
              ],
            ),

            const SizedBox(height: 32),
            if (_activeType == 'Profesi') _buildProfesiContent(isDarkMode),
            if (_activeType == 'Maal') _buildMaalContent(isDarkMode),
            if (_activeType == 'Fitrah') _buildFitrahContent(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildProfesiContent(bool isDarkMode) {
    return Column(
      children: [
        _buildAlignedInput(
          'PENGHASILAN BULANAN',
          _profesiController,
          (_) => _calculateProfesi(),
          Icons.wallet_rounded,
          isDarkMode,
        ),
        const SizedBox(height: 32),
        _buildResultCard(
          'ESTIMASI ZAKAT PROFESI',
          _profesiAmount,
          () => _recordTransaction('Zakat Profesi', _profesiAmount, 'Zakat'),
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildMaalContent(bool isDarkMode) {
    final warningText = (_maalAmount == 0 && _maalController.text.isNotEmpty)
        ? 'Saldo belum mencapai nishab (~Rp ${NumberFormat.decimalPattern('id_ID').format(_nishabMaal)})'
        : null;

    return Column(
      children: [
        _buildAlignedInput(
          'TOTAL HARTA SIMPANAN',
          _maalController,
          (_) => _calculateMaal(),
          Icons.account_balance_rounded,
          isDarkMode,
        ),
        const SizedBox(height: 32),
        _buildResultCard(
          'ESTIMASI ZAKAT MAAL',
          _maalAmount,
          () => _recordTransaction('Zakat Maal', _maalAmount, 'Zakat'),
          isDarkMode,
          warningText: warningText,
        ),
      ],
    );
  }

  Widget _buildFitrahContent(bool isDarkMode) {
    return Column(
      children: [
        _buildAlignedInput(
          'ZAKAT FITRAH',
          _fitrahController,
          (v) => setState(
            () => _fitrahAmount = double.tryParse(v.replaceAll('.', '')) ?? 0,
          ),
          Icons.face_rounded,
          isDarkMode,
        ),
        const SizedBox(height: 20),
        _buildAlignedInput(
          'INFAQ / SEDEKAH',
          _infaqController,
          (v) => setState(
            () => _infaqAmount = double.tryParse(v.replaceAll('.', '')) ?? 0,
          ),
          Icons.favorite_rounded,
          isDarkMode,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'FITRAH',
                _fitrahAmount,
                () =>
                    _recordTransaction('Zakat Fitrah', _fitrahAmount, 'Zakat'),
                isDarkMode,
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                'INFAQ',
                _infaqAmount,
                () => _recordTransaction('Infaq', _infaqAmount, 'Gift'),
                isDarkMode,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactTypeCard(
    String type,
    String label,
    IconData icon,
    bool isDarkMode,
  ) {
    final isSelected = _activeType == type;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: isSelected ? Colors.white : contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlignedInput(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    IconData icon,
    bool isDarkMode,
  ) {
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
          inputFormatters: [_RibuanFormatter()],
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _activeType == 'Profesi'
                  ? 'Zakat profesi wajib dikeluarkan jika mencapai nishab setara 522kg beras.'
                  : _activeType == 'Maal'
                  ? 'Zakat harta simpanan (Maal) wajib dikeluarkan jika mencapai nishab 85g emas.'
                  : 'Sucikan harta Anda dengan zakat fitrah dan infaq/sedekah.',
              style: const TextStyle(
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

  Widget _buildResultCard(
    String title,
    double amount,
    VoidCallback onRecord,
    bool isDarkMode, {
    String? warningText,
    bool compact = false,
  }) {
    final hexBg = isDarkMode ? AppColors.surfaceDark : Colors.white;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    final hasValue = amount > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 24),
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
            title,
            style: TextStyle(
              color: contentColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(amount),
              style: GoogleFonts.comicNeue(
                fontSize: compact ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: hasValue
                    ? AppColors.primary
                    : contentColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 8),
            Text(
              warningText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: hasValue ? onRecord : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade100,
              ),
              child: const Text(
                'Catat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
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
