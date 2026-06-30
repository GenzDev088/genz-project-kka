import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otax/tabunganku/core/routing/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/providers/gold_provider.dart';
import 'package:otax/tabunganku/providers/bills_provider.dart';
import 'package:otax/tabunganku/providers/investment_provider.dart';
import 'package:otax/tabunganku/providers/insurance_provider.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:otax/tabunganku/models/gold_investment_model.dart';

class AllServicesPage extends ConsumerWidget {
  const AllServicesPage({super.key});

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);


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

    final targets = ref.watch(savingTargetsStreamProvider).valueOrNull ?? [];
    final totalTargets = targets.length;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => ref.read(appRouterProvider).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 18,
          ),
        ),
        title: Text(
          'Semua Layanan',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _buildCategoryHeader(isDarkMode, 'MANAJEMEN KEUANGAN'),
          _buildCompactCategoryCard(context, ref, isDarkMode, [
            _ServiceData(
              icon: Icons.document_scanner_rounded,
              title: 'Smart Receipt',
              subtitle: 'Scan struk belanja otomatis',
              color: Colors.teal,
              route: '/scan-receipt',
            ),
            _ServiceData(
              icon: Icons.loop_rounded,
              title: 'Kelola Langganan',
              subtitle: 'Tagihan rutin & hiburan',
              color: Colors.blue,
              route: '/recurring',
            ),
            _ServiceData(
              icon: Icons.receipt_long_rounded,
              title: 'Manajemen Tagihan',
              subtitle: unpaidBillsTotal > 0
                  ? '${_formatRupiah(unpaidBillsTotal)} tertunggak'
                  : 'List tagihan bulanan wajib',
              color: Colors.lightBlue,
              route: '/bills',
            ),
          ]),

          _buildCategoryHeader(isDarkMode, 'TABUNGAN & INVESTASI'),
          _buildCompactCategoryCard(context, ref, isDarkMode, [
            _ServiceData(
              icon: Icons.savings_rounded,
              title: 'Tabungan Receh',
              subtitle: 'Kumpulkan uang kecilmu',
              color: Colors.pinkAccent,
              route: '/piggy-bank',
            ),
            _ServiceData(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Dana Rencana',
              subtitle: 'Masa depan cerah terencana',
              color: AppColors.primary,
              route: '/saving-plans',
            ),
            _ServiceData(
              icon: Icons.monetization_on_rounded,
              title: 'Simpanan Emas',
              subtitle: goldGramBalance > 0
                  ? '${goldGramBalance.toStringAsFixed(3)} Gr tersimpan'
                  : 'Tabungan nilai aset stabil',
              color: Colors.amber,
              route: '/gold',
            ),
            _ServiceData(
              icon: Icons.trending_up_rounded,
              title: 'Portofolio Investasi',
              subtitle: totalInvestmentValuation > 0
                  ? 'Valuasi: ${_formatRupiah(totalInvestmentValuation)}'
                  : 'Pantau aset investasimu',
              color: Colors.indigo,
              route: '/investment',
            ),
            _ServiceData(
              icon: Icons.shield_rounded,
              title: 'Proteksi Asuransi',
              subtitle: totalMonthlyInsurance > 0
                  ? '${_formatRupiah(totalMonthlyInsurance)}/bln'
                  : 'Keamanan jangka panjang',
              color: Colors.blueGrey,
              route: '/insurance',
            ),
            _ServiceData(
              icon: Icons.flight_takeoff_rounded,
              title: 'Target Luar Negeri',
              subtitle: 'Nabung dengan kurs real-time',
              color: Colors.deepPurple,
              route: '/overseas-travel',
            ),
          ]),

          _buildCategoryHeader(isDarkMode, 'ALAT & ANALISIS'),
          _buildCompactCategoryCard(context, ref, isDarkMode, [
            _ServiceData(
              icon: Icons.calculate_rounded,
              title: 'Simulasi Tabungan',
              subtitle: 'Hitung pertumbuhan bungamu',
              color: Colors.cyan,
              route: '/saving-simulator',
            ),
            _ServiceData(
              icon: Icons.calculate_rounded,
              title: 'Kalkulator Pajak',
              subtitle: 'Hitung estimasi PBB & PKB',
              color: Colors.deepPurpleAccent,
              route: '/tax',
            ),
            _ServiceData(
              icon: Icons.notification_important_rounded,
              title: 'Pengingat Pajak',
              subtitle: 'Jangan lewatkan jatuh tempo',
              color: Colors.orange,
              route: '/tax-reminder',
            ),
          ]),

          _buildCategoryHeader(isDarkMode, 'UTILITAS FINANSIAL'),
          _buildCompactCategoryCard(context, ref, isDarkMode, [
            _ServiceData(
              icon: Icons.trending_up_rounded,
              title: 'Bunga Majemuk',
              subtitle: 'Simulasi pertumbuhan aset',
              color: AppColors.primary,
              route: '/compound-interest',
            ),
            _ServiceData(
              icon: Icons.currency_exchange_rounded,
              title: 'Konverter Valas',
              subtitle: 'Cek nilai tukar mata uang',
              color: Colors.blue,
              route: '/currency-converter',
            ),
          ]),

          _buildCategoryHeader(isDarkMode, 'SOSIAL & HADIAH'),
          _buildCompactCategoryCard(context, ref, isDarkMode, [
            _ServiceData(
              icon: Icons.volunteer_activism_rounded,
              title: 'Zakat & Infaq',
              subtitle: 'Donasi & ibadah harta',
              color: Colors.teal,
              route: '/zakat',
            ),
            _ServiceData(
              icon: Icons.mosque_rounded,
              title: 'Sedekah Masjid',
              subtitle: 'Catat sedekah untuk rumah ibadah',
              color: Colors.lightGreen,
              route: '/mosque-donation',
            ),
            _ServiceData(
              icon: Icons.mosque_rounded,
              title: 'Haji & Umrah',
              subtitle: 'Rencanakan ibadah suci',
              color: Colors.amber.shade800,
              route: '/hajj-umrah',
            ),
            _ServiceData(
              icon: Icons.emoji_events_rounded,
              title: 'Misi & Challenge',
              subtitle: 'Mainkan misi, raih reward',
              color: Colors.amber,
              route: '/challenge',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(bool isDarkMode, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.comicNeue(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildCompactCategoryCard(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    List<_ServiceData> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _buildCompactListItem(context, ref, item, isDarkMode),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCompactListItem(
    BuildContext context,
    WidgetRef ref,
    _ServiceData item,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () =>
          ref.read(appRouterProvider).push(item.route, extra: item.extra),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: isDarkMode ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.comicNeue(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  final dynamic extra;

  _ServiceData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
    this.extra,
  });
}
