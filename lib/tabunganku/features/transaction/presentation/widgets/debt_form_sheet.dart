import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/debt_model.dart';
import 'package:otax/tabunganku/providers/debt_provider.dart';

class DebtFormSheet extends ConsumerStatefulWidget {
  final DebtModel? debt;
  final DebtType? initialType;

  const DebtFormSheet({super.key, this.debt, this.initialType});

  static Future<void> show(
    BuildContext context, {
    DebtModel? debt,
    DebtType? initialType,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DebtFormSheet(debt: debt, initialType: initialType),
      ),
    );
  }

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;
  late DebtType _type;
  DateTime? _dueDate;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.debt?.title ?? '');
    String formattedAmount = '';
    if (widget.debt != null) {
      final rawAmount = widget.debt!.amount.toInt().toString();
      formattedAmount = rawAmount.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
    }

    _amountController = TextEditingController(text: formattedAmount);
    _contactController = TextEditingController(
      text: widget.debt?.contactName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.debt?.description ?? '',
    );
    _type = widget.debt?.type ?? widget.initialType ?? DebtType.hutang;
    _dueDate = widget.debt?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final cleanAmount = _amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final amount = double.tryParse(cleanAmount) ?? 0;
      final debt = DebtModel(
        id: widget.debt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        amount: amount,
        type: _type,
        contactName: _contactController.text,
        dueDate: _dueDate,
        isPaid: widget.debt?.isPaid ?? false,
        createdAt: widget.debt?.createdAt ?? DateTime.now(),
      );

      if (widget.debt == null) {
        await ref.read(debtServiceProvider).addDebt(debt);
      } else {
        await ref.read(debtServiceProvider).updateDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.debt == null
                  ? 'Catatan berhasil ditambahkan'
                  : 'Catatan berhasil diperbarui',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.debt != null
                    ? 'Edit Catatan'
                    : (_type == DebtType.hutang
                          ? 'Catat Hutang Baru'
                          : 'Catat Piutang Baru'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),


              if (widget.initialType == null || widget.debt != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Hutang',
                        isSelected: _type == DebtType.hutang,
                        onTap: () => setState(() => _type = DebtType.hutang),
                        icon: Icons.call_made_rounded,
                        color: const Color(0xFFE53935),
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeButton(
                        label: 'Piutang',
                        isSelected: _type == DebtType.piutang,
                        onTap: () => setState(() => _type = DebtType.piutang),
                        icon: Icons.call_received_rounded,
                        color: AppColors.primary,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildLabel('Nama Kontak', isDarkMode, isRequired: true),
              _buildTextField(
                controller: _contactController,
                hint: 'Nama orang/kontak',
                icon: Icons.person_outline_rounded,
                isDarkMode: isDarkMode,
                iconColor: AppColors.primary,
                validator: (v) => v!.isEmpty ? 'Nama harus diisi' : null,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contact_phone_rounded),
                  color: AppColors.primary,
                  onPressed: () async {
                    try {
                      final contact = await _contactPicker.selectContact();
                      if (contact != null && contact.fullName != null) {
                        String phoneStr = '';
                        if (contact.phoneNumbers != null &&
                            contact.phoneNumbers!.isNotEmpty) {
                          phoneStr = ' (${contact.phoneNumbers!.first})';
                        }
                        setState(() {
                          _contactController.text =
                              '${contact.fullName}$phoneStr';
                        });
                      }
                    } catch (e) {

                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              _buildLabel('Nominal', isDarkMode, isRequired: true),
              _buildTextField(
                controller: _amountController,
                hint: '0',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RibuanSeparatorInputFormatter(),
                ],
                isDarkMode: isDarkMode,
                prefixText: 'Rp',
                iconColor: _type == DebtType.hutang
                    ? const Color(0xFFE53935)
                    : AppColors.primary,
                validator: (v) => v!.isEmpty ? 'Nominal harus diisi' : null,
              ),
              const SizedBox(height: 12),

              _buildLabel('Keterangan', isDarkMode, isRequired: true),
              _buildTextField(
                controller: _titleController,
                hint: 'Contoh: Pinjam buat makan',
                icon: Icons.title_rounded,
                isDarkMode: isDarkMode,
                iconColor: AppColors.primary,
                validator: (v) => v!.isEmpty ? 'Keterangan harus diisi' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          'Jatuh Tempo (Opsional)',
                          isDarkMode,
                          isRequired: false,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (date != null) {
                              setState(() => _dueDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _dueDate == null
                                      ? 'Pilih Tanggal'
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_dueDate!),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Catatan',
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

  Widget _buildLabel(String text, bool isDarkMode, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white30 : Colors.black38,
                letterSpacing: 0.5,
              ),
            ),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required bool isDarkMode,
    String? prefixText,
    Color? iconColor,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white12 : Colors.black26,
          fontSize: 13,
        ),
        suffixIcon: suffixIcon,
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            Icon(
              icon,
              color: iconColor ?? (isDarkMode ? Colors.white24 : Colors.grey),
              size: 18,
            ),
            if (prefixText != null) ...[
              const SizedBox(width: 8),
              Text(
                prefixText,
                style: TextStyle(
                  color:
                      iconColor ??
                      (isDarkMode ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? color.withValues(alpha: isDarkMode ? 0.2 : 0.1)
        : (isDarkMode
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.shade50);
    final borderColor = isSelected
        ? color.withValues(alpha: 0.5)
        : (isDarkMode ? Colors.white10 : Colors.grey.shade200);
    final textColor = isSelected
        ? color
        : (isDarkMode ? Colors.white38 : Colors.grey);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibuanSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;


    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');


    final formatted = digitsOnly.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );


    int numDigitsBefore =
        newValue.selection.end -
        newValue.text
            .substring(
              0,
              math.min(newValue.selection.end, newValue.text.length),
            )
            .replaceAll(RegExp(r'[0-9]'), '')
            .length;

    int newSelectionIndex = 0;
    int digitsCount = 0;
    while (digitsCount < numDigitsBefore &&
        newSelectionIndex < formatted.length) {
      if (RegExp(r'[0-9]').hasMatch(formatted[newSelectionIndex])) {
        digitsCount++;
      }
      newSelectionIndex++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
