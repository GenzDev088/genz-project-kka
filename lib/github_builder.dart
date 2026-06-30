import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const Color _bg = Color(0xFF070B12);
const Color _surface = Color(0xFF0D1018);
const Color _card = Color(0xFF111520);
const Color _card2 = Color(0xFF151A28);
const Color _border = Color(0xFF1C2235);
const Color _border2 = Color(0xFF252D42);
const Color _cyan = Color(0xFF00D4FF);
const Color _cyanDim = Color(0xFF0A3D55);
const Color _blue = Color(0xFF4B8FFF);
const Color _blueDim = Color(0xFF162040);
const Color _green = Color(0xFF00E57A);
const Color _greenDim = Color(0xFF003D20);
const Color _red = Color(0xFFFF4F6A);
const Color _redDim = Color(0xFF3D0A12);
const Color _amber = Color(0xFFFFB340);
const Color _purple = Color(0xFFA78BFA);
const Color _text = Color(0xFFE2EAF8);
const Color _textSub = Color(0xFF6B7A9B);
const Color _textMute = Color(0xFF2E3650);
const Color _lcNorm = Color(0xFFB8C4DC);
const Color _lcOk = Color(0xFF00E57A);
const Color _lcErr = Color(0xFFFF4F6A);
const Color _lcInfo = Color(0xFF60A5FA);
const Color _lcSys = Color(0xFF4A546A);
const Color _lcStep = Color(0xFFA78BFA);

enum _SS { idle, running, done, failed }

enum _LT { norm, ok, err, info, sys, step }

class _Step {
  final String id;
  final String label;
  final IconData icon;
  _SS status = _SS.idle;
  _Step({required this.id, required this.label, required this.icon});
}

class _LogEntry {
  final String msg;
  final _LT type;
  final DateTime ts;
  const _LogEntry(this.msg, this.type, this.ts);
}

List<_Step> _freshSteps() => [
  _Step(
    id: 'validate',
    label: 'Validasi Token',
    icon: Icons.verified_user_rounded,
  ),
  _Step(id: 'repo', label: 'Siapkan Repo', icon: Icons.source_rounded),
  _Step(id: 'upload', label: 'Upload ZIP', icon: Icons.upload_file_rounded),
  _Step(id: 'workflow', label: 'Push Workflow', icon: Icons.code_rounded),
  _Step(id: 'trigger', label: 'Trigger Build', icon: Icons.play_circle_rounded),
  _Step(
    id: 'queue',
    label: 'Queue & Setup',
    icon: Icons.hourglass_empty_rounded,
  ),
  _Step(id: 'build', label: 'Flutter Build', icon: Icons.flutter_dash_rounded),
  _Step(id: 'artifact', label: 'Ambil APK', icon: Icons.download_rounded),
];

const _kRepoName = 'flutter-apk-builder';
const _kWorkflowFile = 'build.yml';
const _kPrefToken = 'gh_builder_token';

const _kNotifChannel = 'gh_builder_ch';
const _kNotifChannelName = 'GitHub Builder';
const _kNotifIdFg = 888;
const _kNotifIdResult = 889;

const _kBgRunning = 'bg_running';
const _kBgToken = 'bg_token';
const _kBgOwner = 'bg_owner';
const _kBgRunId = 'bg_run_id';
const _kBgResult = 'bg_result';
const _kBgArtifactId = 'bg_art_id';
const _kBgArtifactName = 'bg_art_name';
const _kBgArtifactSize = 'bg_art_size';
const _kBgErrMsg = 'bg_err_msg';
const _kBgTriggerTime = 'bg_trigger_time';
const _kBgHeartbeat = 'bg_heartbeat';
const _kBgLogs = 'bg_logs';
const _kBgStepState = 'bg_step_state';
const _kBgStatusText = 'bg_status_text';
const _kBgMaxAgeMinutes =
    90; // stale guard: flag dianggap zombie setelah 90 menit

final FlutterLocalNotificationsPlugin _notifPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _bgSetHeartbeat(SharedPreferences prefs) async {
  await prefs.setString(
    _kBgHeartbeat,
    DateTime.now().toUtc().toIso8601String(),
  );
}

Future<void> _bgSetStatusText(SharedPreferences prefs, String value) async {
  await prefs.setString(_kBgStatusText, value);
  await _bgSetHeartbeat(prefs);
}

Future<void> _bgAppendLog(
  SharedPreferences prefs,
  String msg,
  String type,
) async {
  final raw = prefs.getString(_kBgLogs);
  final list = raw == null || raw.isEmpty
      ? <dynamic>[]
      : (jsonDecode(raw) as List<dynamic>);
  list.add({'msg': msg, 't': type, 'ts': DateTime.now().toIso8601String()});
  final trimmed = list.length > 220 ? list.sublist(list.length - 220) : list;
  await prefs.setString(_kBgLogs, jsonEncode(trimmed));
  await _bgSetHeartbeat(prefs);
}

Future<void> _bgSetStepState(
  SharedPreferences prefs,
  String stepId,
  String status,
) async {
  final raw = prefs.getString(_kBgStepState);
  final map = raw == null || raw.isEmpty
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  map[stepId] = status;
  await prefs.setString(_kBgStepState, jsonEncode(map));
  await _bgSetHeartbeat(prefs);
}

Future<void> _bgResetBuildState(SharedPreferences prefs) async {
  await prefs.remove(_kBgRunId);
  await prefs.remove(_kBgResult);
  await prefs.remove(_kBgErrMsg);
  await prefs.remove(_kBgArtifactId);
  await prefs.remove(_kBgArtifactName);
  await prefs.remove(_kBgArtifactSize);
  await prefs.remove(_kBgLogs);
  await prefs.remove(_kBgStepState);
  await prefs.remove(_kBgStatusText);
  await prefs.remove(_kBgHeartbeat);
}

Future<void> _initNotifPlugin({bool requestPermission = true}) async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await _notifPlugin.initialize(settings);
  if (Platform.isAndroid) {
    final impl = _notifPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await impl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kNotifChannel,
        _kNotifChannelName,
        importance: Importance.high,
        enableVibration: true,
      ),
    );
    if (requestPermission) {
      await impl?.requestNotificationsPermission();
    }
  }
}

void _notifProgress(String body) {
  _notifPlugin.show(
    _kNotifIdFg,
    'GitHub Builder — Sedang Build',
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _kNotifChannel,
        _kNotifChannelName,
        ongoing: true,
        autoCancel: false,
        importance: Importance.low,
        priority: Priority.low,
        showWhen: false,
      ),
    ),
  );
}

void _notifResult(bool success, String? artName) {
  _notifPlugin.show(
    _kNotifIdResult,
    success ? '✓ Build APK Berhasil!' : '✗ Build APK Gagal',
    success
        ? (artName != null
              ? 'Artifact: $artName · Buka app untuk download'
              : 'APK siap di-download')
        : 'Buka app untuk melihat log error',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _kNotifChannel,
        _kNotifChannelName,
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
      ),
    ),
  );
}

@pragma('vm:entry-point')
void bgServiceMain(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifPlugin(requestPermission: false);

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'GitHub Builder',
      content: 'Menyiapkan background build...',
    );
  }



  final prefs = await SharedPreferences.getInstance();
  await _bgSetHeartbeat(prefs);
  final token = prefs.getString(_kBgToken) ?? '';
  final owner = prefs.getString(_kBgOwner) ?? '';

  if (token.isEmpty || owner.isEmpty) {
    await prefs.setString(_kBgResult, 'failed');
    await prefs.setString(_kBgErrMsg, 'Data build background tidak lengkap');
    await prefs.setBool(_kBgRunning, false);
    _notifResult(false, null);
    service.stopSelf();
    return;
  }

  final headers = <String, String>{
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/json',
  };

  void emit(String event, Map<String, dynamic> data) =>
      service.invoke(event, data);

  Future<void> svcLog(String msg, String t) async {
    emit('log', {'msg': msg, 't': t, 'ts': DateTime.now().toIso8601String()});
    await _bgAppendLog(prefs, msg, t);
  }

  Future<void> svcStep(String id, String s) async {
    emit('step', {'id': id, 's': s});
    await _bgSetStepState(prefs, id, s);
  }

  Future<void> updateForeground(String body) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'GitHub Builder',
        content: body,
      );
    }
    _notifProgress(body);
    await _bgSetStatusText(prefs, body);
  }


  bool stopped = false;
  service.on('stop').listen((_) {
    stopped = true;
    service.stopSelf();
  });

  Future<void> failBuild(String stepId, String msg) async {
    svcStep(stepId, 'failed');
    svcLog('✗ GAGAL: $msg', 'err');
    await prefs.setString(_kBgResult, 'failed');
    await prefs.setString(_kBgErrMsg, msg);
    await _bgSetStepState(prefs, stepId, 'failed');
    await _bgAppendLog(prefs, 'Build gagal: $msg', 'err');
    _notifResult(false, null);
    await prefs.setBool(_kBgRunning, false);
    await _bgSetStatusText(prefs, 'Gagal');
    service.stopSelf();
  }

  await updateForeground('Menunggu antrian GitHub runner...');
  await Future.delayed(const Duration(seconds: 2));

  String? runId = prefs.getString(_kBgRunId);
  if (runId == null || runId.isEmpty) {
    svcStep('queue', 'running');
    svcLog('▶ Queue & Setup', 'step');
    svcLog('  Menunggu runner tersedia…', 'info');
    svcLog('  (ubuntu-latest)', 'sys');

    await _bgSetStepState(prefs, 'queue', 'running');
    await _bgAppendLog(prefs, 'Queue & Setup', 'step');
    await _bgAppendLog(prefs, 'Menunggu runner tersedia', 'info');
    await _bgAppendLog(prefs, '(ubuntu-latest)', 'sys');

    final triggerTimeStr = prefs.getString(_kBgTriggerTime);
    final triggerTime = triggerTimeStr != null
        ? DateTime.tryParse(
            triggerTimeStr,
          )?.subtract(const Duration(seconds: 30))
        : null;

    bool found = false;
    int queueConsecErrors = 0;
    for (int i = 0; i < 36 && !found && !stopped; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (stopped) break;
      await _bgSetHeartbeat(prefs);
      try {
        final res = await http
            .get(
              Uri.parse(
                'https://api.github.com/repos/$owner/$_kRepoName'
                '/actions/workflows/$_kWorkflowFile/runs'
                '?per_page=25&event=workflow_dispatch&branch=main',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          queueConsecErrors = 0;
          final runs =
              (jsonDecode(res.body) as Map<String, dynamic>)['workflow_runs']
                  as List;

          Map<String, dynamic>? matchedRun;
          for (final r in runs) {
            final createdAt = DateTime.tryParse(
              r['created_at'] as String? ?? '',
            );
            if (triggerTime == null ||
                (createdAt != null && createdAt.isAfter(triggerTime))) {
              matchedRun = r as Map<String, dynamic>;
              break;
            }
          }

          matchedRun ??= runs.isNotEmpty
              ? runs.first as Map<String, dynamic>
              : null;

          if (matchedRun != null) {
            runId = matchedRun['id'].toString();
            await prefs.setString(_kBgRunId, runId);
            emit('runId', {'v': runId});
            svcLog('  Run ID: $runId', 'info');
            svcLog('  Status: ${matchedRun['status']}', 'info');
            await _bgAppendLog(prefs, 'Run ID: $runId', 'info');
            await _bgAppendLog(
              prefs,
              'Status: ${matchedRun['status']}',
              'info',
            );
            found = true;
          }
        }
      } on TimeoutException {
        queueConsecErrors++;
        svcLog('  Request timeout retry ${i + 1}/36…', 'sys');
        if (queueConsecErrors >= 5) {
          svcLog(
            '  5 timeout berturut-turut — berhenti polling antrian',
            'err',
          );
          break;
        }
      } catch (e) {
        queueConsecErrors++;
        svcLog('  Error ${i + 1}/36: $e', 'sys');
        if (queueConsecErrors >= 5) {
          svcLog('  5 error berturut-turut — berhenti polling antrian', 'err');
          break;
        }
      }
      if (!found) svcLog('  Retry ${i + 1}/36…', 'sys');
    }

    if (stopped) return;
    if (!found) {
      await failBuild('queue', 'Timeout — run tidak muncul dalam 3 menit');
      return;
    }

    svcStep('queue', 'done');
    svcLog('✓ Queue & Setup', 'ok');
  }

  await _bgSetStepState(prefs, 'queue', 'done');
  await _bgAppendLog(prefs, 'Queue & Setup selesai', 'ok');

  await updateForeground('Flutter build sedang berjalan di GitHub...');
  svcStep('build', 'running');
  svcLog('▶ Flutter Build', 'step');
  svcLog('  Build berjalan, estimasi 5–15 menit…', 'info');
  svcLog('  (ubuntu-latest runner)', 'sys');

  await _bgSetStepState(prefs, 'build', 'running');
  await _bgAppendLog(prefs, 'Flutter Build', 'step');
  await _bgAppendLog(prefs, 'Build berjalan, estimasi 5-15 menit', 'info');
  await _bgAppendLog(prefs, '(ubuntu-latest runner)', 'sys');

  String lastStatus = '';
  bool buildOk = false;
  int buildConsecErrors = 0;

  for (int i = 0; i < 180 && !stopped; i++) {
    await Future.delayed(const Duration(seconds: 5));
    if (stopped) break;
    await _bgSetHeartbeat(prefs);
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$_kRepoName'
              '/actions/runs/$runId',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        buildConsecErrors++;
        svcLog('  HTTP ${res.statusCode} — retry ${i + 1}/180…', 'sys');
        if (buildConsecErrors >= 8) {
          svcLog('  8 error berturut-turut — hentikan polling build', 'err');
          break;
        }
        continue;
      }

      buildConsecErrors = 0;
      final run = jsonDecode(res.body) as Map<String, dynamic>;
      final status = run['status'] as String;
      final conclusion = run['conclusion'] as String?;

      if (status != lastStatus) {
        svcLog(
          '  Status: $status${conclusion != null ? " → $conclusion" : ""}',
          'info',
        );
        await _bgAppendLog(
          prefs,
          'Status: $status${conclusion != null ? " -> $conclusion" : ""}',
          'info',
        );
        await updateForeground('Build: $status...');
        lastStatus = status;
      }

      if (status == 'completed') {
        buildOk = conclusion == 'success';
        break;
      }
    } on TimeoutException {
      buildConsecErrors++;
      svcLog('  Request timeout, lanjut polling…', 'sys');
      if (buildConsecErrors >= 8) {
        svcLog('  8 timeout berturut-turut — hentikan polling build', 'err');
        break;
      }
    } catch (e) {
      buildConsecErrors++;
      svcLog('  Error polling build: $e', 'sys');
      if (buildConsecErrors >= 8) {
        svcLog('  8 error berturut-turut — hentikan polling build', 'err');
        break;
      }
    }
  }

  if (stopped) return;
  if (!buildOk) {
    await failBuild(
      'build',
      lastStatus == 'completed'
          ? 'Build gagal — cek workflow log di GitHub'
          : 'Build timeout (>15 menit)',
    );
    return;
  }

  svcStep('build', 'done');
  svcLog('✓ Flutter Build', 'ok');

  await _bgSetStepState(prefs, 'build', 'done');
  await _bgAppendLog(prefs, 'Flutter Build selesai', 'ok');

  await updateForeground('Mengambil APK artifact...');
  svcStep('artifact', 'running');
  svcLog('▶ Ambil APK', 'step');
  await Future.delayed(const Duration(seconds: 2));

  try {
    final artRes = await http
        .get(
          Uri.parse(
            'https://api.github.com/repos/$owner/$_kRepoName'
            '/actions/runs/$runId/artifacts',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (artRes.statusCode != 200) {
      throw Exception('Gagal ambil artifact — HTTP ${artRes.statusCode}');
    }

    final artifacts =
        (jsonDecode(artRes.body) as Map<String, dynamic>)['artifacts'] as List;

    if (artifacts.isEmpty) throw Exception('Tidak ada artifact ditemukan');

    final apk =
        artifacts.firstWhere(
              (a) => (a['name'] as String).toLowerCase().contains('apk'),
              orElse: () => artifacts.first,
            )
            as Map<String, dynamic>;

    final artName = apk['name'] as String;
    final artSize = apk['size_in_bytes'] as int;
    final artId = apk['id'] as int;

    await prefs.setString(_kBgArtifactName, artName);
    await prefs.setInt(_kBgArtifactSize, artSize);
    await prefs.setInt(_kBgArtifactId, artId);
    await prefs.setString(_kBgResult, 'success');
    await _bgSetStatusText(prefs, 'Artifact siap');

    svcLog('  Artifact : $artName', 'ok');
    svcLog(
      '  Ukuran   : ${(artSize / 1024 / 1024).toStringAsFixed(1)} MB',
      'info',
    );
    svcLog('  ID       : $artId', 'info');
    await _bgAppendLog(prefs, 'Artifact: $artName', 'ok');
    await _bgAppendLog(
      prefs,
      'Ukuran: ${(artSize / 1024 / 1024).toStringAsFixed(1)} MB',
      'info',
    );
    await _bgAppendLog(prefs, 'ID: $artId', 'info');
    svcStep('artifact', 'done');
    await _bgSetStepState(prefs, 'artifact', 'done');

    svcLog('', 'norm');
    svcLog('╔══════════════════════════════════════╗', 'ok');
    svcLog('║   BUILD APK BERHASIL  ✓               ║', 'ok');
    svcLog('╚══════════════════════════════════════╝', 'ok');
    svcLog('Owner → $owner', 'info');
    svcLog('Repo  → $_kRepoName', 'info');
    svcLog('Run   → $runId', 'info');

    emit('done', {
      'ok': true,
      'artId': artId,
      'artName': artName,
      'artSize': artSize,
      'runId': runId,
      'owner': owner,
    });

    _notifResult(true, artName);
  } catch (e) {
    await failBuild('artifact', e.toString());
    return;
  }

  await prefs.setBool(_kBgRunning, false);
  await _bgSetStatusText(prefs, 'Selesai');
  await _bgSetHeartbeat(prefs);
  service.stopSelf();
}

@pragma('vm:entry-point')
bool bgServiceIos(ServiceInstance service) => true;

Future<void> _configureBackgroundService() async {
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: bgServiceMain,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: _kNotifChannel,
      initialNotificationTitle: 'GitHub Builder',
      initialNotificationContent: 'Build sedang berjalan...',
      foregroundServiceNotificationId: _kNotifIdFg,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: bgServiceMain,
      onBackground: bgServiceIos,
    ),
  );
}

class GithubBuilderPage extends StatefulWidget {
  final String? ghpToken;
  const GithubBuilderPage({super.key, this.ghpToken});

  @override
  State<GithubBuilderPage> createState() => _GithubBuilderState();
}

class _GithubBuilderState extends State<GithubBuilderPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TextEditingController _ctrlToken;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _showToken = false;
  bool _formReady = false;
  bool _tokenSaved = false;

  Uint8List? _zipBytes;
  String? _zipFileName;
  double _zipSizeMB = 0;
  bool _zipPicking = false;

  List<_Step> _steps = _freshSteps();
  final List<_LogEntry> _logs = [];
  bool _running = false;
  bool _finished = false;
  bool _errored = false;
  bool _bgMode = false;
  int _doneCount = 0;
  String _statusMsg = '';
  final ScrollController _scroll = ScrollController();

  String? _githubOwner;
  String? _runId;
  String? _artifactUrl;
  String? _artifactName;
  int? _artifactSizeBytes;
  int? _artifactId;

  bool _downloading = false;
  double _downloadProgress = 0;
  String? _downloadPath;

  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;

  final List<StreamSubscription<Map<String, dynamic>?>> _bgSubs = [];
  Timer? _bgPollTimer;

  String get _token => _ctrlToken.text.trim();

  Map<String, String> get _ghHeaders => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrlToken = TextEditingController(text: widget.ghpToken ?? '');
    _formReady = widget.ghpToken != null;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeOut,
    );

    if (widget.ghpToken == null) _loadSavedToken();
    _initBgInfra();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgPollTimer?.cancel();
    _cancelBgSubs();
    _scroll.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _ctrlToken.dispose();
    super.dispose();
  }

  Future<void> _initBgInfra() async {
    await _initNotifPlugin();
    await _configureBackgroundService();
    await _checkResumeBuild();
  }

  Future<void> _checkResumeBuild() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final storedFlag = prefs.getBool(_kBgRunning) ?? false;
    final result = prefs.getString(_kBgResult);

    if (storedFlag) {

      final triggerStr = prefs.getString(_kBgTriggerTime);
      final triggerDt = triggerStr != null
          ? DateTime.tryParse(triggerStr)
          : null;
      final isStale =
          triggerDt == null ||
          DateTime.now().difference(triggerDt).inMinutes > _kBgMaxAgeMinutes;
      final heartbeatExpired = _isBgHeartbeatExpired(prefs);
      final svcAlive = await FlutterBackgroundService().isRunning();

      if (heartbeatExpired) {
        await _recoverBgStateFromGitHub(prefs);
        await prefs.reload();
      }

      final refreshedRunning = prefs.getBool(_kBgRunning) ?? false;
      final refreshedResult = prefs.getString(_kBgResult);

      if (isStale || (heartbeatExpired && !svcAlive && refreshedRunning)) {

        await prefs.setBool(_kBgRunning, false);
        if (refreshedResult == null || refreshedResult.isEmpty) {
          await prefs.setString(_kBgResult, 'failed');
          await prefs.setString(
            _kBgErrMsg,
            isStale
                ? 'Build expired (>90 menit tanpa respons)'
                : 'Service dihentikan sistem',
          );
        }

        return _checkResumeBuild();
      }

      if (!mounted) return;
      setState(() {
        _bgMode = true;
        _running = true;
        _finished = false;
        _formReady = true;
        _githubOwner = prefs.getString(_kBgOwner);
        _runId = prefs.getString(_kBgRunId);
        _statusMsg = 'Build berjalan di background…';
      });
      _addLog('Build sedang berjalan di background...', _LT.info);
      _addLog('Proses tetap lanjut meski app ditutup.', _LT.sys);
      _addLog('Notifikasi otomatis saat selesai.', _LT.sys);
      await _syncUiFromBgPrefs(prefs);
      _subscribeToService();
      return;
    }

    if (result == 'success') {
      final artId = prefs.getInt(_kBgArtifactId);
      final artName = prefs.getString(_kBgArtifactName);
      final artSize = prefs.getInt(_kBgArtifactSize);
      final owner = prefs.getString(_kBgOwner);
      final runId = prefs.getString(_kBgRunId);

      if (artId != null && mounted) {
        setState(() {
          _running = false;
          _finished = true;
          _errored = false;
          _formReady = true;
          _githubOwner = owner;
          _runId = runId;
          _artifactId = artId;
          _artifactName = artName;
          _artifactSizeBytes = artSize;
          _artifactUrl =
              'https://github.com/$owner/$_kRepoName'
              '/actions/runs/$runId/artifacts/$artId';
          _statusMsg = 'Selesai ✓';
          _doneCount = _steps.length;
        });
        for (final s in _steps) s.status = _SS.done;
        _progressCtrl.animateTo(1.0);
        _addLog('Build selesai (dilanjutkan dari background) ✓', _LT.ok);
        await prefs.remove(_kBgResult);
      }
      return;
    }

    if (result == 'failed') {
      if (!mounted) return;
      final errMsg = prefs.getString(_kBgErrMsg) ?? 'Build gagal';
      setState(() {
        _running = false;
        _finished = true;
        _errored = true;
        _formReady = true;
        _statusMsg = 'Gagal';
      });
      _addLog('Build gagal (dari background): $errMsg', _LT.err);
      await prefs.remove(_kBgResult);
    }
  }

  void _subscribeToService() {
    _cancelBgSubs(); // ← bersihkan sub lama sebelum subscribe ulang
    _startBgPoll(); // ← mulai polling prefs agar UI tidak stuck
    final svc = FlutterBackgroundService();

    _bgSubs.add(
      svc.on('log').listen((data) {
        if (data == null || !mounted) return;
        final msg = data['msg'] as String? ?? '';
        final t = data['t'] as String? ?? 'norm';
        _LT lt;
        switch (t) {
          case 'ok':
            lt = _LT.ok;
            break;
          case 'err':
            lt = _LT.err;
            break;
          case 'info':
            lt = _LT.info;
            break;
          case 'sys':
            lt = _LT.sys;
            break;
          case 'step':
            lt = _LT.step;
            break;
          default:
            lt = _LT.norm;
        }
        _addLog(msg, lt);
      }),
    );

    _bgSubs.add(
      svc.on('step').listen((data) {
        if (data == null || !mounted) return;
        final id = data['id'] as String? ?? '';
        final s = data['s'] as String? ?? '';
        final idx = _steps.indexWhere((x) => x.id == id);
        if (idx < 0) return;
        setState(() {
          switch (s) {
            case 'running':
              _steps[idx].status = _SS.running;
              break;
            case 'done':
              _steps[idx].status = _SS.done;
              break;
            case 'failed':
              _steps[idx].status = _SS.failed;
              break;
          }
          _doneCount = _steps.where((x) => x.status == _SS.done).length;
        });
        _progressCtrl.animateTo(
          _doneCount / _steps.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }),
    );

    _bgSubs.add(
      svc.on('runId').listen((data) {
        if (data == null || !mounted) return;
        setState(() => _runId = data['v'] as String?);
      }),
    );

    _bgSubs.add(
      svc.on('done').listen((data) {
        if (data == null || !mounted) return;
        final ok = data['ok'] as bool? ?? false;
        setState(() {
          _running = false;
          _finished = true;
          _errored = !ok;
          _bgMode = false;
          _statusMsg = ok ? 'Selesai ✓' : 'Gagal';
          if (ok) {
            _artifactId = data['artId'] as int?;
            _artifactName = data['artName'] as String?;
            _artifactSizeBytes = data['artSize'] as int?;
            _runId = data['runId'] as String?;
            _githubOwner = data['owner'] as String?;
            if (_artifactId != null) {
              _artifactUrl =
                  'https://github.com/$_githubOwner/$_kRepoName'
                  '/actions/runs/$_runId/artifacts/$_artifactId';
            }
          }
        });
        if (ok) {
          _progressCtrl.animateTo(
            1.0,
            duration: const Duration(milliseconds: 700),
          );
        }
        _stopBgPoll();
        _cancelBgSubs();
      }),
    );
  }

  void _cancelBgSubs() {
    for (final s in _bgSubs) s.cancel();
    _bgSubs.clear();
  }

  _LT _bgLogTypeFromString(String value) {
    switch (value) {
      case 'ok':
        return _LT.ok;
      case 'err':
        return _LT.err;
      case 'info':
        return _LT.info;
      case 'sys':
        return _LT.sys;
      case 'step':
        return _LT.step;
      default:
        return _LT.norm;
    }
  }

  bool _isBgHeartbeatExpired(
    SharedPreferences prefs, {
    int thresholdMinutes = 3,
  }) {
    final heartbeatStr = prefs.getString(_kBgHeartbeat);
    final heartbeatDt = heartbeatStr != null
        ? DateTime.tryParse(heartbeatStr)
        : null;
    if (heartbeatDt == null) {
      return true;
    }
    return DateTime.now().difference(heartbeatDt).inMinutes > thresholdMinutes;
  }

  Future<bool> _recoverBgStateFromGitHub(SharedPreferences prefs) async {
    final token = prefs.getString(_kBgToken);
    final owner = prefs.getString(_kBgOwner);
    final runId = prefs.getString(_kBgRunId);

    if (token == null ||
        token.isEmpty ||
        owner == null ||
        owner.isEmpty ||
        runId == null ||
        runId.isEmpty) {
      return false;
    }

    try {
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

      final runRes = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$_kRepoName/actions/runs/$runId',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (runRes.statusCode != 200) {
        return false;
      }

      final run = jsonDecode(runRes.body) as Map<String, dynamic>;
      final status = run['status'] as String? ?? '';
      final conclusion = run['conclusion'] as String?;

      if (status != 'completed') {
        await _bgSetStatusText(
          prefs,
          status.isEmpty ? 'Build berjalan di GitHub...' : 'Build: $status...',
        );
        return false;
      }

      if (conclusion != 'success') {
        await prefs.setBool(_kBgRunning, false);
        await prefs.setString(_kBgResult, 'failed');
        await prefs.setString(
          _kBgErrMsg,
          'Build GitHub selesai dengan status ${conclusion ?? "failed"}',
        );
        await _bgSetStatusText(prefs, 'Gagal');
        await _bgSetStepState(prefs, 'build', 'failed');
        await _bgAppendLog(
          prefs,
          'Build GitHub selesai dengan status ${conclusion ?? "failed"}',
          'err',
        );
        return true;
      }

      final artRes = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$_kRepoName/actions/runs/$runId/artifacts',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (artRes.statusCode != 200) {
        return false;
      }

      final artifacts =
          (jsonDecode(artRes.body) as Map<String, dynamic>)['artifacts']
              as List;
      if (artifacts.isEmpty) {
        await prefs.setBool(_kBgRunning, false);
        await prefs.setString(_kBgResult, 'failed');
        await prefs.setString(
          _kBgErrMsg,
          'Build sukses tetapi artifact tidak ditemukan',
        );
        await _bgSetStatusText(prefs, 'Gagal');
        await _bgAppendLog(
          prefs,
          'Artifact tidak ditemukan setelah build sukses',
          'err',
        );
        return true;
      }

      final apk =
          artifacts.firstWhere(
                (a) => (a['name'] as String).toLowerCase().contains('apk'),
                orElse: () => artifacts.first,
              )
              as Map<String, dynamic>;

      final artId = apk['id'] as int;
      final artName = apk['name'] as String;
      final artSize = apk['size_in_bytes'] as int;

      await prefs.setInt(_kBgArtifactId, artId);
      await prefs.setString(_kBgArtifactName, artName);
      await prefs.setInt(_kBgArtifactSize, artSize);
      await prefs.setBool(_kBgRunning, false);
      await prefs.setString(_kBgResult, 'success');
      await _bgSetStatusText(prefs, 'Artifact siap');
      await _bgSetStepState(prefs, 'build', 'done');
      await _bgSetStepState(prefs, 'artifact', 'done');
      await _bgAppendLog(prefs, 'Build dipulihkan dari status GitHub', 'ok');
      await _bgAppendLog(prefs, 'Artifact: $artName', 'ok');
      return true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncUiFromBgPrefs(SharedPreferences prefs) async {
    if (!mounted) return;

    final owner = prefs.getString(_kBgOwner);
    final runId = prefs.getString(_kBgRunId);
    final statusText = prefs.getString(_kBgStatusText);
    final artId = prefs.getInt(_kBgArtifactId);
    final artName = prefs.getString(_kBgArtifactName);
    final artSize = prefs.getInt(_kBgArtifactSize);
    final rawSteps = prefs.getString(_kBgStepState);
    final rawLogs = prefs.getString(_kBgLogs);

    final stepMap = rawSteps == null || rawSteps.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(rawSteps) as Map);
    final logList = rawLogs == null || rawLogs.isEmpty
        ? const <dynamic>[]
        : (jsonDecode(rawLogs) as List<dynamic>);

    setState(() {
      _githubOwner = owner;
      _runId = runId;
      _artifactId = artId;
      _artifactName = artName;
      _artifactSizeBytes = artSize;
      _artifactUrl = artId != null && owner != null && runId != null
          ? 'https://github.com/$owner/$_kRepoName/actions/runs/$runId/artifacts/$artId'
          : null;
      if (statusText != null && statusText.isNotEmpty) {
        _statusMsg = statusText;
      }

      for (final step in _steps) {
        switch (stepMap[step.id]) {
          case 'running':
            step.status = _SS.running;
            break;
          case 'done':
            step.status = _SS.done;
            break;
          case 'failed':
            step.status = _SS.failed;
            break;
          default:
            break;
        }
      }
      _doneCount = _steps.where((x) => x.status == _SS.done).length;

      _logs
        ..clear()
        ..addAll(
          logList.map((e) {
            final row = Map<String, dynamic>.from(e as Map);
            return _LogEntry(
              row['msg'] as String? ?? '',
              _bgLogTypeFromString(row['t'] as String? ?? 'norm'),
              DateTime.tryParse(row['ts'] as String? ?? '') ?? DateTime.now(),
            );
          }),
        );
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _bgMode && _running) {
      _pollBgResult();
    }
  }


  void _startBgPoll() {
    _bgPollTimer?.cancel();
    _bgPollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_bgMode || !_running) {
        _bgPollTimer?.cancel();
        return;
      }
      _pollBgResult();
    });
  }

  void _stopBgPoll() {
    _bgPollTimer?.cancel();
    _bgPollTimer = null;
  }



  Future<void> _pollBgResult() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await _syncUiFromBgPrefs(prefs);
    var stillRun = prefs.getBool(_kBgRunning) ?? false;
    var result = prefs.getString(_kBgResult);
    final svcAlive = await FlutterBackgroundService().isRunning();
    final heartbeatExpired = _isBgHeartbeatExpired(prefs);

    if (heartbeatExpired) {
      await _recoverBgStateFromGitHub(prefs);
      await prefs.reload();
      stillRun = prefs.getBool(_kBgRunning) ?? stillRun;
      result = prefs.getString(_kBgResult) ?? result;
    }

    if (stillRun && heartbeatExpired && !svcAlive) {
      await prefs.setBool(_kBgRunning, false);
      await prefs.setString(_kBgResult, 'failed');
      await prefs.setString(
        _kBgErrMsg,
        'Service background berhenti tanpa hasil',
      );
      stillRun = false;
      result = 'failed';
    }


    if (!stillRun && _running && _bgMode) {
      _stopBgPoll();
      _cancelBgSubs();

      if (result == 'success') {
        final artId = prefs.getInt(_kBgArtifactId);
        final artName = prefs.getString(_kBgArtifactName);
        final artSize = prefs.getInt(_kBgArtifactSize);
        final owner = prefs.getString(_kBgOwner);
        final runId = prefs.getString(_kBgRunId);
        if (artId != null && mounted) {
          setState(() {
            _running = false;
            _finished = true;
            _errored = false;
            _bgMode = false;
            _statusMsg = 'Selesai ✓';
            _artifactId = artId;
            _artifactName = artName;
            _artifactSizeBytes = artSize;
            _githubOwner = owner;
            _runId = runId;
            _artifactUrl =
                'https://github.com/$owner/$_kRepoName'
                '/actions/runs/$runId/artifacts/$artId';
            _doneCount = _steps.length;
          });
          for (final s in _steps) s.status = _SS.done;
          _progressCtrl.animateTo(1.0);
          _addLog(
            '✓ Build selesai (dideteksi via poll — event tidak diterima langsung)',
            _LT.ok,
          );
          await prefs.remove(_kBgResult);
        }
      } else if (result == 'failed' || result != null) {
        final errMsg = prefs.getString(_kBgErrMsg) ?? 'Build gagal';
        if (mounted) {
          setState(() {
            _running = false;
            _finished = true;
            _errored = true;
            _bgMode = false;
            _statusMsg = 'Gagal';
          });
          _addLog('✗ Build gagal (dideteksi via poll): $errMsg', _LT.err);
          await prefs.remove(_kBgResult);
        }
      } else {

        if (mounted) {
          setState(() {
            _running = false;
            _finished = true;
            _errored = true;
            _bgMode = false;
            _statusMsg = 'Gagal';
          });
          _addLog(
            '✗ Service dihentikan sistem tanpa hasil (OOM/killed)',
            _LT.err,
          );
        }
      }
    }
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPrefToken);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        _ctrlToken.text = saved;
        _tokenSaved = true;
      });
    }
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefToken, _token);
    if (mounted) setState(() => _tokenSaved = true);
  }

  Future<void> _clearSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefToken);
    if (mounted) setState(() => _tokenSaved = false);
  }

  Future<void> _pickZip() async {
    if (_zipPicking) return;
    setState(() => _zipPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (mounted) {
          setState(() {
            _zipBytes = file.bytes;
            _zipFileName = file.name;
            _zipSizeMB = file.size / 1024 / 1024;
          });
        }
      }
    } catch (e) {
      if (mounted) _snack('Gagal buka file: $e');
    } finally {
      if (mounted) setState(() => _zipPicking = false);
    }
  }

  void _addLog(String msg, [_LT type = _LT.norm]) {
    if (!mounted) return;
    setState(() => _logs.add(_LogEntry(msg, type, DateTime.now())));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stepBegin(String id) {
    final idx = _steps.indexWhere((s) => s.id == id);
    if (idx < 0 || !mounted) return;
    setState(() {
      for (final s in _steps) if (s.status == _SS.running) s.status = _SS.idle;
      _steps[idx].status = _SS.running;
      _statusMsg = '${_steps[idx].label}…';
    });
    _addLog('▶ ${_steps[idx].label}', _LT.step);
  }

  void _stepDone(String id) {
    final idx = _steps.indexWhere((s) => s.id == id);
    if (idx < 0 || !mounted) return;
    setState(() {
      _steps[idx].status = _SS.done;
      _doneCount = _steps.where((s) => s.status == _SS.done).length;
    });
    _progressCtrl.animateTo(
      _doneCount / _steps.length,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
    _addLog('✓ ${_steps[idx].label}', _LT.ok);
  }

  void _stepFail(String id, String msg) {
    final idx = _steps.indexWhere((s) => s.id == id);
    if (idx >= 0 && mounted) setState(() => _steps[idx].status = _SS.failed);
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _errored = true;
      _statusMsg = 'Gagal';
    });
    _addLog('✗ GAGAL: $msg', _LT.err);
  }

  Future<void> _startBuild() async {
    if (_zipBytes == null) {
      _snack('Pilih file ZIP project Flutter terlebih dahulu');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final alreadyRunning = await FlutterBackgroundService().isRunning();
    final flaggedRunning = prefs.getBool(_kBgRunning) ?? false;
    if (alreadyRunning || flaggedRunning) {
      _snack(
        'Build sudah berjalan di background. Menyambung ke status terakhir...',
      );
      await _checkResumeBuild();
      return;
    }

    setState(() {
      _running = true;
      _finished = false;
      _errored = false;
      _bgMode = false;
      _doneCount = 0;
      _statusMsg = 'Memulai…';
      _steps = _freshSteps();
      _githubOwner = null;
      _runId = null;
      _artifactUrl = null;
      _artifactName = null;
      _artifactSizeBytes = null;
      _artifactId = null;
      _downloadPath = null;
      _downloadProgress = 0;
      _logs.clear();
    });
    _progressCtrl.reset();

    _addLog('GitHub Actions Flutter Builder', _LT.sys);
    _addLog('Source: ZIP upload dari perangkat', _LT.sys);
    _addLog('─' * 44, _LT.sys);

    try {
      _stepBegin('validate');
      final userRes = await http
          .get(Uri.parse('https://api.github.com/user'), headers: _ghHeaders)
          .timeout(const Duration(seconds: 15));

      if (userRes.statusCode != 200) {
        _stepFail('validate', 'Token tidak valid — HTTP ${userRes.statusCode}');
        return;
      }
      final userJson = jsonDecode(userRes.body) as Map<String, dynamic>;
      _githubOwner = userJson['login'] as String;
      final plan =
          (userJson['plan'] as Map<String, dynamic>?)?['name'] ?? 'free';
      _addLog('  User  : $_githubOwner', _LT.info);
      _addLog('  Plan  : $plan', _LT.info);
      _stepDone('validate');
      await _saveToken();
      _addLog('  Token tersimpan lokal ✓', _LT.ok);

      _stepBegin('repo');
      final repoRes = await http
          .get(
            Uri.parse('https://api.github.com/repos/$_githubOwner/$_kRepoName'),
            headers: _ghHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (repoRes.statusCode == 404) {
        _addLog('  Repo belum ada, membuat…', _LT.info);
        final createRes = await http
            .post(
              Uri.parse('https://api.github.com/user/repos'),
              headers: _ghHeaders,
              body: jsonEncode({
                'name': _kRepoName,
                'private': false,
                'auto_init': true,
                'description': 'Flutter APK builder via GitHub Actions',
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (createRes.statusCode != 201) {
          _stepFail(
            'repo',
            'Gagal buat repo — HTTP ${createRes.statusCode}: ${createRes.body}',
          );
          return;
        }
        _addLog('  Repo dibuat: $_githubOwner/$_kRepoName', _LT.ok);
        await Future.delayed(const Duration(seconds: 3));
      } else if (repoRes.statusCode == 200) {
        _addLog('  Repo sudah ada: $_githubOwner/$_kRepoName', _LT.info);
      } else {
        _stepFail('repo', 'Error cek repo — HTTP ${repoRes.statusCode}');
        return;
      }
      _stepDone('repo');

      _stepBegin('upload');
      _addLog('  File    : $_zipFileName', _LT.info);
      _addLog('  Ukuran  : ${_zipSizeMB.toStringAsFixed(1)} MB', _LT.info);
      _addLog('  Encoding base64 & upload ke repo…', _LT.info);

      final zipB64 = base64.encode(_zipBytes!);

      String? existingZipSha;
      final checkZipRes = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_githubOwner/$_kRepoName/contents/source.zip',
            ),
            headers: _ghHeaders,
          )
          .timeout(const Duration(seconds: 30));

      if (checkZipRes.statusCode == 200) {
        try {
          final zb = jsonDecode(checkZipRes.body) as Map<String, dynamic>;
          existingZipSha = zb['sha'] as String?;
          _addLog(
            '  ZIP lama ditemukan (sha: ${existingZipSha?.substring(0, 7)}…), menimpa…',
            _LT.info,
          );
        } catch (_) {
          _addLog('  SHA tidak terbaca, upload ulang…', _LT.sys);
        }
      } else {
        _addLog('  Upload pertama kali…', _LT.info);
      }

      final uploadZipRes = await http
          .put(
            Uri.parse(
              'https://api.github.com/repos/$_githubOwner/$_kRepoName/contents/source.zip',
            ),
            headers: _ghHeaders,
            body: jsonEncode({
              'message':
                  'chore: upload source ZIP ${DateTime.now().toIso8601String()}',
              'content': zipB64,
              if (existingZipSha != null) 'sha': existingZipSha,
            }),
          )
          .timeout(const Duration(minutes: 5));

      if (uploadZipRes.statusCode != 200 && uploadZipRes.statusCode != 201) {
        _stepFail(
          'upload',
          'Gagal upload ZIP — HTTP ${uploadZipRes.statusCode}: ${uploadZipRes.body}',
        );
        return;
      }
      _addLog('  ZIP berhasil diupload ke repo ✓', _LT.ok);
      _stepDone('upload');

      _stepBegin('workflow');
      final workflowB64 = base64.encode(utf8.encode(_buildWorkflowYaml()));

      String? existingSha;
      final checkRes = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_githubOwner/$_kRepoName'
              '/contents/.github/workflows/$_kWorkflowFile',
            ),
            headers: _ghHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (checkRes.statusCode == 200) {
        existingSha =
            (jsonDecode(checkRes.body) as Map<String, dynamic>)['sha']
                as String?;
        _addLog('  Workflow sudah ada, update…', _LT.info);
      } else {
        _addLog('  Push workflow baru…', _LT.info);
      }

      final pushRes = await http
          .put(
            Uri.parse(
              'https://api.github.com/repos/$_githubOwner/$_kRepoName'
              '/contents/.github/workflows/$_kWorkflowFile',
            ),
            headers: _ghHeaders,
            body: jsonEncode({
              'message': 'ci: update Flutter build workflow',
              'content': workflowB64,
              if (existingSha != null) 'sha': existingSha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (pushRes.statusCode != 200 && pushRes.statusCode != 201) {
        _stepFail(
          'workflow',
          'Gagal push workflow — HTTP ${pushRes.statusCode}: ${pushRes.body}',
        );
        return;
      }
      _addLog('  Workflow ter-push ✓', _LT.ok);
      _stepDone('workflow');

      await Future.delayed(const Duration(seconds: 2));

      _stepBegin('trigger');
      final triggerRes = await http
          .post(
            Uri.parse(
              'https://api.github.com/repos/$_githubOwner/$_kRepoName'
              '/actions/workflows/$_kWorkflowFile/dispatches',
            ),
            headers: _ghHeaders,
            body: jsonEncode({'ref': 'main'}),
          )
          .timeout(const Duration(seconds: 15));

      if (triggerRes.statusCode != 204) {
        _stepFail(
          'trigger',
          'Gagal trigger — HTTP ${triggerRes.statusCode}: ${triggerRes.body}',
        );
        return;
      }
      _addLog('  Workflow dispatch OK (HTTP 204)', _LT.ok);
      _stepDone('trigger');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBgRunning, true);
      await prefs.setString(_kBgToken, _token);
      await prefs.setString(_kBgOwner, _githubOwner!);
      await prefs.setString(
        _kBgTriggerTime,
        DateTime.now().toUtc().toIso8601String(),
      );
      await _bgResetBuildState(prefs);
      await prefs.setString(_kBgOwner, _githubOwner!);
      await prefs.setString(_kBgToken, _token);
      await prefs.setBool(_kBgRunning, true);
      await _bgSetStatusText(prefs, 'Build berjalan di background...');
      await _bgSetStepState(prefs, 'validate', 'done');
      await _bgSetStepState(prefs, 'repo', 'done');
      await _bgSetStepState(prefs, 'upload', 'done');
      await _bgSetStepState(prefs, 'workflow', 'done');
      await _bgSetStepState(prefs, 'trigger', 'done');
      await _bgAppendLog(prefs, 'Workflow dispatch OK (HTTP 204)', 'ok');

      if (mounted) {
        setState(() {
          _bgMode = true;
          _statusMsg = 'Build berjalan di background...';
        });
      }

      final started = await FlutterBackgroundService().startService();
      if (!started) {
        await prefs.setBool(_kBgRunning, false);
        await prefs.setString(_kBgResult, 'failed');
        await prefs.setString(
          _kBgErrMsg,
          'Background service gagal dijalankan',
        );
        await _bgSetStatusText(prefs, 'Service gagal start');
        if (mounted) {
          setState(() {
            _running = false;
            _finished = true;
            _errored = true;
            _bgMode = false;
            _statusMsg = 'Service gagal start';
          });
          _addLog('Background service gagal dijalankan', _LT.err);
        }
        return;
      }
      await _syncUiFromBgPrefs(prefs);
      _subscribeToService();
      return;

      /*

      _addLog('', _LT.norm);
      _addLog('  Build dialihkan ke background service…', _LT.sys);
      _addLog('  App bisa ditutup, build tetap jalan! 🚀', _LT.ok);
      _addLog('  Notifikasi otomatis saat selesai.', _LT.info);
      _addLog('─' * 44, _LT.sys);

      final legacyPrefs = await SharedPreferences.getInstance();
      await legacyPrefs.setBool(_kBgRunning, true);
      await legacyPrefs.setString(_kBgToken, _token);
      await legacyPrefs.setString(_kBgOwner, _githubOwner!);
      await legacyPrefs.setString(_kBgTriggerTime, DateTime.now().toUtc().toIso8601String());
      await legacyPrefs.remove(_kBgRunId);
      await legacyPrefs.remove(_kBgResult);
      await legacyPrefs.remove(_kBgErrMsg);

      if (mounted) {
        setState(() {
          _bgMode    = true;
          _statusMsg = 'Build berjalan di background…';
        });
      }

      final legacyStarted = await FlutterBackgroundService().startService();
      if (!legacyStarted) {
        final legacyPrefs = await SharedPreferences.getInstance();
        await legacyPrefs.setBool(_kBgRunning, false);
        await legacyPrefs.setString(_kBgResult, 'failed');
        await legacyPrefs.setString(_kBgErrMsg, 'Background service gagal dijalankan');
        if (mounted) {
          setState(() {
            _running   = false;
            _finished  = true;
            _errored   = true;
            _bgMode    = false;
            _statusMsg = 'Service gagal start';
          });
          _addLog('âœ— Background service gagal dijalankan', _LT.err);
        }
        return;
      }
      _subscribeToService();

      */
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _running = false;
          _finished = true;
          _errored = true;
          _statusMsg = 'Timeout';
        });
        _addLog('✗ Request timeout — cek koneksi internet', _LT.err);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _running = false;
          _finished = true;
          _errored = true;
          _statusMsg = 'Error';
        });
        _addLog('✗ Exception: $e', _LT.err);
      }
    }
  }

  Future<void> _cancelBuild() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bgMode) {
      FlutterBackgroundService().invoke('stop');
      await prefs.setBool(_kBgRunning, false);
      await prefs.setString(_kBgResult, 'failed');
      await prefs.setString(_kBgErrMsg, 'Dibatalkan oleh pengguna');
      await _bgSetStatusText(prefs, 'Dibatalkan');
    }
    _stopBgPoll();
    _cancelBgSubs();
    if (mounted) {
      setState(() {
        _running = false;
        _finished = true;
        _errored = true;
        _bgMode = false;
        _statusMsg = 'Dibatalkan';
      });
      _addLog('✗ Dibatalkan oleh pengguna.', _LT.err);
    }
  }

  Future<void> _downloadArtifactZip() async {
    if (_artifactId == null || _githubOwner == null) return;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _downloadPath = null;
    });

    try {
      final Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir.createSync(recursive: true);
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName = '${_artifactName ?? "artifact"}.zip';
      final savePath = '${dir.path}/$fileName';

      _addLog('  Mulai download: $fileName', _LT.info);
      _addLog('  Simpan ke: $savePath', _LT.sys);

      final dio = Dio();
      await dio.download(
        'https://api.github.com/repos/$_githubOwner/$_kRepoName'
        '/actions/artifacts/$_artifactId/zip',
        savePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 10),
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadPath = savePath;
        });
        _addLog('  Download selesai ✓', _LT.ok);
        _addLog('  Path: $savePath', _LT.ok);
        _snack('✓ ZIP tersimpan di folder Download');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        _addLog('✗ Download error: $e', _LT.err);
        _snack('Download gagal: $e');
      }
    }
  }

  String _buildWorkflowYaml() => r'''
name: Build Flutter APK from ZIP

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Extract source ZIP
        run: |
          mkdir -p /tmp/zip_raw
          unzip source.zip -d /tmp/zip_raw
          COUNT=$(ls /tmp/zip_raw | wc -l | tr -d ' ')
          FIRST=$(ls /tmp/zip_raw | head -1)
          if [ "$COUNT" = "1" ] && [ -d "/tmp/zip_raw/$FIRST" ]; then
            mv "/tmp/zip_raw/$FIRST" /tmp/flutter_src
          else
            mv /tmp/zip_raw /tmp/flutter_src
          fi
          echo "=== Isi /tmp/flutter_src ==="
          ls /tmp/flutter_src

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"
          channel: stable
          cache: true

      - name: Install dependencies
        run: cd /tmp/flutter_src && flutter pub get

      - name: Analyze
        run: cd /tmp/flutter_src && flutter analyze --no-fatal-infos || true

      - name: Build APK release
        run: cd /tmp/flutter_src && flutter build apk --release

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: /tmp/flutter_src/build/app/outputs/flutter-apk/app-release.apk
          retention-days: 7
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.0, 0.025), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          ),
          child: _formReady
              ? _buildTerminalView(key: const ValueKey('t'))
              : _buildFormView(key: const ValueKey('f')),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 16,
        color: _textSub,
      ),
      onPressed: () => Navigator.maybePop(context),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _glowIcon(Icons.bolt_rounded, _cyan, size: 17),
        const SizedBox(width: 9),
        const Text(
          'GitHub Actions Builder',
          style: TextStyle(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
    actions: [
      if (_bgMode && _running)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _badge('Background', _amber, spin: true),
        ),
      if (_logs.isNotEmpty)
        _iconBtn(Icons.content_copy_rounded, 'Salin log', _copyLogs),
      if (_formReady && !_running)
        _iconBtn(Icons.tune_rounded, 'Edit token', () {
          setState(() {
            _formReady = false;
            _steps = _freshSteps();
          });
        }),
      const SizedBox(width: 4),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _border),
    ),
  );

  void _copyLogs() {
    Clipboard.setData(
      ClipboardData(
        text: _logs.map((e) => '[${_ts(e.ts)}] ${e.msg}').join('\n'),
      ),
    );
    _snack('Log disalin ✓');
  }

  Widget _buildFormView({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _banner(),
            const SizedBox(height: 18),
            _formStepsPreview(),
            const SizedBox(height: 24),
            if (_tokenSaved) ...[
              _savedTokenBadge(),
              const SizedBox(height: 14),
            ],
            _formSection(Icons.token_rounded, 'GitHub Personal Access Token'),
            const SizedBox(height: 14),
            _lbl('GHP Token  ·  Settings › Developer Settings › PAT'),
            _pFld(
              _ctrlToken,
              'ghp_xxxxxxxxxxxxxxxxxxxx',
              _showToken,
              () => setState(() => _showToken = !_showToken),
              val: (v) {
                if (v == null || v.trim().isEmpty) return 'Token wajib diisi';
                if (!v.trim().startsWith('ghp_') &&
                    !v.trim().startsWith('github_pat_')) {
                  return 'Format tidak valid (harus diawali ghp_ atau github_pat_)';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _scopeInfo(),
            const SizedBox(height: 20),
            _formSection(
              Icons.folder_zip_rounded,
              'Upload Project Flutter (ZIP)',
            ),
            const SizedBox(height: 14),
            _zipPickerWidget(),
            const SizedBox(height: 6),
            _zipInfoCard(),
            const SizedBox(height: 14),
            _warningCard(),
            const SizedBox(height: 14),
            _bgInfoCard(),
            const SizedBox(height: 20),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _bgInfoCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _amber.withOpacity(0.05),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _amber.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notifications_active_rounded,
          color: _amber.withOpacity(0.9),
          size: 15,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Mode background aktif.\n'
            'Build tetap lanjut walau app ditutup. Saat dibuka lagi, status dan log terakhir akan disambungkan otomatis.',
            style: TextStyle(color: _amber, fontSize: 12, height: 1.55),
          ),
        ),
      ],
    ),
  );

  Widget _zipPickerWidget() => GestureDetector(
    onTap: _pickZip,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _zipBytes != null ? _green.withOpacity(0.55) : _border2,
          width: _zipBytes != null ? 1.5 : 1.0,
        ),
        boxShadow: _zipBytes != null
            ? [BoxShadow(color: _green.withOpacity(0.06), blurRadius: 14)]
            : null,
      ),
      child: _zipPicking
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: _cyan,
                ),
              ),
            )
          : _zipBytes != null
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _greenDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.folder_zip_rounded,
                    color: _green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _zipFileName ?? '',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_zipSizeMB.toStringAsFixed(1)} MB · Ketuk untuk ganti',
                        style: const TextStyle(color: _textSub, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.check_circle_rounded, color: _green, size: 20),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _cyanDim,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _cyan.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: _cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ketuk untuk pilih file ZIP',
                  style: TextStyle(
                    color: _text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'ZIP project Flutter kamu (pubspec.yaml harus ada di dalam)',
                  style: TextStyle(color: _textSub, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    ),
  );

  Widget _zipInfoCard() => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _blueDim,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _blue.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: _blue.withOpacity(0.8),
          size: 13,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'ZIP akan diupload ke repo GitHub kamu, kemudian diekstrak & di-build oleh GitHub Actions. '
            'Ukuran maksimal ±50 MB. Struktur ZIP: bisa root langsung atau satu folder di dalam.',
            style: TextStyle(color: _textSub, fontSize: 11.5, height: 1.55),
          ),
        ),
      ],
    ),
  );

  Widget _savedTokenBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: _greenDim,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _green.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: _green, size: 14),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Token tersimpan di perangkat ini',
            style: TextStyle(color: _green, fontSize: 12.5),
          ),
        ),
        GestureDetector(
          onTap: () async {
            await _clearSavedToken();
            _ctrlToken.clear();
            _snack('Token dihapus dari penyimpanan lokal');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _redDim,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _red.withOpacity(0.3)),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: _red,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _banner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border2),
      boxShadow: [
        BoxShadow(
          color: _cyan.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_cyan.withOpacity(0.9), _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _cyan.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANTA GitHub Actions Builder',
                style: TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tanpa VPS · Tanpa SSH · Cukup token GitHub\n'
                'Upload ZIP → build APK → notifikasi otomatis',
                style: TextStyle(color: _textSub, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _formStepsPreview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '8 LANGKAH OTOMATIS VIA GITHUB API',
        style: TextStyle(
          color: _textMute,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 5,
        runSpacing: 5,
        children: _freshSteps()
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, color: _textMute, size: 11),
                    const SizedBox(width: 5),
                    Text(
                      s.label,
                      style: const TextStyle(color: _textSub, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _formSection(IconData icon, String title) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _cyanDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cyan.withOpacity(0.2)),
        ),
        child: Icon(icon, color: _cyan, size: 15),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: _text,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _scopeInfo() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _blueDim,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _blue.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: _blue.withOpacity(0.85),
              size: 13,
            ),
            const SizedBox(width: 7),
            const Text(
              'Scope token yang dibutuhkan',
              style: TextStyle(
                color: _blue,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in const [
          ('repo', 'Akses penuh ke repo (push workflow & ZIP)'),
          ('workflow', 'Buat & jalankan GitHub Actions workflow'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _cyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      color: _cyan,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.$2,
                  style: const TextStyle(color: _textSub, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _warningCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _amber.withOpacity(0.05),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _amber.withOpacity(0.18)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.schedule_rounded, color: _amber.withOpacity(0.85), size: 15),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Estimasi build: 5–15 menit (Ubuntu runner)\n'
            'Repo public → gratis unlimited. Repo private → kuota 2.000 mnt/bln.',
            style: TextStyle(color: _amber, fontSize: 12, height: 1.55),
          ),
        ),
      ],
    ),
  );

  Widget _submitButton() => GestureDetector(
    onTap: () {
      if (_formKey.currentState!.validate()) {
        if (_zipBytes == null) {
          _snack('Pilih file ZIP project Flutter terlebih dahulu');
          return;
        }
        setState(() => _formReady = true);
      }
    },
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cyan.withOpacity(0.85), _blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text(
            'Mulai Build via GitHub Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTerminalView({Key? key}) => Column(
    key: key,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: _serverBar(),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: _progressBar(),
      ),
      SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          itemCount: _steps.length,
          itemBuilder: (_, i) => _stepChip(_steps[i]),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 6),
        height: 1,
        color: _border,
      ),
      Expanded(child: _terminalOutput()),
      _bottomBar(),
    ],
  );

  Widget _serverBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _border2),
    ),
    child: Row(
      children: [
        Row(
          children: [
            _wDot(const Color(0xFFFF5F57)),
            const SizedBox(width: 5),
            _wDot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 5),
            _wDot(const Color(0xFF28C840)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _githubOwner != null
                        ? 'github.com/$_githubOwner/$_kRepoName'
                        : 'github.com / …',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pill('Actions', _blueDim, _blue),
                  if (_runId != null) ...[
                    const SizedBox(width: 5),
                    _pill('run #$_runId', _cyanDim, _cyan),
                  ],
                  if (_bgMode && _running) ...[
                    const SizedBox(width: 5),
                    _pill('background', _amber.withOpacity(0.15), _amber),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _statusMsg.isEmpty ? 'Siap' : _statusMsg,
                  key: ValueKey(_statusMsg),
                  style: TextStyle(
                    fontSize: 11,
                    color: _finished && !_errored
                        ? _green
                        : _errored
                        ? _red
                        : _running
                        ? (_bgMode ? _amber : _cyan)
                        : _textSub,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(),
      ],
    ),
  );

  Widget _progressBar() => Row(
    children: [
      Text(
        '$_doneCount/${_steps.length}',
        style: const TextStyle(color: _textSub, fontSize: 10.5),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: AnimatedBuilder(
          animation: _progressAnim,
          builder: (_, __) {
            final v = _progressAnim.value;
            return Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _card2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _errored
                            ? [_red, _red.withOpacity(0.6)]
                            : _finished
                            ? [_green, _green.withOpacity(0.7)]
                            : _bgMode
                            ? [_amber, _amber.withOpacity(0.7)]
                            : [_cyan, _blue],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_errored
                                      ? _red
                                      : _finished
                                      ? _green
                                      : _bgMode
                                      ? _amber
                                      : _cyan)
                                  .withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      AnimatedBuilder(
        animation: _progressAnim,
        builder: (_, __) => Text(
          '${(_progressAnim.value * 100).toInt()}%',
          style: const TextStyle(color: _textSub, fontSize: 10.5),
        ),
      ),
    ],
  );

  Widget _stepChip(_Step s) {
    final Color fg;
    final Widget icn;

    switch (s.status) {
      case _SS.idle:
        fg = _textMute;
        icn = Icon(s.icon, color: _textMute, size: 11);
        break;
      case _SS.running:
        fg = _bgMode ? _amber : _cyan;
        icn = AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                color: _bgMode ? _amber : _cyan,
              ),
            ),
          ),
        );
        break;
      case _SS.done:
        fg = _green;
        icn = const Icon(Icons.check_rounded, color: _green, size: 11);
        break;
      case _SS.failed:
        fg = _red;
        icn = const Icon(Icons.close_rounded, color: _red, size: 11);
        break;
    }

    final isActive = s.status == _SS.running || s.status == _SS.done;

    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withOpacity(s.status == _SS.idle ? 0.0 : 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: fg.withOpacity(s.status == _SS.running ? 0.65 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icn,
          const SizedBox(width: 5),
          Text(
            s.label,
            style: TextStyle(
              color: isActive ? fg : _textSub,
              fontSize: 10.5,
              fontWeight: s.status == _SS.running
                  ? FontWeight.w700
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalOutput() => Container(
    margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded, color: _textMute, size: 12),
              const SizedBox(width: 7),
              const Text(
                'github actions log',
                style: TextStyle(
                  color: _textMute,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (_bgMode && _running)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'live · background',
                    style: TextStyle(color: _amber, fontSize: 9.5),
                  ),
                ),
              Text(
                '${_logs.length} lines',
                style: const TextStyle(color: _textMute, fontSize: 10),
              ),
            ],
          ),
        ),
        Expanded(
          child: _logs.isEmpty
              ? _emptyTerminal()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(10),
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => _logRow(_logs[i]),
                ),
        ),
      ],
    ),
  );

  Widget _logRow(_LogEntry e) {
    final color = _lcColor(e.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_ts(e.ts)} ',
            style: const TextStyle(
              color: _textMute,
              fontSize: 9.5,
              fontFamily: 'monospace',
            ),
          ),
          if (e.type == _LT.step)
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _purple.withOpacity(0.3)),
              ),
              child: Text(
                e.msg,
                style: const TextStyle(
                  color: _lcStep,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                e.msg,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyTerminal() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: 0.15 + _pulseAnim.value * 0.25,
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: _textSub,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'GitHub Actions log akan muncul di sini',
          style: TextStyle(color: _textSub, fontSize: 13),
        ),
        const SizedBox(height: 5),
        const Text(
          'Tekan tombol di bawah untuk memulai build',
          style: TextStyle(color: _textMute, fontSize: 11.5),
        ),
      ],
    ),
  );

  Widget _bottomBar() {
    if (_finished && !_errored) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _greenDim,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _green.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: _green.withOpacity(0.06), blurRadius: 16),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: _green,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'APK berhasil di-build! 🎉',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (_artifactName != null)
                          Text(
                            '📦 $_artifactName'
                            '${_artifactSizeBytes != null ? " · ${(_artifactSizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB" : ""}',
                            style: const TextStyle(
                              color: _lcNorm,
                              fontSize: 11.5,
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (_downloadPath != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.folder_open_rounded,
                                color: _green,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _downloadPath!,
                                  style: const TextStyle(
                                    color: _green,
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else if (_artifactUrl != null)
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: _artifactUrl!),
                              );
                              _snack('URL artifact disalin ✓');
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _artifactUrl!,
                                    style: const TextStyle(
                                      color: _cyan,
                                      fontSize: 10.5,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.copy_rounded,
                                  color: _green.withOpacity(0.6),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_downloading)
              _downloadProgressWidget()
            else if (_downloadPath == null)
              _actionBtn(
                'Download APK ZIP ke Perangkat',
                Icons.download_rounded,
                _downloadArtifactZip,
                color: _green,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _greenDim,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ZIP tersimpan di perangkat ✓',
                      style: TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 15),
              label: const Text('Kembali'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textSub,
                side: BorderSide(color: _border2),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_errored) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: _redDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _red.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: _red, size: 15),
                  SizedBox(width: 9),
                  Text(
                    'Build gagal — lihat log di atas',
                    style: TextStyle(color: _red, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _formReady = false;
                      _steps = _freshSteps();
                    }),
                    icon: const Icon(Icons.edit_rounded, size: 13),
                    label: const Text('Edit Token'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSub,
                      side: BorderSide(color: _border2),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  flex: 2,
                  child: _actionBtn('Coba Ulang', Icons.refresh_rounded, () {
                    setState(() => _steps = _freshSteps());
                    _startBuild();
                  }, color: _red),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_running) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bgMode)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _amber.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Opacity(
                        opacity: _pulseAnim.value,
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: _amber,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Build berjalan di background — app bisa ditutup!\nNotifikasi otomatis saat selesai.',
                        style: TextStyle(
                          color: _amber,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _cancelBuild,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  size: 14,
                  color: _textSub,
                ),
                label: const Text(
                  'Batalkan',
                  style: TextStyle(color: _textSub, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            _actionBtn(
              _bgMode
                  ? 'Background build $_doneCount/${_steps.length} langkah…'
                  : 'Sedang build…  ($_doneCount/${_steps.length} langkah)',
              _bgMode ? Icons.cloud_sync_rounded : Icons.hourglass_top_rounded,
              null,
              color: _bgMode ? _amber : null,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: _actionBtn(
        'Mulai Build Sekarang',
        Icons.rocket_launch_rounded,
        _startBuild,
      ),
    );
  }

  Widget _downloadProgressWidget() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: _card2,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _border2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.6, color: _cyan),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mengunduh APK ZIP…',
                style: TextStyle(color: _textSub, fontSize: 12.5),
              ),
            ),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: _cyan,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: _border,
            valueColor: const AlwaysStoppedAnimation(_cyan),
            minHeight: 4,
          ),
        ),
        if (_artifactSizeBytes != null) ...[
          const SizedBox(height: 6),
          Text(
            '${(_downloadProgress * _artifactSizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB'
            ' / ${(_artifactSizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB',
            style: const TextStyle(color: _textMute, fontSize: 10.5),
          ),
        ],
      ],
    ),
  );

  Widget _statusBadge() {
    if (_running && !_finished && _bgMode)
      return _badge('Background', _amber, spin: true);
    if (_running && !_finished) return _badge('Building', _cyan, spin: true);
    if (_finished && !_errored) return _badge('Done', _green);
    if (_errored) return _badge('Error', _red);
    return _badge('Idle', _textMute);
  }

  Widget _badge(String label, Color c, {bool spin = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (spin)
          SizedBox(
            width: 7,
            height: 7,
            child: CircularProgressIndicator(strokeWidth: 1.4, color: c),
          )
        else
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: c,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _actionBtn(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    Color? color,
  }) {
    final c = color ?? _cyan;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? LinearGradient(
                  colors: color != null
                      ? [c.withOpacity(0.8), c]
                      : [_cyan.withOpacity(0.85), _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: onTap == null ? _card2 : null,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: onTap == null ? _border2 : Colors.transparent,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: c.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_running && onTap == null)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white54,
                ),
              )
            else
              Icon(
                icon,
                color: onTap != null ? Colors.white : _textSub,
                size: 17,
              ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? Colors.white : _textSub,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowIcon(IconData icon, Color color, {double size = 16}) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
      boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8)],
    ),
    child: Icon(icon, color: color, size: size),
  );

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon, size: 16, color: _textSub),
        tooltip: tooltip,
        onPressed: onTap,
      );

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        color: _textSub,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _pFld(
    TextEditingController c,
    String hint,
    bool vis,
    VoidCallback toggle, {
    String? Function(String?)? val,
  }) => TextFormField(
    controller: c,
    obscureText: !vis,
    style: const TextStyle(color: _text, fontSize: 13.5),
    decoration: _deco(hint).copyWith(
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: _textMute,
        size: 16,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          vis ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _textMute,
          size: 16,
        ),
        onPressed: toggle,
      ),
    ),
    validator: val,
  );

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _textMute, fontSize: 13),
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _cyan.withOpacity(0.7), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _red.withOpacity(0.5)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _red, width: 1.5),
    ),
    errorStyle: const TextStyle(color: _red, fontSize: 11),
  );

  Widget _wDot(Color c) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _pill(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label, style: TextStyle(color: fg, fontSize: 10.5)),
  );

  Color _lcColor(_LT t) {
    switch (t) {
      case _LT.ok:
        return _lcOk;
      case _LT.err:
        return _lcErr;
      case _LT.info:
        return _lcInfo;
      case _LT.sys:
        return _lcSys;
      case _LT.step:
        return _lcStep;
      case _LT.norm:
        return _lcNorm;
    }
  }

  String _ts(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: _card2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 3),
    ),
  );
}
