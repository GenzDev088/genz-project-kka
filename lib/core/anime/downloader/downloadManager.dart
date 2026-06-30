import 'package:otax/core/anime/downloader/downloader.dart';
import 'package:otax/core/anime/downloader/downloaderHelper.dart';
import 'package:otax/core/anime/downloader/types.dart';
import 'package:otax/core/app/logging.dart';
import 'package:otax/core/app/runtimeDatas.dart';
import 'package:otax/ui/models/snackBar.dart';
import 'package:flutter/widgets.dart';


class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();


  static final List<DownloadItem> _downloadingItems = [];


  static final ValueNotifier<int> downloadsCount = ValueNotifier(0);


  static List<DownloadItem> get downloadingItems =>
      List.unmodifiable(_downloadingItems);

  final Downloader _downloader = Downloader(logger: Logs.downloader);


  static void enqueue(DownloadItem item) {
    _downloadingItems.add(item);
    downloadsCount.value++;
    Logs.downloader.log(
      "Added item to queue. Items in queue: ${downloadsCount.value}. [queue mode: ${(currentUserSettings?.useQueuedDownloads ?? false)}]",
    );
  }


  static void dequeue(int id) {
    _downloadingItems.removeWhere((it) => it.id == id);
    downloadsCount.value--;
  }


  Future<void> addDownloadTask(
    String url,
    String filename, {
    String? subtitleUrl,
    Map<String, String> customHeaders = const {},
  }) async {
    if (!(await DownloaderHelper().checkAndRequestPermission())) {
      floatingSnackBar("Provide storage access for downloading...");
      Logs.downloader.log(
        "Storage permission not granted. Rejecting download request...",
      );
      return;
    }
    final id = DownloaderHelper.generateId();

    final item = DownloadItem(
      id: id,
      url: url,
      status: DownloadStatus
          .queued, // Every download is queued before initialisation!
      fileName: filename,
      customHeaders: customHeaders,
      progress: 0,
      subtitleUrl: subtitleUrl,
    );

    await _downloader.startDownload(item);
  }




  void cancelDownload(int id) {
    _downloader.requestCancellation(id);
  }

  void pauseDownload(int id) {
    _downloader.requestPause(id);
  }

  void resumeDownload(int id) {
    _downloader.requestResume(id);
  }

  Future<void> retryDownload(int id) async {}
}
