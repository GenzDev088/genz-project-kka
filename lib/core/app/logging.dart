import 'dart:io';

import 'package:otax/core/app/runtimeDatas.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Logs {


  static final app = Logbook("APP"); // Overall
  static final player = Logbook("PLAYER"); // Player related
  static final downloader = Logbook("DOWNLOADER"); // downloader service


  static Future<void> writeAllLogs() async {
    await app.writeLog();
    await player.writeLog();
    await downloader.writeLog();
  }
}

class Logbook {
  final String tag;
  Logbook(this.tag) {
    final now = DateTime.now();
    session =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}_"
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
  }

  late final String session;

  final List<String> _logBuffer = [];


  ValueNotifier<List<String>> logNotifier = ValueNotifier([]);







  void log(String message, {bool addToBuffer = false}) {
    if (addToBuffer || (currentUserSettings?.enableLogging ?? false)) {
      if (this._logBuffer.length > 500) {

        this._logBuffer.removeAt(0);
      }
      _logBuffer.add("[$tag]: $message");

      logNotifier.value = List.unmodifiable(_logBuffer);
    }

    if (kDebugMode) {
      debugPrint("[$tag]: $message");
    }
  }


  void clearLog() {
    _logBuffer.clear();
    logNotifier.value.clear();
  }


  Future<void> writeLog() async {
    try {

      final docs = await getApplicationDocumentsDirectory();
      final dir = await Directory(
        '${docs.path}/logs/${tag.toLowerCase()}',
      ).create(recursive: true);

      final filePath = "${dir.path}/$session.txt";
      final file = File(filePath);
      final data = _logBuffer.join(' \n');


      await file.writeAsString(data, mode: FileMode.append);
      _logBuffer.clear();
    } catch (err) {
      print("Failed to write log: $err");
    }
  }
}
