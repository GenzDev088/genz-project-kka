import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:otax/tabunganku/core/services/permission_service.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/services/ocr_service.dart';
import 'package:otax/tabunganku/features/settings/presentation/providers/security_provider.dart';

class ScanReceiptPage extends ConsumerStatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  ConsumerState<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends ConsumerState<ScanReceiptPage> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  File? _image;
  bool _isScanning = false;


  double _amount = 0.0;
  TransactionType _type = TransactionType.expense;
  String _detectedTitle = '';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();


  final List<Map<String, dynamic>> _scanTips = [
    {
      'icon': Icons.wb_sunny_rounded,
      'title': 'Cahaya Terang',
      'subtitle': 'Hindari bayangan',
    },
    {
      'icon': Icons.center_focus_strong_rounded,
      'title': 'Fokus & Jelas',
      'subtitle': 'Pastikan teks terbaca',
    },
    {
      'icon': Icons.crop_free_rounded,
      'title': 'Seluruh Bukti',
      'subtitle': 'Potret hingga tepi',
    },
  ];

  @override
  void dispose() {
    _ocrService.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {

      ref.read(securityProvider.notifier).setExternalOperation(true);


      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await PermissionService.requestPermission(
          context,
          permission: Permission.camera,
          title: 'Kamera',
          description:
              'Aplikasi membutuhkan akses kamera untuk memindai teks pada struk belanja Anda secara otomatis.',
          icon: Icons.camera_alt_rounded,
        );
      } else {



        hasPermission = await PermissionService.requestPermission(
          context,
          permission: Permission.photos,
          title: 'Galeri',
          description:
              'Aplikasi membutuhkan akses galeri untuk mengambil foto atau screenshot struk belanja yang ingin Anda pindai.',
          icon: Icons.photo_library_rounded,
        );
      }

      if (!hasPermission) return;

      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isScanning = true;
        });

        final result = await _ocrService.scanReceipt(_image!);

        setState(() {
          _amount = result['amount'];
          _type = result['type'];
          _detectedTitle = result['brandName'] ?? 'Bukti Transaksi';

          _amountController.text = _formatDigitsWithDots(
            _amount.toStringAsFixed(0),
          );
          _titleController.text = _detectedTitle;
          _isScanning = false;
        });
      }
    } finally {

      ref.read(securityProvider.notifier).setExternalOperation(false);
    }
  }

  Future<void> _saveTransaction() async {
    final amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty
          ? _detectedTitle
          : _titleController.text.trim(),
      description: _noteController.text.trim().isEmpty
          ? 'Bukti Transaksi'
          : _noteController.text.trim(),
      amount: amount,
      type: _type,
      date: DateTime.now(),
      category: _type == TransactionType.income ? 'Pemasukan' : 'Lainnya',
      groupId: null, // Personal history only
    );

    await ref.read(transactionServiceProvider).addTransaction(transaction);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dicatat ke Tabungan Pribadi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Scan Bukti Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              GestureDetector(
                onTap: () => _isScanning ? null : _showPickerOptions(),
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      width: 2,
                    ),
                    boxShadow: [
                      if (_image == null)
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: isDarkMode ? 0.05 : 0.02,
                          ),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                    ],
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_image!, fit: BoxFit.cover),
                              if (_isScanning) _buildScanningEffect(isDarkMode),
                            ],
                          ),
                        )
                      : _buildPlaceholder(isDarkMode),
                ),
              ),
              if (_image == null) ...[
                const SizedBox(height: 32),
                _buildScanningTips(isDarkMode),
              ],
              const SizedBox(height: 32),

              if (_image != null && !_isScanning) ...[

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDarkMode ? 0.3 : 0.04,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HASIL ANALISA AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'CONFIRMED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),


                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Keterangan Transaksi',
                          prefixIcon: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: actsAsSurface(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 20),


                      Row(
                        children: [
                          Expanded(
                            child: _typeButton(
                              label: 'Pemasukan',
                              isSelected: _type == TransactionType.income,
                              color: Colors.green,
                              isDarkMode: isDarkMode,
                              onTap: () => setState(
                                () => _type = TransactionType.income,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _typeButton(
                              label: 'Pengeluaran',
                              isSelected: _type == TransactionType.expense,
                              isDarkMode: isDarkMode,
                              color: Colors.red,
                              onTap: () => setState(
                                () => _type = TransactionType.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),


                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _RibuanSeparatorInputFormatter(),
                        ],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nominal yang Terdeteksi',
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: actsAsSurface(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildInfoRow(isDarkMode),
                    ],
                  ),
                ),
                const SizedBox(height: 24),


                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      'Simpan Transaksi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _image = null;
                      _amountController.clear();
                      _titleController.clear();
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Abaikan & Scan Ulang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDarkMode ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDarkMode ? Colors.white10 : Colors.grey.shade200),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? color
                  : (isDarkMode ? Colors.white38 : Colors.black38),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Scan Bukti Transaksi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ambil foto struk atau screenshot transfer',
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildScanningEffect(bool isDarkMode) {
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.6)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MEMINDAI DATA...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 12,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Positioned(
              top: value * 320,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0),
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            );
          },
          onEnd: () {}, // Handled by continuous rebuild during _isScanning
        ),
      ],
    );
  }

  Widget _buildScanningTips(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPS SCANNING',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: isDarkMode ? Colors.white24 : Colors.black26,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _scanTips.length,
            itemBuilder: (context, index) {
              final tip = _scanTips[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tip['icon'] as IconData,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip['title'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tip['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pastikan nominal dan judul sudah sesuai dengan bukti transfer kamu.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.orange.shade200
                    : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color actsAsSurface(bool isDarkMode) =>
      isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Bukti Transfer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDigitsWithDots(String digitsText) {
    if (digitsText.isEmpty) return '';
    final digits = digitsText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
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
            .substring(0, newValue.selection.end)
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
