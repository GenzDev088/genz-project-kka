import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/overseas_travel_model.dart';
import 'package:otax/tabunganku/providers/overseas_travel_provider.dart';
import 'package:otax/tabunganku/services/currency_service.dart';
import 'package:uuid/uuid.dart';

class OverseasTravelPage extends ConsumerStatefulWidget {
  const OverseasTravelPage({super.key});

  @override
  ConsumerState<OverseasTravelPage> createState() => _OverseasTravelPageState();
}

class _OverseasTravelPageState extends ConsumerState<OverseasTravelPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedCountry = 'US';

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'United States Dollar', 'country': 'US'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'country': 'JP'},
    {'code': 'KRW', 'name': 'South Korean Won', 'country': 'KR'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'country': 'SG'},
    {'code': 'EUR', 'name': 'Euro', 'country': 'EU'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'country': 'SA'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'country': 'MY'},
    {'code': 'THB', 'name': 'Thai Baht', 'country': 'TH'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    final goalsAsync = ref.watch(overseasTravelStreamProvider);
    final ratesAsync = ref.watch(currencyRatesProvider);

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
          'Target Luar Negeri',
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
            const SizedBox(height: 32),

            Text(
              'TARGET AKTIF',
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: contentColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),

            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return _buildEmptyState(isDarkMode);
                }
                return Column(
                  children: goals.map((goal) {
                    final rates = ratesAsync.valueOrNull ?? {};
                    final currentRate = rates[goal.currencyCode] ?? 1.0;
                    return _buildGoalResultCard(goal, currentRate, isDarkMode);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            const SizedBox(height: 40),
            Text(
              'BUAT TARGET BARU',
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: contentColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),

            _buildNewGoalForm(isDarkMode),
            const SizedBox(height: 40),
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
      child: Row(
        children: [
          const Icon(Icons.public_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rencanakan liburanmu dengan memantau kurs mata uang asing secara real-time. Tabungan ini tidak tercatat di riwayat utama.',
              style: GoogleFonts.comicNeue(
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

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada target liburan',
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white38 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalResultCard(
    OverseasTravelGoalModel goal,
    double rate,
    bool isDarkMode,
  ) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    final idrFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final foreignFormat = NumberFormat.simpleCurrency(name: goal.currencyCode);

    final targetIdr = goal.targetForeignAmount * rate;
    final progress = (goal.collectedIdrAmount / targetIdr).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _getFlag(goal.countryCode),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.destinationName.toUpperCase(),
                        style: GoogleFonts.comicNeue(
                          color: contentColor.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(goal),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              idrFormat.format(goal.collectedIdrAmount),
              style: GoogleFonts.comicNeue(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${foreignFormat.format(goal.targetForeignAmount)} (~${idrFormat.format(targetIdr)})',
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              color: contentColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: $percent%',
                style: GoogleFonts.comicNeue(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Kurs: 1 ${goal.currencyCode} = ${idrFormat.format(rate)}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 9,
                    color: contentColor.withValues(alpha: 0.3),
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showAddSavingDialog(goal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Tambah Tabungan',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewGoalForm(bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Column(
      children: [
        _buildAlignedInput(
          'NAMA TUJUAN',
          _nameController,
          null,
          Icons.map_rounded,
          isDarkMode,
          isText: true,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'VALAS',
                      style: GoogleFonts.comicNeue(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: contentColor.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        isExpanded: true,
                        dropdownColor: isDarkMode
                            ? AppColors.surfaceDark
                            : Colors.white,
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          color: contentColor,
                        ),
                        items: _currencies.map((c) {
                          return DropdownMenuItem(
                            value: c['code'],
                            child: Text(
                              '${_getFlag(c['country']!)} ${c['code']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCurrency = val!;
                            _selectedCountry = _currencies.firstWhere(
                              (c) => c['code'] == val,
                            )['country']!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildAlignedInput(
                'NOMINAL TARGET',
                _amountController,
                null,
                Icons.ads_click_rounded,
                isDarkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _createNewGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Simpan Target Baru',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlignedInput(
    String label,
    TextEditingController controller,
    Function(String)? onChanged,
    IconData icon,
    bool isDarkMode, {
    bool isText = false,
  }) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: contentColor.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: isText ? TextInputType.text : TextInputType.number,
          inputFormatters: isText ? [] : [_RibuanFormatter()],
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: isText ? 'Masukkan nama tujuan' : '0',
            hintStyle: GoogleFonts.comicNeue(
              fontSize: 14,
              color: isDarkMode ? Colors.white10 : Colors.black38,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(icon, color: AppColors.primary, size: 20),
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

  void _createNewGoal() {
    if (_nameController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      final amountText = _amountController.text.replaceAll('.', '');
      final amount = double.tryParse(amountText) ?? 0;

      final goal = OverseasTravelGoalModel(
        id: const Uuid().v4(),
        destinationName: _nameController.text,
        currencyCode: _selectedCurrency,
        targetForeignAmount: amount,
        collectedIdrAmount: 0,
        createdAt: DateTime.now(),
        countryCode: _selectedCountry,
      );

      ref.read(overseasTravelServiceProvider).addGoal(goal);

      _nameController.clear();
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Target liburan berhasil dibuat!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showAddSavingDialog(OverseasTravelGoalModel goal) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Tambah Tabungan',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: contentColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan nominal dalam Rupiah untuk tujuan ${goal.destinationName}',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: contentColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [_RibuanFormatter()],
              autofocus: true,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                color: contentColor,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.comicNeue(
                color: isDarkMode ? Colors.white38 : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.replaceAll('.', '');
              final amount = double.tryParse(text) ?? 0;
              if (amount > 0) {
                final updatedGoal = goal.copyWith(
                  collectedIdrAmount: goal.collectedIdrAmount + amount,
                );
                ref.read(overseasTravelServiceProvider).updateGoal(updatedGoal);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(OverseasTravelGoalModel goal) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Target?',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: contentColor,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus target liburan ke ${goal.destinationName}?',
          style: GoogleFonts.comicNeue(
            color: contentColor.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.comicNeue(
                color: isDarkMode ? Colors.white38 : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(overseasTravelServiceProvider).deleteGoal(goal.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFlag(String countryCode) {
    if (countryCode == 'EU') return '🇪🇺';
    return countryCode.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
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
