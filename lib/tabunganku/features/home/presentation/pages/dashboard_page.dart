import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:otax/tabunganku/main.dart' show flutterLocalNotificationsPlugin;
import 'package:otax/tabunganku/core/providers/module_providers.dart';
import 'package:otax/tabunganku/core/routing/app_router.dart';
import 'package:otax/tabunganku/services/recurring_service.dart';
import 'package:otax/tabunganku/providers/transaction_provider.dart';
import 'package:otax/tabunganku/providers/family_group_provider.dart';
import 'package:otax/tabunganku/features/transaction/presentation/widgets/transaction_detail_sheet.dart';
import 'package:otax/tabunganku/features/friends/presentation/pages/family_group_page.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/features/transaction/presentation/pages/debt_list_page.dart';
import 'package:otax/tabunganku/features/shopping/presentation/pages/shopping_list_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/features/settings/presentation/pages/settings_page.dart';
import 'package:otax/tabunganku/features/transaction/presentation/pages/recurring_list_page.dart';
import 'package:otax/tabunganku/core/utils/currency_formatter.dart';
import 'package:otax/tabunganku/core/services/export_service.dart';
import 'package:otax/tabunganku/features/home/presentation/widgets/smart_clock_widgets.dart';
import 'package:otax/tabunganku/core/constants/quick_action_type.dart';
import 'package:otax/tabunganku/features/home/presentation/widgets/home_tab_view.dart'
    as widgets;
import 'package:otax/tabunganku/providers/notification_provider.dart';
import 'package:otax/tabunganku/features/home/presentation/widgets/notification_sheet.dart';
import 'package:otax/tabunganku/core/constants/transaction_categories.dart';

import 'package:otax/tabunganku/providers/bills_provider.dart';
import 'package:otax/tabunganku/models/bill_model.dart';
import 'package:otax/tabunganku/features/home/presentation/widgets/connectivity_guard.dart';
import 'package:otax/tabunganku/providers/gold_provider.dart';
import 'package:otax/tabunganku/providers/investment_provider.dart';
import 'package:otax/tabunganku/models/gold_investment_model.dart';
import 'package:otax/tabunganku/models/investment_model.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _showBalance = true;
  final PageController _targetPageController = PageController();



  void _showSavingSimulatorSheet() {
    ref.read(appRouterProvider).push('/saving-simulator');
  }

  Future<void> _deleteSavingTarget(String? targetId) async {
    if (targetId == null) return;
    await ref.read(savingTargetServiceProvider).deleteTarget(targetId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Target tabungan dihapus.')));
    }
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSheet(),
    );
  }







  
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      await Future.delayed(const Duration(milliseconds: 500));
      await _loadLocalData();

      await ref.read(recurringServiceProvider).processRecurring();
    });
  }

  @override
  void dispose() {
    _targetPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeUserId = 'default_user';
    if (_loadedUserId != activeUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLocalData();
      });
    }


    final personalTransactions = ref.watch(transactionsByGroupProvider(null));




    final transactionsAsync = AsyncValue.data(personalTransactions);
    final transactions = List<TransactionModel>.from(personalTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final themeMode = ref.watch(themeProvider);
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;


        final currentTab = ref.read(dashboardTabIndexProvider);
        if (currentTab != 0) {
          ref.read(dashboardTabIndexProvider.notifier).state = 0;
          return;
        }


        final onExit = ref.read(moduleExitProvider);
        if (onExit != null) {
          onExit();
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            size: 20,
          ),
          onPressed: () {

            final navigator = rootNavigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
              return;
            }


            if (ref.read(dashboardTabIndexProvider) != 0) {
              ref.read(dashboardTabIndexProvider.notifier).state = 0;
              return;
            }


            final onExit = ref.read(moduleExitProvider);
            if (onExit != null) {
              onExit();
            }
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: CustomPaint(
            painter: _HeaderPainter(
              color: AppColors.primary.withValues(
                alpha: isDarkMode ? 0.05 : 0.03,
              ),
              isDarkMode: isDarkMode,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _navItems[ref.watch(dashboardTabIndexProvider)].label,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  if (ref.watch(dashboardTabIndexProvider) != 3) ...[
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SmartDateDisplay(isDarkMode: isDarkMode),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (ref.watch(dashboardTabIndexProvider) != 3)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SmartDigitalClock(isDarkMode: isDarkMode),
              ),
          ],
        ),
        actions: [
          if (ref.watch(dashboardTabIndexProvider) == 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Consumer(
                builder: (context, ref, child) {
                  final unreadCountAsync = ref.watch(
                    unreadNotificationsCountProvider,
                  );
                  return Badge(
                    label: unreadCountAsync.maybeWhen(
                      data: (count) =>
                          count > 0 ? Text(count.toString()) : null,
                      orElse: () => null,
                    ),
                    isLabelVisible: unreadCountAsync.maybeWhen(
                      data: (count) => count > 0,
                      orElse: () => false,
                    ),
                    backgroundColor: AppColors.primary,
                    offset: const Offset(-4, 4),
                    child: IconButton(
                      onPressed: _showNotificationSheet,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: () {
        final index = ref.watch(dashboardTabIndexProvider);
        switch (index) {
          case 0:
            return widgets.HomeTabView(
              showBalance: _showBalance,
              onToggleBalance: () => setState(() => _showBalance = !_showBalance),
              onTransactionTap: _showTransactionDetailSheet,
              onTargetTap: _showTargetDetailSheet,
              onActionTap: (type) => _handleQuickActionTap(
                _QuickAction(icon: Icons.add, label: '', type: type),
              ),
            );
          case 1:
            return _buildFinanceTab(transactionsAsync, transactions);
          case 2:
            return _buildHistoryTab(transactionsAsync, transactions);
          case 3:
            return const SettingsPage();
          default:
            return const SizedBox.shrink();
        }
      }(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 100, // Slightly taller for more airy feel
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                  child: Row(
                    children: [
                      _buildNavItem(0),
                      _buildNavItem(1),
                      const SizedBox(width: 72), // Space for center button
                      _buildNavItem(2),
                      _buildNavItem(3),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 0,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showCalculatorSheet(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryLight, AppColors.primary],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(
                                0x4D00BFA5,
                              ), // AppColors.primary with alpha 0.3
                              blurRadius: 15,
                              offset: Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 4,
                          ),
                        ),
                        child: const Icon(
                          Icons.calculate_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kalkulator',
                      style: GoogleFonts.comicNeue(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }



  Future<void> _loadLocalData() async {
    const userId = 'default_user';
    final prefs = await SharedPreferences.getInstance();


    const migrationKey =
        'migration_saving_target_v3_done_$userId'; // Use v3 to be sure
    if (prefs.getBool(migrationKey) != true) {
      final oldAmount = prefs.getString('saving_target_amount_$userId');
      final oldItem = prefs.getString('saving_target_item_$userId');
      final oldDueRaw = prefs.getString('saving_target_due_$userId');

      if (oldAmount != null && oldItem != null && oldDueRaw != null) {
        final oldDue = DateTime.tryParse(oldDueRaw);
        if (oldDue != null) {

          final target = SavingTargetModel(
            id: 'legacy_${DateTime.now().millisecondsSinceEpoch}',
            name: oldItem,
            targetAmount: _toAmount(oldAmount) ?? 0,
            dueDate: oldDue,
            createdAt: DateTime.now(),
          );
          await ref.read(savingTargetServiceProvider).addTarget(target);


          await prefs.setBool(migrationKey, true);


          await prefs.remove('saving_target_amount_$userId');
          await prefs.remove('saving_target_item_$userId');
          await prefs.remove('saving_target_due_$userId');
        } else {
          await prefs.setBool(
            migrationKey,
            true,
          ); // Even if invalid, don't retry forever
        }
      } else {
        await prefs.setBool(migrationKey, true); // Nothing to migrate
      }
    }

    if (!mounted) return;
    setState(() {
      _loadedUserId = userId;
    });

    final targets = await ref.read(savingTargetServiceProvider).getTargets();
    for (final t in targets) {
      await _maybeShowTargetReminder(userId, t);
    }
  }

  Future<void> _maybeShowTargetReminder(
    String userId,
    SavingTargetModel target,
  ) async {
    final remaining = target.dueDate.difference(DateTime.now()).inDays;
    if (remaining < 0 || remaining > 3) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final notifiedKey = 'saving_target_notified_${target.id}_day_$userId';
    if (prefs.getString(notifiedKey) == todayKey) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'saving_target_channel_v2',
        'Saving Target Reminder',
        channelDescription: 'Pengingat target tabungan',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      target.id.hashCode,
      'Target Tabungan Hampir Jatuh Tempo',
      'Sisa $remaining hari untuk target ${target.name} (${_formatRupiah(target.targetAmount)})',
      details,
    );
    await prefs.setString(notifiedKey, todayKey);
  }

  Future<void> _handleQuickActionTap(_QuickAction action) async {
    switch (action.type) {
      case QuickActionType.expense:
        await _showManualTransactionSheet(TransactionType.expense);
        break;
      case QuickActionType.income:
        await _showManualTransactionSheet(TransactionType.income);
        break;
      case QuickActionType.savingTarget:
        final txs = ref.read(transactionsByGroupProvider(null));
        final bal = txs.fold<double>(
          0,
          (sum, t) => sum + (t.type == TransactionType.income ? t.amount : 0),
        );
        await _showSavingTargetDialog(bal);
        break;
      case QuickActionType.buyingTarget:
        ref.read(appRouterProvider).push('/buying-targets');
        break;
      case QuickActionType.budget:
        ref.read(appRouterProvider).push('/monthly-budget');
        break;
      case QuickActionType.calculator:
        _showCalculatorSheet();
        break;
      case QuickActionType.history:
        ref.read(dashboardTabIndexProvider.notifier).state = 2;
        break;
      case QuickActionType.simulator:
        _showSavingSimulatorSheet();
        break;
      case QuickActionType.family:
        ref.read(appRouterProvider).push('/family-group');
        break;
      case QuickActionType.debt:
        ref.read(appRouterProvider).push('/debts');
        break;
      case QuickActionType.shoppingList:
        ref.read(appRouterProvider).push('/shopping');
        break;
      case QuickActionType.scanReceipt:
        ref.read(appRouterProvider).push('/scan-receipt');
        break;
      case QuickActionType.challenge:
        ref.read(appRouterProvider).push('/challenge');
        break;
      case QuickActionType.recurring:
        ref.read(appRouterProvider).push('/recurring');
        break;
      case QuickActionType.zakat:
        ref.read(appRouterProvider).push('/zakat');
        break;
      case QuickActionType.goldSavings:
        ref.read(appRouterProvider).push('/gold');
        break;
      case QuickActionType.emergencyFund:
        ref.read(appRouterProvider).push('/emergency-fund');
        break;
      case QuickActionType.educationFund:
        ref.read(appRouterProvider).push('/education-fund');
        break;
      case QuickActionType.retirementFund:
        ref.read(appRouterProvider).push('/retirement-fund');
        break;
      case QuickActionType.tax:
        ref.read(appRouterProvider).push('/tax');
        break;
      case QuickActionType.bills:
        ref.read(appRouterProvider).push('/bills');
        break;

      case QuickActionType.qurban:
        ref.read(appRouterProvider).push('/qurban');
        break;
      case QuickActionType.investment:
        ref.read(appRouterProvider).push('/investment');
        break;
      case QuickActionType.insurance:
        ref.read(appRouterProvider).push('/insurance');
        break;
      case QuickActionType.savingPlans:
        ref.read(appRouterProvider).push('/saving-plans');
        break;
    }
  }

  void _showTargetDetailSheet(SavingTargetModel target, double _) {
    final transactions = ref.read(transactionsByGroupProvider(null));
    final targetBalance = transactions
        .where((t) => !t.date.isBefore(target.createdAt))
        .fold<double>(
          0,
          (s, t) => s + (t.type == TransactionType.income ? t.amount : 0),
        );

    final progress = (target.targetAmount > 0)
        ? (targetBalance / target.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remainingDays = target.dueDate.difference(DateTime.now()).inDays;
    final remainingAmount = target.targetAmount - targetBalance;
    final isCompleted = progress >= 1.0;

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
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
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),


              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDarkMode ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? (isDarkMode
                                      ? Colors.green.shade800
                                      : Colors.green.shade500)
                                : (isDarkMode
                                      ? Colors.orange.shade800
                                      : Colors.orange.shade500),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCompleted
                                ? 'TARGET TERCAPAI 🎊'
                                : 'SEDANG BERJALAN 🚀',
                            style: GoogleFonts.comicNeue(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),


              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.primary.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? Colors.green.shade400
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.comicNeue(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Tercapai',
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white54
                                : AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),


              _buildDetailRow(
                'Nominal Target',
                _formatRupiah(target.targetAmount),
                Icons.flag_rounded,
                Colors.teal,
              ),
              Divider(
                height: 32,
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
              ),
              _buildDetailRow(
                'Telah Terkumpul',
                _formatRupiah(targetBalance),
                Icons.account_balance_wallet_rounded,
                Colors.green,
              ),
              Divider(
                height: 32,
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
              ),
              _buildDetailRow(
                'Sisa Kekurangan',
                remainingAmount <= 0 ? 'Lunas' : _formatRupiah(remainingAmount),
                Icons.hourglass_bottom_rounded,
                Colors.red,
              ),
              Divider(
                height: 32,
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
              ),
              _buildDetailRow(
                'Jatuh Tempo',
                '${DateFormat('d MMM yyyy').format(target.dueDate)} ($remainingDays Hari lagi)',
                Icons.calendar_today_rounded,
                Colors.orange,
              ),

              const SizedBox(height: 40),


              Center(
                child: Text(
                  'Dibuat pada ${DateFormat('d MMM yyyy').format(target.createdAt)}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white12 : Colors.black26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),


              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditTargetDialog(target: target);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(
                        'Ubah Target',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : AppColors.primary.withValues(alpha: 0.03),
                        foregroundColor: isDarkMode
                            ? Colors.white
                            : AppColors.primary,
                        elevation: 0,
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteSavingTarget(target.id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        'Hapus',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.red.shade900.withValues(alpha: 0.2)
                            : Colors.red.shade50,
                        foregroundColor: isDarkMode
                            ? Colors.red.shade300
                            : Colors.red,
                        elevation: 0,
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Row(
      children: [
        Icon(
          icon,
          color: isDarkMode ? color.withValues(alpha: 0.8) : color,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDarkMode ? Colors.white38 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  void _showCalculatorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CalculatorSheetContent(),
    );
  }

  Widget _buildSmartAllocationPlanner(double amount, bool isDarkMode) {
    if (amount <= 0) return const SizedBox.shrink();

    final needs = amount * 0.5;
    final wants = amount * 0.3;
    final savings = amount * 0.2;
    final zakat = amount * 0.025;

    Widget allocationChip(
      String label,
      double val,
      Color color,
      IconData icon,
    ) {
      return Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.comicNeue(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  _formatRupiah(val),
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.amber.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'ALOKASI CERDAS (50/30/20)',
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white24
                    : Colors.teal.shade800.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              allocationChip(
                'Kebutuhan (50%)',
                needs,
                Colors.blue,
                Icons.home_rounded,
              ),
              allocationChip(
                'Keinginan (30%)',
                wants,
                Colors.orange,
                Icons.shopping_bag_rounded,
              ),
              allocationChip(
                'Tabungan (20%)',
                savings,
                Colors.green,
                Icons.savings_rounded,
              ),
              allocationChip(
                'Zakat (2.5%)',
                zakat,
                Colors.purple,
                Icons.volunteer_activism_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showManualTransactionSheet(TransactionType type) async {
    final amountController = TextEditingController();
    final nameController = TextEditingController();
    final customCategoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final List<TransactionCategory> categoryObjects =
        type == TransactionType.income
        ? AppCategories.incomeCategories
        : AppCategories.expenseCategories;


    final Map<String, List<TransactionCategory>> groupedCategories = {};
    for (var cat in categoryObjects) {
      groupedCategories.putIfAbsent(cat.group, () => []).add(cat);
    }

    var selectedCategory = type == TransactionType.expense
        ? 'Makanan & Minuman Harian'
        : 'Gaji Pokok';


    if (categoryObjects.isNotEmpty &&
        !categoryObjects.any((cat) => cat.label == selectedCategory)) {
      selectedCategory = categoryObjects.first.label;
    }

    var selectedGroup =
        categoryObjects.any((cat) => cat.label == selectedCategory)
        ? categoryObjects
              .firstWhere((cat) => cat.label == selectedCategory)
              .group
        : (categoryObjects.isNotEmpty ? categoryObjects.first.group : '');
    var noteText = '';
    StateSetter? sheetSetter;


    nameController.addListener(() {
      if (type == TransactionType.expense) {
        final text = nameController.text.toLowerCase();
        final adminKeywords = [
          'admin',
          'dana',
          'top up',
          'fee',
          'transfer',
          'biaya',
        ];


        if (adminKeywords.any((k) => text.contains(k))) {
          const adminCat = 'Biaya Admin Bank';
          if (selectedCategory != adminCat) {
            sheetSetter?.call(() {
              selectedCategory = adminCat;
              selectedGroup = 'Keuangan';
            });
          }
        }
      }
    });
    String? selectedTopUpSource;
    String topUpBankName = '';
    String? selectedInterestBank;
    String interestOtherBankName = '';

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final topUpSources = [
      {'label': 'Bank', 'icon': Icons.account_balance_rounded},
      {'label': 'GoPay', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'OVO', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'Dana', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'ShopeePay', 'icon': Icons.account_balance_wallet_rounded},
      {'label': 'LinkAja', 'icon': Icons.account_balance_wallet_rounded},
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool prevKeyboardVisible = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            sheetSetter = setSheetState;
            final inset = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardVisible = inset > 0;

            if (prevKeyboardVisible && !isKeyboardVisible) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
            prevKeyboardVisible = isKeyboardVisible;


            final formContrastColor = type == TransactionType.income
                ? Colors.teal
                : Colors.black87;
            final formLabelColor = isDarkMode ? Colors.white70 : Colors.black87;
            final formSubTextColor = isDarkMode
                ? Colors.white54
                : Colors.black54;
            final formBorderColor = isDarkMode
                ? Colors.white10
                : Colors.black26;

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: inset),
                child: Form(
                  key: formKey,
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
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Center(
                            child: Text(
                              type == TransactionType.expense
                                  ? 'Tambah Pengeluaran'
                                  : 'Tambah Pemasukan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOMINAL TRANSAKSI *',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.black38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: amountController,
                                autofocus: false,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.left,
                                style: GoogleFonts.comicNeue(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  RibuanFormatter(),
                                ],
                                onChanged: (val) => setSheetState(() {}),
                                onEditingComplete: () =>
                                    FocusScope.of(context).unfocus(),
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: GoogleFonts.comicNeue(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white10
                                        : formSubTextColor,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.payments_rounded,
                                          color: type == TransactionType.income
                                              ? AppColors.primary
                                              : const Color(0xFFE53935),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Rp',
                                          style: GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                type == TransactionType.income
                                                ? AppColors.primary
                                                : const Color(0xFFE53935),
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
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Nominal tidak boleh kosong!';
                                  }
                                  final amount = _toAmount(val);
                                  if (amount == null || amount <= 0) {
                                    return 'Nominal transaksi tidak valid.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (type == TransactionType.income) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1DA462),
                                            Color(0xFF0C7A45),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'INSTAN',
                                        style: GoogleFonts.comicNeue(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'BUNGA TABUNGAN (CEPAT) *',
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white24
                                            : Colors.black38,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedInterestBank,
                                  isExpanded: true,
                                  itemHeight: 60,
                                  dropdownColor: isDarkMode
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  decoration: InputDecoration(
                                    hintText: 'Pilih Bank / Jenis Bunga',
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formBorderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formBorderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formContrastColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.account_balance_rounded,
                                      color: AppColors.primary,
                                    ),
                                    labelStyle: GoogleFonts.comicNeue(
                                      color: formLabelColor,
                                    ),
                                  ),
                                  selectedItemBuilder: (context) {
                                    return [
                                      const Text('None'),
                                      ...([
                                        'SeaBank (Standar)',
                                        'SeaBank (Deposito)',
                                        'Bank Neo Commerce',
                                        'Bank Jago',
                                        'Blu by BCA Digital',
                                        'Bank BRI',
                                        'Bank BCA',
                                        'Bank Mandiri',
                                        'Bank BNI',
                                        'Bank Lainnya',
                                      ].map((label) {
                                        return Text(
                                          label,
                                          style: GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        );
                                      })),
                                    ];
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'None',
                                        style: GoogleFonts.comicNeue(
                                          color: isDarkMode
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                    ...([
                                      {
                                        'value': 'SeaBank (Standar)',
                                        'label': 'SeaBank (Standar)',
                                        'subtitle':
                                            '2,5% p.a. – Tanpa min. saldo',
                                        'icon': Icons.savings_rounded,
                                        'color': Colors.teal,
                                      },
                                      {
                                        'value': 'SeaBank (Deposito)',
                                        'label': 'SeaBank (Deposito)',
                                        'subtitle':
                                            'Up to 6% p.a. – Bunga Tinggi',
                                        'icon': Icons.trending_up_rounded,
                                        'color': Colors.orangeAccent,
                                      },
                                      {
                                        'value': 'Bank Neo',
                                        'label': 'Bank Neo Commerce',
                                        'subtitle': 'Bunga cair harian',
                                        'icon': Icons.bolt_rounded,
                                        'color': Colors.amber.shade700,
                                      },
                                      {
                                        'value': 'Bank Jago',
                                        'label': 'Bank Jago',
                                        'subtitle': 'Bunga cair bulanan',
                                        'icon': Icons
                                            .account_balance_wallet_rounded,
                                        'color': Colors.orange.shade800,
                                      },
                                      {
                                        'value': 'Blu by BCA',
                                        'label': 'Blu by BCA Digital',
                                        'subtitle': 'Bunga cair bulanan',
                                        'icon': Icons.water_drop_rounded,
                                        'color': Colors.blue.shade500,
                                      },
                                      {
                                        'value': 'Bank BRI',
                                        'label': 'Bank BRI',
                                        'subtitle': 'Bunga bulanan',
                                        'icon': Icons.account_balance_rounded,
                                        'color': Colors.blue.shade900,
                                      },
                                      {
                                        'value': 'Bank BCA',
                                        'label': 'Bank BCA',
                                        'subtitle': 'Bunga bulanan',
                                        'icon': Icons.account_balance_rounded,
                                        'color': Colors.blue.shade800,
                                      },
                                      {
                                        'value': 'Bank Mandiri',
                                        'label': 'Bank Mandiri',
                                        'subtitle': 'Bunga bulanan',
                                        'icon': Icons.account_balance_rounded,
                                        'color': Colors.yellow.shade800,
                                      },
                                      {
                                        'value': 'Bank BNI',
                                        'label': 'Bank BNI',
                                        'subtitle': 'Bunga bulanan',
                                        'icon': Icons.account_balance_rounded,
                                        'color': Colors.orange.shade600,
                                      },
                                      {
                                        'value': 'Bank Lainnya',
                                        'label': 'Bank Lainnya',
                                        'subtitle': 'Bank digital/konvensional',
                                        'icon': Icons.more_horiz_rounded,
                                        'color': Colors.grey.shade600,
                                      },
                                    ].map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item['value'] as String,
                                        child: Row(
                                          children: [
                                            Icon(
                                              item['icon'] as IconData,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    item['label'] as String,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        GoogleFonts.comicNeue(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                        ),
                                                  ),
                                                  Text(
                                                    item['subtitle'] as String,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        GoogleFonts.comicNeue(
                                                          fontSize: 11,
                                                          color:
                                                              formSubTextColor,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })),
                                  ],
                                  onChanged: (val) {
                                    setSheetState(() {
                                      selectedInterestBank = val;
                                      interestOtherBankName = '';
                                      if (val == null) {
                                        if (nameController.text.startsWith(
                                          'Bunga ',
                                        )) {
                                          nameController.clear();
                                        }
                                        selectedCategory = 'Gaji Pokok';
                                        selectedGroup = 'Pekerjaan Utama';
                                      } else if (val == 'Bank Lainnya') {

                                        selectedCategory =
                                            'Bunga Tabungan Reguler';
                                        selectedGroup = 'Keuangan & Bank';
                                      } else {
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
                                        String bankClean = val
                                            .replaceAll(' (Premium)', '')
                                            .replaceAll(' (Standar)', '');


                                        if (nameController.text.isEmpty ||
                                            nameController.text.startsWith(
                                              'Bunga ',
                                            )) {
                                          nameController.text =
                                              'Bunga $bankClean $monthName ${now.year}';
                                        }

                                        selectedCategory =
                                            'Bunga Tabungan Reguler';
                                        selectedGroup = 'Keuangan & Bank';
                                      }
                                    });

                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                                if (selectedInterestBank == 'Bank Lainnya') ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'NAMA BANK *',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.black38,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    style: GoogleFonts.comicNeue(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan Nama Bank',
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: formBorderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: formBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: formContrastColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.account_balance_rounded,
                                        color: AppColors.primary,
                                      ),
                                      labelStyle: GoogleFonts.comicNeue(
                                        color: formLabelColor,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      interestOtherBankName = val;
                                      setSheetState(() {
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


                                        if (nameController.text.isEmpty ||
                                            nameController.text.startsWith(
                                              'Bunga ',
                                            )) {
                                          nameController.text =
                                              val.trim().isEmpty
                                              ? ''
                                              : 'Bunga ${val.trim()} $monthName ${now.year}';
                                        }

                                        selectedCategory =
                                            'Bunga Tabungan Reguler';
                                        selectedGroup = 'Keuangan & Bank';
                                      });
                                    },
                                  ),
                                ],
                                if (selectedInterestBank != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isDarkMode
                                            ? [
                                                AppColors.primary.withValues(
                                                  alpha: 0.25,
                                                ),
                                                AppColors.primary.withValues(
                                                  alpha: 0.15,
                                                ),
                                              ]
                                            : [
                                                Colors.grey.shade100,
                                                Colors.white,
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.info_outline_rounded,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedInterestBank ==
                                                            'Bank Lainnya' &&
                                                        interestOtherBankName
                                                            .trim()
                                                            .isNotEmpty
                                                    ? 'Bunga ${interestOtherBankName.trim()}'
                                                    : 'Bunga $selectedInterestBank',
                                                style: GoogleFonts.comicNeue(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                selectedInterestBank ==
                                                        'SeaBank (Premium)'
                                                    ? '7,4% p.a. dihitung harian untuk saldo ≥ Rp 1 juta. Dikreditkan otomatis setiap hari.'
                                                    : selectedInterestBank ==
                                                          'SeaBank (Standar)'
                                                    ? '2,5% p.a. Tanpa saldo minimum, bebas tarik kapan saja. Bunga dihitung & dikreditkan harian.'
                                                    : selectedInterestBank ==
                                                          'SeaBank (Deposito)'
                                                    ? 'Sampai dengan 6% p.a. Bunga deposito tinggi untuk simpanan berjangka Anda.'
                                                    : selectedInterestBank ==
                                                          'Bank Lainnya'
                                                    ? 'Masukkan nama bank Anda di kolom atas. Nama transaksi akan terisi otomatis.'
                                                    : 'Bunga tabungan dari $selectedInterestBank. Tambahkan catatan nominal pajak jika diperlukan.',
                                                style: GoogleFonts.comicNeue(
                                                  fontSize: 11,
                                                  color: isDarkMode
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (type == TransactionType.expense) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BIAYA ADMIN TOP-UP (CEPAT) *',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white24
                                        : Colors.black38,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedTopUpSource,
                                  isExpanded: true,
                                  dropdownColor: isDarkMode
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  decoration: InputDecoration(
                                    hintText: 'Pilih Sumber Top-up',
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formBorderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formBorderColor,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      selectedTopUpSource == 'Bank'
                                          ? Icons.account_balance_rounded
                                          : Icons
                                                .account_balance_wallet_rounded,
                                      color: AppColors.primary,
                                    ),
                                    labelStyle: GoogleFonts.comicNeue(
                                      color: isDarkMode
                                          ? Colors.white38
                                          : Colors.black45,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('None'),
                                    ),
                                    ...topUpSources.map((source) {
                                      final label = source['label'] as String;
                                      return DropdownMenuItem<String>(
                                        value: label,
                                        child: Text(
                                          label,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.comicNeue(
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    setSheetState(() {
                                      selectedTopUpSource = val;
                                      if (val == null) {
                                        if (nameController.text.startsWith(
                                          'Biaya Admin',
                                        )) {
                                          nameController.clear();
                                        }
                                        selectedCategory =
                                            type == TransactionType.expense
                                            ? 'Makanan & Minuman Harian'
                                            : 'Gaji Pokok';
                                        selectedGroup =
                                            type == TransactionType.expense
                                            ? 'Kebutuhan Pokok'
                                            : 'Pekerjaan Utama';
                                      } else if (val != 'Bank') {
                                        if (nameController.text.isEmpty ||
                                            nameController.text.startsWith(
                                              'Biaya Admin',
                                            )) {
                                          nameController.text =
                                              'Biaya Admin $val';
                                        }
                                        selectedCategory = 'Biaya Admin Bank';
                                        selectedGroup = 'Keuangan';
                                      } else {
                                        if (nameController.text.isEmpty ||
                                            nameController.text.startsWith(
                                              'Biaya Admin',
                                            )) {
                                          nameController.text =
                                              'Biaya Admin Bank ${topUpBankName.trim()}'
                                                  .trim();
                                        }
                                        selectedCategory = 'Biaya Admin Bank';
                                        selectedGroup = 'Keuangan';
                                      }
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                                if (selectedTopUpSource == 'Bank') ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'NAMA BANK *',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.black38,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    style: GoogleFonts.comicNeue(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan Nama Bank',
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: formBorderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: formBorderColor,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.account_balance_rounded,
                                        color: AppColors.primary,
                                      ),
                                      labelStyle: GoogleFonts.comicNeue(
                                        color: isDarkMode
                                            ? Colors.white38
                                            : Colors.black45,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      topUpBankName = val;
                                      setSheetState(() {
                                        if (nameController.text.isEmpty ||
                                            nameController.text.startsWith(
                                              'Biaya Admin Bank',
                                            )) {
                                          nameController.text =
                                              'Biaya Admin Bank ${val.trim()}'
                                                  .trim();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                'KETERANGAN TRANSAKSI *',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.black38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: nameController,
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Keterangan',
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: formBorderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: formBorderColor,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.edit_note_rounded,
                                    color: AppColors.primary,
                                  ),
                                  hintStyle: GoogleFonts.comicNeue(
                                    color: formSubTextColor,
                                  ),
                                ),
                                onChanged: (val) {
                                  if (type == TransactionType.expense) {
                                    final lowerVal = val.toLowerCase();
                                    if (lowerVal.contains('makan') ||
                                        lowerVal.contains('minum') ||
                                        lowerVal.contains('warung') ||
                                        lowerVal.contains('nasi')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Makanan & Minuman Harian';
                                        selectedGroup = 'Kebutuhan Pokok';
                                      });
                                    } else if (lowerVal.contains('sembako') ||
                                        lowerVal.contains('beras') ||
                                        lowerVal.contains('minyak')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Belanja Sembako / Pasar';
                                        selectedGroup = 'Kebutuhan Pokok';
                                      });
                                    } else if (lowerVal.contains('listrik') ||
                                        lowerVal.contains('pln') ||
                                        lowerVal.contains('token')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Token Listrik / PLN';
                                        selectedGroup = 'Kebutuhan Pokok';
                                      });
                                    } else if (lowerVal.contains('bensin') ||
                                        lowerVal.contains('pertalite') ||
                                        lowerVal.contains('pertamax') ||
                                        lowerVal.contains('spbu')) {
                                      setSheetState(() {
                                        selectedCategory = 'Bahan Bakar (BBM)';
                                        selectedGroup = 'Transportasi';
                                      });
                                    } else if (lowerVal.contains('ojek') ||
                                        lowerVal.contains('gojek') ||
                                        lowerVal.contains('grab') ||
                                        lowerVal.contains('maxim')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Ojek Online (Gojek/Grab)';
                                        selectedGroup = 'Transportasi';
                                      });
                                    } else if (lowerVal.contains('pulsa') ||
                                        lowerVal.contains('kuota') ||
                                        lowerVal.contains('data')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Pulsa & Paket Data Seluler';
                                        selectedGroup = 'Teknologi';
                                      });
                                    } else if (lowerVal.contains('wifi') ||
                                        lowerVal.contains('indihome') ||
                                        lowerVal.contains('biznet')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'WiFi / Internet Rumah';
                                        selectedGroup = 'Teknologi';
                                      });
                                    } else if (lowerVal.contains('netflix') ||
                                        lowerVal.contains('disney') ||
                                        lowerVal.contains('spotify') ||
                                        lowerVal.contains('youtube')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Langganan Netflix / Disney+';
                                        selectedGroup = 'Teknologi';
                                      });
                                    } else if (lowerVal.contains('obat') ||
                                        lowerVal.contains('sakit') ||
                                        lowerVal.contains('vitamin') ||
                                        lowerVal.contains('apotek')) {
                                      setSheetState(() {
                                        selectedCategory = 'Obat & Vitamin';
                                        selectedGroup = 'Kesehatan';
                                      });
                                    } else if (lowerVal.contains('kopi') ||
                                        lowerVal.contains('coffee') ||
                                        lowerVal.contains('cafe') ||
                                        lowerVal.contains('nongkrong')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Nongkrong / Coffee Shop';
                                        selectedGroup = 'Gaya Hidup';
                                      });
                                    } else if (lowerVal.contains('zakat') ||
                                        lowerVal.contains('sedekah') ||
                                        lowerVal.contains('infak')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Zakat / Infak / Sedekah';
                                        selectedGroup = 'Sosial & Ibadah';
                                      });
                                    } else if (lowerVal.contains('admin') ||
                                        lowerVal.contains('biaya') ||
                                        lowerVal.contains('fee') ||
                                        lowerVal.contains('top up')) {
                                      setSheetState(() {
                                        selectedCategory = 'Biaya Admin Bank';
                                        selectedGroup = 'Keuangan';
                                      });
                                    } else if (lowerVal.contains('hutang') ||
                                        lowerVal.contains('cicilan') ||
                                        lowerVal.contains('pinjol') ||
                                        lowerVal.contains('bayar')) {
                                      setSheetState(() {
                                        selectedCategory =
                                            'Bayar Hutang / Pinjol';
                                        selectedGroup = 'Keuangan';
                                      });
                                    }
                                  }
                                },
                                onEditingComplete: () =>
                                    FocusScope.of(context).unfocus(),
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Keterangan transaksi harus diisi!';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'GRUP KATEGORI *',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.black38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),

                              DropdownButtonFormField<String>(
                                value:
                                    groupedCategories.containsKey(selectedGroup)
                                    ? selectedGroup
                                    : (groupedCategories.isNotEmpty
                                          ? groupedCategories.keys.first
                                          : null),
                                key: ValueKey('group_${type}'),
                                isExpanded: true,
                                dropdownColor: isDarkMode
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                decoration: InputDecoration(
                                  hintText: 'Pilih Grup',
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.grid_view_rounded,
                                    color: AppColors.primary,
                                  ),
                                  labelStyle: GoogleFonts.comicNeue(
                                    color: isDarkMode
                                        ? Colors.white38
                                        : Colors.black45,
                                  ),
                                ),
                                items: groupedCategories.keys
                                    .map(
                                      (group) => DropdownMenuItem(
                                        value: group,
                                        child: Text(
                                          group,
                                          style: GoogleFonts.comicNeue(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() {
                                      selectedGroup = val;

                                      selectedCategory =
                                          groupedCategories[val]!.first.label;
                                    });
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'PILIH KATEGORI *',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.black38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),

                              DropdownButtonFormField<String>(
                                value:
                                    (groupedCategories[selectedGroup]?.any(
                                          (c) => c.label == selectedCategory,
                                        ) ??
                                        false)
                                    ? selectedCategory
                                    : (groupedCategories[selectedGroup]
                                                  ?.isNotEmpty ??
                                              false
                                          ? groupedCategories[selectedGroup]!
                                                .first
                                                .label
                                          : null),
                                key: ValueKey('category_${type}'),
                                isExpanded: true,
                                dropdownColor: isDarkMode
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                decoration: InputDecoration(
                                  hintText: 'Pilih Kategori',
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(
                                    categoryObjects.any(
                                          (c) => c.label == selectedCategory,
                                        )
                                        ? categoryObjects
                                              .firstWhere(
                                                (c) =>
                                                    c.label == selectedCategory,
                                              )
                                              .icon
                                        : Icons.help_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                  labelStyle: GoogleFonts.comicNeue(
                                    color: isDarkMode
                                        ? Colors.white38
                                        : Colors.black45,
                                  ),
                                ),
                                items: (groupedCategories[selectedGroup] ?? [])
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat.label,
                                        child: Text(
                                          cat.label,
                                          style: GoogleFonts.comicNeue(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() {
                                      selectedCategory = val;
                                    });
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                              if (selectedCategory == 'Lainnya') ...[
                                const SizedBox(height: 16),
                                Text(
                                  'NAMA KATEGORI KUSTOM *',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: isDarkMode
                                        ? Colors.white24
                                        : Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: customCategoryController,
                                  style: GoogleFonts.comicNeue(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Misal: Hibah dari Atasan',
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formBorderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: formBorderColor,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.star_rounded,
                                      color: AppColors.primary,
                                    ),
                                    hintStyle: GoogleFonts.comicNeue(
                                      color: formSubTextColor,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (selectedCategory == 'Lainnya' &&
                                        (val == null || val.trim().isEmpty)) {
                                      return 'Kategori kustom harus diisi!';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              if (type == TransactionType.income)
                                _buildSmartAllocationPlanner(
                                  _toAmount(amountController.text) ?? 0,
                                  isDarkMode,
                                ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final amount = _toAmount(
                                    amountController.text,
                                  );
                                  if (amount == null) {
                                    return; // Should be handled by validator
                                  }

                                  final finalCategory =
                                      (selectedCategory == 'Lainnya' &&
                                          customCategoryController.text
                                              .trim()
                                              .isNotEmpty)
                                      ? customCategoryController.text.trim()
                                      : selectedCategory;

                                  final tx = TransactionModel(
                                    id: DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    title: nameController.text.trim().isEmpty
                                        ? finalCategory
                                        : nameController.text.trim(),
                                    description: noteText.trim(),
                                    amount: amount,
                                    type: type,
                                    date: DateTime.now(),
                                    category: finalCategory,
                                    creatorName: ref.read(userNameProvider),
                                  );

                                  await ref
                                      .read(transactionServiceProvider)
                                      .addTransaction(tx);
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (sheetContext.mounted && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Berhasil mencatat transaksi! ✨',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Text(
                                  'Simpan Transaksi',
                                  style: GoogleFonts.comicNeue(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSavingTargetDialog(double totalBalance) async {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Target',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddEditTargetDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final targetsAsync = ref.watch(savingTargetsStreamProvider);
                    return targetsAsync.when(
                      data: (targets) {
                        if (targets.isEmpty) {
                          return Center(
                            child: Text(
                              'Belum ada target.',
                              style: GoogleFonts.comicNeue(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black38,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: targets.length,
                          itemBuilder: (context, index) {
                            final t = targets[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: isDarkMode ? 0.15 : 0.1,
                                ),
                                child: const Icon(
                                  Icons.track_changes_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                t.name,
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Target: ${_formatRupiah(t.targetAmount)}',
                                style: GoogleFonts.comicNeue(
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.black54,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(
                                  sheetContext,
                                ); // Close the list sheet
                                _showTargetDetailSheet(t, totalBalance);
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('Error: $e')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddEditTargetDialog({SavingTargetModel? target}) async {
    final isEdit = target != null;
    final amountController = TextEditingController(
      text: isEdit
          ? _formatDigitsWithDots(target.targetAmount.round().toString())
          : '',
    );
    final itemController = TextEditingController(
      text: isEdit ? target.name : '',
    );
    DateTime selectedDate = isEdit
        ? target.dueDate
        : DateTime.now().add(const Duration(days: 30));

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool prevKeyboardVisible = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final inset = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardVisible = inset > 0;

            if (prevKeyboardVisible && !isKeyboardVisible) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
            prevKeyboardVisible = isKeyboardVisible;
            return AlertDialog(
              backgroundColor: isDarkMode
                  ? AppColors.surfaceDark
                  : Colors.white,
              surfaceTintColor: isDarkMode
                  ? AppColors.surfaceDark
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              title: Text(
                isEdit ? 'Ubah Target' : 'Target Baru',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Nominal Target', isDarkMode),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RibuanFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.comicNeue(
                          color: isDarkMode ? Colors.white12 : Colors.black26,
                        ),
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rp',
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : AppColors.primary.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 24),
                    _buildInputLabel('Target Pembelian', isDarkMode),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: itemController,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Laptop, Motor, HP...',
                        hintStyle: GoogleFonts.comicNeue(
                          color: isDarkMode ? Colors.white12 : Colors.black26,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : AppColors.primary.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 24),
                    _buildInputLabel('Target Tanggal Selesai', isDarkMode),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ), // 10 years max
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: isDarkMode
                                    ? ColorScheme.dark(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        surface: AppColors.surfaceDark,
                                        onSurface: Colors.white,
                                      )
                                    : ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.teal.shade900,
                                      ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.primary.withValues(alpha: 0.03),
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
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                  'id_ID',
                                ).format(selectedDate),
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.comicNeue(
                            color: isDarkMode
                                ? Colors.white38
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = _toAmount(amountController.text);
                          final name = itemController.text.trim();

                          if (amount == null || amount <= 0 || name.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Mohon lengkapi data dengan benar.',
                                ),
                              ),
                            );
                            return;
                          }

                          const userId = 'default_user';
                          if (isEdit) {
                            final updated = target.copyWith(
                              name: name,
                              targetAmount: amount,
                              dueDate: selectedDate,
                            );
                            await ref
                                .read(savingTargetServiceProvider)
                                .updateTarget(updated);
                          } else {
                            final newTarget = SavingTargetModel(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: name,
                              targetAmount: amount,
                              dueDate: selectedDate,
                              createdAt: DateTime.now(),
                            );
                            await ref
                                .read(savingTargetServiceProvider)
                                .addTarget(newTarget);
                            await _maybeShowTargetReminder(userId, newTarget);
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (isEdit && context.mounted) {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(
                                context,
                              ); // Close management sheet if edit
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Simpan',
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
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

  double? _toAmount(String raw) {

    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return double.tryParse(digitsOnly);
  }

  Widget _buildMiniAuditMetric(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white24 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineAsset(
    String label,
    double amount,
    Color color,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          _showBalance ? _formatCompactRupiah(amount) : '••••',
          style: GoogleFonts.comicNeue(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDarkMode
                ? Colors.white38
                : Colors.teal.shade800.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInsightCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
    bool isDarkMode,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDarkMode ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.comicNeue(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceTab(
    AsyncValue<List<TransactionModel>> transactionsAsync,
    List<TransactionModel> transactions,
  ) {
    if (transactionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, a) => s + a.amount);
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, a) => s + a.amount);


    final now = DateTime.now();

    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && theme.brightness == Brightness.dark);


    final currentMonthTx = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();


    final categoryTotals = <String, double>{};
    for (var t in currentMonthTx.where(
      (t) => t.type == TransactionType.expense,
    )) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    final topCategory = categoryTotals.entries.isEmpty
        ? null
        : categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);


    final largestTransaction = currentMonthTx.isEmpty
        ? null
        : currentMonthTx.reduce((a, b) => a.amount > b.amount ? a : b);


    final monthlyActivity = currentMonthTx.length;


    final targetsAsync = ref.watch(savingTargetsStreamProvider);
    final targets = targetsAsync.valueOrNull ?? [];



    final billsAsync = ref.watch(billsStreamProvider);
    final bills = billsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => <BillModel>[],
    );


    final balance = totalIncome - totalExpense;
    final goldTxs =
        ref.watch(goldTransactionsStreamProvider).asData?.value ?? [];
    final totalGoldGrams = goldTxs.fold(
      0.0,
      (s, t) => s + (t.type == GoldTransactionType.buy ? t.grams : -t.grams),
    );
    final investments = ref.watch(investmentStreamProvider).asData?.value ?? [];
    final investmentValuation = investments.fold(
      0.0,
      (s, i) => s + i.currentValuation,
    );
    final unpaidBillsAmount = bills
        .where((b) => !b.isPaid)
        .fold(0.0, (s, b) => s + b.amount);

    BillModel? closestBill;
    int? daysUntilDue;
    if (bills.isNotEmpty) {
      final unpaid = bills.where((b) => !b.isPaid).toList();
      if (unpaid.isNotEmpty) {
        unpaid.sort((a, b) {
          int daysA = a.dueDay >= now.day
              ? a.dueDay - now.day
              : (30 - now.day + a.dueDay);
          int daysB = b.dueDay >= now.day
              ? b.dueDay - now.day
              : (30 - now.day + b.dueDay);
          return daysA.compareTo(daysB);
        });
        closestBill = unpaid.first;
        daysUntilDue = closestBill.dueDay >= now.day
            ? closestBill.dueDay - now.day
            : (30 - now.day + closestBill.dueDay);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                    : [const Color(0xFFF0FDF4), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.teal.shade50,
              ),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'KEKAYAAN BERSIH',
                        style: GoogleFonts.comicNeue(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDarkMode
                              ? Colors.white24
                              : Colors.teal.shade800.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showBalance
                            ? _formatRupiah(
                                balance +
                                    totalGoldGrams * 1200000.0 +
                                    investmentValuation -
                                    unpaidBillsAmount,
                              )
                            : '••••••',
                        style: GoogleFonts.comicNeue(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniAuditMetric(
                            'Saving Rate',
                            '${((totalIncome - totalExpense) / (totalIncome > 0 ? totalIncome : 1) * 100).toStringAsFixed(0)}%',
                            isDarkMode,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.teal.shade50,
                          ),
                          _buildMiniAuditMetric(
                            'Ketahanan',
                            '${(totalExpense / 30 > 0 ? (balance / (totalExpense / 30)) : 0).toInt()} Hari',
                            isDarkMode,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.teal.shade50,
                          ),
                          _buildMiniAuditMetric(
                            'Tagihan',
                            unpaidBillsAmount > 0
                                ? _formatCompactRupiah(unpaidBillsAmount)
                                : 'Lunas',
                            isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.teal.shade50.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInlineAsset(
                        'Saldo',
                        balance,
                        Colors.teal,
                        isDarkMode,
                      ),
                      _buildInlineAsset(
                        'Emas',
                        totalGoldGrams * 1200000.0,
                        Colors.amber,
                        isDarkMode,
                      ),
                      _buildInlineAsset(
                        'Invest',
                        investmentValuation,
                        Colors.indigo,
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),


          _buildSmartSavingPlannerSection(balance, targets, isDarkMode),

          const SizedBox(height: 28),


          Text(
            'INSIGHTS & HABITS',
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCompactInsightCard(
                    'Terboros',
                    topCategory != null
                        ? '${topCategory.key} (${_formatCompactRupiah(topCategory.value)})'
                        : 'Rp 0',
                    AppCategories.getIconForCategory(topCategory?.key ?? ''),
                    Colors.red,
                    itemWidth,
                    isDarkMode,
                  ),
                  _buildCompactInsightCard(
                    'Terbesar',
                    largestTransaction != null
                        ? _formatCompactRupiah(largestTransaction.amount)
                        : 'Rp 0',
                    Icons.payments_rounded,
                    Colors.blue,
                    itemWidth,
                    isDarkMode,
                  ),
                  _buildCompactInsightCard(
                    'Aktivitas',
                    '$monthlyActivity Transaksi',
                    Icons.analytics_rounded,
                    Colors.teal,
                    itemWidth,
                    isDarkMode,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),


          _buildExpenseAllocationSection(
            categoryTotals,
            totalExpense,
            isDarkMode,
          ),

          const SizedBox(height: 28),


          _buildSavingsPetCard(balance, isDarkMode),

          const SizedBox(height: 40),
          const SizedBox(height: 24), // Final padding
        ],
      ),
    );
  }

  Widget _buildSmartSavingPlannerSection(
    double currentBalance,
    List<SavingTargetModel> targets,
    bool isDarkMode,
  ) {

    final incomplete = targets
        .where((t) => currentBalance < t.targetAmount)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.teal.shade50,
        ),
      ),
      child: (targets.isEmpty || incomplete.isEmpty)
          ? Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.teal,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RENCANA NABUNG HARIAN',
                      style: GoogleFonts.comicNeue(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Icon(
                  Icons.track_changes_rounded,
                  size: 32,
                  color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  targets.isEmpty
                      ? 'Belum ada target tabungan'
                      : 'Semua target sudah tercapai!',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                ),
              ],
            )
          : Builder(
              builder: (context) {

                incomplete.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                final target = incomplete.first;

                final remaining = target.targetAmount - currentBalance;
                final daysLeft = target.dueDate
                    .difference(DateTime.now())
                    .inDays;
                final dailyTarget = daysLeft > 0
                    ? (remaining / daysLeft)
                    : remaining;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.teal,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'RENCANA NABUNG HARIAN',
                          style: GoogleFonts.comicNeue(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Target: ${target.name}',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatRupiah(dailyTarget),
                          style: GoogleFonts.comicNeue(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ hr',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (currentBalance / target.targetAmount).clamp(
                          0,
                          1,
                        ),
                        backgroundColor: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.teal,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sisa ${_formatRupiah(remaining)} • $daysLeft hr lagi',
                      style: GoogleFonts.comicNeue(
                        fontSize: 10,
                        color: isDarkMode
                            ? Colors.white38
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildExpenseAllocationSection(
    Map<String, double> categoryTotals,
    double totalExpense,
    bool isDarkMode,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DISTRIBUSI PENGELUARAN',
          style: GoogleFonts.comicNeue(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.teal.shade50,
            ),
          ),
          child: categoryTotals.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 40,
                      color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada data pengeluaran bulan ini',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: sortedCategories.take(4).map((entry) {
                    final percentage = totalExpense > 0
                        ? (entry.value / totalExpense)
                        : 0.0;
                    final color = AppCategories.getColorForCategory(entry.key);
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
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white38
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSavingsPetCard(double totalBalance, bool isDarkMode) {


    String petName = "Tunas Tabungan";
    IconData petIcon = Icons.eco_rounded;
    Color petColor = Colors.green;
    String status = "Baru mulai tumbuh!";
    double growth = (totalBalance / 1000000).clamp(0.0, 1.0);

    if (totalBalance >= 1000000) {
      petName = "Pohon Emas";
      petIcon = Icons.park_rounded;
      petColor = Colors.amber;
      status = "Luar biasa! Pohonmu sudah berbuah.";
    } else if (totalBalance >= 100000) {
      petName = "Pohon Muda";
      petIcon = Icons.forest_rounded;
      petColor = Colors.lightGreen;
      status = "Sedang rajin tumbuh!";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: petColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: petColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(petIcon, size: 40, color: petColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      petName,
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${(growth * 100).toInt()}%',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: petColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: growth,
                    minHeight: 6,
                    backgroundColor: petColor.withValues(alpha: 0.1),
                    color: petColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: GoogleFonts.comicNeue(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white38 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    AsyncValue<List<TransactionModel>> transactionsAsync,
    List<TransactionModel> transactions,
  ) {
    if (transactionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return _HistoryTabView(
      allTransactions: transactions,
      isDarkMode: isDarkMode,
      buildTransactionCard: _buildTransactionCard,
      miniHeaderStat: _miniHeaderStat,
      formatRupiah: _formatRupiah,
      formatCompact: _formatCompactRupiah,
      onTransactionTap: _showTransactionDetailSheet,
      onExportMonth: _showExportSheetForMonth,
    );
  }


  Future<void> _showExportSheetForMonth({
    required List<TransactionModel> monthTx,
    required String monthLabel,
  }) async {
    final isDark =
        ref.read(themeProvider) == ThemeMode.dark ||
        (ref.read(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final regular = monthTx.where((t) {
      if (t.category == 'Hutang' || t.category == 'Piutang') return false;
      if (t.id.startsWith('shopping_')) return false;
      return true;
    }).toList();

    final income = regular
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = regular
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final fmtNum = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheet) {
          return Container(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ekspor Laporan',
                            style: GoogleFonts.comicNeue(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Bulan $monthLabel (${regular.length} transaksi)',
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniExportStat(
                        isDark,
                        'PEMASUKAN',
                        fmtNum.format(income),
                        Colors.green,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      _miniExportStat(
                        isDark,
                        'PENGELUARAN',
                        fmtNum.format(expense),
                        Colors.red,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      _miniExportStat(
                        isDark,
                        'SALDO',
                        fmtNum.format(income - expense),
                        (income - expense) >= 0 ? Colors.teal : Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _exportOptionTile(
                  ctx2,
                  isDark: isDark,
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: Colors.red.shade500,
                  title: 'Bagikan sebagai PDF',
                  subtitle: 'Laporan lengkap dalam format PDF siap cetak',
                  onTap: () async {
                    Navigator.pop(ctx2);
                    try {
                      await ExportService.shareMonthlyReport(
                        context: ctx2,
                        transactions: regular,
                        monthLabel: monthLabel,
                        asPdf: true,
                      );
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _miniExportStat(bool isDark, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _exportOptionTile(
    BuildContext ctx, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.comicNeue(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniHeaderStat(String label, double amount, Color color) {
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _formatRupiah(amount),
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? color : color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel t) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final isExpense = t.type == TransactionType.expense;


    final IconData catIcon = isExpense
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final Color catColor = isExpense
        ? (isDarkMode ? Colors.redAccent.shade100 : Colors.red)
        : (isDarkMode ? Colors.greenAccent.shade400 : Colors.green);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showTransactionDetailSheet(t),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? theme.cardColor
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.01),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: isDarkMode ? 0.2 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: catColor, size: 18),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white
                              : Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('EEEE, dd MMM', 'id_ID').format(t.date)} • ${DateFormat('HH:mm', 'id_ID').format(t.date)}',
                        style: GoogleFonts.comicNeue(
                          color: isDarkMode ? Colors.white54 : Colors.black26,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                    color: isExpense
                        ? (isDarkMode ? Colors.redAccent : Colors.red.shade700)
                        : (isDarkMode
                              ? Colors.greenAccent
                              : Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTransactionDetailSheet(TransactionModel t) async {
    final isSystemLinked =
        t.category == 'Hutang' ||
        t.category == 'Piutang' ||
        t.id.startsWith('shopping_');

    await TransactionDetailSheet.show(
      context,
      ref,
      t,
      onEdit: isSystemLinked ? null : () => _showEditTransactionSheet(t),
      onDelete: () => _confirmDeleteTransaction(t),
    );
  }



  Future<void> _confirmDeleteTransaction(TransactionModel t) async {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Transaksi?',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus ${t.title}? Langkah ini tidak bisa dibatalkan.',
          style: GoogleFonts.comicNeue(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.comicNeue(
                color: isDarkMode ? Colors.white30 : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.comicNeue(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(transactionServiceProvider).deleteTransaction(t.id);
      if (mounted) setState(() {});
    }
  }

  Widget _buildNavItem(int index) {
    final isSelected = ref.watch(dashboardTabIndexProvider) == index;
    final item = _navItems[index];
    final color = isSelected ? AppColors.primary : const Color(0xFF94A3B8);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(dashboardTabIndexProvider.notifier).state = index,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.comicNeue(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRupiah(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatCompactRupiah(double value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)} M';
    }
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    return _formatRupiah(value);
  }

  String _formatDigitsWithDots(String digitsText) {
    final digits = digitsText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  Future<void> _showEditTransactionSheet(TransactionModel t) async {
    final amountController = TextEditingController(
      text: _formatDigitsWithDots(t.amount.round().toString()),
    );
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final inset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: inset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        'Edit Nominal',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.title,
                        style: GoogleFonts.comicNeue(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white38
                              : Colors.teal.shade800.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 24),


                      TextFormField(
                        controller: amountController,
                        autofocus: t.type == TransactionType.expense,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          RibuanFormatter(),
                        ],
                        style: GoogleFonts.comicNeue(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Input Nominal Baru *',
                          labelStyle: GoogleFonts.comicNeue(
                            color: isDarkMode ? Colors.white38 : Colors.black45,
                          ),
                          prefixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rp',
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final valText = amountController.text.replaceAll(
                              '.',
                              '',
                            );
                            final finalAmount = double.tryParse(valText);
                            if (finalAmount == null || finalAmount <= 0) {
                              return;
                            }

                            final updated = t.copyWith(amount: finalAmount);

                            await ref
                                .read(transactionServiceProvider)
                                .updateTransaction(updated);

                            if (mounted) {
                              if (sheetContext.mounted &&
                                  Navigator.canPop(sheetContext)) {
                                Navigator.pop(sheetContext);
                              }
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nominal berhasil diperbarui!'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.comicNeue(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

const List<_NavItem> _navItems = [
  _NavItem(icon: Icons.home_rounded, label: 'Tabunganku'),
  _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Keuangan'),
  _NavItem(icon: Icons.receipt_long_rounded, label: 'Riwayat'),
  _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
];

class _CalculatorSheetContent extends ConsumerStatefulWidget {
  const _CalculatorSheetContent();

  @override
  ConsumerState<_CalculatorSheetContent> createState() =>
      _CalculatorSheetContentState();
}

class _CalculatorSheetContentState
    extends ConsumerState<_CalculatorSheetContent> {
  String _output = "0";
  String _expression = "";
  double? _num1;
  double? _num2;
  String? _operand;

  void _calculate() {
    if (_num1 == null || _operand == null) return;
    _num2 = double.tryParse(_output.replaceAll('.', '').replaceAll(',', '.'));
    if (_num2 == null) return;

    double result = 0;
    switch (_operand) {
      case "+":
        result = _num1! + _num2!;
        break;
      case "-":
        result = _num1! - _num2!;
        break;
      case "×":
        result = _num1! * _num2!;
        break;
      case "÷":
        result = _num2 == 0 ? 0 : _num1! / _num2!;
        break;
    }

    _output = result % 1 == 0
        ? result.toInt().toString()
        : result.toStringAsFixed(2).replaceAll('.', ',');
    _num1 = result;
    _num2 = null;
    _operand = null;
  }

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _output = "0";
        _expression = "";
        _num1 = null;
        _num2 = null;
        _operand = null;
      } else if (buttonText == "C") {
        if (_output != "0") {
          _output = _output.length > 1
              ? _output.substring(0, _output.length - 1)
              : "0";
        }
      } else if (buttonText == "+" ||
          buttonText == "-" ||
          buttonText == "×" ||
          buttonText == "÷") {
        double currentVal =
            double.tryParse(_output.replaceAll('.', '').replaceAll(',', '.')) ??
            0;

        if (_num1 == null) {
          _num1 = currentVal;
          _operand = buttonText;
          _expression = "$_output $buttonText";
          _output = "0";
        } else if (_operand != null) {
          if (_output == "0") {

            _operand = buttonText;
            _expression =
                _expression.substring(0, _expression.length - 1) + buttonText;
          } else {

            _calculate();
            _operand = buttonText;
            _expression = "$_output $buttonText";
            _output = "0";
          }
        } else {

          _num1 = currentVal;
          _operand = buttonText;
          _expression = "$_output $buttonText";
          _output = "0";
        }
      } else if (buttonText == "%") {
        double val =
            double.tryParse(_output.replaceAll('.', '').replaceAll(',', '.')) ??
            0;
        _output = (val / 100).toString().replaceAll('.', ',');
      } else if (buttonText == "+/-") {
        if (_output.startsWith("-")) {
          _output = _output.substring(1);
        } else if (_output != "0") {
          _output = "-$_output";
        }
      } else if (buttonText == "=") {
        if (_num1 != null && _operand != null) {
          _expression = ""; // Clear expression on final result
          _calculate();

          _num1 = null;
          _operand = null;
        }
      } else {
        if (_output == "0") {
          _output = buttonText;
        } else {
          _output = _output + buttonText;
        }
      }
    });
  }

  String _formatDisplay(String val) {
    if (val == "0") return "0";
    if (val.contains(',')) return val;
    final clean = val.replaceAll('.', '');
    final parts = clean.split(',');
    final whole = parts[0];
    final formattedWhole = whole.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return parts.length > 1 ? '$formattedWhole,${parts[1]}' : formattedWhole;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression,
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.white24
                          : Colors.teal.shade800.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _formatDisplay(_output),
                      style: GoogleFonts.comicNeue(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.teal.shade900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _calcButton("AC", isAction: true, isDarkMode: isDarkMode),
                _calcButton("+/-", isAction: true, isDarkMode: isDarkMode),
                _calcButton("%", isAction: true, isDarkMode: isDarkMode),
                _calcButton("÷", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("7", isDarkMode: isDarkMode),
                _calcButton("8", isDarkMode: isDarkMode),
                _calcButton("9", isDarkMode: isDarkMode),
                _calcButton("×", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("4", isDarkMode: isDarkMode),
                _calcButton("5", isDarkMode: isDarkMode),
                _calcButton("6", isDarkMode: isDarkMode),
                _calcButton("-", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("1", isDarkMode: isDarkMode),
                _calcButton("2", isDarkMode: isDarkMode),
                _calcButton("3", isDarkMode: isDarkMode),
                _calcButton("+", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("C", isDarkMode: isDarkMode),
                _calcButton("0", isDarkMode: isDarkMode),
                _calcButton(",", isDarkMode: isDarkMode),
                _calcButton(
                  "=",
                  isOperator: true,
                  isPrimary: true,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _calcButton(
    String text, {
    bool isOperator = false,
    bool isAction = false,
    bool isPrimary = false,
    required bool isDarkMode,
  }) {
    Color bgColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.teal.shade900;

    if (isOperator) {
      bgColor = isPrimary
          ? AppColors.primary
          : (isDarkMode
                ? Colors.teal.shade900.withValues(alpha: 0.3)
                : Colors.teal.shade50);
      textColor = isPrimary
          ? Colors.white
          : (isDarkMode ? Colors.teal.shade300 : AppColors.primary);
    } else if (isAction) {
      bgColor = isDarkMode
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade50;
      textColor = isDarkMode ? Colors.teal.shade200 : Colors.teal.shade700;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _buttonPressed(text == "," ? "." : text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.teal.shade50.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}




class _HistoryTabView extends StatefulWidget {
  final List<TransactionModel> allTransactions;
  final bool isDarkMode;
  final Widget Function(TransactionModel) buildTransactionCard;
  final Widget Function(String, double, Color) miniHeaderStat;
  final String Function(double) formatRupiah;
  final String Function(double) formatCompact;
  final void Function(TransactionModel) onTransactionTap;
  final Future<void> Function({
    required List<TransactionModel> monthTx,
    required String monthLabel,
  })
  onExportMonth;

  const _HistoryTabView({
    required this.allTransactions,
    required this.isDarkMode,
    required this.buildTransactionCard,
    required this.miniHeaderStat,
    required this.formatRupiah,
    required this.formatCompact,
    required this.onTransactionTap,
    required this.onExportMonth,
  });

  @override
  State<_HistoryTabView> createState() => _HistoryTabViewState();
}

class _HistoryTabViewState extends State<_HistoryTabView> {
  int _filterIndex = 0;


  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int _typeFilter = 0;

  int _debtTypeFilter = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isHutangPiutang(TransactionModel t) =>
      t.category == 'Hutang' || t.category == 'Piutang';
  bool _isBelanja(TransactionModel t) => t.id.startsWith('shopping_');
  bool _isRegular(TransactionModel t) => !_isHutangPiutang(t) && !_isBelanja(t);

  String _fmtCur(double amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.allTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final regularList = sorted.where(_isRegular).toList();
    final hutangList = sorted.where(_isHutangPiutang).toList();
    final belanjaList = sorted.where(_isBelanja).toList();
    final isDark = widget.isDarkMode;

    return Column(
      children: [

        _buildHistoryFilter(isDark, regularList, hutangList, belanjaList),


        if (_filterIndex == 0) _buildSearchBar(isDark, regularList),


        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildFilteredBody(
              sorted,
              regularList,
              hutangList,
              belanjaList,
              isDark,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildSearchBar(bool isDark, List<TransactionModel> regularList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Builder(
            builder: (context) {
              final isDk = isDark;
              return TextField(
                controller: _searchCtrl,
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  color: isDk ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  hintStyle: GoogleFonts.comicNeue(
                    fontSize: 14,
                    color: isDk ? Colors.white24 : Colors.black26,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDk ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: isDk ? Colors.white38 : Colors.black38,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDk
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDk
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _typeChip(isDark, 0, 'Semua', Icons.receipt_long_rounded),
              const SizedBox(width: 8),
              _typeChip(isDark, 1, 'Pemasukan', Icons.arrow_downward_rounded),
              const SizedBox(width: 8),
              _typeChip(isDark, 2, 'Pengeluaran', Icons.arrow_upward_rounded),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _typeChip(bool isDark, int value, String label, IconData icon) {
    final selected = _typeFilter == value;
    const activeColor = Color(0xFF00BFA5);

    return GestureDetector(
      onTap: () => setState(() => _typeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? activeColor
                  : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? (isDark ? Colors.white : activeColor)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilter(
    bool isDark,
    List<TransactionModel> regularList,
    List<TransactionModel> hutangList,
    List<TransactionModel> belanjaList,
  ) {
    final categories = [
      'Pemasukan & Pengeluaran',
      'Hutang & Piutang',
      'Belanja',
    ];
    final categoryIcons = [
      Icons.account_balance_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.shopping_basket_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Navigator.of(context).overlay!.context.findRenderObject()
                        as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(
                      const Offset(0, 45),
                      ancestor: overlay,
                    ),
                    button.localToGlobal(
                      button.size.bottomRight(Offset.zero),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                final int? result = await showMenu<int>(
                  context: context,
                  position: position,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  elevation: 8,
                  items: [
                    for (int i = 0; i < categories.length; i++)
                      PopupMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            Icon(
                              categoryIcons[i],
                              size: 18,
                              color: _filterIndex == i
                                  ? AppColors.primary
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              categories[i],
                              style: GoogleFonts.comicNeue(
                                fontSize: 13,
                                fontWeight: _filterIndex == i
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _filterIndex == i
                                    ? AppColors.primary
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
                if (result != null && mounted) {
                  setState(() => _filterIndex = result);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.03),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categoryIcons[_filterIndex],
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      categories[_filterIndex],
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ),


          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _filterIndex == 0
                  ? '${regularList.length} Item'
                  : (_filterIndex == 1
                        ? '${hutangList.length} Item'
                        : '${belanjaList.length} Item'),
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredBody(
    List<TransactionModel> allSorted,
    List<TransactionModel> regularList,
    List<TransactionModel> hutangList,
    List<TransactionModel> belanjaList,
    bool isDark,
  ) {
    switch (_filterIndex) {
      case 0:
        return _buildRegularTab(allSorted, regularList, isDark);
      case 1:
        return _buildHutangTab(hutangList, isDark);
      case 2:
        return _buildBelanjaTab(belanjaList, isDark);
      default:
        return const SizedBox.shrink();
    }
  }



  Widget _buildRegularTab(
    List<TransactionModel> allSorted,
    List<TransactionModel> regularList,
    bool isDark,
  ) {

    final filtered = regularList.where((t) {
      if (_typeFilter == 1 && t.type != TransactionType.income) {
        return false;
      }
      if (_typeFilter == 2 && t.type != TransactionType.expense) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        if (!t.title.toLowerCase().contains(q) &&
            !t.category.toLowerCase().contains(q) &&
            !t.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final isFiltering = _searchQuery.isNotEmpty || _typeFilter != 0;

    if (regularList.isEmpty) {
      return _emptyState(
        isDark,
        icon: Icons.receipt_long_outlined,
        label: 'Belum ada pemasukan/pengeluaran',
      );
    }

    if (filtered.isEmpty && isFiltering) {
      return _emptyState(
        isDark,
        icon: Icons.search_off_rounded,
        label: 'Tidak ada hasil',
        subtitle: 'Coba ubah kata kunci atau hapus filter',
      );
    }


    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in filtered) {
      final k = DateFormat('MMMM yyyy', 'id_ID').format(t.date).toUpperCase();
      grouped.putIfAbsent(k, () => []).add(t);
    }

    final Map<String, List<TransactionModel>> allGrouped = {};
    for (final t in allSorted) {
      final k = DateFormat('MMMM yyyy', 'id_ID').format(t.date).toUpperCase();
      allGrouped.putIfAbsent(k, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: grouped.keys.length,
      itemBuilder: (context, i) {
        final monthKey = grouped.keys.elementAt(i);
        final monthTx = grouped[monthKey]!;
        final allMonthTx = allGrouped[monthKey] ?? monthTx;


        final totalIn = allMonthTx
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final totalOut = allMonthTx
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthKey,
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white60
                                : Colors.teal.shade900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            widget.miniHeaderStat(
                              'MASUK',
                              totalIn,
                              isDark
                                  ? Colors.greenAccent.shade400
                                  : Colors.green,
                            ),
                            widget.miniHeaderStat(
                              'KELUAR',
                              totalOut,
                              isDark ? Colors.redAccent.shade200 : Colors.red,
                            ),

                            GestureDetector(
                              onTap: () => widget.onExportMonth(
                                monthTx: allMonthTx,
                                monthLabel: monthKey,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.18 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.share_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'EKSPOR',
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
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
            ...monthTx.map((t) => widget.buildTransactionCard(t)),
          ],
        );
      },
    );
  }


  Widget _buildHutangTab(List<TransactionModel> list, bool isDark) {
    if (list.isEmpty) {
      return _emptyState(
        isDark,
        icon: Icons.account_balance_wallet_outlined,
        label: 'Belum ada riwayat hutang/piutang',
        subtitle: 'Muncul saat hutang/piutang ditandai lunas',
      );
    }

    final hutangOnly = list.where((t) => t.category == 'Hutang').toList();
    final piutangOnly = list.where((t) => t.category == 'Piutang').toList();
    final totalH = hutangOnly.fold(0.0, (s, t) => s + t.amount);
    final totalP = piutangOnly.fold(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      children: [

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              _debtTypeChip(isDark, 0, 'Semua', Icons.receipt_long_rounded),
              const SizedBox(width: 8),
              _debtTypeChip(isDark, 1, 'Hutang', Icons.call_made_rounded),
              const SizedBox(width: 8),
              _debtTypeChip(isDark, 2, 'Piutang', Icons.call_received_rounded),
            ],
          ),
        ),


        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _sumItemMinimalist(
                  isDark,
                  label: 'HUTANG DIBAYAR',
                  amount: totalH,
                  color: Colors.red.shade400,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              Expanded(
                child: _sumItemMinimalist(
                  isDark,
                  label: 'PIUTANG DITERIMA',
                  amount: totalP,
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
        ),

        if ((_debtTypeFilter == 0 || _debtTypeFilter == 1) &&
            hutangOnly.isNotEmpty) ...[
          ...hutangOnly.map((t) => _debtCard(t, isDark)),
        ],
        if ((_debtTypeFilter == 0 || _debtTypeFilter == 2) &&
            piutangOnly.isNotEmpty) ...[
          ...piutangOnly.map((t) => _debtCard(t, isDark)),
        ],
      ],
    );
  }

  Widget _debtTypeChip(bool isDark, int value, String label, IconData icon) {
    final selected = _debtTypeFilter == value;
    const activeColor = Color(0xFF00BFA5);

    return GestureDetector(
      onTap: () => setState(() => _debtTypeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? activeColor
                  : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? (isDark ? Colors.white : activeColor)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBelanjaTab(List<TransactionModel> list, bool isDark) {
    if (list.isEmpty) {
      return _emptyState(
        isDark,
        icon: Icons.shopping_bag_outlined,
        label: 'Belum ada riwayat belanja',
        subtitle: 'Muncul saat item belanja ditandai dibeli',
      );
    }

    final total = list.fold(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      children: [

        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _sumItemMinimalist(
                  isDark,
                  label: 'TOTAL BELANJA',
                  amount: total,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              Expanded(
                child: _sumItemMinimalist(
                  isDark,
                  label: 'JUMLAH ITEM',
                  amount: list.length.toDouble(),
                  isCurrency: false,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
        ...list.map((t) => _shoppingCard(t, isDark)),
      ],
    );
  }


  Widget _debtCard(TransactionModel t, bool isDark) {
    final isHutang = t.category == 'Hutang';
    final color = isHutang ? Colors.red.shade400 : Colors.green.shade400;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onTransactionTap(t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    isHutang
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: GoogleFonts.comicNeue(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (t.description.isNotEmpty)
                        Text(
                          t.description,
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _fmtCur(t.amount),
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shoppingCard(TransactionModel t, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onTransactionTap(t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.title,
                    style: GoogleFonts.comicNeue(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  _fmtCur(t.amount),
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sumItemMinimalist(
    bool isDark, {
    required String label,
    required double amount,
    required Color color,
    bool isCurrency = true,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isCurrency ? _fmtCur(amount) : amount.toInt().toString(),
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _groupHeader(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(
    bool isDark, {
    required IconData icon,
    required String label,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final QuickActionType type;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.type,
  });
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
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

class _HeaderPainter extends CustomPainter {
  final Color color;
  final bool isDarkMode;

  _HeaderPainter({required this.color, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;


    const spacing = 20.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }


    final accentPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: isDarkMode ? 0.2 : 0.1)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
