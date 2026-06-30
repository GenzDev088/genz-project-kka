import 'package:otax/core/commons/subtitleParsers/subtitleParsers.dart';
import 'package:otax/core/commons/subtitleParsers/util.dart';
import 'package:otax/ui/models/widgets/subtitles/subtitle.dart';


class ASSRIPPER {

  Map<String, int>? _fieldOrder;

  List<Subtitle> parseASS(String rawAss) {
    final subtitles = <Subtitle>[];
    final lines = rawAss.split('\n');


    var inEventsSection = false;
    for (var line in lines) {
      final trimmed = line.trim();


      if (trimmed.startsWith('[')) {
        inEventsSection = trimmed.toLowerCase().contains('events');
      }


      if (inEventsSection && trimmed.startsWith('Format:')) {
        _fieldOrder = _parseFormatLine(line);
        break;
      }
    }

    final eventLines = lines.where((line) => line.startsWith('Dialogue:'));
    for (var eventLine in eventLines) {
      try {
        final parsed = _parseASSEventLine(eventLine);
        subtitles.add(parsed);
      } catch (_) {

        continue;
      }
    }
    return subtitles;
  }

  Map<String, int> _parseFormatLine(String line) {

    final content = line.substring(line.indexOf(':') + 1).trim();
    final fieldNames = content.split(',').map((f) => f.trim()).toList();
    final order = <String, int>{};
    for (var i = 0; i < fieldNames.length; i++) {
      order[fieldNames[i]] = i;
    }
    return order;
  }

  String _removeASSFormatting(String text) {
    return text.replaceAll(RegExp(r'\{.*?\}'), '');
  }

  SubtitleAlignment _getAlignmentFromStyleName(String styleName) {

    if (styleName.contains('topcenter') || styleName.contains('top_center')) {
      return SubtitleAlignment.topCenter;
    } else if (styleName.contains('topleft') ||
        styleName.contains('top_left')) {
      return SubtitleAlignment.topLeft;
    } else if (styleName.contains('topright') ||
        styleName.contains('top_right')) {
      return SubtitleAlignment.topRight;
    } else if (styleName.contains('bottomcenter') ||
        styleName.contains('bottom_center')) {
      return SubtitleAlignment.bottomCenter;
    } else if (styleName.contains('bottomleft') ||
        styleName.contains('bottom_left')) {
      return SubtitleAlignment.bottomLeft;
    } else if (styleName.contains('bottomright') ||
        styleName.contains('bottom_right')) {
      return SubtitleAlignment.bottomRight;
    } else if (styleName.contains('centerleft') ||
        styleName.contains('center_left') ||
        styleName.contains('middleleft')) {
      return SubtitleAlignment.centerLeft;
    } else if (styleName.contains('centerright') ||
        styleName.contains('center_right') ||
        styleName.contains('middleright')) {
      return SubtitleAlignment.centerRight;
    } else if (styleName == 'center' || styleName.contains('middle')) {
      return SubtitleAlignment.center;
    }

    return SubtitleAlignment.bottomCenter;
  }

  Subtitle _parseASSEventLine(String line) {
    int fieldCount = 10; // maximum params

    if (_fieldOrder != null && _fieldOrder!.isNotEmpty) {
      fieldCount = _fieldOrder!.length;
    }


    final content = line.substring('Dialogue:'.length).trim();
    final fields = <String>[];
    var startIdx = 0;
    for (var i = 0; i < fieldCount - 1; i++) {
      final next = content.indexOf(',', startIdx);
      if (next == -1) {

        break;
      }
      fields.add(content.substring(startIdx, next));
      startIdx = next + 1;
    }

    final rawText = startIdx < content.length
        ? content.substring(startIdx)
        : '';

    if (fields.length < 3) {
      throw FormatException('Malformed ASS Dialogue line: not enough fields');
    }


    startIdx = _fieldOrder?['Start'] ?? 1;
    final endIdx = _fieldOrder?['End'] ?? 2;

    if (fields.length <= startIdx || fields.length <= endIdx) {
      throw FormatException('Malformed ASS Dialogue line: missing time fields');
    }


    Duration start = Duration.zero;
    Duration end = Duration.zero;
    start = Subtitleparsers.parseDuration(fields[startIdx].trim());
    end = Subtitleparsers.parseDuration(fields[endIdx].trim());


    SubtitleAlignment alignment = SubtitleAlignment.bottomCenter;
    final styleIdx = _fieldOrder?['Style'] ?? 3;
    if (fields.length > styleIdx) {
      final styleName = fields[styleIdx].trim().toLowerCase();
      alignment = _getAlignmentFromStyleName(styleName);
    }


    final alignPattern = RegExp(r'\{\\an(\d+)\}');
    final alignMatches = alignPattern.allMatches(rawText);
    if (alignMatches.isNotEmpty) {

      final lastMatch = alignMatches.last;
      final alignmentNumber = int.parse(lastMatch.group(1)!);
      alignment = SubtitleParserUtil.getAlignmentFromNumber(alignmentNumber);
    }


    final dialogue = _removeASSFormatting(
      rawText,
    ).replaceAll(r"\N", "\n").trim();

    return Subtitle(
      dialogue: dialogue,
      end: end,
      start: start,
      alignment: alignment,
    );
  }
}
