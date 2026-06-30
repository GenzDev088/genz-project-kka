import 'dart:io';
import 'dart:isolate';

import 'package:otax/core/commons/extractQuality.dart';
import 'package:collection/collection.dart';

import 'package:otax/core/anime/downloader/downloadManager.dart';
import 'package:otax/core/anime/downloader/downloaderCore.dart';
import 'package:otax/core/anime/downloader/downloaderHelper.dart';
import 'package:otax/core/anime/downloader/types.dart';
import 'package:otax/core/app/logging.dart';
import 'package:otax/core/app/runtimeDatas.dart';
import 'package:otax/core/commons/extensions.dart';
import 'package:otax/core/data/downloadHistory.dart';

enum _DownloadType { stream, video, image }


class Downloader {
  final DownloaderHelper _helper = DownloaderHelper();

  final Logbook? logger;

  Downloader({this.logger});

  static final Map<int, Isolate> _isolates = {};

  static final Map<int, ReceivePort> _receivePorts = {};


  static final Map<int, SendPort> _isolatePorts = {};


  static const int MAX_DOWNLOADS_COUNT = 5;


  static int MAX_STREAM_BATCH_SIZE = 5;


  static int MAX_RETRY_ATTEMPTS = 10;

  DownloadItem _getDownloadItem(int id) {
    final item = DownloadManager.downloadingItems.firstWhereOrNull(
      (it) => it.id == id,
    );
    if (item != null) return item;
    throw Exception("Couldnt find an item with given id!");
  }

  DownloadItem? _maybeGetDownloadItem(int id) =>
      DownloadManager.downloadingItems.firstWhereOrNull((it) => it.id == id);

  Future<void> startDownload(DownloadItem item) async {

    DownloadManager.enqueue(item);

    _processQueue();
  }


  Future<void> _processQueue() async {
    final isFull = DownloadManager.downloadsCount.value >= MAX_DOWNLOADS_COUNT;

    if (isFull) return; // ignore download request if batch is full

    if (currentUserSettings?.useQueuedDownloads ?? false) {

      final item = DownloadManager.downloadingItems.firstWhereOrNull(
        (it) => it.status == DownloadStatus.queued,
      );
      if (item == null) return;


      if (DownloadManager.downloadingItems.any(
        (it) => it.status == DownloadStatus.downloading,
      ))
        return;

      await _fireUpIsolate(item);
    } else {

      while (DownloadManager.downloadsCount.value < MAX_DOWNLOADS_COUNT) {
        final next = DownloadManager.downloadingItems.firstWhereOrNull(
          (it) => it.isQueued,
        );
        if (next == null) break;
        next.status = DownloadStatus.downloading;
        await _fireUpIsolate(next);
      }
    }
  }

  Future<void> _fireUpIsolate(DownloadItem item) async {
    Future<void> Function(DownloadTaskIsolate) downloadFunction;

    final type = await _getDownloadType(item);


    switch (type) {
      case _DownloadType.image:
        downloadFunction = DownloaderCore.downloadImage;
      case _DownloadType.video:
        downloadFunction = DownloaderCore.downloadVideo;
      case _DownloadType.stream:
        downloadFunction = DownloaderCore.downloadStream;
    }

    final path = await _helper.getDownloadsPath();

    final task = _cookTask(item, path);

    logger?.log('Queuing task $task with type: ${type.name}');


    final isolate = await Isolate.spawn(downloadFunction, task);
    _isolates[item.id] = isolate;
  }

  Future<void> _cleanUp(int id, {bool dequeue = true}) async {

    _isolates[id]?.kill(priority: Isolate.immediate); // NUKE THAT F-
    _isolates.remove(id);


    _isolatePorts.remove(id);


    _receivePorts[id]?.close();
    _receivePorts.remove(id);


    if (dequeue) DownloadManager.dequeue(id);
  }

  Future<void> _endTask(int id) async {

    await _cleanUp(id);


    _processQueue();
  }

  Future<void> requestCancellation(int id) async {
    _isolatePorts[id]?.send('cancel');


    DownloadManager.downloadingItems
            .firstWhereOrNull((it) => it.id == id)
            ?.status =
        DownloadStatus.cancelled;
  }

  Future<void> requestPause(int id) async {
    _isolatePorts[id]?.send('pause');
  }

  Future<void> requestResume(int id) async {
    _resumeTask(id);
  }

  Future<void> _pauseTask(
    int id,
    int progress,
    int nextSegmentIndex,
    String filePath,
  ) async {
    final item = _getDownloadItem(id);
    item.status = DownloadStatus.paused;
    item.lastDownloadedPart = nextSegmentIndex == -1 ? null : nextSegmentIndex;

  }

  Future<void> _resumeTask(int id) async {
    if (_isolates[id] == null) {
      final item = _getDownloadItem(id);
      return _fireUpIsolate(item);
    } else {

      _isolatePorts[id]?.send('resume');
    }
  }

  Future<void> _retryDownload(int id) async {
    _cleanUp(id, dequeue: false);
    final item = _getDownloadItem(id);


    item.progress = 0;
    item.status = DownloadStatus.downloading;
    item.lastDownloadedPart = null;

    _fireUpIsolate(item);
  }

  Future<void> _handleMessage(dynamic msg) async {
    if (!(msg is DownloadMessage)) {
      print("Recieved message. But not as DownloadMessage!\nMessage: $msg");
      return;
    }
    switch (msg.status) {

      case 'progress':
        {
          _maybeGetDownloadItem(msg.id)?.progress = msg.progress;
          _helper.sendProgressNotif(
            msg.id,
            msg.progress,
            msg.extras[0] as String,
            msg.extras[1] as String,
          );
          if (msg.progress % 10 == 0)
            logger?.log("<${msg.id}> Progress: ${msg.progress}%");
          break;
        }
      case 'downloading':
        _maybeGetDownloadItem(msg.id)?.status = DownloadStatus.downloading;
        logger?.log("<${msg.id}> Changed download state to 'downloading'.");
        break;

      case 'complete':
        {
          if (!msg.silent) {
            _helper.sendCompletedNotif(
              msg.id,
              msg.extras[0] as String,
              msg.extras[1] as String,
            );
            DownloadHistory.saveItem(
              _cookHistoryItem(
                _getDownloadItem(msg.id),
                DownloadStatus.completed,
                msg.extras[1] as String,
              ),
            );
          }
          _endTask(msg.id);
          logger?.log("Download completed for task ${msg.id}.");
          break;
        }
      case 'error':
        {
          _endTask(msg.id);
          print("Welp, something went wrong..");
          logger?.log(
            "Download error for ${msg.id}. Reason: ${msg.message} \n StackTrace: ${msg.extras[0] as String}",
          );
          await logger?.writeLog();
          break;
        }
      case 'fail':
        {
          _helper.sendCancelledNotif(msg.id, failed: true);
          _endTask(msg.id);
          logger?.log("Download failed for ${msg.id}. Reason: ${msg.message}");
          break;
        }
      case 'cancel':
        {
          _helper.sendCancelledNotif(msg.id, failed: false);
          _endTask(msg.id);

          logger?.log(
            "Download cancelled for ${msg.id}. Reason: ${msg.message}",
          );
          break;
        }
      case 'paused':
        _pauseTask(
          msg.id,
          msg.progress,
          msg.extras.first as int,
          msg.extras[1] as String,
        );
        logger?.log("<${msg.id}> Download paused.");
        break;

      case 'retry':
        _retryDownload(msg.id);
        logger?.log("<${msg.id}> Retrying download.");
        break;


      case 'port':
        if (msg.extras.isNotEmpty && msg.extras.first is SendPort)
          _isolatePorts[msg.id] = msg.extras.first as SendPort;
        break;

      case 'isolate_timeout':
        _cleanUp(msg.id, dequeue: false);
        logger?.log("<${msg.id}> Isolate timed out. Nuking the isolate.");
        break;

      default:
        {
          throw Exception(
            "What the f*ck is ${msg.status} supposed to mean? (Unknown status exception)",
          );
        }
    }
  }

  DownloadTaskIsolate _cookTask(DownloadItem item, String downloadPath) {
    final rp = ReceivePort();

    rp.listen(_handleMessage);



    _receivePorts[item.id]?.close(); // close if already exists (JIC)
    _receivePorts[item.id] = rp;

    final task = DownloadTaskIsolate(
      url: item.url,
      fileName: item.fileName,
      customHeaders: item.customHeaders,
      retryAttempts: MAX_RETRY_ATTEMPTS,
      parallelBatches:
          MAX_STREAM_BATCH_SIZE *
          ((currentUserSettings?.fasterDownloads ?? false) ? 2 : 1),
      subsUrl: item.subtitleUrl,
      sendPort: rp.sendPort,
      id: item.id,

      downloadPath: downloadPath,
      resumeFrom: item.lastDownloadedPart ?? 0,
    );

    return task;
  }

  DownloadHistoryItem _cookHistoryItem(
    DownloadItem item,
    DownloadStatus newStatus,
    String filepath,
  ) {
    int size;


    try {
      size = File(filepath).lengthSync();
    } catch (err) {
      size = 0;
    }

    return DownloadHistoryItem(
      id: item.id,
      status: newStatus,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      filePath: filepath,
      url: item.url,
      headers: item.customHeaders,
      fileName: item.fileName,
      size: size,
      lastDownloadedPart: item.lastDownloadedPart,
    );
  }

  Future<_DownloadType> _getDownloadType(DownloadItem item) async {
    final ext = _helper.extractExtension(item.url);
    final videoExtensions = ['mp4', 'mkv', 'avi', 'webm', 'flv'];
    final streamExtensions = ['m3u8', 'm3u'];

    if ((videoExtensions + streamExtensions).contains(ext)) {
      if (videoExtensions.contains(ext)) return _DownloadType.video;
      if (streamExtensions.contains(ext)) return _DownloadType.stream;
      if (['webp', 'jpeg', 'jpg', 'png'].contains(ext))
        return _DownloadType.image;
    }


    final mime = await _helper.getMimeType(item.url, item.customHeaders);
    if (mime == null) throw Exception("Couldnt identify the media type.");
    if (mime.contains("mpegurl") ||
        await isM3u8Playlist(item.url, customHeader: item.customHeaders))
      return _DownloadType.stream;
    if (mime.contains("video")) return _DownloadType.video;
    if (mime.contains("image")) return _DownloadType.image;

    throw Exception("The file of recieved format downloading isnt supported!");
  }
}
