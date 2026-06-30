import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/shopping_item_model.dart';
import 'package:otax/tabunganku/providers/shopping_item_provider.dart';
import 'package:otax/tabunganku/features/settings/presentation/providers/security_provider.dart';
import 'package:otax/tabunganku/core/constants/transaction_categories.dart';

class ShoppingFormSheet extends ConsumerStatefulWidget {
  final ShoppingItem? item;

  const ShoppingFormSheet({super.key, this.item});

  static Future<void> show(BuildContext context, {ShoppingItem? item}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(child: ShoppingFormSheet(item: item)),
      ),
    );
  }

  @override
  ConsumerState<ShoppingFormSheet> createState() => _ShoppingFormSheetState();
}

class _ShoppingFormSheetState extends ConsumerState<ShoppingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController; // Total Price
  late TextEditingController _pricePerUnitController; // Added
  late TextEditingController _quantityController; // Added
  late TextEditingController _unitController; // Added
  late TextEditingController _categoryController;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.item?.name ?? '');

    _quantityController = TextEditingController(
      text: widget.item != null
          ? widget.item!.quantity.toString().replaceAll(RegExp(r'\.0$'), '')
          : '',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? '');


    double initialPricePerUnit = 0;
    if (widget.item != null) {
      initialPricePerUnit = widget.item!.estimatedPrice / widget.item!.quantity;
    }


    String initialPriceStr = '';
    if (widget.item != null) {
      final pricePerUnit = (widget.item!.estimatedPrice / widget.item!.quantity)
          .toInt();
      initialPriceStr = pricePerUnit.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
    }

    _pricePerUnitController = TextEditingController(text: initialPriceStr);

    _priceController = TextEditingController(
      text: widget.item != null
          ? widget.item!.estimatedPrice.toInt().toString()
          : '',
    );
    _categoryController = TextEditingController(
      text: widget.item?.category ?? '',
    );
    _imagePath = widget.item?.imagePath;


    _pricePerUnitController.addListener(_calculateTotalPrice);
    _quantityController.addListener(_calculateTotalPrice);


    if (_priceController.text.isNotEmpty) {
      final val = _priceController.text;
      _priceController.value = _RibuanSeparatorInputFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(
              text: val,
              selection: TextSelection.collapsed(offset: val.length),
            ),
          );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _pricePerUnitController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _calculateTotalPrice() {
    final qtyStr = _quantityController.text.replaceAll(',', '.');
    final priceStr = _pricePerUnitController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final qty = double.tryParse(qtyStr) ?? 0;
    final pricePerUnit = double.tryParse(priceStr) ?? 0;

    final total = qty * pricePerUnit;

    setState(() {
      if (total > 0) {
        final formattedTotal = _RibuanSeparatorInputFormatter()
            .formatEditUpdate(
              const TextEditingValue(text: ''),
              TextEditingValue(
                text: total.toInt().toString(),
                selection: TextSelection.collapsed(offset: 0),
              ),
            )
            .text;

        _priceController.text = formattedTotal;
      } else {
        _priceController.text = '';
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {

      ref.read(securityProvider.notifier).setExternalOperation(true);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(pickedFile.path);
        final permanentPath = p.join(appDir.path, fileName);

        await File(pickedFile.path).copy(permanentPath);

        setState(() {
          _imagePath = permanentPath;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {

      ref.read(securityProvider.notifier).setExternalOperation(false);
    }
  }

  void _showImageSourceSheet() {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.teal.shade50.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.teal.shade50,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.teal.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final cleanAmount = _priceController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final price = double.tryParse(cleanAmount) ?? 0;

      final finalCategory = _categoryController.text.trim().isEmpty
          ? 'Belanja'
          : _categoryController.text.trim();

      final newItem = ShoppingItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        estimatedPrice: price,
        quantity:
            double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1,
        unit: _unitController.text.trim().isEmpty
            ? 'unit'
            : _unitController.text.trim(),
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        category: finalCategory,
        imagePath: _imagePath,
        isBought: widget.item?.isBought ?? false,
      );

      if (widget.item == null) {
        await ref.read(shoppingItemServiceProvider).addItem(newItem);
      } else {
        await ref.read(shoppingItemServiceProvider).updateItem(newItem);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? 'Rencana belanja ditambahkan'
                  : 'Rencana belanja diperbarui',
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item == null ? 'Bikin Rencana' : 'Ubah Rencana',
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (_priceController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rp ${_priceController.text}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.grey.shade100,
                          ),
                        ),
                        child: _imagePath != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(_imagePath!),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _imagePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Tambah Foto Barang',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Nama Barang', isDarkMode, isRequired: true),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Misal: Kopi, Beras, dll...',
                      icon: Icons.shopping_bag_outlined,
                      isDarkMode: isDarkMode,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                'Harga/Unit',
                                isDarkMode,
                                isRequired: true,
                              ),
                              _buildTextField(
                                controller: _pricePerUnitController,
                                hint: '0',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _RibuanSeparatorInputFormatter(),
                                ],
                                isDarkMode: isDarkMode,
                                prefixText: 'Rp',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                'Jumlah',
                                isDarkMode,
                                isRequired: true,
                              ),
                              _buildTextField(
                                controller: _quantityController,
                                hint: '1',
                                icon: Icons.onetwothree_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Satuan (Unit)', isDarkMode),
                    _buildTextField(
                      controller: _unitController,
                      hint: 'pcs, kg, box...',
                      icon: Icons.straighten_rounded,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Kategori', isDarkMode),
                    _buildTextField(
                      controller: _categoryController,
                      hint: 'Misal: Sembako, Kebutuhan Dapur...',
                      icon: Icons.label_outline_rounded,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 32),


                    if (_priceController.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Estimasi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Rp ${_priceController.text}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                        child: Text(
                          widget.item == null
                              ? 'Simpan Rencana'
                              : 'Simpan Perubahan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white24 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black87,
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
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white12 : Colors.black26,
          fontSize: 14,
        ),
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: AppColors.primary, size: 20),
            if (prefixText != null) ...[
              const SizedBox(width: 8),
              Text(
                prefixText,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
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
