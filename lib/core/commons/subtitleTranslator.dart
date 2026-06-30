

import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:otax/ui/models/widgets/subtitles/subtitle.dart';




const _kSeparator = '\u2060|\u2060|\u2060|\u2060';




const _kBatchSize = 80;


const _kDelayBetweenBatches = Duration(milliseconds: 400);


const _kRequestTimeout = Duration(seconds: 20);

class SubtitleTranslator {









  static Future<List<Subtitle>> translate(
    List<Subtitle> subtitles, {
    String targetLang = 'id',
    String sourceLang = 'auto',
    void Function(double progress)? onProgress,
  }) async {
    if (subtitles.isEmpty) return subtitles;

    final dialogues = subtitles.map((s) => s.dialogue).toList();
    final translatedDialogues = List<String>.from(dialogues); // fallback = asli


    final int totalBatches = (dialogues.length / _kBatchSize).ceil();

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final start = batchIndex * _kBatchSize;
      final end = min(start + _kBatchSize, dialogues.length);
      final batchTexts = dialogues.sublist(start, end);

      try {
        final translated = await _translateBatch(
          batchTexts,
          targetLang: targetLang,
          sourceLang: sourceLang,
        );


        for (int i = 0; i < translated.length; i++) {
          if (start + i < translatedDialogues.length) {
            translatedDialogues[start + i] = translated[i].isNotEmpty
                ? translated[i]
                : dialogues[start + i]; // fallback ke asli kalau kosong
          }
        }
      } catch (e) {

        print('[SubtitleTranslator] Batch $batchIndex gagal: $e');
      }


      onProgress?.call((batchIndex + 1) / totalBatches);


      if (batchIndex < totalBatches - 1) {
        await Future.delayed(_kDelayBetweenBatches);
      }
    }


    return List.generate(subtitles.length, (i) {
      return Subtitle(
        start: subtitles[i].start,
        end: subtitles[i].end,
        alignment: subtitles[i].alignment,
        dialogue: translatedDialogues[i],
      );
    });
  }



  static Future<List<String>> _translateBatch(
    List<String> texts, {
    required String targetLang,
    required String sourceLang,
  }) async {

    final cleaned = texts.map(_cleanText).toList();
    final joined = cleaned.join(_kSeparator);

    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': sourceLang,
      'tl': targetLang,
      'dt': 't',
      'q': joined,
    });

    final response = await http.get(uri).timeout(_kRequestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Google Translate error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    final parts = decoded[0] as List<dynamic>;
    final resultJoined = parts
        .map((part) => (part[0] as String? ?? ''))
        .join('');



    final results = resultJoined
        .split(RegExp(r'\s*\u2060\|\u2060\|\u2060\|\u2060\s*'))
        .map((s) => s.trim())
        .toList();



    if (results.length != texts.length) {
      print(
        '[SubtitleTranslator] Jumlah baris tidak cocok: input=${texts.length}, output=${results.length}',
      );

      final fallbackResults = resultJoined
          .split('||||')
          .map((s) => s.trim())
          .toList();
      if (fallbackResults.length == texts.length) return fallbackResults;

      return texts;
    }

    return results;
  }


  static String _cleanText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_kSeparator, ' ') // hapus separator kalau kebetulan ada
        .trim();
  }
}
