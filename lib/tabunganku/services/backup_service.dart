import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const String _botTokenKey = 'telegram_bot_token';
  static const String _userIdKey = 'telegram_user_id';

  Future<void> saveTelegramConfig(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_botTokenKey, token);
    await prefs.setString(_userIdKey, userId);
  }

  Future<Map<String, String>> getTelegramConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_botTokenKey) ?? '',
      'userId': prefs.getString(_userIdKey) ?? '',
    };
  }

  Future<String?> createBackupZip() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final backupFolder = Directory(p.join(tempDir.path, 'tabunganku_backup'));

      if (await backupFolder.exists()) {
        await backupFolder.delete(recursive: true);
      }
      await backupFolder.create();


      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefsData = <String, dynamic>{};
      for (final key in keys) {

        prefsData[key] = prefs.get(key);
      }
      final prefsFile = File(p.join(backupFolder.path, 'shared_prefs.json'));
      await prefsFile.writeAsString(jsonEncode(prefsData));


      final photosDir = Directory(p.join(appDir.path, 'profile_photos'));
      if (await photosDir.exists()) {
        final backupPhotosDir = Directory(
          p.join(backupFolder.path, 'profile_photos'),
        );
        await backupPhotosDir.create();

        await for (final entity in photosDir.list()) {
          if (entity is File) {
            await entity.copy(
              p.join(backupPhotosDir.path, p.basename(entity.path)),
            );
          }
        }
      }


      final zipEncoder = ZipFileEncoder();
      final zipPath = p.join(
        tempDir.path,
        'tabunganku_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      zipEncoder.create(zipPath);
      await zipEncoder.addDirectory(backupFolder);
      zipEncoder.close();

      return zipPath;
    } catch (e) {
      print("Error creating backup: $e");
      return null;
    }
  }

  Future<bool> sendBackupToTelegram(String zipPath) async {
    final config = await getTelegramConfig();
    final token = config['token']!;
    final userId = config['userId']!;

    if (token.isEmpty || userId.isEmpty) return false;

    try {
      final url = Uri.parse('https://api.telegram.org/bot$token/sendDocument');
      final request = http.MultipartRequest('POST', url);
      request.fields['chat_id'] = userId;
      request.fields['caption'] =
          '📦 Backup Data TabunganKu - ${DateTime.now().toString()}';

      final file = await http.MultipartFile.fromPath('document', zipPath);
      request.files.add(file);

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Error sending to telegram: $e");
      return false;
    }
  }

  Future<bool> restoreFromZip(File zipFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final decodeDir = Directory(p.join(tempDir.path, 'restore_temp'));

      if (await decodeDir.exists()) {
        await decodeDir.delete(recursive: true);
      }
      await decodeDir.create();


      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(decodeDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(
            p.join(decodeDir.path, filename),
          ).createSync(recursive: true);
        }
      }


      final prefsFile = File(p.join(decodeDir.path, 'shared_prefs.json'));
      if (await prefsFile.exists()) {
        final prefsData =
            jsonDecode(await prefsFile.readAsString()) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();


        for (final entry in prefsData.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is String)
            await prefs.setString(key, value);
          else if (value is int)
            await prefs.setInt(key, value);
          else if (value is double)
            await prefs.setDouble(key, value);
          else if (value is bool)
            await prefs.setBool(key, value);
          else if (value is List)
            await prefs.setStringList(key, value.cast<String>());
        }
      }


      final backupPhotosDir = Directory(
        p.join(decodeDir.path, 'profile_photos'),
      );
      if (await backupPhotosDir.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory(p.join(appDir.path, 'profile_photos'));
        if (!await photosDir.exists()) await photosDir.create(recursive: true);

        await for (final entity in backupPhotosDir.list()) {
          if (entity is File) {
            await entity.copy(p.join(photosDir.path, p.basename(entity.path)));
          }
        }
      }

      return true;
    } catch (e) {
      print("Error restoring: $e");
      return false;
    }
  }
}
