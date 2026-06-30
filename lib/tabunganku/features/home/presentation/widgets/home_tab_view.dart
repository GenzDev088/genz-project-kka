import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:otax/tabunganku/core/routing/app_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:otax/tabunganku/core/constants/quick_action_type.dart';
import '../../../../core/constants/app_version.dart';
import 'package:otax/tabunganku/core/constants/transaction_categories.dart';
import 'package:otax/tabunganku/models/gold_investment_model.dart';
import 'package:otax/tabunganku/providers/gold_provider.dart';
import 'package:otax/tabunganku/providers/bills_provider.dart';
import 'package:otax/tabunganku/providers/investment_provider.dart';
import 'package:otax/tabunganku/providers/insurance_provider.dart';

class HomeTabView extends ConsumerStatefulWidget {
  final bool showBalance;
  final VoidCallback onToggleBalance;
  final Function(TransactionModel) onTransactionTap;
  final Function(SavingTargetModel, double) onTargetTap;
  final Function(QuickActionType) onActionTap;

  const HomeTabView({
    super.key,
    required this.showBalance,
    required this.onToggleBalance,
    required this.onTransactionTap,
    required this.onTargetTap,
    required this.onActionTap,
  });

  @override
  ConsumerState<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends ConsumerState<HomeTabView> {
  int _currentTargetIndex = 0;

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {

    final personalTransactions = ref.watch(transactionsByGroupProvider(null));
    final transactions = List<TransactionModel>.from(personalTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalBalance = totalIncome - totalExpense;

    final targetsAsync = ref.watch(savingTargetsStreamProvider);
    final targets = targetsAsync.valueOrNull ?? [];


    final goldTxs = ref.watch(goldTransactionsStreamProvider).valueOrNull ?? [];
    final goldGramBalance = goldTxs.fold<double>(
      0,
      (sum, t) =>
          sum + (t.type == GoldTransactionType.buy ? t.grams : -t.grams),
    );

    final bills = ref.watch(billsStreamProvider).valueOrNull ?? [];
    final unpaidBillsTotal = bills.fold<double>(
      0,
      (sum, b) => sum + (b.isPaid ? 0 : b.amount),
    );

    final investments = ref.watch(investmentStreamProvider).valueOrNull ?? [];
    final totalInvestmentValuation = investments.fold<double>(
      0,
      (sum, i) => sum + i.currentValuation,
    );

    final insurances = ref.watch(insuranceStreamProvider).valueOrNull ?? [];
    final totalMonthlyInsurance = insurances.fold<double>(
      0,
      (sum, i) => sum + i.premiumAmount,
    );

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),


          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
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
            clipBehavior: Clip.antiAlias,
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
                      color: Colors.amber.withValues(
                        alpha: isDarkMode ? 0.05 : 0.08,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'TOTAL SALDO TERKUMPUL',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                          color: isDarkMode
                              ? Colors.white30
                              : Colors.teal.shade800.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 40),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.showBalance
                                    ? _formatRupiah(totalBalance)
                                    : '••••••',
                                style: GoogleFonts.comicNeue(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.teal.shade900,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              widget.showBalance
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: isDarkMode
                                  ? Colors.white24
                                  : Colors.teal.shade700.withValues(alpha: 0.3),
                              size: 22,
                            ),
                            onPressed: widget.onToggleBalance,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildEstimationCard(
                        totalIncome,
                        totalExpense,
                        isDarkMode,
                      ),
                      const SizedBox(height: 24),


                      Container(
                        height: 1,
                        width: double.infinity,
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.teal.shade50.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),


                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _miniStat(
                              'Pemasukan',
                              totalIncome,
                              Colors.green.shade600,
                              isDarkMode,
                              center: true,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 1.2,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.teal.shade50,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _miniStat(
                              'Pengeluaran',
                              totalExpense,
                              Colors.red.shade600,
                              isDarkMode,
                              center: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40), // Lega (tidak mepet atas)

          _buildActionGrid(
            isDarkMode,
            goldGramBalance: goldGramBalance,
            unpaidBillsTotal: unpaidBillsTotal,
            totalInvestmentValuation: totalInvestmentValuation,
            totalMonthlyInsurance: totalMonthlyInsurance,
            targets: targets,
          ),

          const SizedBox(height: 32), // Seimbang (tidak terlalu rapat)
          _buildSavingTargetSection(transactions, targets, isDarkMode),

          const SizedBox(height: 12),
          _buildAllocationSection(
            totalIncome,
            totalExpense,
            transactions,
            isDarkMode,
          ),

          const SizedBox(height: 32),

          _buildRecentActivitySection(transactions, isDarkMode),

          const SizedBox(height: 60),
          _buildWatermark(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildEstimationCard(
    double totalIncome,
    double totalExpense,
    bool isDarkMode,
  ) {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final day = now.day;
    final currentDay = day > 0 ? day : 1;
    final estIncome = (totalIncome / currentDay) * totalDays;
    final estExpense = (totalExpense / currentDay) * totalDays;
    final estBalance = estIncome - estExpense;
    final isDanger = estBalance < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDanger
            ? Colors.red.withValues(alpha: 0.1)
            : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.teal.shade50.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDanger ? Icons.warning_amber_rounded : Icons.auto_graph_rounded,
              size: 14,
              color: isDanger ? Colors.red : Colors.teal,
            ),
            const SizedBox(width: 8),
            Text(
              'Estimasi Bulan Ini: ',
              style: GoogleFonts.comicNeue(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white38
                    : Colors.teal.shade900.withValues(alpha: 0.5),
              ),
            ),
            Text(
              widget.showBalance ? _formatRupiah(estBalance) : '••••••',
              style: GoogleFonts.comicNeue(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDanger
                    ? Colors.red
                    : (isDarkMode ? Colors.white70 : Colors.teal.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    String label,
    double amount,
    Color color,
    bool isDarkMode, {
    bool center = false,
  }) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.comicNeue(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.showBalance ? _formatRupiah(amount) : '••••',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.comicNeue(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: isDarkMode ? 0.9 : 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(
    bool isDarkMode, {
    required double goldGramBalance,
    required double unpaidBillsTotal,
    required double totalInvestmentValuation,
    required double totalMonthlyInsurance,
    required List<SavingTargetModel> targets,
  }) {
    final Map<QuickActionType, String> balances = {
      QuickActionType.goldSavings: goldGramBalance > 0
          ? '${goldGramBalance.toStringAsFixed(3)} Gr'
          : '',
      QuickActionType.bills: unpaidBillsTotal > 0
          ? _formatRupiah(unpaidBillsTotal)
          : '',
      QuickActionType.investment: totalInvestmentValuation > 0
          ? _formatRupiah(totalInvestmentValuation)
          : '',
      QuickActionType.insurance: totalMonthlyInsurance > 0
          ? '${_formatRupiah(totalMonthlyInsurance)}/bln'
          : '',
      QuickActionType.savingPlans: _getPlansTotal(targets),
      QuickActionType.buyingTarget: _getBuyingTotal(targets),
    };

    final primaryActions = _allActions.take(7).toList();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      crossAxisCount: 4,
      mainAxisSpacing: 24,
      crossAxisSpacing: 12,
      childAspectRatio: 0.76,
      children: [
        for (var action in primaryActions)
          _buildToolAction(
            action.icon,
            action.label,
            action.type,
            isDarkMode,
            color: action.baseColor,
            subLabel: balances[action.type],
          ),

        _buildToolAction(
          Icons.apps_rounded,
          'Lainnya',
          null, // Special case for "More"
          isDarkMode,
          color: Colors.blueGrey,
          onTap: () => ref.read(appRouterProvider).push('/all-services'),
        ),
      ],
    );
  }

  String _getPlansTotal(List<SavingTargetModel> targets) {
    final planCategories = ['Darurat', 'Pendidikan', 'Pensiun', 'Kurban'];
    final total = targets
        .where((t) => planCategories.contains(t.category))
        .fold<double>(0, (sum, t) => sum + t.targetAmount);
    return total > 0 ? _formatRupiah(total) : '';
  }

  String _getBuyingTotal(List<SavingTargetModel> targets) {
    final total = targets
        .where((t) => t.category == 'Pembelian' || t.category == 'Umum')
        .fold<double>(0, (sum, t) => sum + t.targetAmount);
    return total > 0 ? _formatRupiah(total) : '';
  }

  Widget _buildToolAction(
    IconData icon,
    String label,
    QuickActionType? type,
    bool isDarkMode, {
    required Color color,
    VoidCallback? onTap,
    String? subLabel,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => widget.onActionTap(type!),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDarkMode ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? color.withValues(alpha: 0.9) : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  static const List<_QuickActionItem> _allActions = [
    _QuickActionItem(
      icon: Icons.add_circle_outline_rounded,
      label: 'Pemasukan',
      type: QuickActionType.income,
      baseColor: Colors.green,
    ),
    _QuickActionItem(
      icon: Icons.remove_circle_outline_rounded,
      label: 'Pengeluaran',
      type: QuickActionType.expense,
      baseColor: Colors.red,
    ),
    _QuickActionItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Budget',
      type: QuickActionType.budget,
      baseColor: Colors.cyan,
    ),
    _QuickActionItem(
      icon: Icons.auto_stories_rounded,
      label: 'Pinjaman',
      type: QuickActionType.debt,
      baseColor: Colors.orange,
    ),
    _QuickActionItem(
      icon: Icons.family_restroom_rounded,
      label: 'Keluarga',
      type: QuickActionType.family,
      baseColor: Colors.indigo,
    ),
    _QuickActionItem(
      icon: Icons.shopping_cart_outlined,
      label: 'Belanja',
      type: QuickActionType.shoppingList,
      baseColor: Colors.purple,
    ),
    _QuickActionItem(
      icon: Icons.track_changes_rounded,
      label: 'Target Saya',
      type: QuickActionType.buyingTarget,
      baseColor: AppColors.primary,
    ),
    _QuickActionItem(
      icon: Icons.document_scanner_rounded,
      label: 'Scan Bukti',
      type: QuickActionType.scanReceipt,
      baseColor: Colors.teal,
    ),
    _QuickActionItem(
      icon: Icons.emoji_events_rounded,
      label: 'Challenge',
      type: QuickActionType.challenge,
      baseColor: Colors.amber,
    ),
    _QuickActionItem(
      icon: Icons.loop_rounded,
      label: 'Langganan',
      type: QuickActionType.recurring,
      baseColor: Colors.blue,
    ),
    _QuickActionItem(
      icon: Icons.volunteer_activism_rounded,
      label: 'Zakat/Infaq',
      type: QuickActionType.zakat,
      baseColor: Colors.teal,
    ),
    _QuickActionItem(
      icon: Icons.calculate_outlined,
      label: 'Simulasi',
      type: QuickActionType.simulator,
      baseColor: Colors.cyan,
    ),
    _QuickActionItem(
      icon: Icons.monetization_on_rounded,
      label: 'Nabung Emas',
      type: QuickActionType.goldSavings,
      baseColor: Colors.amber,
    ),
    _QuickActionItem(
      icon: Icons.assignment_turned_in_rounded,
      label: 'Dana Rencana',
      type: QuickActionType.savingPlans,
      baseColor: AppColors.primary,
    ),
    _QuickActionItem(
      icon: Icons.request_quote_rounded,
      label: 'Pajak',
      type: QuickActionType.tax,
      baseColor: Colors.orange,
    ),
    _QuickActionItem(
      icon: Icons.receipt_long_rounded,
      label: 'Tagihan',
      type: QuickActionType.bills,
      baseColor: Colors.lightBlue,
    ),
    _QuickActionItem(
      icon: Icons.trending_up_rounded,
      label: 'Investasi',
      type: QuickActionType.investment,
      baseColor: Colors.indigo,
    ),
    _QuickActionItem(
      icon: Icons.shield_rounded,
      label: 'Asuransi',
      type: QuickActionType.insurance,
      baseColor: Colors.blueGrey,
    ),
  ];

  Widget _buildSavingTargetSection(
    List<TransactionModel> transactions,
    List<SavingTargetModel> targets,
    bool isDarkMode,
  ) {

    final buyingTargets = targets
        .where((t) => t.category == 'Pembelian' || t.category == 'Umum')
        .toList();
    final bool isEmpty = buyingTargets.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target Pembelian Saya',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white30
                    : AppColors.primaryDark.withValues(alpha: 0.4),
              ),
            ),
            if (buyingTargets.length > 1)
              Text(
                '${buyingTargets.length} Barang Impian',
                style: GoogleFonts.comicNeue(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (isEmpty)
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 32,
                  color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada target barang impian',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 180,
            child: PageView.builder(
              itemCount: buyingTargets.length,
              onPageChanged: (idx) => setState(() => _currentTargetIndex = idx),
              itemBuilder: (context, index) {
                final target = buyingTargets[index];
                return _targetCardMinimalist(
                  target,
                  transactions,
                  isDarkMode,
                  index,
                );
              },
            ),
          ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(buyingTargets.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentTargetIndex == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentTargetIndex == index
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _targetCardMinimalist(
    SavingTargetModel target,
    List<TransactionModel> transactions,
    bool isDarkMode,
    int index,
  ) {

    final targetBalance = transactions
        .where((t) => !t.date.isBefore(target.createdAt))
        .fold<double>(
          0,
          (s, t) => s + (t.type == TransactionType.income ? t.amount : 0),
        );

    final progress = (target.targetAmount > 0)
        ? (targetBalance / target.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => widget.onTargetTap(target, targetBalance),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [

              const Positioned(
                top: -20,
                right: -20,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 100,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target #${index + 1}',
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              target.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.comicNeue(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.comicNeue(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ 100%',
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.showBalance
                          ? '${_formatRupiah(targetBalance)} / ${_formatRupiah(target.targetAmount)}'
                          : '••••••',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white38
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationSection(
    double totalIncome,
    double totalExpense,
    List<TransactionModel> transactions,
    bool isDarkMode,
  ) {
    final bool isEmpty = totalIncome == 0 && totalExpense == 0;

    final actualTotal = totalIncome + totalExpense;
    final totalVal = isEmpty ? 1.0 : actualTotal;
    final incomePercent = isEmpty
        ? '0'
        : (totalIncome / totalVal * 100).toStringAsFixed(0);
    final expensePercent = isEmpty
        ? '0'
        : (totalExpense / totalVal * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20), // More compact padding
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALOKASI PENGELUARAN',
                style: GoogleFonts.comicNeue(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isDarkMode
                      ? Colors.white30
                      : Colors.teal.shade800.withValues(alpha: 0.4),
                ),
              ),
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 16,
                color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 32
          Column(
            children: [

              SizedBox(
                height: 210, // Keeping chart size as requested
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        sections: isEmpty
                            ? [
                                PieChartSectionData(
                                  color: isDarkMode
                                      ? Colors.white10
                                      : Colors.grey.shade100,
                                  value: 1,
                                  radius: 12,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                if (totalIncome > 0)
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: totalIncome,
                                    radius: 14,
                                    title: '$incomePercent%',
                                    showTitle: true,
                                    titlePositionPercentageOffset: 2.2,
                                    titleStyle: GoogleFonts.comicNeue(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.green.shade300
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                if (totalExpense > 0)
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: totalExpense,
                                    radius: 14,
                                    title: '$expensePercent%',
                                    showTitle: true,
                                    titlePositionPercentageOffset: 2.2,
                                    titleStyle: GoogleFonts.comicNeue(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.red.shade300
                                          : Colors.red.shade700,
                                    ),
                                  ),
                              ],
                      ),
                    ),
                    if (isEmpty)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 24,
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Belum Ada Data',
                            style: GoogleFonts.comicNeue(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      )
                    else
                      Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        size: 20,
                        color: isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade100,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12), // Reduced from 24

              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1.5),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _buildTableRow(
                      'Pemasukan',
                      totalIncome,
                      Colors.green,
                      isDarkMode,
                    ),
                    _buildTableRow(
                      'Pengeluaran',
                      totalExpense,
                      Colors.red,
                      isDarkMode,
                    ),
                    _buildTableRow(
                      'Total Alokasi',
                      actualTotal,
                      isDarkMode ? Colors.white : Colors.black87,
                      isDarkMode,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Reduced from 32
              _buildCategoryBreakdown(transactions, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    double val,
    Color color,
    bool isDarkMode, {
    bool isTotal = false,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                style: GoogleFonts.comicNeue(
                  fontSize: 13,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(), // Spacer column
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _formatRupiah(val),
              textAlign: TextAlign.right,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
    List<TransactionModel> transactions,
    bool isDarkMode,
  ) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Belum Ada Pengeluaran',
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
                Text(
                  '0.0%',
                  style: GoogleFonts.comicNeue(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0,
                backgroundColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                color: Colors.grey.shade300,
                minHeight: 4.5,
              ),
            ),
          ],
        ),
      );
    }


    final categoryMap = <String, double>{};
    for (var t in expenses) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
    }

    final totalExp = categoryMap.values.fold(0.0, (sum, val) => sum + val);
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedCategories.take(4).map((entry) {
        final percentage = entry.value / totalExp;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppCategories.getColorForCategory(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        entry.key,
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.comicNeue(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: isDarkMode
                      ? Colors.white10
                      : Colors.grey.shade100,
                  color: AppCategories.getColorForCategory(entry.key),
                  minHeight: 4.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivitySection(
    List<TransactionModel> transactions,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas Terakhir',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 24,
                  color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada aktivitas baru-baru ini',
                  style: GoogleFonts.comicNeue(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                ),
              ],
            ),
          )
        else
          ...transactions.take(3).map((t) => _minimalTile(t, isDarkMode)),
      ],
    );
  }

  Widget _minimalTile(TransactionModel t, bool isDarkMode) {
    final bool isExpense = t.type == TransactionType.expense;
    final IconData icon = isExpense
        ? Icons.arrow_outward_rounded
        : Icons.call_received_rounded;
    final Color color = isExpense ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => widget.onTransactionTap(t),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(t.date),
                        style: GoogleFonts.comicNeue(
                          fontSize: 10,
                          color: isDarkMode ? Colors.white38 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '- ' : '+ '}${_formatRupiah(t.amount)}',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatermark(bool isDarkMode) {
    return Center(
      child: Opacity(
        opacity: 0.4,
        child: Column(
          children: [
            Text(
              'MANTAX APK',
              style: GoogleFonts.comicNeue(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppVersion.fullVersion,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final QuickActionType type;
  final Color baseColor;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.type,
    required this.baseColor,
  });
}
