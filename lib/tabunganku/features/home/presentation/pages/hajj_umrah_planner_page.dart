import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';

class HajjUmrahPlannerPage extends ConsumerStatefulWidget {
  const HajjUmrahPlannerPage({super.key});

  @override
  ConsumerState<HajjUmrahPlannerPage> createState() =>
      _HajjUmrahPlannerPageState();
}

class _HajjUmrahPlannerPageState extends ConsumerState<HajjUmrahPlannerPage> {
  String _activeType = 'Haji'; // Haji, Umrah

  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365 * 5));

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
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

    final targetsAsync = ref.watch(savingTargetsStreamProvider);

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
          'Haji & Umrah',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
      ),
      body: targetsAsync.when(
        data: (targets) {
          final filteredTargets = targets
              .where((t) => t.category == _activeType)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),

                Text(
                  'PILIH PROGRAM',
                  style: GoogleFonts.comicNeue(
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
                      'Haji',
                      'Haji',
                      Icons.mosque_rounded,
                      isDarkMode,
                    ),
                    const SizedBox(width: 12),
                    _buildCompactTypeCard(
                      'Umrah',
                      'Umrah',
                      Icons.star_rounded,
                      isDarkMode,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                _buildInputForm(isDarkMode),

                const SizedBox(height: 40),
                Text(
                  'RENCANA AKTIF',
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: contentColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredTargets.isEmpty)
                  _buildEmptyState(isDarkMode)
                else
                  ...filteredTargets.map(
                    (t) => _buildTargetItem(t, isDarkMode),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
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
        onTap: () => setState(() {
          _activeType = type;
          _nameController.clear();
          _amountController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _activeType == 'Haji'
                  ? 'Persiapkan bekal perjalanan haji Anda sedini mungkin untuk ibadah yang lebih tenang.'
                  : 'Wujudkan impian ibadah Umrah Anda dengan perencanaan keuangan yang matang.',
              style: GoogleFonts.comicNeue(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm(bool isDarkMode) {
    return Column(
      children: [
        _buildAlignedInput(
          'NAMA RENCANA',
          _nameController,
          Icons.edit_note_rounded,
          isDarkMode,
          hint: 'Masukkan nama rencana',
        ),
        const SizedBox(height: 20),
        _buildAlignedInput(
          'TARGET TABUNGAN',
          _amountController,
          Icons.account_balance_wallet_rounded,
          isDarkMode,
          isAmount: true,
          hint: '0',
        ),
        const SizedBox(height: 20),
        _buildDatePicker(isDarkMode),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _saveTarget(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Simpan Rencana',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
    IconData icon,
    bool isDarkMode, {
    bool isAmount = false,
    String? hint,
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
          keyboardType: isAmount ? TextInputType.number : TextInputType.text,
          inputFormatters: isAmount ? [_RibuanFormatter()] : null,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.comicNeue(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: isDarkMode ? Colors.white10 : Colors.black12,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  if (isAmount) ...[
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

  Widget _buildDatePicker(bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ESTIMASI KEBERANGKATAN',
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: contentColor.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate),
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: contentColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveTarget() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0 || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama dan nominal rencana.')),
      );
      return;
    }

    final target = SavingTargetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      targetAmount: amount,
      dueDate: _selectedDate,
      createdAt: DateTime.now(),
      category: _activeType,
    );

    await ref.read(savingTargetServiceProvider).addTarget(target);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rencana $_activeType Berhasil Dibuat'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _nameController.clear();
      _amountController.clear();
    }
  }

  Widget _buildTargetItem(SavingTargetModel target, bool isDarkMode) {
    final transactions = ref.watch(transactionsByGroupProvider(null));
    final targetBalance = transactions
        .where((t) => !t.date.isBefore(target.createdAt))
        .fold<double>(
          0,
          (s, t) => s + (t.type == TransactionType.income ? t.amount : 0),
        );
    final progress = (target.targetAmount > 0)
        ? (targetBalance / target.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  target.name,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: contentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          _buildMilestones(target, targetBalance, isDarkMode),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniInfo(
                'Target',
                _formatRupiah(target.targetAmount),
                isDarkMode,
              ),
              _buildMiniInfo(
                'Estimasi',
                DateFormat('MMM yyyy').format(target.dueDate),
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(
    SavingTargetModel target,
    double balance,
    bool isDarkMode,
  ) {
    final milestones = target.category == 'Haji'
        ? [
            {'label': 'Daftar (Porsi)', 'amount': 25000000.0},
            {'label': 'Pelunasan', 'amount': target.targetAmount * 0.8},
            {'label': 'Siap Berangkat', 'amount': target.targetAmount},
          ]
        : [
            {'label': 'Booking DP', 'amount': 5000000.0},
            {'label': 'Pelunasan', 'amount': target.targetAmount * 0.9},
            {'label': 'Siap Berangkat', 'amount': target.targetAmount},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MILESTONE PERJALANAN',
          style: GoogleFonts.comicNeue(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white24 : Colors.black26,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ...milestones.map((m) {
          final isReached = balance >= (m['amount'] as double);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  isReached
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 12,
                  color: isReached
                      ? AppColors.primary
                      : (isDarkMode ? Colors.white10 : Colors.grey.shade300),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m['label'] as String,
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: isReached
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isReached
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatRupiah(m['amount'] as double),
                  style: GoogleFonts.comicNeue(
                    fontSize: 9,
                    color: isReached ? AppColors.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniInfo(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 8,
            color: isDarkMode ? Colors.white24 : Colors.black26,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada rencana aktif.',
              style: GoogleFonts.comicNeue(
                color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                fontSize: 12,
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
