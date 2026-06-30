import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/providers/piggy_bank_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';

class PiggyBankPage extends ConsumerStatefulWidget {
  const PiggyBankPage({super.key});

  @override
  ConsumerState<PiggyBankPage> createState() => _PiggyBankPageState();
}

class _PiggyBankPageState extends ConsumerState<PiggyBankPage> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _submitAmount() {
    if (_formKey.currentState?.validate() ?? false) {
      final rawValue = _amountController.text.replaceAll('.', '');
      final amount = double.tryParse(rawValue) ?? 0;

      if (amount > 0) {
        ref.read(piggyBankProvider.notifier).addAmount(amount);
        _amountController.clear();
        FocusScope.of(context).unfocus();
        _showSuccessSnackBar(amount);
      }
    }
  }

  void _showSuccessSnackBar(double amount) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Berhasil memasukkan ${_formatRupiah(amount)}!',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(piggyBankProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: contentColor,
            size: 18,
          ),
        ),
        title: Text(
          'Tabungan Receh',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),


              _buildCompactBalanceCard(balance, isDarkMode),

              const SizedBox(height: 32),


              Text(
                'NOMINAL MASUKKAN RECEH *',
                style: GoogleFonts.comicNeue(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white24 : Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),


              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RibuanFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white10 : Colors.black26,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.only(left: 20, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rp',
                          style: GoogleFonts.comicNeue(
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
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal tidak boleh kosong!';
                  }
                  final cleaned = val.replaceAll('.', '');
                  final amount = double.tryParse(cleaned);
                  if (amount == null || amount <= 0) {
                    return 'Nominal tidak valid.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitAmount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Simpan ke Celengan',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),


              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: balance > 0
                      ? () => _showBreakJarDialog(context, ref, balance)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.02),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: Text(
                    'Pecahkan Celengan',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBalanceCard(double balance, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDarkMode ? 0 : 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL ISI CELENGAN',
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatRupiah(balance),
              style: GoogleFonts.comicNeue(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Uang receh yang terselamatkan',
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              color: Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBreakJarDialog(
    BuildContext context,
    WidgetRef ref,
    double balance,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        title: Text(
          'Pecahkan Celengan?',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Kamu akan mengambil semua uang di celengan sebesar ${_formatRupiah(balance)}. Celengan akan kembali kosong.',
          style: GoogleFonts.comicNeue(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.comicNeue(color: Colors.grey, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () async {

              final transaction = TransactionModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Hasil Pecahkan Celengan',
                description: 'Uang terkumpul dari Tabungan Receh',
                amount: balance,
                type: TransactionType.income,
                date: DateTime.now(),
                category: 'Lainnya',
              );


              await ref.read(addTransactionProvider)(transaction);


              await ref.read(piggyBankProvider.notifier).reset();

              if (mounted) {
                Navigator.pop(context);
                _showBreakSuccess(context, balance);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Pecahkan!',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBreakSuccess(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 56),
            const SizedBox(height: 16),
            Text(
              'Selamat!',
              style: GoogleFonts.comicNeue(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu telah mengumpulkan ${_formatRupiah(amount)} dari uang receh!',
              textAlign: TextAlign.center,
              style: GoogleFonts.comicNeue(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Mantap!',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
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
