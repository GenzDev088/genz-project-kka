import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';

class BuyingTargetsPage extends ConsumerStatefulWidget {
  const BuyingTargetsPage({super.key});

  @override
  ConsumerState<BuyingTargetsPage> createState() => _BuyingTargetsPageState();
}

class _BuyingTargetsPageState extends ConsumerState<BuyingTargetsPage> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90));

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    final bgColor = isDarkMode
        ? AppColors.backgroundDark
        : const Color(0xFFF8FAF9);
    final targetsAsync = ref.watch(savingTargetsStreamProvider);

    return Scaffold(
      backgroundColor: bgColor,
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
          'Target Saya',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: contentColor,
          ),
        ),
      ),
      body: targetsAsync.when(
        data: (targets) {
          final buyingTargets = targets
              .where((t) => t.category == 'Pembelian' || t.category == 'Umum')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDarkMode),
                const SizedBox(height: 32),
                _buildInputForm(isDarkMode),
                const SizedBox(height: 32),
                Text(
                  'Daftar Target Pembelian',
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: contentColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                if (buyingTargets.isEmpty)
                  _buildEmptyState(isDarkMode)
                else
                  ...buyingTargets.map((t) => _buildTargetItem(t, isDarkMode)),
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

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Belanja',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Mulai cicil tabungan untuk barang impianmu.',
                  style: GoogleFonts.comicNeue(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
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

  Widget _buildInputForm(bool isDarkMode) {
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
          _buildInputLabel('Barang Impian', isDarkMode),
          const SizedBox(height: 8),
          _buildHighVisInput(
            controller: _nameController,
            icon: Icons.label_important_rounded,
            unit: '',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            hint: 'Contoh: iPhone 15 Pro',
          ),
          const SizedBox(height: 16),
          _buildInputLabel('Harga Estimasi', isDarkMode),
          const SizedBox(height: 8),
          _buildHighVisInput(
            controller: _amountController,
            icon: Icons.price_check_rounded,
            unit: 'Rp',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            isPremium: true,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _pickDate(isDarkMode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Tanggal',
                        style: GoogleFonts.comicNeue(
                          fontSize: 10,
                          color: (isDarkMode
                              ? Colors.white38
                              : Colors.grey.shade500),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'd MMMM yyyy',
                          'id_ID',
                        ).format(_selectedDate),
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final amount =
                    double.tryParse(
                      _amountController.text.replaceAll('.', ''),
                    ) ??
                    0;
                if (amount > 0 && _nameController.text.isNotEmpty) {
                  final target = SavingTargetModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text,
                    targetAmount: amount,
                    dueDate: _selectedDate,
                    createdAt: DateTime.now(),
                    category: 'Pembelian',
                  );
                  await ref.read(savingTargetServiceProvider).addTarget(target);
                  _amountController.clear();
                  _nameController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Target Berhasil Ditambahkan!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Tambah Target',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: GoogleFonts.comicNeue(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white70 : Colors.black87,
      ),
    );
  }

  void _pickDate(bool isDarkMode) async {
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
    const baseColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showEditDialog(target),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
            child: Row(
              children: [

                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: baseColor.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          baseColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: baseColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.name.toUpperCase(),
                        style: GoogleFonts.comicNeue(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 12,
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatRupiah(target.targetAmount),
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM').format(target.dueDate),
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.comicNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: baseColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _deleteTarget(target.id),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: isDarkMode
                            ? Colors.white12
                            : Colors.redAccent.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(SavingTargetModel target) async {
    final nameController = TextEditingController(text: target.name);
    final amountController = TextEditingController(
      text: target.targetAmount.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      ),
    );
    DateTime selectedDate = target.dueDate;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Ubah Target',
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputLabel('Nama Barang', isDarkMode),
              const SizedBox(height: 8),
              _buildHighVisInput(
                controller: nameController,
                icon: Icons.label_important_rounded,
                unit: '',
                color: AppColors.primary,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildInputLabel('Harga Estimasi', isDarkMode),
              const SizedBox(height: 8),
              _buildHighVisInput(
                controller: amountController,
                icon: Icons.price_check_rounded,
                unit: 'Rp',
                color: AppColors.primary,
                isDarkMode: isDarkMode,
                isPremium: true,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null)
                    setDialogState(() => selectedDate = picked);
                },
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
                      Text(DateFormat('d/M/yy').format(selectedDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    double.tryParse(
                      amountController.text.replaceAll('.', ''),
                    ) ??
                    0;
                if (amount > 0) {
                  await ref
                      .read(savingTargetServiceProvider)
                      .updateTarget(
                        target.copyWith(
                          name: nameController.text,
                          targetAmount: amount,
                          dueDate: selectedDate,
                        ),
                      );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTarget(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Target?'),
        content: const Text('Target belanja ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(savingTargetServiceProvider).deleteTarget(id);
    }
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada target pembelian.',
              style: GoogleFonts.comicNeue(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
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
