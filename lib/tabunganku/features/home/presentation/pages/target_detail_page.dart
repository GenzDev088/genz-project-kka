import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/saving_target_model.dart';
import 'package:otax/tabunganku/providers/saving_target_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class TargetDetailPage extends ConsumerWidget {
  final SavingTargetModel target;
  final double totalBalance;

  const TargetDetailPage({
    super.key,
    required this.target,
    required this.totalBalance,
  });

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

    final progress = (target.targetAmount > 0)
        ? (totalBalance / target.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remainingDays = target.dueDate.difference(DateTime.now()).inDays;
    final remainingAmount = target.targetAmount - totalBalance;
    final isCompleted = progress >= 1.0;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => ref.read(appRouterProvider).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 20,
          ),
        ),
        title: Text(
          'Detail Target',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF121212)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    target.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.comicNeue(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCompleted ? 'TARGET TERCAPAI ✨' : 'SEDANG BERJALAN 🚀',
                      style: GoogleFonts.comicNeue(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ),
                      Column(
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
                              color: isDarkMode ? Colors.white24 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),


            _buildDetailRow(
              'Nominal Target',
              _formatRupiah(target.targetAmount),
              Icons.flag_rounded,
              AppColors.primary,
              isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Telah Terkumpul',
              _formatRupiah(totalBalance),
              Icons.account_balance_wallet_rounded,
              Colors.green,
              isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Sisa Kekurangan',
              remainingAmount <= 0 ? 'Lunas' : _formatRupiah(remainingAmount),
              Icons.hourglass_bottom_rounded,
              remainingAmount <= 0 ? Colors.green : Colors.red,
              isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Jatuh Tempo',
              '${DateFormat('d MMM yyyy').format(target.dueDate)} ($remainingDays Hari lagi)',
              Icons.calendar_today_rounded,
              Colors.orange,
              isDarkMode,
            ),

            const SizedBox(height: 48),


            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(appRouterProvider).push('/saving-target-form', extra: target),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      'Ubah Target',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.background,
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
                      await ref
                          .read(savingTargetServiceProvider)
                          .deleteTarget(target.id);
                      if (context.mounted) ref.read(appRouterProvider).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      'Hapus',
                      style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white38 : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.primaryDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
