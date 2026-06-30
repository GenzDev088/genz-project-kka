import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:google_fonts/google_fonts.dart';

class SpecializedSavingPage extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final Color baseColor;
  final String category;

  const SpecializedSavingPage({
    super.key,
    required this.title,
    required this.icon,
    required this.baseColor,
    required this.category,
  });

  @override
  ConsumerState<SpecializedSavingPage> createState() =>
      _SpecializedSavingPageState();
}

class _SpecializedSavingPageState extends ConsumerState<SpecializedSavingPage> {
  late final TextEditingController _nameController;
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '${widget.category} ');
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
    final targetsAsync = ref.watch(savingTargetsStreamProvider);
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
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: targetsAsync.when(
        data: (targets) {
          final filteredTargets = targets
              .where(
                (t) => t.name.toLowerCase().contains(
                  widget.category.toLowerCase(),
                ),
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(isDarkMode),
                const SizedBox(height: 32),

                _buildInlineInputForm(isDarkMode),
                const SizedBox(height: 32),

                Text(
                  'TARGET ${widget.title.toUpperCase()}',
                  style: TextStyle(
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
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
            controller: _nameController,
            icon: Icons.edit_note_rounded,
            label: 'Nama Rencana',
            unit: '',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            hint: 'Masukkan nama...',
          ),
          const SizedBox(height: 16),
          _buildHighVisInput(
            controller: _amountController,
            icon: Icons.account_balance_wallet_rounded,
            label: 'Nominal Target',
            unit: 'Rp',
            color: Colors.green,
            isDarkMode: isDarkMode,
            isPremium: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDateInline(isDarkMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.03)
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
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d/M/yy').format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(
                          _amountController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (amount > 0) {
                      final target = SavingTargetModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text,
                        targetAmount: amount,
                        dueDate: _selectedDate,
                        createdAt: DateTime.now(),
                      );
                      await ref
                          .read(savingTargetServiceProvider)
                          .addTarget(target);
                      _amountController.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rencana Berhasil Dibuat'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickDateInline(bool isDarkMode) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: contentColor,
      ),
      decoration: InputDecoration(
        hintText: hint ?? '0',
        hintStyle: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white10 : Colors.black38,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  unit,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
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
          borderRadius: BorderRadius.circular(16),
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
      onTap: () => _showAddTargetSheet(isDarkMode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.baseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.add_rounded, size: 16, color: widget.baseColor),
            const SizedBox(width: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.baseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.baseColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.baseColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 28, color: widget.baseColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: widget.baseColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rencanakan dana masa depanmu dengan target yang produktif.',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.baseColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetItem(SavingTargetModel target, bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  target.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: contentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.baseColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: widget.baseColor.withValues(alpha: 0.1),
              color: widget.baseColor,
            ),
          ),
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
                'Jatuh Tempo',
                DateFormat('d MMM yyyy').format(target.dueDate),
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: contentColor.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
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
              widget.icon,
              size: 64,
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada rencana yang dibuat.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTargetSheet(bool isDarkMode) {
    final nameController = TextEditingController(text: '${widget.category} ');
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 24,
            left: 28,
            right: 28,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'BUAT RENCANA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.teal.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildCompactInput(
                'Nama Rencana',
                nameController,
                Icons.edit_note_rounded,
                isDarkMode,
                isPremium: false,
              ),
              const SizedBox(height: 16),
              _buildCompactInput(
                'Nominal Target',
                amountController,
                Icons.account_balance_wallet_rounded,
                isDarkMode,
                isPremium: true,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                selectedDate,
                (d) => setSheetState(() => selectedDate = d),
                isDarkMode,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(
                          amountController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (amount > 0) {
                      final target = SavingTargetModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        targetAmount: amount,
                        dueDate: selectedDate,
                        createdAt: DateTime.now(),
                      );
                      await ref
                          .read(savingTargetServiceProvider)
                          .addTarget(target);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Buat Rencana',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: contentColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: isPremium ? TextInputType.number : TextInputType.text,
          inputFormatters: isPremium ? [_RibuanFormatter()] : null,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
          decoration: InputDecoration(
            hintText: isPremium ? '0' : 'Masukkan nama...',
            hintStyle: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white10 : Colors.teal.shade50,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  if (isPremium) ...[
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
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    DateTime selected,
    Function(DateTime) onPicked,
    bool isDarkMode,
  ) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) onPicked(picked);
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
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TARGET SELESAI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: contentColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMMM yyyy').format(selected),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: contentColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: contentColor.withValues(alpha: 0.3),
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
