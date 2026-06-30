import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/budget_model.dart';
import 'package:otax/tabunganku/providers/budget_provider.dart';
import 'package:otax/tabunganku/core/utils/currency_formatter.dart';
import 'package:otax/tabunganku/core/constants/transaction_categories.dart';



class BudgetFormSheet extends ConsumerStatefulWidget {
  final BudgetModel? budget;
  final String? initialCategory;

  const BudgetFormSheet({super.key, this.budget, this.initialCategory});

  static Future<void> show(
    BuildContext context, {
    BudgetModel? budget,
    String? initialCategory,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BudgetFormSheet(budget: budget, initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedCategory;
  String? _selectedGroup;
  bool _isCustomCategory = false;

  static final _fixedCategories = AppCategories.expenseCategories
      .map((c) => {'label': c.label, 'icon': c.icon})
      .toList();

  final Map<String, List<TransactionCategory>> groupedCategories = {};

  @override
  void initState() {
    super.initState();


    for (var cat in AppCategories.expenseCategories) {
      groupedCategories.putIfAbsent(cat.group, () => []).add(cat);
    }

    if (widget.budget != null) {
      final rawAmount = widget.budget!.limitAmount.toInt().toString();

      final formatted = rawAmount.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      _amountController.text = formatted;

      final existingCat = widget.budget!.category;
      final isKnown =
          _fixedCategories.any((c) => c['label'] == existingCat) &&
          existingCat != AppCategories.otherLabel;
      if (isKnown) {
        _selectedCategory = existingCat;
        _isCustomCategory = false;

        _selectedGroup = AppCategories.expenseCategories
            .firstWhere((c) => c.label == existingCat)
            .group;
      } else {
        _selectedCategory = AppCategories.otherLabel;
        _isCustomCategory = true;
        _customCategoryController.text = existingCat == AppCategories.otherLabel
            ? ''
            : existingCat;
        _selectedGroup = AppCategories.expenseCategories
            .firstWhere((c) => c.label == AppCategories.otherLabel)
            .group;
      }
    } else if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      try {
        _selectedGroup = AppCategories.expenseCategories
            .firstWhere((c) => c.label == _selectedCategory)
            .group;
      } catch (_) {
        _selectedGroup = AppCategories.expenseCategories.first.group;
      }
    } else {

      _selectedCategory = 'Makanan & Minuman';
      _selectedGroup = 'Kebutuhan Pokok';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  String get _effectiveCategory {
    if (_isCustomCategory) {
      final custom = _customCategoryController.text.trim();
      return custom.isEmpty ? AppCategories.otherLabel : custom;
    }
    return _selectedCategory ?? '';
  }

  Future<void> _saveBudget() async {
    final amountRaw = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '');
    final amount = double.tryParse(amountRaw) ?? 0;
    if (amount <= 0) return;
    if (_effectiveCategory.isEmpty) return;

    final now = DateTime.now();
    final budget = BudgetModel(
      id:
          widget.budget?.id ??
          'budget_${DateTime.now().millisecondsSinceEpoch}',
      category: _effectiveCategory,
      limitAmount: amount,
      month: now.month,
      year: now.year,
    );

    await ref.read(budgetServiceProvider).saveBudget(budget);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteBudget() async {
    if (widget.budget == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Budget?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hapus budget kategori "${widget.budget!.category}"?\nLangkah ini tidak bisa dibatalkan.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(budgetServiceProvider).deleteBudget(widget.budget!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.budget != null;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: inset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_calendar_rounded
                          : Icons.add_chart_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Perbarui Budget' : 'Budget Baru',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Atur batas pengeluaran bulanan Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.white38
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      onPressed: _deleteBudget,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      tooltip: 'Hapus budget ini',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [

                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    isExpanded: true,
                    dropdownColor: isDarkMode
                        ? AppColors.surfaceDark
                        : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Grup Kategori',
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.primary,
                      ),
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    items: groupedCategories.keys
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(
                              group,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGroup = val;
                          _selectedCategory =
                              groupedCategories[val]!.first.label;
                          _isCustomCategory =
                              _selectedCategory == AppCategories.otherLabel;
                        });
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: isDarkMode
                        ? AppColors.surfaceDark
                        : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Kategori Budget',
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        AppCategories.expenseCategories
                            .firstWhere((c) => c.label == _selectedCategory)
                            .icon,
                        color: AppColors.primary,
                      ),
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    items: groupedCategories[_selectedGroup]!
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat.label,
                            child: Text(
                              cat.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          _isCustomCategory = val == AppCategories.otherLabel;
                        });
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ],
              ),
            ),


            if (_isCustomCategory) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _customCategoryController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori Kustom',
                    hintText: 'Misal: Gym, Netflix, Skincare...',
                    prefixIcon: const Icon(
                      Icons.label_outline_rounded,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limit Anggaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              RibuanFormatter(),
                            ],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 10,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing
                            ? Icons.update_rounded
                            : Icons.check_circle_rounded,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Perbarui Anggaran' : 'Simpan Anggaran',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
