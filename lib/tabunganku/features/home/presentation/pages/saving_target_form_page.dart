import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';

class SavingTargetFormPage extends ConsumerStatefulWidget {
  final SavingTargetModel? target;

  const SavingTargetFormPage({super.key, this.target});

  @override
  ConsumerState<SavingTargetFormPage> createState() =>
      _SavingTargetFormPageState();
}

class _SavingTargetFormPageState extends ConsumerState<SavingTargetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  String _selectedCategory = 'Umum';

  final List<String> _categories = [
    'Umum',
    'Pembelian',
    'Darurat',
    'Pendidikan',
    'Pensiun',
    'Kurban',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.target?.name ?? '');
    _amountController = TextEditingController(
      text: widget.target != null
          ? NumberFormat.currency(
              locale: 'id_ID',
              symbol: '',
              decimalDigits: 0,
            ).format(widget.target!.targetAmount).trim()
          : '',
    );
    if (widget.target != null) {
      _selectedDate = widget.target!.dueDate;
      _selectedCategory = widget.target!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _toAmount(String val) {
    if (val.isEmpty) return null;
    final clean = val.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean);
  }

  void _saveTarget() async {
    if (_formKey.currentState!.validate()) {
      final amount = _toAmount(_amountController.text) ?? 0;

      final target = SavingTargetModel(
        id:
            widget.target?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        targetAmount: amount,
        dueDate: _selectedDate,
        createdAt: widget.target?.createdAt ?? DateTime.now(),
        category: _selectedCategory,
      );

      if (widget.target != null) {
        await ref.read(savingTargetServiceProvider).updateTarget(target);
      } else {
        await ref.read(savingTargetServiceProvider).addTarget(target);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.target != null
                  ? 'Target berhasil diperbarui!'
                  : 'Target baru berhasil ditambahkan!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
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
          widget.target != null ? 'Ubah Target' : 'Target Baru',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('Nama Barang / Impian', isDarkMode),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: _inputDecoration(
                  'Misal: iPhone 15 Pro',
                  Icons.stars_rounded,
                  isDarkMode,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 24),

              _buildInputLabel('Nominal Target', isDarkMode),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [_RibuanFormatter()],
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 24,
                ),
                decoration:
                    _inputDecoration(
                      '0',
                      Icons.payments_rounded,
                      isDarkMode,
                    ).copyWith(
                      prefixText: 'Rp ',
                      prefixStyle: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 20,
                      ),
                    ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Masukkan nominal';
                  if (_toAmount(val) == null || _toAmount(val)! <= 0)
                    return 'Nominal tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildInputLabel('Kategori Target', isDarkMode),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: isDarkMode
                        ? AppColors.surfaceDark
                        : Colors.white,
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildInputLabel('Target Tanggal Tercapai', isDarkMode),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
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
                        DateFormat(
                          'EEEE, dd MMMM yyyy',
                          'id_ID',
                        ).format(_selectedDate),
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _saveTarget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    widget.target != null
                        ? 'Simpan Perubahan'
                        : 'Mulai Menabung',
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDarkMode) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white70 : Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    bool isDarkMode,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: isDarkMode
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
