import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String githubRepo = "OtaStoree/manta";

  static Future<void> checkAndPromptUpdate(BuildContext context) async {
    try {

      final PackageInfo info = await PackageInfo.fromPlatform();
      final String currentVersion = info.version; 


      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String latestTag = data['tag_name'] ?? ''; // Format: v1.0.1
        final String latestVersion = latestTag.replaceAll('v', '');
        
        final String releaseNotes = data['body'] ?? 'Update wajib untuk melanjutkan.';
        

        String? downloadUrl;
        if (data['assets'] != null && data['assets'].isNotEmpty) {
          for (var asset in data['assets']) {
            if (asset['name'].toString().endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'];
              break;
            }
          }
        }
        

        downloadUrl ??= data['html_url'];


        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showMandatoryUpdateDialog(context, latestVersion, releaseNotes, downloadUrl!);
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal mengecek update otomatis: $e");

    }
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final currParts = current.split('.');
      final lateParts = latest.split('.');
      for (int i = 0; i < 3; i++) {
        int c = int.parse(currParts[i]);
        int l = int.parse(lateParts[i]);
        if (l > c) return true;
        if (l < c) return false;
      }
      return false; // Sama
    } catch (e) {
      return false;
    }
  }

  static void _showMandatoryUpdateDialog(BuildContext context, String newVersion, String notes, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan klik luar
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Tidak bisa ditutup dengan tombol back
          child: AlertDialog(
            backgroundColor: const Color(0xFF111E30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: Colors.cyanAccent),
                const SizedBox(width: 10),
                const Text(
                  'Update Wajib',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versi $newVersion telah tersedia! Anda wajib memperbarui aplikasi untuk dapat menggunakannya.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    notes,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Update', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final uri = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
