import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otax/tabunganku/features/splash/presentation/pages/splash_screen.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/dashboard_page.dart';
import 'package:otax/tabunganku/features/auth/presentation/pages/lock_screen.dart';
import 'package:otax/tabunganku/features/friends/presentation/pages/family_group_page.dart';
import 'package:otax/tabunganku/features/settings/presentation/pages/pin_setup_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/saving_simulator_page.dart';
import 'package:otax/tabunganku/features/transaction/presentation/pages/scan_receipt_page.dart';
import 'package:otax/tabunganku/features/challenge/presentation/pages/challenge_page.dart';
import 'package:otax/tabunganku/features/budget/presentation/pages/monthly_budget_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/zakat_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/gold_savings_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/specialized_saving_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/bills_tracker_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/tax_calculator_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/investment_tracker_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/insurance_tracker_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/saving_plans_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/buying_targets_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/all_services_page.dart';
import 'package:otax/tabunganku/features/transaction/presentation/pages/recurring_list_page.dart';
import 'package:otax/tabunganku/features/transaction/presentation/pages/debt_list_page.dart';
import 'package:otax/tabunganku/features/shopping/presentation/pages/shopping_list_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/tax_reminder_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/piggy_bank_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/compound_interest_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/currency_converter_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/mosque_donation_page.dart';
import 'package:otax/tabunganku/features/home/presentation/pages/hajj_umrah_planner_page.dart';

import 'package:otax/tabunganku/features/budget/presentation/pages/overseas_travel_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [

      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),


      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardPage(),
        ),
      ),


      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) {
          return const LockScreen();
        },
      ),


      GoRoute(
        path: '/family-group',
        name: 'family-group',
        builder: (context, state) => const FamilyGroupPage(),
      ),


      GoRoute(
        path: '/pin-setup',
        name: 'pin-setup',
        builder: (context, state) => const PinSetupPage(),
      ),

      GoRoute(
        path: '/saving-simulator',
        name: 'saving-simulator',
        builder: (context, state) => const SavingSimulatorPage(),
      ),


      GoRoute(
        path: '/scan-receipt',
        name: 'scan-receipt',
        builder: (context, state) => const ScanReceiptPage(),
      ),


      GoRoute(
        path: '/challenge',
        name: 'challenge',
        builder: (context, state) => const ChallengePage(),
      ),


      GoRoute(
        path: '/monthly-budget',
        name: 'monthly-budget',
        builder: (context, state) => const MonthlyBudgetPage(),
      ),


      GoRoute(
        path: '/zakat',
        name: 'zakat',
        builder: (context, state) => const ZakatPage(),
      ),


      GoRoute(
        path: '/gold',
        name: 'gold',
        builder: (context, state) => const GoldSavingsPage(),
      ),


      GoRoute(
        path: '/emergency-fund',
        name: 'emergency-fund',
        builder: (context, state) => const SpecializedSavingPage(
          title: 'Dana Darurat',
          category: 'Darurat',
          icon: Icons.health_and_safety_rounded,
          baseColor: Colors.redAccent,
        ),
      ),
      GoRoute(
        path: '/education-fund',
        name: 'education-fund',
        builder: (context, state) => const SpecializedSavingPage(
          title: 'Dana Pendidikan',
          category: 'Pendidikan',
          icon: Icons.school_rounded,
          baseColor: Colors.blueAccent,
        ),
      ),
      GoRoute(
        path: '/retirement-fund',
        name: 'retirement-fund',
        builder: (context, state) => const SpecializedSavingPage(
          title: 'Dana Pensiun',
          category: 'Pensiun',
          icon: Icons.elderly_rounded,
          baseColor: Colors.brown,
        ),
      ),
      GoRoute(
        path: '/qurban',
        name: 'qurban',
        builder: (context, state) => const SpecializedSavingPage(
          title: 'Tabungan Kurban',
          category: 'Kurban',
          icon: Icons.pets_rounded,
          baseColor: Colors.green,
        ),
      ),

      GoRoute(
        path: '/saving-plans',
        name: 'saving-plans',
        builder: (context, state) => const SavingPlansPage(),
      ),
      GoRoute(
        path: '/buying-targets',
        name: 'buying-targets',
        builder: (context, state) => const BuyingTargetsPage(),
      ),


      GoRoute(
        path: '/bills',
        name: 'bills',
        builder: (context, state) => const BillsTrackerPage(),
      ),


      GoRoute(
        path: '/tax',
        name: 'tax',
        builder: (context, state) => const TaxCalculatorPage(),
      ),


      GoRoute(
        path: '/investment',
        name: 'investment',
        builder: (context, state) => const InvestmentTrackerPage(),
      ),


      GoRoute(
        path: '/insurance',
        name: 'insurance',
        builder: (context, state) => const InsuranceTrackerPage(),
      ),

      GoRoute(
        path: '/all-services',
        name: 'all-services',
        builder: (context, state) => const AllServicesPage(),
      ),
      GoRoute(
        path: '/recurring',
        name: 'recurring',
        builder: (context, state) => const RecurringListPage(),
      ),

      GoRoute(
        path: '/debts',
        name: 'debts',
        builder: (context, state) => const DebtListPage(),
      ),
      GoRoute(
        path: '/shopping',
        name: 'shopping',
        builder: (context, state) => const ShoppingListPage(),
      ),

      GoRoute(
        path: '/tax-reminder',
        name: 'tax-reminder',
        builder: (context, state) => const TaxReminderPage(),
      ),
      GoRoute(
        path: '/piggy-bank',
        name: 'piggy-bank',
        builder: (context, state) => const PiggyBankPage(),
      ),
      GoRoute(
        path: '/compound-interest',
        name: 'compound-interest',
        builder: (context, state) => const CompoundInterestPage(),
      ),
      GoRoute(
        path: '/currency-converter',
        name: 'currency-converter',
        builder: (context, state) => const CurrencyConverterPage(),
      ),
      GoRoute(
        path: '/mosque-donation',
        name: 'mosque-donation',
        builder: (context, state) => const MosqueDonationPage(),
      ),
      GoRoute(
        path: '/hajj-umrah',
        name: 'hajj-umrah',
        builder: (context, state) => const HajjUmrahPlannerPage(),
      ),
      GoRoute(
        path: '/overseas-travel',
        name: 'overseas-travel',
        builder: (context, state) => const OverseasTravelPage(),
      ),


      GoRoute(path: '/', name: 'home', redirect: (context, state) => '/dashboard'),
    ],


    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Kembali ke Awal'),
            ),
          ],
        ),
      ),
    ),
  );
});
