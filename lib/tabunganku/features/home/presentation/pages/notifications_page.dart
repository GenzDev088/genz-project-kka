import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/models/notification_model.dart';
import 'package:otax/tabunganku/providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
          'Notifikasi',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
            child: Text(
              'Tandai Dibaca',
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _buildNotificationTile(context, ref, n, isDarkMode);
                  },
                ),
              ),
              if (notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(notificationNotifierProvider.notifier)
                          .clearAll(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Hapus Semua Riwayat',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Notifikasi',
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua kabar terbaru akan muncul di sini',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    NotificationModel n,
    bool isDarkMode,
  ) {
    IconData icon;
    Color color;

    switch (n.type) {
      case NotificationType.badge:
        icon = Icons.emoji_events_rounded;
        color = Colors.amber;
        break;
      case NotificationType.savings:
        icon = Icons.track_changes_rounded;
        color = AppColors.primary;
        break;
      case NotificationType.family:
        icon = Icons.family_restroom_rounded;
        color = Colors.blue;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        color = Colors.teal;
        break;
      case NotificationType.bills:
        icon = Icons.receipt_long_rounded;
        color = Colors.redAccent;
        break;
      case NotificationType.investment:
        icon = Icons.trending_up_rounded;
        color = Colors.indigo;
        break;
      case NotificationType.tax:
        icon = Icons.account_balance_rounded;
        color = Colors.deepPurpleAccent;
        break;
      case NotificationType.recurring:
        icon = Icons.loop_rounded;
        color = Colors.teal;
        break;
      case NotificationType.healthCheck:
        icon = Icons.health_and_safety_rounded;
        color = Colors.green;
        break;
      case NotificationType.gold:
        icon = Icons.monetization_on_rounded;
        color = Colors.amber.shade700;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!n.isRead) {
          ref.read(notificationNotifierProvider.notifier).markAsRead(n.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead
              ? (isDarkMode
                    ? const Color(0xFF121212)
                    : AppColors.background.withValues(alpha: 0.5))
              : (isDarkMode
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.primary.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: n.isRead
                ? (isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade100)
                : AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.comicNeue(
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(n.timestamp),
                        style: GoogleFonts.comicNeue(
                          fontSize: 10,
                          color: isDarkMode ? Colors.white24 : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(n.timestamp),
                    style: GoogleFonts.comicNeue(
                      fontSize: 9,
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
