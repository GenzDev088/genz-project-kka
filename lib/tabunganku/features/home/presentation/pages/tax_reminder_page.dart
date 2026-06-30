import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/models/tax_reminder_model.dart';
import 'package:otax/tabunganku/services/tax_reminder_service.dart';

class TaxReminderPage extends ConsumerStatefulWidget {
  const TaxReminderPage({super.key});

  @override
  ConsumerState<TaxReminderPage> createState() => _TaxReminderPageState();
}

class _TaxReminderPageState extends ConsumerState<TaxReminderPage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final remindersAsync = ref.watch(taxRemindersStreamProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 18,
          ),
        ),
        title: Text(
          'Pengingat Pajak',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: remindersAsync.when(
        data: (reminders) => reminders.isEmpty
            ? _buildEmptyState(isDarkMode)
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Jadwal Pembayaran Pajak',
                    style: GoogleFonts.comicNeue(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jangan biarkan denda menumpuk, catat tanggal jatuh temponya.',
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF121212)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reminders.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) => _buildTaxTile(
                          reminders[index],
                          isDarkMode,
                          isFirst: index == 0,
                          isLast: index == reminders.length - 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(isDarkMode),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Pengingat',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notification_important_outlined,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Pengingat',
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white30 : Colors.black26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan jadwal pajak Anda seperti PKB atau PBB agar tidak terlambat membayar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.comicNeue(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxTile(
    TaxReminderModel item,
    bool isDarkMode, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final statusColor = item.status == 'Sudah Bayar'
        ? Colors.green
        : Colors.redAccent;
    final iconColor = Color(item.colorValue);

    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(24) : Radius.zero,
      bottom: isLast ? const Radius.circular(24) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIcon(item.iconCodePoint),
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10,
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormat(
                              'd MMM yyyy',
                              'id_ID',
                            ).format(item.dueDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.comicNeue(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                onSelected: (val) {
                  if (val == 'status') {
                    _toggleStatus(item);
                  } else if (val == 'delete') {
                    _deleteReminder(item.id);
                  }
                },
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.withValues(alpha: 0.5),
                  size: 18,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          item.status == 'Sudah Bayar'
                              ? Icons.undo_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.status == 'Sudah Bayar'
                              ? 'Tandai Belum Bayar'
                              : 'Tandai Sudah Bayar',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Hapus Pengingat',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  void _toggleStatus(TaxReminderModel item) {
    final newStatus = item.status == 'Sudah Bayar'
        ? 'Belum Bayar'
        : 'Sudah Bayar';
    ref
        .read(taxReminderServiceProvider)
        .updateReminder(item.copyWith(status: newStatus));
  }

  void _deleteReminder(String id) {
    ref.read(taxReminderServiceProvider).deleteReminder(id);
  }

  IconData _getIcon(int codePoint) {

    if (codePoint == Icons.notification_important_rounded.codePoint) {
      return Icons.notification_important_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Future<void> _showAddDialog(bool isDarkMode) async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Pengingat Baru',
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NAMA PAJAK',
                style: GoogleFonts.comicNeue(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                style: GoogleFonts.comicNeue(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Contoh: PKB Motor, PBB Rumah',
                  hintStyle: GoogleFonts.comicNeue(
                    fontSize: 13,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  fillColor: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'TANGGAL JATUH TEMPO',
                style: GoogleFonts.comicNeue(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate),
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.comicNeue(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                final reminder = TaxReminderModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  dueDate: selectedDate,
                  status: 'Belum Bayar',
                  iconCodePoint: Icons.notification_important_rounded.codePoint,
                  colorValue: Colors.orange.value,
                );
                ref.read(taxReminderServiceProvider).addReminder(reminder);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.comicNeue(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
