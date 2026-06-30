import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../providers/family_group_provider.dart';
import '../../../../providers/transaction_provider.dart';
import '../../../../models/family_group_model.dart';
import '../../../../models/transaction_model.dart';
import '../../../home/presentation/widgets/connectivity_guard.dart';
import '../widgets/name_setup_sheet.dart';

class FamilyGroupPage extends ConsumerStatefulWidget {
  const FamilyGroupPage({super.key});

  @override
  ConsumerState<FamilyGroupPage> createState() => _FamilyGroupPageState();
}

class _FamilyGroupPageState extends ConsumerState<FamilyGroupPage> {
  final _joinCodeController = TextEditingController();
  final _createGroupController = TextEditingController();
  late ScrollController _scrollController;
  bool _isFabExtended = true;
  Timer? _hideTimer;
  bool _isLoading = false;


  String? _joinError;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isFabExtended) {
        setState(() => _isFabExtended = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hideTimer?.cancel();
    _joinCodeController.dispose();
    _createGroupController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDarkMode ? Colors.red.shade900 : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDarkMode
            ? AppColors.primaryDark
            : Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleJoin() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (ref.read(userNameProvider).isEmpty) {
      showNameSetupSheet(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _joinError = null;
    });
    try {
      await ref.read(familyGroupServiceProvider).joinGroup(code);
      _joinCodeController.clear();
      _showSuccess('Berhasil bergabung ke keluarga!');
    } catch (e) {
      setState(() => _joinError = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreate() async {
    if (ref.read(userNameProvider).isEmpty) {
      showNameSetupSheet(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? createError;
        bool isCreating = false;
        final isDarkMode =
            ref.watch(themeProvider) == ThemeMode.dark ||
            (ref.watch(themeProvider) == ThemeMode.system &&
                Theme.of(context).brightness == Brightness.dark);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Buat Grup Keluarga',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beri nama grup untuk keluarga kamu.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white38 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _createGroupController,
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Tabungan Liburan Keluarga',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white24 : Colors.grey,
                      ),
                      prefixIcon: Icon(
                        Icons.group,
                        color: isDarkMode
                            ? AppColors.primary
                            : AppColors.primary,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isCreating
                          ? null
                          : () async {
                              final name = _createGroupController.text.trim();
                              if (name.isEmpty) return;
                              setModalState(() {
                                isCreating = true;
                                createError = null;
                              });
                              try {
                                await ref
                                    .read(familyGroupServiceProvider)
                                    .createGroup(name);
                                _createGroupController.clear();
                                if (context.mounted) Navigator.pop(context);
                                _showSuccess('Keluarga baru berhasil dibuat!');
                              } catch (e) {
                                setModalState(() {
                                  createError = e.toString().replaceAll(
                                    "Exception: ",
                                    "",
                                  );
                                });
                              } finally {
                                if (mounted)
                                  setModalState(() => isCreating = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isCreating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Buat Sekarang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddFamilyTransaction(
    FamilyGroupModel group, {
    TransactionModel? existingTx,
  }) async {
    final groupId = group.id;

    final amountController = TextEditingController(
      text: existingTx != null ? _formatNumberWithDots(existingTx.amount) : '',
    );
    final customCategoryController = TextEditingController(
      text:
          existingTx != null &&
              ![
                'Tabungan',
                'Belanja Bulanan',
                'Listrik & Air',
                'Pendidikan',
                'Kesehatan',
                'Cicilan & Hutang',
                'Transportasi',
                'Kebutuhan Anak',
                'Dana Darurat',
                'Hiburan & Liburan',
                'Renovasi Rumah',
                'Sosial & Zakat',
              ].contains(existingTx.category)
          ? existingTx.category
          : '',
    );

    String selectedCategory = existingTx?.category ?? 'Tabungan';
    TransactionType selectedType = existingTx?.type ?? TransactionType.income;
    final userName = ref.read(userNameProvider);


    if (existingTx != null &&
        ![
          'Tabungan',
          'Belanja Bulanan',
          'Listrik & Air',
          'Pendidikan',
          'Kesehatan',
          'Cicilan & Hutang',
          'Transportasi',
          'Kebutuhan Anak',
          'Dana Darurat',
          'Hiburan & Liburan',
          'Renovasi Rumah',
          'Sosial & Zakat',
        ].contains(existingTx.category)) {
      selectedCategory = 'Lainnya';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDarkMode =
              ref.watch(themeProvider) == ThemeMode.dark ||
              (ref.watch(themeProvider) == ThemeMode.system &&
                  Theme.of(context).brightness == Brightness.dark);
          final inset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: inset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Center(
                        child: Text(
                          existingTx != null
                              ? 'Edit Transaksi Keluarga'
                              : 'Tambah Transaksi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),


                    if (existingTx == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeToggleItem(
                                  'Pemasukan',
                                  TransactionType.income,
                                  selectedType,
                                  Colors.green,
                                  isDarkMode,
                                  () => setModalState(
                                    () => selectedType = TransactionType.income,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildTypeToggleItem(
                                  'Pengeluaran',
                                  TransactionType.expense,
                                  selectedType,
                                  Colors.red,
                                  isDarkMode,
                                  () => setModalState(
                                    () =>
                                        selectedType = TransactionType.expense,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),


                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: Container(
                            padding: const EdgeInsets.only(left: 20, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payments_rounded,
                                  color: selectedType == TransactionType.income
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        selectedType == TransactionType.income
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
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
                    ),
                    const SizedBox(height: 20),


                    if (existingTx == null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          'KATEGORI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          dropdownColor: isDarkMode
                              ? AppColors.surfaceDark
                              : Colors.white,
                          decoration: InputDecoration(
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
                            prefixIcon: const Icon(
                              Icons.category_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          items:
                              [
                                'Tabungan',
                                'Belanja Bulanan',
                                'Listrik & Air',
                                'Pendidikan',
                                'Kesehatan',
                                'Cicilan & Hutang',
                                'Transportasi',
                                'Kebutuhan Anak',
                                'Dana Darurat',
                                'Hiburan & Liburan',
                                'Renovasi Rumah',
                                'Sosial & Zakat',
                                'Lainnya',
                              ].map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setModalState(() => selectedCategory = newValue);
                            }
                          },
                        ),
                      ),

                      if (selectedCategory == 'Lainnya') ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: TextField(
                            controller: customCategoryController,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nama Kategori Kustom',
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amountText = amountController.text.replaceAll(
                              '.',
                              '',
                            );
                            final amount = double.tryParse(amountText) ?? 0;
                            if (amount <= 0) return;

                            String finalCategory = selectedCategory;
                            if (selectedCategory == 'Lainnya' &&
                                customCategoryController.text.isNotEmpty) {
                              finalCategory = customCategoryController.text
                                  .trim();
                            }

                            final title =
                                "${selectedType == TransactionType.income ? 'Pemasukan' : 'Pengeluaran'} $finalCategory";

                            if (existingTx != null) {
                              final updatedTx = existingTx.copyWith(
                                amount: amount,
                                category: finalCategory,
                                title: title,
                                description: finalCategory,
                                type: selectedType,
                              );
                              await ref
                                  .read(transactionServiceProvider)
                                  .updateTransaction(updatedTx);
                              if (context.mounted) Navigator.pop(context);
                              _showSuccess('Transaksi diperbarui!');
                            } else {
                              final tx = TransactionModel(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                title: title,
                                description: finalCategory,
                                amount: amount,
                                type: selectedType,
                                date: DateTime.now(),
                                category: finalCategory,
                                groupId: groupId,
                                creatorName: userName,
                              );
                              await ref
                                  .read(transactionServiceProvider)
                                  .addTransaction(tx);
                              if (context.mounted) Navigator.pop(context);
                              _showSuccess('Transaksi dicatat!');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedType == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            existingTx != null
                                ? 'Simpan Perubahan'
                                : 'Catat Sekarang',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeToggleItem(
    String label,
    TransactionType type,
    TransactionType selected,
    Color color,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white38 : Colors.black38),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumberWithDots(double value) {
    final rounded = value.round();
    return rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  String _formatK(double amount) {
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';

    if (absAmount >= 1000000) {
      return '$sign${(absAmount / 1000000).toStringAsFixed(1).replaceAll('.0', '')} JT';
    } else if (absAmount >= 1000) {
      return '$sign${(absAmount / 1000).toStringAsFixed(1).replaceAll('.0', '')} K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final groupId = ref.watch(userGroupIdProvider);
    final groupAsync = ref.watch(familyGroupStreamProvider);


    ref.watch(familyBalanceSyncProvider);

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return ConnectivityGuard(
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.backgroundDark
            : AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Keluarga',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          elevation: 0,
          foregroundColor: isDarkMode ? Colors.white : AppColors.primaryDark,
        ),
        body: (groupId == null || groupId.isEmpty)
            ? _buildNoGroupView(userName)
            : groupAsync.when(
                data: (group) {
                  if (group == null) {

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(userGroupIdProvider.notifier).setGroupId(null);
                    });
                    return _buildNoGroupView(userName);
                  }
                  return _buildGroupDashboard(group, userName);
                },
                loading: () => _buildPremiumLoading(isDarkMode),
                error: (e, st) => _buildPremiumError(e.toString(), isDarkMode),
              ),
        floatingActionButton: (groupId != null && groupId.isNotEmpty)
            ? groupAsync.when(
                data: (group) =>
                    group != null ? _buildSmartFab(group) : const SizedBox(),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              )
            : null,
      ),
    );
  }

  Widget _buildPremiumLoading(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Container(
                    width: 100 + (20 * value),
                    height: 100 + (20 * value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: 0.1 * (1.0 - value),
                      ),
                    ),
                  );
                },
                onEnd: () {},
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.cloud_sync_rounded,
                color: AppColors.primary.withValues(alpha: 0.4),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Menghubungkan ke Cloud',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Sinkronisasi Data Keluarga...',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumError(String error, bool isDarkMode) {
    bool isNoInternet =
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('offline');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.redAccent.withValues(alpha: 0.2),
                    Colors.orangeAccent.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    isNoInternet
                        ? Icons.wifi_off_rounded
                        : Icons.cloud_off_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              isNoInternet ? 'Koneksi Terputus' : 'Gagal Terhubung',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isNoInternet
                  ? 'Ups! Sepertinya aplikasi kehilangan koneksi internet. Pastikan WiFi atau Data Seluler kamu aktif ya.'
                  : 'Terjadi kesalahan saat mencoba memuat data keluarga kamu dari cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => ref.invalidate(familyGroupStreamProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!isNoInternet)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  'Detail: $error',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFab(FamilyGroupModel group) {
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutQuart,
      height: 56,
      width: _isFabExtended ? 160 : 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.primary : AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? AppColors.primary : AppColors.primaryDark)
                .withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _showAddFamilyTransaction(group),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 24),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutQuart,
                      child: SizedBox(
                        width: _isFabExtended ? null : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: _isFabExtended ? 1 : 0,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Text(
                              'Tambah Transaksi',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoGroupView(String userName) {
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (isDarkMode ? AppColors.primary : AppColors.primaryLight)
                    .withValues(alpha: isDarkMode ? 0.2 : 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.family_restroom,
                size: 64,
                color: isDarkMode ? AppColors.primary : AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tabungan Keluarga',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.primaryDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName.isEmpty
                ? 'Halo! Silakan atur nama Anda terlebih dahulu untuk mulai menabung bersama.'
                : 'Halo, $userName!\nGabung dengan keluarga kamu atau buat grup baru sekarang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),


          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.2 : 0.04,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Buat Keluarga Baru'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode
                        ? AppColors.primary
                        : AppColors.primary,
                    side: BorderSide(
                      color: isDarkMode
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.primary,
                      width: 2,
                    ),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _handleCreate,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade300,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 2,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ketik Kode',
                    errorText: _joinError,
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                      letterSpacing: 0,
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.primary
                        : AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Gabung dengan Kode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDashboard(FamilyGroupModel group, String userName) {

    final prefixes = [
      'Sultan',
      'Jagoan',
      'Pejuang',
      'Juragan',
      'Master',
      'Pendekar',
      'Bintang',
    ];
    final suffixes = [
      'Hemat',
      'Cuan',
      'Tabung',
      'MasaDepan',
      'Bijak',
      'Sukses',
    ];
    String? randomNameInGroup;
    for (var m in group.members) {
      for (var p in prefixes) {
        for (var s in suffixes) {
          if (m == '$p $s') {
            randomNameInGroup = m;
            break;
          }
        }
        if (randomNameInGroup != null) break;
      }
      if (randomNameInGroup != null) break;
    }

    final needsSync =
        !group.members.contains(userName) && randomNameInGroup != null;

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final groupTransactions = ref.watch(transactionsByGroupProvider(group.id));

    final totalIn = groupTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalOut = groupTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needsSync)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_problem_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinkronisasi Nama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.orange
                                : Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          'Gunakan nama "$userName" di grup ini?',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.orange.withValues(alpha: 0.7)
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      _showSuccess('Memperbarui nama di grup...');
                      await ref
                          .read(familyGroupServiceProvider)
                          .trySyncMemberName(userName);
                    },
                    child: Text(
                      'Sinkron',
                      style: TextStyle(
                        color: isDarkMode ? Colors.orange : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildFamilyBalanceCard(group, totalIn, totalOut, isDarkMode),
          const SizedBox(height: 24),
          _buildFamilyAllocationSection(
            totalIn,
            totalOut,
            groupTransactions,
            isDarkMode,
            group.totalGroupSavings,
          ),
          const SizedBox(height: 32),
          _buildMemberSection(group, userName, isDarkMode),
          const SizedBox(height: 32),
          _buildFamilyRecentActivity(
            groupTransactions,
            isDarkMode,
            group,
            userName,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyBalanceCard(
    FamilyGroupModel group,
    double totalIn,
    double totalOut,
    bool isDarkMode,
  ) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.withValues(
                  alpha: isDarkMode ? 0.05 : 0.08,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        group.name.toUpperCase(),
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                          color: isDarkMode
                              ? Colors.white30
                              : Colors.indigo.shade800.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                      onPressed: () async {
                        final act = await showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: isDarkMode
                                ? AppColors.surfaceDark
                                : Colors.white,
                            title: const Text('Keluar Grup?'),
                            content: const Text(
                              'Kamu akan menghapus aksesmu dari grup ini secara lokal.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text(
                                  'Keluar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (act == true) {
                          await ref
                              .read(familyGroupServiceProvider)
                              .leaveGroup();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatCurrency.format(group.totalGroupSavings),
                    style: GoogleFonts.comicNeue(
                      color: isDarkMode ? Colors.white : Colors.indigo.shade900,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.indigo.shade50.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PEMASUKAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${_formatK(totalIn)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PENGELUARAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${_formatK(totalOut)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.indigo.shade50.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KODE GABUNG',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.code,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: group.code));
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyAllocationSection(
    double totalIn,
    double totalOut,
    List<TransactionModel> transactions,
    bool isDarkMode,
    double balance,
  ) {
    final totalVal = totalIn + totalOut;
    final inP = totalVal > 0
        ? (totalIn / totalVal * 100).toStringAsFixed(0)
        : "0";
    final outP = totalVal > 0
        ? (totalOut / totalVal * 100).toStringAsFixed(0)
        : "0";

    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALOKASI DANA BERSAMA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: totalIn > 0 ? totalIn : 1,
                        radius: 14,
                        title: '$inP%',
                        showTitle: true,
                        titlePositionPercentageOffset: 2.2,
                        titleStyle: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: totalOut > 0 ? totalOut : 0,
                        radius: 14,
                        title: '$outP%',
                        showTitle: true,
                        titlePositionPercentageOffset: 2.2,
                        titleStyle: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.family_restroom_rounded,
                  color: isDarkMode ? Colors.white10 : Colors.indigo.shade50,
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildTableRowFamily(
                'Pemasukan',
                totalIn,
                Colors.green,
                isDarkMode,
              ),
              _buildTableRowFamily(
                'Pengeluaran',
                totalOut,
                Colors.red,
                isDarkMode,
              ),
              _buildTableRowFamily(
                'Total Saldo bersama',
                balance,
                Colors.indigo,
                isDarkMode,
                isTotal: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRowFamily(
    String label,
    double val,
    Color color,
    bool isDarkMode, {
    bool isTotal = false,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(),
        Text(
          'Rp ${_formatK(val)}',
          textAlign: TextAlign.right,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSection(
    FamilyGroupModel group,
    String userName,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANGGOTA KELUARGA',
          style: GoogleFonts.comicNeue(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: group.members.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final member = group.members[index];
              final isCurrent = member == userName;
              final balance = group.memberBalances[member] ?? 0.0;
              final photoUrl = group.memberPhotos[member];

              return Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : Colors.grey.withValues(alpha: 0.1),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCurrent ? AppColors.primary : Colors.black)
                              .withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? (photoUrl.startsWith('http')
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 32),
                                    )
                                  : Image.file(
                                      File(photoUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 32),
                                    ))
                            : Icon(
                                Icons.person,
                                size: 32,
                                color: isCurrent
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isCurrent ? 'Anda' : member.split(' ')[0],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Rp ${_formatK(balance)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyRecentActivity(
    List<TransactionModel> transactions,
    bool isDarkMode,
    FamilyGroupModel group,
    String userName,
  ) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRANSPARANSI RIWAYAT',
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.grey,
              ),
            ),
            const Icon(Icons.security_rounded, size: 14, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        ...transactions
            .take(10)
            .map((t) => _familyTransactionTile(t, isDarkMode, group, userName)),
      ],
    );
  }

  Widget _familyTransactionTile(
    TransactionModel t,
    bool isDarkMode,
    FamilyGroupModel group,
    String currentUserName,
  ) {
    final bool isExpense = t.type == TransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;
    final creator = t.creatorName ?? "System";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showTransactionActions(context, ref, t, isDarkMode, group);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.description.isNotEmpty
                                ? t.description
                                : t.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (creator.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (creator == currentUserName
                                          ? Colors.indigo
                                          : Colors.orange)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (creator == currentUserName
                                            ? Colors.indigo
                                            : Colors.orange)
                                        .withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_pin_rounded,
                                  size: 13,
                                  color: creator == currentUserName
                                      ? Colors.indigo
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  creator == currentUserName
                                      ? 'Oleh Anda'
                                      : 'Oleh $creator',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: creator == currentUserName
                                        ? Colors.indigo
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(t.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? Colors.white38
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '- ' : '+ '}${_formatK(t.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionActions(
    BuildContext context,
    WidgetRef ref,
    TransactionModel t,
    bool isDarkMode,
    FamilyGroupModel group,
  ) {
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
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Opsi Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.blue),
              ),
              title: const Text(
                'Edit Catatan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddFamilyTransaction(group, existingTx: t);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
              title: const Text(
                'Hapus Catatan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, t.id);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Tindakan ini tidak bisa dibatalkan dan akan berpengaruh ke saldo keluarga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(transactionServiceProvider).deleteTransaction(id);
              if (context.mounted) Navigator.pop(context);
              _showSuccess('Transaksi berhasil dihapus');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
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
