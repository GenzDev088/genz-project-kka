import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:otax/tabunganku/models/transaction_model.dart';

enum ReceiptBrand {
  bca,
  mandiri,
  bri,
  bni,
  dana,
  gopay,
  ovo,
  shopeepay,
  unknown,
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<Map<String, dynamic>> scanReceipt(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    double? detectedAmount = _parseAmount(recognizedText);
    TransactionType detectedType = _detectType(recognizedText.text);
    ReceiptBrand brand = _detectBrand(recognizedText.text);

    return {
      'amount': detectedAmount ?? 0.0,
      'type': detectedType,
      'brand': brand,
      'brandName': _getBrandDisplayName(brand),
      'text': recognizedText.text,
    };
  }

  String _getBrandDisplayName(ReceiptBrand brand) {
    switch (brand) {
      case ReceiptBrand.bca:
        return 'BCA Transfer';
      case ReceiptBrand.mandiri:
        return 'Mandiri Transfer';
      case ReceiptBrand.bri:
        return 'BRI Transfer';
      case ReceiptBrand.bni:
        return 'BNI Transfer';
      case ReceiptBrand.dana:
        return 'DANA Top-up';
      case ReceiptBrand.gopay:
        return 'GoPay Top-up';
      case ReceiptBrand.ovo:
        return 'OVO Top-up';
      case ReceiptBrand.shopeepay:
        return 'ShopeePay Top-up';
      default:
        return 'Bukti Transaksi';
    }
  }

  void dispose() {
    _textRecognizer.close();
  }

  double? _parseAmount(RecognizedText recognizedText) {
    String fullText = recognizedText.text.toLowerCase();
    ReceiptBrand brand = _detectBrand(fullText);

    List<TextLine> allLines = [];
    for (var block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }


    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final Map<ReceiptBrand, List<String>> brandKeywords = {
      ReceiptBrand.bca: ['nominal', 'jumlah', 'pembayaran'],
      ReceiptBrand.mandiri: ['jumlah', 'nominal', 'total'],
      ReceiptBrand.dana: ['total bayar', 'bayar', 'jumlah'],
      ReceiptBrand.gopay: ['total', 'jumlah', 'nominal'],
      ReceiptBrand.ovo: [
        'transfer',
        'total',
        'ovo cash',
        'nominal',
        'berhasil',
        'terpakai',
      ],
      ReceiptBrand.shopeepay: ['total pembayaran', 'pembayaran'],
      ReceiptBrand.bri: ['jumlah', 'nominal'],
      ReceiptBrand.bni: ['jumlah', 'nominal'],
      ReceiptBrand.unknown: [
        'total',
        'jumlah',
        'rp',
        'nominal',
        'bayar',
        'berhasil',
      ],
    };


    final List<String> negativeKeywords = [
      'biaya', 'blaya', 'blaya', // common misreads of biaya
      'admin', 'admln', 'adm',
      'pajak', 'pjk',
      'fee',
      'dpp',
      'ppn',
      'rekening',
      'rek.',
      'virtual account',
      'va',
      'no.',
      'nomor',
    ];

    List<String> targetKeywords =
        brandKeywords[brand] ?? brandKeywords[ReceiptBrand.unknown]!;

    Map<double, int> candidates = {}; // Amount : Score

    for (int i = 0; i < allLines.length; i++) {
      String lineText = allLines[i].text.toLowerCase();


      if (_isLikelyDateOrTime(lineText)) continue;


      if (negativeKeywords.any((nk) => lineText.contains(nk))) {
        continue; // ABSOLUTELY IGNORE ANY NUMBER ON THIS LINE
      }


      if (lineText.contains(RegExp(r'\b08\d{8,11}\b')) ||
          lineText.contains(RegExp(r'\b628\d{8,11}\b'))) {
        continue;
      }


      if (lineText.contains('id transaksi') ||
          lineText.contains('id order') ||
          lineText.contains('akun')) {
        continue;
      }

      double? val = _extractAmountFromText(allLines[i].text);
      if (val == null || val < 1 || val > 9999999999) continue;

      int score = 0;


      if (lineText.contains('rp') || lineText.contains('idr')) {
        score += 250;
        if (RegExp(r'(?:rp|idr)\s?\d+').hasMatch(lineText)) {
          score += 200;
        }
      }


      if (targetKeywords.any((kw) => lineText.contains(kw))) score += 400;


      if (i > 0) {
        String prevText = allLines[i - 1].text.toLowerCase();
        if (targetKeywords.any((kw) => prevText.contains(kw))) {

          double gap =
              allLines[i].boundingBox.top - allLines[i - 1].boundingBox.bottom;
          if (gap < allLines[i].boundingBox.height * 2.5) {
            score += 250;
          }
        }
      }


      if (val.toStringAsFixed(0).length > 10) score -= 500;


      if (lineText.length < 25) score += 100;

      candidates[val] = (candidates[val] ?? 0) + score;
    }

    if (candidates.isEmpty) return null;



    var sortedEntries = candidates.entries.toList()
      ..sort((a, b) {
        int scoreComp = b.value.compareTo(a.value);
        if (scoreComp != 0) return scoreComp;

        return b.key.compareTo(a.key);
      });

    if (sortedEntries.first.value < 100) return null;

    return sortedEntries.first.key;
  }

  bool _isLikelyDateOrTime(String text) {
    final dateRegex = RegExp(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}');
    final timeRegex = RegExp(r'\d{1,2}:\d{2}(?::\d{2})?');
    return dateRegex.hasMatch(text) || timeRegex.hasMatch(text);
  }

  double? _extractAmountFromText(String text) {
    final amountRegex = RegExp(r'(?:Rp\.?|IDR)?\s?([\d\.,]{1,})');
    final match = amountRegex.firstMatch(text);

    if (match != null) {
      String raw = match.group(1) ?? '';

      if (text.contains('/') || text.contains(':')) {
        if (!text.toLowerCase().contains('rp')) return null;
      }

      if (raw.endsWith(',00') || raw.endsWith('.00')) {
        raw = raw.substring(0, raw.length - 3);
      }

      String digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) return null;

      return double.tryParse(digitsOnly);
    }
    return null;
  }

  ReceiptBrand _detectBrand(String text) {
    String lower = text.toLowerCase();
    if (lower.contains('bca')) return ReceiptBrand.bca;
    if (lower.contains('mandiri')) return ReceiptBrand.mandiri;
    if (lower.contains('dana')) return ReceiptBrand.dana;
    if (lower.contains('gopay')) return ReceiptBrand.gopay;
    if (lower.contains('ovo')) return ReceiptBrand.ovo;
    if (lower.contains('shopeepay')) return ReceiptBrand.shopeepay;
    if (lower.contains('bri')) return ReceiptBrand.bri;
    if (lower.contains('bni')) return ReceiptBrand.bni;
    return ReceiptBrand.unknown;
  }

  TransactionType _detectType(String text) {
    String lowerText = text.toLowerCase();

    List<String> incomeKeywords = [
      'diterima',
      'masuk',
      'credit',
      'penerimaan',
      'top up',
      'isi saldo',
      'refund',
    ];

    for (var kw in incomeKeywords) {
      if (lowerText.contains(kw)) return TransactionType.income;
    }

    return TransactionType.expense;
  }
}
