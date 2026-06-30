import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';

class ExportService {

  static String _fmtRupiah(double v) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(v);
  }


  static String buildTextSummary({
    required List<TransactionModel> transactions,
    required String monthLabel,
  }) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;

    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════╗');
    buf.writeln('   RINGKASAN KEUANGAN');
    buf.writeln('   $monthLabel');
    buf.writeln('╚══════════════════════════════╝');
    buf.writeln();
    buf.writeln('▶ Total Pemasukan : ${_fmtRupiah(income)}');
    buf.writeln('▶ Total Pengeluaran: ${_fmtRupiah(expense)}');
    buf.writeln('▶ Saldo Akhir     : ${_fmtRupiah(balance)}');
    buf.writeln();
    buf.writeln('─── DETAIL TRANSAKSI (${transactions.length} item) ───');
    buf.writeln();


    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    for (final t in sorted) {
      final sign = t.type == TransactionType.income ? '+' : '-';
      final dateStr = DateFormat('dd/MM HH:mm').format(t.date);
      buf.writeln(
        '$sign ${_fmtRupiah(t.amount).padRight(18)} $dateStr  ${t.title}',
      );
    }

    buf.writeln();
    buf.writeln('─────────────────────────────────');
    buf.writeln('Dibuat oleh TabunganKu App');
    buf.writeln(
      DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now()),
    );

    return buf.toString();
  }


  static Future<String> buildPdf({
    required List<TransactionModel> transactions,
    required String monthLabel,
  }) async {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;


    final poppinsRegular = await rootBundle.load(
      "assets/fonts/Poppins-Regular.ttf",
    );
    final poppinsMedium = await rootBundle.load(
      "assets/fonts/Poppins-Medium.ttf",
    );
    final poppinsBold = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final logoData = await rootBundle.load('assets/icon.png');

    final fontRegular = pw.Font.ttf(poppinsRegular);
    final fontMedium = pw.Font.ttf(poppinsMedium);
    final fontBold = pw.Font.ttf(poppinsBold);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final doc = pw.Document();
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));


    final primaryColor = PdfColor.fromHex('#009688');
    final secondaryColor = PdfColor.fromHex('#004D40');
    final lightBg = PdfColor.fromHex('#F1F8F7');
    final incomeColor = PdfColor.fromHex('#2E7D32');
    final expenseColor = PdfColor.fromHex('#C62828');
    final balanceColor = balance >= 0
        ? PdfColor.fromHex('#00796B')
        : PdfColor.fromHex('#D32F2F');


    final headerStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 18,
      color: PdfColor.fromHex('#009688'),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      height: 45,
                      width: 45,
                      child: pw.Image(logoImage),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TabunganKu', style: headerStyle),
                        pw.Text(
                          'Catatan Keuangan Cerdas & Rapi',
                          style: pw.TextStyle(
                            font: fontMedium,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: primaryColor, width: 0.5),
                      ),
                      child: pw.Text(
                        monthLabel,
                        style: pw.TextStyle(
                          font: fontBold,
                          color: primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Record: ${transactions.length}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 15),
          ],
        ),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Laporan ini digenerate secara otomatis melalui aplikasi TabunganKu.',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                  style: pw.TextStyle(
                    font: fontMedium,
                    fontSize: 8,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (ctx) => [

          pw.Text(
            'RINGKASAN KEUANGAN',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: secondaryColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _pdfSummaryCard(
                'PEMASUKAN',
                _fmtRupiah(income),
                incomeColor,
                PdfColor.fromHex('#E8F5E9'),
                fontBold,
                fontRegular,
              ),
              pw.SizedBox(width: 12),
              _pdfSummaryCard(
                'PENGELUARAN',
                _fmtRupiah(expense),
                expenseColor,
                PdfColor.fromHex('#FFEBEE'),
                fontBold,
                fontRegular,
              ),
              pw.SizedBox(width: 12),
              _pdfSummaryCard(
                'SALDO AKHIR',
                _fmtRupiah(balance),
                balanceColor,
                PdfColor.fromHex('#E0F2F1'),
                fontBold,
                fontRegular,
              ),
            ],
          ),
          pw.SizedBox(height: 30),


          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'RIWAYAT TRANSAKSI',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: secondaryColor,
                  letterSpacing: 1,
                ),
              ),
              pw.Text(
                'Dicetak: ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),


          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(70), // Tanggal
              1: const pw.FlexColumnWidth(3), // Keterangan
              2: const pw.FlexColumnWidth(1.5), // Kategori
              3: const pw.FlexColumnWidth(2), // Nominal
              4: const pw.FixedColumnWidth(45), // Jenis
            },
            children: [

              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _tableHeader('TANGGAL', fontBold),
                  _tableHeader('KETERANGAN', fontBold),
                  _tableHeader('KATEGORI', fontBold),
                  _tableHeader('NOMINAL', fontBold),
                  _tableHeader('TIPE', fontBold),
                ],
              ),

              ...sorted.map((t) {
                final isIncome = t.type == TransactionType.income;
                final amountColor = isIncome ? incomeColor : expenseColor;

                return pw.TableRow(
                  children: [
                    _tableCell(
                      DateFormat('dd/MM/yy\nHH:mm').format(t.date),
                      fontRegular,
                    ),
                    _tableCell(t.title, fontMedium),
                    _tableCell(t.category, fontRegular),
                    _tableCell(
                      _fmtRupiah(t.amount),
                      fontBold,
                      color: amountColor,
                    ),
                    _tableCell(
                      isIncome ? 'Masuk' : 'Keluar',
                      fontBold,
                      color: amountColor,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeMonth = monthLabel.replaceAll(' ', '_').replaceAll('/', '-');
    final file = File('${dir.path}/TabunganKu_$safeMonth.pdf');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  static pw.Widget _pdfSummaryCard(
    String label,
    String value,
    PdfColor color,
    PdfColor bg,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7,
                font: fontBold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, font: fontBold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(
    String text,
    pw.Font font, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, font: font, fontSize: 8),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    PdfColor? color,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }


  static Future<void> shareMonthlyReport({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required String monthLabel,
    required bool asPdf,
  }) async {
    try {
      if (asPdf) {
        final path = await buildPdf(
          transactions: transactions,
          monthLabel: monthLabel,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Laporan Keuangan $monthLabel – TabunganKu',
          ),
        );
      } else {
        final text = buildTextSummary(
          transactions: transactions,
          monthLabel: monthLabel,
        );
        await SharePlus.instance.share(
          ShareParams(text: text, subject: 'Laporan Keuangan $monthLabel'),
        );
      }
    } catch (e) {
      debugPrint('Error sharing report: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membagikan laporan: $e')));
      }
    }
  }
}
