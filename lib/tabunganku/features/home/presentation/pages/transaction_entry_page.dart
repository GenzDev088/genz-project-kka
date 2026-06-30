import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/core/constants/transaction_categories.dart';
import 'package:otax/tabunganku/core/utils/currency_formatter.dart';

class TransactionEntryPage extends ConsumerStatefulWidget {
  final TransactionType type;
  final TransactionModel? existingTransaction;

  const TransactionEntryPage({
    super.key,
    required this.type,
    this.existingTransaction,
  });

  @override
  ConsumerState<TransactionEntryPage> createState() =>
      _TransactionEntryPageState();
}

class _TransactionEntryPageState extends ConsumerState<TransactionEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late String _selectedCategory;
  late String _selectedGroup;
  late TextEditingController _customCategoryController;

  String? _selectedTopUpSource;
  String? _selectedInterestBank;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final isEdit = widget.existingTransaction != null;
    _nameController = TextEditingController(
      text: isEdit ? widget.existingTransaction!.title : '',
    );
    _amountController = TextEditingController(
      text: isEdit
          ? _formatInitialAmount(widget.existingTransaction!.amount)
          : '',
    );

    final categoryObjects = widget.type == TransactionType.income
        ? AppCategories.incomeCategories
        : AppCategories.expenseCategories;

    if (isEdit) {
      _selectedCategory = widget.existingTransaction!.category;
      _selectedGroup = categoryObjects
          .firstWhere(
            (cat) => cat.label == _selectedCategory,
            orElse: () => categoryObjects.first,
          )
          .group;
      _selectedDate = widget.existingTransaction!.date;
    } else {
      _selectedCategory = widget.type == TransactionType.income
          ? 'Gaji Pokok'
          : 'Makanan & Minuman Harian';
      _selectedGroup = categoryObjects
          .firstWhere((cat) => cat.label == _selectedCategory)
          .group;
    }

    _customCategoryController = TextEditingController();
    _nameController.addListener(_autoDetectCategory);
  }

  String _formatInitialAmount(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount).trim();
  }

  void _autoDetectCategory() {
    final text = _nameController.text.toLowerCase();

    if (widget.type == TransactionType.expense &&
        widget.existingTransaction == null) {
      if (text.contains('makan') ||
          text.contains('minum') ||
          text.contains('warung') ||
          text.contains('nasi')) {
        _updateIncomeCategory('Makanan & Minuman Harian', 'Kebutuhan Pokok');
      } else if (text.contains('sembako') ||
          text.contains('beras') ||
          text.contains('minyak')) {
        _updateIncomeCategory('Belanja Sembako / Pasar', 'Kebutuhan Pokok');
      } else if (text.contains('listrik') ||
          text.contains('pln') ||
          text.contains('token')) {
        _updateIncomeCategory('Token Listrik / PLN', 'Kebutuhan Pokok');
      } else if (text.contains('bensin') ||
          text.contains('pertalite') ||
          text.contains('pertamax') ||
          text.contains('spbu')) {
        _updateIncomeCategory('Bahan Bakar (BBM)', 'Transportasi');
      } else if (text.contains('ojek') ||
          text.contains('gojek') ||
          text.contains('grab') ||
          text.contains('maxim')) {
        _updateIncomeCategory('Ojek Online (Gojek/Grab)', 'Transportasi');
      } else if (text.contains('pulsa') ||
          text.contains('kuota') ||
          text.contains('data')) {
        _updateIncomeCategory('Pulsa & Paket Data Seluler', 'Teknologi');
      } else if (text.contains('wifi') ||
          text.contains('indihome') ||
          text.contains('biznet')) {
        _updateIncomeCategory('WiFi / Internet Rumah', 'Teknologi');
      } else if (text.contains('netflix') ||
          text.contains('disney') ||
          text.contains('spotify') ||
          text.contains('youtube')) {
        _updateIncomeCategory('Langganan Netflix / Disney+', 'Teknologi');
      } else if (text.contains('obat') ||
          text.contains('sakit') ||
          text.contains('vitamin') ||
          text.contains('apotek')) {
        _updateIncomeCategory('Obat & Vitamin', 'Kesehatan');
      } else if (text.contains('kopi') ||
          text.contains('coffee') ||
          text.contains('cafe') ||
          text.contains('nongkrong')) {
        _updateIncomeCategory('Nongkrong / Coffee Shop', 'Gaya Hidup');
      } else if (text.contains('zakat') ||
          text.contains('sedekah') ||
          text.contains('infak')) {
        _updateIncomeCategory('Zakat / Infak / Sedekah', 'Sosial & Ibadah');
      } else if (text.contains('admin') ||
          text.contains('biaya') ||
          text.contains('fee') ||
          text.contains('top up')) {
        _updateIncomeCategory('Biaya Admin Bank', 'Keuangan');
      } else if (text.contains('hutang') ||
          text.contains('cicilan') ||
          text.contains('pinjol') ||
          text.contains('bayar')) {
        _updateIncomeCategory('Bayar Hutang / Pinjol', 'Keuangan');
      }
    } else if (widget.type == TransactionType.income &&
        widget.existingTransaction == null) {

      if (text.contains('gaji') || text.contains('salary')) {
        _updateIncomeCategory('Gaji Pokok', 'Pekerjaan Utama');
      } else if (text.contains('thr')) {
        _updateIncomeCategory('THR (Tunjangan Hari Raya)', 'Pekerjaan Utama');
      } else if (text.contains('bonus')) {
        _updateIncomeCategory('Bonus Tahunan & Performa', 'Pekerjaan Utama');
      } else if (text.contains('hutang') ||
          text.contains('bayar') ||
          text.contains('pinjam')) {
        _updateIncomeCategory(
          'Teman Mengembalikan Hutang',
          'Pinjaman & Hutang',
        );
      } else if (text.contains('crypto') ||
          text.contains('saham') ||
          text.contains('forex') ||
          text.contains('trading')) {
        _updateIncomeCategory('Profit Trading (Saham/Crypto)', 'Investasi');
      } else if (text.contains('cashback')) {
        _updateIncomeCategory('Cashback e-Wallet / Belanja', 'Keuangan & Bank');
      } else if (text.contains('refund')) {
        _updateIncomeCategory('Refund / Pengembalian Dana', 'Keuangan & Bank');
      } else if (text.contains('jual') ||
          text.contains('omzet') ||
          text.contains('dagang')) {
        _updateIncomeCategory('Omzet Penjualan Produk', 'Bisnis & Usaha');
      }
    }
  }

  void _updateIncomeCategory(String cat, String group) {
    if (_selectedCategory != cat) {
      setState(() {
        _selectedCategory = cat;
        _selectedGroup = group;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  double? _toAmount(String val) {
    if (val.isEmpty) return null;
    final clean = val.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean);
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amount = _toAmount(_amountController.text) ?? 0;

      final transaction = TransactionModel(
        id:
            widget.existingTransaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _nameController.text.trim(),
        description: _getDetailedDescription(),
        amount: amount,
        type: widget.type,
        date: _selectedDate,
        category:
            _selectedCategory == AppCategories.otherLabel &&
                _customCategoryController.text.trim().isNotEmpty
            ? _customCategoryController.text.trim()
            : _selectedCategory,
      );

      if (widget.existingTransaction != null) {
        await ref
            .read(transactionServiceProvider)
            .updateTransaction(transaction);
      } else {
        await ref.read(transactionServiceProvider).addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingTransaction != null
                  ? 'Transaksi berhasil diperbarui!'
                  : 'Transaksi berhasil dicatat!',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getDetailedDescription() {
    if (_selectedCategory == 'Biaya Admin Bank' &&
        _selectedTopUpSource != null) {
      return 'Top Up $_selectedTopUpSource';
    }
    if (_selectedCategory == 'Bunga Deposito / Tabungan' &&
        _selectedInterestBank != null) {
      return 'Bunga $_selectedInterestBank';
    }
    return widget.type == TransactionType.income
        ? 'Pemasukan mandiri'
        : 'Pengeluaran mandiri';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final categoryObjects = widget.type == TransactionType.income
        ? AppCategories.incomeCategories
        : AppCategories.expenseCategories;

    final Map<String, List<TransactionCategory>> groupedCategories = {};
    for (var cat in categoryObjects) {
      groupedCategories.putIfAbsent(cat.group, () => []).add(cat);
    }

    final accentColor = widget.type == TransactionType.income
        ? AppColors.success
        : AppColors.error;

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
          widget.existingTransaction != null
              ? 'Edit Transaksi'
              : (widget.type == TransactionType.income
                    ? 'Tambah Pemasukan'
                    : 'Tambah Pengeluaran'),
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF121212)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOMINAL',
                      style: GoogleFonts.comicNeue(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_RibuanFormatter()],
                      style: GoogleFonts.comicNeue(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.comicNeue(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                        prefixIcon: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Rp',
                              style: GoogleFonts.comicNeue(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Masukkan nominal';
                        if (_toAmount(val) == null || _toAmount(val)! <= 0)
                          return 'Nominal tidak valid';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),


              _buildLabel('KETERANGAN / NAMA TRANSAKSI', isDarkMode),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: _inputDecoration(
                  'Misal: Gaji Bulan April',
                  Icons.edit_note_rounded,
                  isDarkMode,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Keterangan tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),


              _buildLabel('TANGGAL TRANSAKSI', isDarkMode),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: _buildFakeInput(
                  DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(_selectedDate),
                  Icons.calendar_today_rounded,
                  isDarkMode,
                ),
              ),
              const SizedBox(height: 24),


              _buildLabel('PILIH KATEGORI', isDarkMode),
              const SizedBox(height: 6),
              _buildCategoryDropdown(groupedCategories, isDarkMode),
              const SizedBox(height: 16),


              if (_selectedCategory == AppCategories.otherLabel) ...[
                const SizedBox(height: 4),
                _buildLabel('NAMA KATEGORI KUSTOM', isDarkMode),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _customCategoryController,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: _inputDecoration(
                    'Masukkan Kategori Transaksi',
                    Icons.star_rounded,
                    isDarkMode,
                  ),
                  validator: (val) {
                    if (_selectedCategory == AppCategories.otherLabel &&
                        (val == null || val.trim().isEmpty)) {
                      return 'Kategori kustom harus diisi!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 12),


              if (_selectedCategory == 'Biaya Admin Bank')
                _buildTopUpSourceSelection(isDarkMode),
              if (_selectedCategory == 'Bunga Tabungan Reguler')
                _buildInterestBankSelection(isDarkMode),

              const SizedBox(height: 48),


              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    widget.existingTransaction != null
                        ? 'Simpan Perubahan'
                        : 'Catat Transaksi Sekarang',
                    style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text, bool isDarkMode) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: isDarkMode ? Colors.white24 : Colors.black38,
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

  Widget _buildFakeInput(String text, IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(
    Map<String, List<TransactionCategory>> grouped,
    bool isDarkMode,
  ) {
    return Container(
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
          dropdownColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCategory = val;

                for (var entry in grouped.entries) {
                  if (entry.value.any((c) => c.label == val)) {
                    _selectedGroup = entry.key;
                    break;
                  }
                }
              });
              FocusScope.of(context).unfocus();
            }
          },
          items: grouped.entries.expand((group) {
            return [
              DropdownMenuItem<String>(
                enabled: false,
                child: Text(
                  group.key.toUpperCase(),
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ...group.value.map(
                (cat) => DropdownMenuItem<String>(
                  value: cat.label,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Icon(
                          cat.icon,
                          size: 16,
                          color: isDarkMode ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cat.label,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.comicNeue(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopUpSourceSelection(bool isDarkMode) {
    final sources = [
      {'label': 'Bank', 'icon': Icons.account_balance_rounded},
      {'label': 'GoPay', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'OVO', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'Dana', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'ShopeePay', 'icon': Icons.account_balance_wallet_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('PILIH SUMBER TOP UP', isDarkMode),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: sources.map((s) {
            final isSel = _selectedTopUpSource == s['label'];
            return ChoiceChip(
              label: Text(s['label'] as String),
              selected: isSel,
              onSelected: (val) {
                setState(() {
                  _selectedTopUpSource = val ? s['label'] as String : null;
                  if (val) {
                    final source = s['label'] as String;
                    if (_nameController.text.isEmpty ||
                        _nameController.text.startsWith('Biaya Admin')) {
                      _nameController.text = source == 'Bank'
                          ? 'Biaya Admin Bank'
                          : 'Biaya Admin $source';
                    }
                  } else {
                    if (_nameController.text.startsWith('Biaya Admin')) {
                      _nameController.clear();
                    }
                  }
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSel
                    ? AppColors.primary
                    : (isDarkMode ? Colors.white38 : Colors.grey),
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestBankSelection(bool isDarkMode) {
    final banks = [
      'SeaBank',
      'Bank Neo',
      'Bank Jago',
      'Blu by BCA',
      'Mandiri',
      'BRI',
      'BCA',
      'Lainnya',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('PILIH BANK SUMBER BUNGA', isDarkMode),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: banks.map((b) {
            final isSel = _selectedInterestBank == b;
            return ChoiceChip(
              label: Text(b),
              selected: isSel,
              onSelected: (val) {
                setState(() {
                  _selectedInterestBank = val ? b : null;
                  if (val) {
                    if (_nameController.text.isEmpty ||
                        _nameController.text.startsWith('Bunga ')) {
                      final now = DateTime.now();
                      final monthName = [
                        '',
                        'Januari',
                        'Februari',
                        'Maret',
                        'April',
                        'Mei',
                        'Juni',
                        'Juli',
                        'Agustus',
                        'September',
                        'Oktober',
                        'November',
                        'Desember',
                      ][now.month];
                      _nameController.text = 'Bunga $b $monthName ${now.year}';
                    }
                  } else {
                    if (_nameController.text.startsWith('Bunga ')) {
                      _nameController.clear();
                    }
                  }
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
            );
          }).toList(),
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
