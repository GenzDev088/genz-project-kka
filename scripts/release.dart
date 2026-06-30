import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🚀 Memulai Proses Auto-Release MANTA...\n');


  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ File .env tidak ditemukan. Silakan buat file .env dengan format:');
    print('GITHUB_TOKEN=ghp_xxxxxxx');
    print('GITHUB_REPO=OtaStoree/manta');
    exit(1);
  }

  final envContent = envFile.readAsLinesSync();
  String? githubToken;
  String githubRepo = 'OtaStoree/manta';

  for (var line in envContent) {
    if (line.startsWith('GITHUB_TOKEN=')) {
      githubToken = line.substring('GITHUB_TOKEN='.length).trim();
    }
    if (line.startsWith('GITHUB_REPO=')) {
      githubRepo = line.substring('GITHUB_REPO='.length).trim();
    }
  }

  if (githubToken == null || githubToken.isEmpty) {
    print('❌ GITHUB_TOKEN tidak valid di file .env');
    exit(1);
  }


  final pubspecFile = File('pubspec.yaml');
  final lines = pubspecFile.readAsLinesSync();
  String oldVersion = '';
  String newVersion = '';
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('version: ')) {
      oldVersion = lines[i].substring('version: '.length).trim();
      final parts = oldVersion.split('+');
      if (parts.length == 2) {
        final semantic = parts[0].split('.');
        final buildNumber = int.parse(parts[1]);
        

        final patch = int.parse(semantic[2]) + 1;
        newVersion = '${semantic[0]}.${semantic[1]}.$patch+${buildNumber + 1}';
      } else {
        newVersion = '${oldVersion.split('+')[0]}+1';
      }
      lines[i] = 'version: $newVersion';
      break;
    }
  }

  pubspecFile.writeAsStringSync(lines.join('\n') + '\n');
  print('✅ Versi berhasil dinaikkan: $oldVersion -> $newVersion');


  print('\n🔨 Sedang mem-build APK Release...');
  final process = await Process.start('flutter', ['build', 'apk', '--release'], runInShell: true);
  

  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });
  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  final exitCode = await process.exitCode;
  
  if (exitCode != 0) {
    print('❌ Gagal mem-build APK!');
    exit(1);
  }
  print('✅ APK berhasil di-build!');


  print('\n🌐 Mengunggah rilis ke GitHub ($githubRepo)...');
  final releaseUrl = Uri.parse('https://api.github.com/repos/$githubRepo/releases');
  
  final tagName = 'v${newVersion.split('+')[0]}';
  
  final releasePayload = {
    "tag_name": tagName,
    "target_commitish": "main",
    "name": "Update v$newVersion",
    "body": "Pembaruan otomatis sistem MANTA versi $newVersion",
    "draft": false,
    "prerelease": false
  };

  final releaseRes = await http.post(
    releaseUrl,
    headers: {
      'Authorization': 'token $githubToken',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(releasePayload),
  );

  if (releaseRes.statusCode != 201) {
    print('❌ Gagal membuat release di GitHub: ${releaseRes.body}');
    exit(1);
  }

  final releaseData = jsonDecode(releaseRes.body);
  final uploadUrl = releaseData['upload_url'].toString().split('{')[0]; // Hapus template query


  print('📦 Mengunggah APK ke GitHub Releases...');
  final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
  final apkBytes = apkFile.readAsBytesSync();

  final uploadRes = await http.post(
    Uri.parse('$uploadUrl?name=app-release.apk'),
    headers: {
      'Authorization': 'token $githubToken',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/vnd.android.package-archive',
    },
    body: apkBytes,
  );

  if (uploadRes.statusCode == 201) {
    print('🎉 SELESAI! Rilis versi $newVersion berhasil dipublikasikan!');
    print('Tautan Rilis: ${releaseData['html_url']}');
  } else {
    print('❌ Gagal mengunggah APK: ${uploadRes.body}');
    exit(1);
  }
}
