import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/models/insurance_model.dart';
import 'package:otax/tabunganku/services/insurance_service.dart';
import 'package:google_fonts/google_fonts.dart';

class InsuranceTrackerPage extends ConsumerStatefulWidget {
  const InsuranceTrackerPage({super.key});

  @override
  ConsumerState<InsuranceTrackerPage> createState() =>
      _InsuranceTrackerPageState();
}

class _InsuranceTrackerPageState extends ConsumerState<InsuranceTrackerPage> {
  final _nameController = TextEditingController();
  final _providerController = TextEditingController();
  final _premiController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final insuranceAsync = ref.watch(insuranceServiceProvider).watchInsurance();
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
          'Asuransi & Proteksi',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<InsuranceModel>>(
        stream: insuranceAsync,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final totalPremi = items.fold(0.0, (s, i) => s + i.premiumAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(totalPremi, items.length, isDarkMode),
                const SizedBox(height: 32),

                _buildInlineInputForm(isDarkMode),
                const SizedBox(height: 32),

                Text(
                  'POLIS TERDAFTAR',
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: contentColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  _buildEmptyState(isDarkMode)
                else
                  ...items.map((i) => _buildInsuranceItem(i, isDarkMode)),
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
            controller: _nameController,
            icon: Icons.shield_rounded,
            label: 'Nama Polis',
            unit: '',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            hint: 'Masukkan Nama Polis',
          ),
          const SizedBox(height: 12),
          _buildHighVisInput(
            controller: _providerController,
            icon: Icons.business_rounded,
            label: 'Penyedia',
            unit: '',
            color: Colors.blueGrey,
            isDarkMode: isDarkMode,
            hint: 'Masukkan Nama Penyedia',
          ),
          const SizedBox(height: 12),
          _buildHighVisInput(
            controller: _premiController,
            icon: Icons.payments_rounded,
            label: 'Premi',
            unit: 'Rp',
            color: Colors.green,
            isDarkMode: isDarkMode,
            isPremium: true,
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              InkWell(
                onTap: () => _pickDateInline(isDarkMode),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
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
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masa Berlaku Hingga',
                            style: TextStyle(
                              fontSize: 10,
                              color: (isDarkMode
                                  ? Colors.white38
                                  : Colors.grey.shade500),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM yyyy').format(_expiryDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final premi =
                        double.tryParse(
                          _premiController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (_nameController.text.isNotEmpty && premi > 0) {
                      final ins = InsuranceModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        policyName: _nameController.text,
                        provider: _providerController.text,
                        premiumAmount: premi,
                        expiryDate: _expiryDate,
                      );
                      await ref
                          .read(insuranceServiceProvider)
                          .addInsurance(ins);
                      _nameController.clear();
                      _providerController.clear();
                      _premiController.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Polis Berhasil Disimpan'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'Simpan Polis',
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
        ],
      ),
    );
  }

  void _pickDateInline(bool isDarkMode) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
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
      style: GoogleFonts.comicNeue(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: contentColor,
      ),
      decoration: InputDecoration(
        hintText: hint ?? '0',
        hintStyle: GoogleFonts.comicNeue(
          fontSize: 15,
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
      onTap: () => _showAddInsuranceSheet(isDarkMode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 4),
            Text(
              'Polis',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double premi, int count, bool isDarkMode) {
    final hexBg = isDarkMode ? AppColors.surfaceDark : Colors.white;
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: hexBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ESTIMASI PREMI BULANAN',
            style: GoogleFonts.comicNeue(
              color: contentColor.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatRupiah(premi),
              style: GoogleFonts.comicNeue(
                color: premi > 0
                    ? Colors.blueGrey
                    : contentColor.withValues(alpha: 0.1),
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count Polis Aktif Terlindungi',
            style: GoogleFonts.comicNeue(
              color: contentColor.withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInsurance(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Polis?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Data polis asuransi ini akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(insuranceServiceProvider).deleteInsurance(id);
    }
  }

  void _showEditInsuranceSheet(InsuranceModel item, bool isDarkMode) {
    final nameController = TextEditingController(text: item.policyName);
    final providerController = TextEditingController(text: item.provider);
    final premiController = TextEditingController(
      text: item.premiumAmount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      ),
    );
    DateTime expiryDate = item.expiryDate;

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
                  'UBAH POLIS ASURANSI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.teal.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildCompactInput(
                'Nama Polis',
                nameController,
                Icons.shield_rounded,
                isDarkMode,
                isPremium: false,
                hint: 'e.g. Asuransi Kesehatan',
              ),
              const SizedBox(height: 16),
              _buildCompactInput(
                'Penyedia Layanan',
                providerController,
                Icons.business_rounded,
                isDarkMode,
                isPremium: false,
                hint: 'e.g. Prudential, Allianz',
              ),
              const SizedBox(height: 16),
              _buildCompactInput(
                'Premi Bulanan',
                premiController,
                Icons.payments_rounded,
                isDarkMode,
                isPremium: true,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                expiryDate,
                (d) => setSheetState(() => expiryDate = d),
                isDarkMode,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final premi =
                        double.tryParse(
                          premiController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (nameController.text.isNotEmpty && premi > 0) {
                      final updatedIns = item.copyWith(
                        policyName: nameController.text,
                        provider: providerController.text,
                        premiumAmount: premi,
                        expiryDate: expiryDate,
                      );
                      await ref
                          .read(insuranceServiceProvider)
                          .updateInsurance(updatedIns);
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
                    'Simpan Perubahan',
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

  Widget _buildInsuranceItem(InsuranceModel item, bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    final remainingDays = item.expiryDate.difference(DateTime.now()).inDays;
    final isNearExpiry = remainingDays < 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.blueGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.policyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: contentColor,
                  ),
                ),
                Text(
                  item.provider,
                  style: GoogleFonts.comicNeue(
                    color: isDarkMode ? Colors.white24 : Colors.black38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isNearExpiry ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    remainingDays > 0
                        ? 'Sisa $remainingDays Hari'
                        : 'Kedaluwarsa',
                    style: GoogleFonts.comicNeue(
                      color: isNearExpiry ? Colors.orange : Colors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatRupiah(item.premiumAmount),
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: 8),
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
                    _showEditInsuranceSheet(item, isDarkMode);
                  if (value == 'delete') _deleteInsurance(item.id);
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
                          'Edit',
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.health_and_safety_rounded,
              size: 64,
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada polis terdaftar.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInsuranceSheet(bool isDarkMode) {
    final nameController = TextEditingController();
    final providerController = TextEditingController();
    final premiController = TextEditingController();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 365));

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
                  'TAMBAH POLIS ASURANSI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.teal.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildCompactInput(
                'Nama Polis',
                nameController,
                Icons.shield_rounded,
                isDarkMode,
                isPremium: false,
                hint: 'e.g. Asuransi Kesehatan',
              ),
              const SizedBox(height: 16),
              _buildCompactInput(
                'Penyedia Layanan',
                providerController,
                Icons.business_rounded,
                isDarkMode,
                isPremium: false,
                hint: 'e.g. Prudential, Allianz',
              ),
              const SizedBox(height: 16),
              _buildCompactInput(
                'Premi Bulanan',
                premiController,
                Icons.payments_rounded,
                isDarkMode,
                isPremium: true,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                expiryDate,
                (d) => setSheetState(() => expiryDate = d),
                isDarkMode,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final premi =
                        double.tryParse(
                          premiController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    if (nameController.text.isNotEmpty && premi > 0) {
                      final ins = InsuranceModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        policyName: nameController.text,
                        provider: providerController.text,
                        premiumAmount: premi,
                        expiryDate: expiryDate,
                      );
                      await ref
                          .read(insuranceServiceProvider)
                          .addInsurance(ins);
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
                    'Simpan Polis',
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
            hintText: hint ?? (isPremium ? '0' : 'Masukkan...'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MASA BERLAKU HINGGA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: contentColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        InkWell(
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
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('d MMMM yyyy').format(selected),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: contentColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: contentColor.withValues(alpha: 0.3),
                ),
              ],
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
