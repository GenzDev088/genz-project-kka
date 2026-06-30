import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:archive/archive.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
const Color _purpleDim = Color(0xFF2A2040);
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

class _ConfigField {
  final String key;
  final String label;
  final String defaultVal;
  final bool isSensitive;
  final bool isRequired;
  late final TextEditingController ctrl;

  _ConfigField({
    required this.key,
    required this.label,
    required this.defaultVal,
    required this.isSensitive,
    required this.isRequired,
  }) {
    ctrl = TextEditingController(text: defaultVal);
  }

  void dispose() => ctrl.dispose();
}

class _ZipInfo {
  final Uint8List bytes;
  final String fileName;
  final String rootDir;
  final bool isPython;
  final bool isNode;
  final bool hasFFmpeg;
  final bool hasExpiry;
  final String entrypoint;
  final String envTemplateName;
  final List<_ConfigField> fields;
  final List<String> pythonModuleSpecs;

  const _ZipInfo({
    required this.bytes,
    required this.fileName,
    required this.rootDir,
    required this.isPython,
    required this.isNode,
    required this.hasFFmpeg,
    required this.hasExpiry,
    required this.entrypoint,
    required this.envTemplateName,
    required this.fields,
    required this.pythonModuleSpecs,
  });
}

List<_Step> _buildSteps(_ZipInfo info) => [
  _Step(id: 'update', label: 'System Update', icon: Icons.sync_alt_rounded),
  _Step(id: 'upload', label: 'Upload ZIP', icon: Icons.upload_rounded),
  _Step(id: 'extract', label: 'Extract Repo', icon: Icons.folder_zip_outlined),
  if (info.hasFFmpeg)
    _Step(id: 'ffmpeg', label: 'Install FFmpeg', icon: Icons.videocam_outlined),
  if (info.isPython)
    _Step(
      id: 'pyenv',
      label: 'Python venv + pip',
      icon: Icons.terminal_rounded,
    ),
  if (info.isNode)
    _Step(id: 'nodepm', label: 'Node.js + npm', icon: Icons.code_rounded),
  _Step(id: 'dotenv', label: 'Configure .env', icon: Icons.settings_rounded),
  if (info.isPython && info.hasExpiry)
    _Step(id: 'noexp', label: 'Disable Expiry', icon: Icons.timer_off_outlined),
  _Step(
    id: 'start',
    label: 'Start Userbot',
    icon: Icons.play_circle_outline_rounded,
  ),
];

String _humanLabel(String key) {
  const fixes = {
    'API': 'API',
    'ID': 'ID',
    'URL': 'URL',
    'BOT': 'Bot',
    'MONGO': 'MongoDB',
    'RMBG': 'RMBG',
    'SSH': 'SSH',
    'VPS': 'VPS',
  };
  return key
      .split('_')
      .map((w) {
        if (w.isEmpty) return w;
        final up = w.toUpperCase();
        if (fixes.containsKey(up)) return fixes[up]!;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
}

bool _isSensitive(String key) {
  final k = key.toUpperCase();
  return k.contains('TOKEN') ||
      k.contains('HASH') ||
      k.contains('SECRET') ||
      k.contains('PASSWORD') ||
      k.contains('PASS') ||
      k.contains('MONGO') ||
      k.contains('RMBG') ||
      k.contains('WEBHOOK') ||
      k.contains('API_KEY') ||
      k.contains('SESSION');
}

bool _isRequired(String key, String defVal) {
  if (defVal.isEmpty) return true;
  const mustFill = {
    'BOT_TOKEN',
    'API_ID',
    'API_HASH',
    'OWNER_ID',
    'MONGO_URL',
    'STRING_SESSION',
    'SESSION',
  };
  return mustFill.contains(key.toUpperCase());
}

List<_ConfigField> _parseConfigPy(String src) {
  final out = <_ConfigField>[];
  final seen = <String>{};
  final re = RegExp(
    r'''os\.getenv\(\s*["']([A-Z_][A-Z0-9_]*)["']'''
    r'''(?:\s*,\s*["']([^"']*)["'])?\s*\)''',
  );
  for (final m in re.allMatches(src)) {
    final key = m.group(1)!;
    final def = m.group(2) ?? '';
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add(
      _ConfigField(
        key: key,
        label: _humanLabel(key),
        defaultVal: def,
        isSensitive: _isSensitive(key),
        isRequired: _isRequired(key, def),
      ),
    );
  }
  return out;
}

List<_ConfigField> _parseEnvFile(String src) {
  final out = <_ConfigField>[];
  final seen = <String>{};
  for (final raw in src.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('#') || line.isEmpty || !line.contains('=')) continue;
    final idx = line.indexOf('=');
    final key = line.substring(0, idx).trim();
    var val = line.substring(idx + 1).trim();
    if (!RegExp(r'^[A-Z_][A-Z0-9_]*$').hasMatch(key)) continue;
    if (seen.contains(key)) continue;
    seen.add(key);
    if ((val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))) {
      val = val.substring(1, val.length - 1);
    }
    out.add(
      _ConfigField(
        key: key,
        label: _humanLabel(key),
        defaultVal: val,
        isSensitive: _isSensitive(key),
        isRequired: _isRequired(key, val),
      ),
    );
  }
  return out;
}

String _detectEntry(Archive ar, bool isPy, bool isNode) {
  const commonPythonEntrypoints = {
    'main.py',
    'app.py',
    'bot.py',
    'run.py',
    'start.py',
    'userbot.py',
  };
  for (final f in ar.files) {
    if (!f.isFile) continue;
    final name = f.name.toLowerCase().split('/').last;
    if (commonPythonEntrypoints.contains(name)) {
      return 'python3 ${f.name.split('/').last}';
    }
  }
  for (final f in ar.files) {
    if (!f.isFile) continue;
    final parts = f.name.split('/');
    if (parts.last == '__main__.py' && parts.length >= 2) {
      final pkg = parts[parts.length - 2];
      if (pkg.isNotEmpty &&
          !pkg.startsWith('.') &&
          pkg != 'test' &&
          pkg != 'venv') {
        return 'python3 -m $pkg';
      }
    }
  }
  for (final f in ar.files) {
    if (!f.isFile) continue;
    final name = f.name.toLowerCase().split('/').last;
    if (name.contains('readme')) {
      final c = utf8.decode(f.content as List<int>, allowMalformed: true);
      final mPy = RegExp(
        r'python3?\s+-m\s+(?!venv\b|pip\b|ensurepip\b)(\w[\w.]+)',
      ).firstMatch(c);
      if (mPy != null) return 'python3 -m ${mPy.group(1)}';
      final mNode = RegExp(r'node\s+(\S+\.js)').firstMatch(c);
      if (mNode != null) return 'node ${mNode.group(1)}';
    }
  }
  for (final f in ar.files) {
    if (!f.isFile) continue;
    if (f.name.endsWith('package.json') && !f.name.contains('node_modules')) {
      try {
        final j = jsonDecode(utf8.decode(f.content as List<int>)) as Map;
        final start = (j['scripts'] as Map?)?['start'];
        if (start != null) return start.toString();
        if (j['main'] != null) return 'node ${j["main"]}';
      } catch (_) {}
      return 'node index.js';
    }
  }
  if (isNode) return 'node index.js';
  return 'python3 main.py';
}

List<String> _detectPythonModuleSpecs(Archive ar) {
  const stdlib = {
    '__future__',
    'abc',
    'argparse',
    'array',
    'ast',
    'asyncio',
    'base64',
    'binascii',
    'calendar',
    'collections',
    'concurrent',
    'contextlib',
    'copy',
    'csv',
    'ctypes',
    'datetime',
    'decimal',
    'difflib',
    'enum',
    'functools',
    'gc',
    'getpass',
    'glob',
    'gzip',
    'hashlib',
    'heapq',
    'hmac',
    'html',
    'http',
    'importlib',
    'inspect',
    'io',
    'ipaddress',
    'itertools',
    'json',
    'logging',
    'math',
    'mimetypes',
    'multiprocessing',
    'numbers',
    'operator',
    'os',
    'pathlib',
    'pickle',
    'platform',
    'plistlib',
    'pprint',
    'queue',
    'random',
    're',
    'secrets',
    'shlex',
    'shutil',
    'signal',
    'socket',
    'sqlite3',
    'ssl',
    'statistics',
    'string',
    'subprocess',
    'sys',
    'tempfile',
    'textwrap',
    'threading',
    'time',
    'traceback',
    'typing',
    'types',
    'unicodedata',
    'unittest',
    'urllib',
    'uuid',
    'warnings',
    'wave',
    'weakref',
    'xml',
    'zipfile',
    'zoneinfo',
  };
  const packageMap = {
    'telethon': 'telethon',
    'pyrogram': 'pyrogram',
    'pyrofork': 'pyrofork',
    'tgcrypto': 'tgcrypto',
    'dotenv': 'python-dotenv',
    'yaml': 'pyyaml',
    'bs4': 'beautifulsoup4',
    'PIL': 'pillow',
    'cv2': 'opencv-python-headless',
    'pymongo': 'pymongo',
    'motor': 'motor',
    'aiohttp': 'aiohttp',
    'aiogram': 'aiogram',
    'uvloop': 'uvloop',
    'requests': 'requests',
    'httpx': 'httpx',
    'ujson': 'ujson',
    'orjson': 'orjson',
    'sqlalchemy': 'sqlalchemy',
    'redis': 'redis',
    'emoji': 'emoji',
    'psutil': 'psutil',
    'meval': 'meval',
    'gtts': 'gTTS',
    'dateutil': 'python-dateutil',
    'dns': 'dnspython',
    'Crypto': 'pycryptodome',
    'OpenSSL': 'pyOpenSSL',
    'git': 'gitpython',
    'telegraph': 'telegraph',
    'pyromod': 'pyromod',
    'apscheduler': 'apscheduler',
    'heroku3': 'heroku3',
    'jinja2': 'jinja2',
    'flask': 'flask',
    'fastapi': 'fastapi',
    'uvicorn': 'uvicorn',
    'quart': 'quart',
    'faker': 'faker',
    'numpy': 'numpy',
    'pytz': 'pytz',
    'brotli': 'brotli',
  };

  final imports = <String>{};
  for (final f in ar.files) {
    if (!f.isFile) continue;
    final filePath = f.name.toLowerCase();
    if (!filePath.endsWith('.py')) continue;
    if (filePath.contains('/venv/') ||
        filePath.contains('/.venv/') ||
        filePath.contains('/site-packages/') ||
        filePath.contains('/__pycache__/') ||
        filePath.contains('/tests/') ||
        filePath.contains('/test/')) {
      continue;
    }
    final content = utf8.decode(f.content as List<int>, allowMalformed: true);
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimLeft();
      if (line.startsWith('import ')) {
        final part = line.substring(7);
        for (final chunk in part.split(',')) {
          final token = chunk.trim().split(RegExp(r'[\s.]')).first.trim();
          if (token.isNotEmpty) imports.add(token);
        }
      } else if (line.startsWith('from ') && !line.startsWith('from .')) {
        final token = line.substring(5).split(RegExp(r'[\s.]')).first.trim();
        if (token.isNotEmpty) imports.add(token);
      }
    }
  }

  final specs = <String>[];
  for (final entry in packageMap.entries) {
    if (imports.contains(entry.key) && !stdlib.contains(entry.key)) {
      specs.add('${entry.key}|${entry.value}');
    }
  }
  specs.sort();
  return specs;
}

_ZipInfo? parseZipFile(Uint8List bytes, String fileName) {
  try {
    final ar = ZipDecoder().decodeBytes(bytes);

    final topDirs = <String>{};
    for (final f in ar.files) {
      final parts = f.name.split('/');
      if (parts.length > 1) topDirs.add(parts[0]);
    }
    final rootDir = topDirs.length == 1 ? topDirs.first : '';

    bool isPy = false, isNode = false, hasFFmpeg = false, hasExpiry = false;
    String envTmplName = '';
    List<_ConfigField> fields = [];

    for (final f in ar.files) {
      if (!f.isFile) continue;
      final name = f.name.toLowerCase().split('/').last;
      final content = utf8.decode(f.content as List<int>, allowMalformed: true);

      if (name == 'requirements.txt' ||
          name == 'setup.py' ||
          name == 'pyproject.toml')
        isPy = true;
      if (name == 'package.json' && !f.name.contains('node_modules'))
        isNode = true;
      if (name.contains('readme') && content.toLowerCase().contains('ffmpeg'))
        hasFFmpeg = true;
      if (name == '__main__.py' && content.contains('expiredUserbots'))
        hasExpiry = true;

      if (name == 'config.py' && fields.isEmpty) {
        fields = _parseConfigPy(content);
      }
    }

    const envTemplates = [
      'sample.env',
      '.env.example',
      '.env.sample',
      'example.env',
      'config.env',
    ];
    for (final f in ar.files) {
      if (!f.isFile) continue;
      final name = f.name.toLowerCase().split('/').last;
      if (envTemplates.contains(name) &&
          (fields.isEmpty || envTmplName.isEmpty)) {
        final content = utf8.decode(
          f.content as List<int>,
          allowMalformed: true,
        );
        envTmplName = name;
        if (fields.isEmpty) fields = _parseEnvFile(content);
      }
    }

    if (fields.isEmpty) {
      for (final f in ar.files) {
        if (!f.isFile) continue;
        if (f.name.split('/').last == '.env') {
          final content = utf8.decode(
            f.content as List<int>,
            allowMalformed: true,
          );
          envTmplName = '.env';
          fields = _parseEnvFile(content);
          break;
        }
      }
    }

    final entry = _detectEntry(ar, isPy, isNode);
    final pythonModuleSpecs = isPy
        ? _detectPythonModuleSpecs(ar)
        : const <String>[];

    return _ZipInfo(
      bytes: bytes,
      fileName: fileName,
      rootDir: rootDir,
      isPython: isPy,
      isNode: isNode,
      hasFFmpeg: hasFFmpeg,
      hasExpiry: hasExpiry,
      entrypoint: entry,
      envTemplateName: envTmplName,
      fields: fields,
      pythonModuleSpecs: pythonModuleSpecs,
    );
  } catch (_) {
    return null;
  }
}

class InstallUbotPage extends StatefulWidget {
  const InstallUbotPage({super.key});

  @override
  State<InstallUbotPage> createState() => _InstallUbotState();
}

class _InstallUbotState extends State<InstallUbotPage>
    with TickerProviderStateMixin {
  final _ctrlIp = TextEditingController();
  final _ctrlUser = TextEditingController(text: 'root');
  final _ctrlPass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPass = false;
  bool _showSensitive = false;

  int _phase = 0;

  _ZipInfo? _zip;
  bool _loadingZip = false;
  String? _zipError;

  List<_Step> _steps = [];
  final List<_LogEntry> _logs = [];
  bool _running = false;
  bool _finished = false;
  bool _errored = false;
  int _doneCount = 0;
  String _statusMsg = '';
  final ScrollController _scroll = ScrollController();

  SSHClient? _sshClient;
  SSHSession? _sshShell;
  Timer? _keepalive;
  String _outBuf = '';

  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _sshCleanup();
    _scroll.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _ctrlIp.dispose();
    _ctrlUser.dispose();
    _ctrlPass.dispose();
    _zip?.fields.forEach((f) => f.dispose());
    super.dispose();
  }

  void _sshCleanup() {
    _keepalive?.cancel();
    _keepalive = null;
    try {
      _sshShell?.close();
    } catch (_) {}
    try {
      _sshClient?.close();
    } catch (_) {}
    _sshClient = null;
    _sshShell = null;
  }

  void _write(String s) => _sshShell?.stdin.add(utf8.encode(s));

  static String _stripAnsi(String raw) => raw
      .replaceAll(RegExp(r'\x1B\[[0-9;]*[mGKHFABCDJMPX]'), '')
      .replaceAll(RegExp(r'\x1B\[\?[0-9;]*[hl]'), '')
      .replaceAll(RegExp(r'\x1B[()][A-Z0]'), '')
      .replaceAll(RegExp(r'\x1B\][^\x07]*\x07'), '')
      .replaceAll('\r', '');

  void _onData(String raw) {
    if (raw.isEmpty) return;
    _outBuf += _stripAnsi(raw);
    final parts = _outBuf.split('\n');
    for (int i = 0; i < parts.length - 1; i++) {
      final line = parts[i].trim();
      if (line.isNotEmpty) _processLine(line);
    }
    _outBuf = parts.last;
  }

  void _processLine(String line) {
    if (line.startsWith('UBOT_STEP:')) {
      _onStepBegin(line.substring(10).trim());
      return;
    }
    if (line.startsWith('UBOT_OK:')) {
      _onStepDone(line.substring(8).trim());
      return;
    }
    if (line.startsWith('UBOT_FAIL:')) {
      final rest = line.substring(10).trim();
      _onStepFail(rest.split(' - ').first.trim(), rest);
      return;
    }
    if (line.contains('UBOT_INSTALL_COMPLETE')) {
      _onInstallComplete(success: true);
      return;
    }

    final l = line.toLowerCase();
    _LT type = _LT.norm;
    if (l.contains('error') || l.contains('failed') || l.contains('fatal')) {
      final benign =
          l.contains('dpkg') ||
          l.contains('apt-get') ||
          l.contains('note:') ||
          l.contains('0 upgraded') ||
          l.contains('already installed') ||
          l.contains('0 newly');
      type = benign ? _LT.norm : _LT.err;
    } else if (l.contains('✓') ||
        l.contains('success') ||
        l.contains('complete')) {
      type = _LT.ok;
    } else if (line.startsWith('[') ||
        l.contains('installing') ||
        l.contains('downloading') ||
        l.contains('uploading') ||
        l.contains('extracting') ||
        l.contains('collecting')) {
      type = _LT.info;
    }
    _addLog(line, type);
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

  void _onStepBegin(String id) {
    final idx = _steps.indexWhere((s) => s.id == id);
    if (idx < 0 || !mounted) return;
    setState(() {
      for (final s in _steps) {
        if (s.status == _SS.running) {
          s.status = _SS.idle;
        }
      }
      _steps[idx].status = _SS.running;
      _statusMsg = '${_steps[idx].label}…';
    });
    _addLog('▶ ${_steps[idx].label}', _LT.step);
  }

  void _onStepDone(String id) {
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

  void _onStepFail(String id, String detail) {
    final idx = _steps.indexWhere((s) => s.id == id);
    if (idx >= 0 && mounted) setState(() => _steps[idx].status = _SS.failed);
    if (mounted) setState(() => _errored = true);
    _addLog('✗ GAGAL: $detail', _LT.err);
  }

  void _onInstallComplete({required bool success}) {
    if (!mounted || _finished) return;
    _keepalive?.cancel();
    if (success) {
      _progressCtrl.animateTo(1.0, duration: const Duration(milliseconds: 700));
    }
    setState(() {
      _running = false;
      _finished = true;
      _errored = !success;
      _statusMsg = success ? 'Selesai ✓' : 'Gagal';
    });
    if (success) {
      _addLog('', _LT.norm);
      _addLog('╔══════════════════════════════════════╗', _LT.ok);
      _addLog('║    USERBOT BERHASIL TERINSTALL ✓     ║', _LT.ok);
      _addLog('╚══════════════════════════════════════╝', _LT.ok);
      _addLog('Log systemd : journalctl -u ubot -f', _LT.info);
      _addLog('Log nohup   : tail -f /root/ubot.log', _LT.info);
      _addLog('Restart     : systemctl restart ubot', _LT.info);
      _addLog('Stop        : systemctl stop ubot', _LT.info);
    } else {
      _addLog('✗ Instalasi gagal — periksa log di atas.', _LT.err);
    }
  }

  void _onShellClosed() {
    if (!mounted || _finished) return;
    _keepalive?.cancel();
    final ok = _doneCount >= (_steps.length * 0.8).ceil();
    _onInstallComplete(success: ok);
  }

  Future<void> _pickZip() async {
    setState(() {
      _loadingZip = true;
      _zipError = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loadingZip = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _loadingZip = false;
          _zipError = 'Gagal membaca file ZIP.';
        });
        return;
      }
      final info = parseZipFile(bytes, file.name);
      if (info == null) {
        setState(() {
          _loadingZip = false;
          _zipError = 'File bukan ZIP yang valid.';
        });
        return;
      }
      setState(() {
        _loadingZip = false;
        _zip = info;
        _phase = 1;
      });
    } catch (e) {
      setState(() {
        _loadingZip = false;
        _zipError = 'Error: $e';
      });
    }
  }

  Future<void> _startInstall() async {
    final info = _zip!;
    final steps = _buildSteps(info);
    setState(() {
      _running = true;
      _finished = false;
      _errored = false;
      _doneCount = 0;
      _statusMsg = 'Menghubungkan SSH…';
      _steps = steps;
      _logs.clear();
      _outBuf = '';
      _phase = 2;
    });
    _progressCtrl.reset();

    final ip = _ctrlIp.text.trim();
    final user = _ctrlUser.text.trim().isEmpty ? 'root' : _ctrlUser.text.trim();

    _addLog('MANTA Ubot Auto-Installer v3', _LT.sys);
    _addLog('Host   → $ip', _LT.sys);
    _addLog('User   → $user', _LT.sys);
    _addLog('File   → ${info.fileName}', _LT.sys);
    _addLog(
      'Type   → ${info.isPython ? "Python " : ""}${info.isNode ? "Node.js " : ""}',
      _LT.sys,
    );
    _addLog('Entry  → ${info.entrypoint}', _LT.sys);
    _addLog(
      'Expiry → ${info.hasExpiry ? "akan dinonaktifkan" : "tidak ada"}',
      _LT.sys,
    );
    _addLog('Config → ${info.fields.length} fields', _LT.sys);
    if (info.pythonModuleSpecs.isNotEmpty) {
      _addLog(
        'Py auto → ${info.pythonModuleSpecs.length} modul terdeteksi',
        _LT.sys,
      );
    }
    _addLog('─' * 44, _LT.sys);

    try {
      _sshCleanup();
      final socket = await SSHSocket.connect(ip, 22).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Koneksi SSH timeout (20s)'),
      );
      _sshClient = SSHClient(
        socket,
        username: user,
        onPasswordRequest: () => _ctrlPass.text.trim(),
      );
      await _sshClient!.authenticated.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Autentikasi timeout'),
      );
      _addLog('✓ Terhubung sebagai $user@$ip', _LT.ok);

      _sshShell = await _sshClient!.shell(
        pty: const SSHPtyConfig(type: 'xterm', width: 220, height: 50),
      );
      _sshShell!.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_onData, onDone: _onShellClosed);
      _sshShell!.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_onData);

      _keepalive = Timer.periodic(const Duration(seconds: 25), (_) {
        if (_running && !_finished) {
          try {
            _sshClient?.ping();
          } catch (_) {}
        }
      });

      await Future.delayed(const Duration(milliseconds: 700));
      await _deliverAll(info);
    } on TimeoutException catch (e) {
      _addLog('✗ ${e.message}', _LT.err);
      _onInstallComplete(success: false);
    } catch (e) {
      _addLog('✗ Error: $e', _LT.err);
      _onInstallComplete(success: false);
    }
  }

  Future<void> _deliverAll(_ZipInfo info) async {
    final script = _buildScript(info);
    final sb64 = base64.encode(utf8.encode(script));
    const chunk = 800;
    final sChunks = (sb64.length / chunk).ceil();
    _addLog(
      'Script ${(script.length / 1024).toStringAsFixed(1)} KB → $sChunks chunks',
      _LT.sys,
    );

    _write('rm -f /tmp/_ubs.b64 /tmp/_ubs.sh /tmp/_ubz.b64 /tmp/_ub.zip\n');
    await Future.delayed(const Duration(milliseconds: 600));

    for (int i = 0; i < sb64.length; i += chunk) {
      _write(
        "printf '%s' '${sb64.substring(i, min(i + chunk, sb64.length))}' >> /tmp/_ubs.b64\n",
      );
      await Future.delayed(const Duration(milliseconds: 60));
    }
    await Future.delayed(const Duration(milliseconds: 700));

    final zb64 = base64.encode(info.bytes);
    const zChunk = 1000;
    final zChunks = (zb64.length / zChunk).ceil();
    _addLog(
      'ZIP ${(info.bytes.length / 1024).toStringAsFixed(0)} KB → $zChunks chunks',
      _LT.sys,
    );

    for (int i = 0; i < zb64.length; i += zChunk) {
      _write(
        "printf '%s' '${zb64.substring(i, min(i + zChunk, zb64.length))}' >> /tmp/_ubz.b64\n",
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('Decode & jalankan installer…', _LT.info);
    _write(
      'base64 -d /tmp/_ubs.b64 > /tmp/_ubs.sh && '
      'base64 -d /tmp/_ubz.b64 > /tmp/_ub.zip && '
      '[ -s /tmp/_ubs.sh ] && [ -s /tmp/_ub.zip ] && '
      'chmod +x /tmp/_ubs.sh && bash /tmp/_ubs.sh '
      '|| echo "UBOT_FAIL:decode - base64 decode gagal"\n',
    );
  }

  String _buildScript(_ZipInfo info) {
    final entrypoint = info.entrypoint;
    final envTmpl = info.envTemplateName;

    String escVal(String v) =>
        v.trim().replaceAll('\r', '').replaceAll('\n', ' ');

    final sb = StringBuffer();

    sb.writeln(r'''#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
_step() { echo "UBOT_STEP:$1"; }
_ok()   { echo "UBOT_OK:$1";   }
_fail() { echo "UBOT_FAIL:$1 - $2"; exit 1; }
set -eo pipefail

UBOT_ZIP=/tmp/_ub.zip
UBOT_DIR=/root/ubot
''');

    sb.writeln(r'''_step "update"
echo "=== System Update ==="
apt-get update -qq 2>&1 | tail -3
apt-get install -y -qq unzip curl wget git screen python3 python3-pip python3-venv 2>&1 | tail -3 \
  || _fail "update" "apt-get install gagal"
echo "  System ready."
_ok "update"
''');

    sb.writeln(r'''_step "upload"
echo "=== Upload ZIP ==="
[ -f "$UBOT_ZIP" ] || _fail "upload" "File ZIP tidak ditemukan"
echo "  ZIP: $(du -sh $UBOT_ZIP | cut -f1)"
rm -rf /tmp/_ub_extract && mkdir -p /tmp/_ub_extract
unzip -o "$UBOT_ZIP" -d /tmp/_ub_extract/ 2>&1 | tail -5 \
  || _fail "upload" "Gagal unzip"
_ok "upload"
''');

    sb.writeln(r'''_step "extract"
echo "=== Extract Repo ==="
rm -rf "$UBOT_DIR" && mkdir -p "$UBOT_DIR"
ITEMS=$(ls /tmp/_ub_extract/ | wc -l)
FIRST=$(ls /tmp/_ub_extract/ | head -1)
if [ "$ITEMS" -eq 1 ] && [ -d "/tmp/_ub_extract/$FIRST" ]; then
  cp -r "/tmp/_ub_extract/$FIRST/." "$UBOT_DIR/"
  echo "  Root dir: $FIRST"
else
  cp -r /tmp/_ub_extract/. "$UBOT_DIR/"
fi
rm -rf /tmp/_ub_extract
echo "  Files: $(ls $UBOT_DIR | head -8 | tr '\n' ' ')"
_ok "extract"
''');

    if (info.hasFFmpeg) {
      sb.writeln(r'''_step "ffmpeg"
echo "=== Install FFmpeg ==="
apt-get install -y ffmpeg 2>&1 | tail -3 \
  || _fail "ffmpeg" "Gagal install ffmpeg"
echo "  $(ffmpeg -version 2>&1 | head -1)"
_ok "ffmpeg"
''');
    }

    if (info.isPython) {
      sb.writeln("cat > /tmp/_ub_py_mods.txt << 'PYMODS'");
      for (final spec in info.pythonModuleSpecs) {
        sb.writeln(spec);
      }
      sb.writeln('PYMODS');
      sb.writeln(r'''_step "pyenv"
echo "=== Python venv + pip ==="
cd "$UBOT_DIR"
apt-get install -y python3-venv python3-pip python3-dev build-essential libffi-dev libssl-dev 2>/dev/null | tail -2 \
  || apt-get install -y python3.11-venv 2>/dev/null | tail -2 \
  || apt-get install -y python3.10-venv 2>/dev/null | tail -2 \
  || _fail "pyenv" "Gagal install python3-venv"
python3 -m venv venv || _fail "pyenv" "python3 -m venv gagal"
source venv/bin/activate
pip3 install --upgrade pip setuptools wheel -q 2>&1 | tail -2
py_has_module() {
  python3 - "$1" <<'PY'
import importlib.util, sys
name = sys.argv[1]
sys.exit(0 if importlib.util.find_spec(name) else 1)
PY
}
map_missing_pkg() {
  case "$1" in
    telethon) echo "telethon" ;;
    pyrogram) echo "pyrogram" ;;
    pyrofork) echo "pyrofork" ;;
    tgcrypto) echo "tgcrypto" ;;
    dotenv) echo "python-dotenv" ;;
    yaml) echo "pyyaml" ;;
    bs4) echo "beautifulsoup4" ;;
    PIL) echo "pillow" ;;
    cv2) echo "opencv-python-headless" ;;
    pymongo) echo "pymongo" ;;
    motor) echo "motor" ;;
    aiohttp) echo "aiohttp" ;;
    aiogram) echo "aiogram" ;;
    uvloop) echo "uvloop" ;;
    requests) echo "requests" ;;
    httpx) echo "httpx" ;;
    ujson) echo "ujson" ;;
    orjson) echo "orjson" ;;
    sqlalchemy) echo "sqlalchemy" ;;
    redis) echo "redis" ;;
    emoji) echo "emoji" ;;
    psutil) echo "psutil" ;;
    meval) echo "meval" ;;
    gtts) echo "gTTS" ;;
    dateutil) echo "python-dateutil" ;;
    dns) echo "dnspython" ;;
    Crypto) echo "pycryptodome" ;;
    OpenSSL) echo "pyOpenSSL" ;;
    git) echo "gitpython" ;;
    telegraph) echo "telegraph" ;;
    pyromod) echo "pyromod" ;;
    apscheduler) echo "apscheduler" ;;
    heroku3) echo "heroku3" ;;
    jinja2) echo "jinja2" ;;
    flask) echo "flask" ;;
    fastapi) echo "fastapi" ;;
    uvicorn) echo "uvicorn" ;;
    quart) echo "quart" ;;
    faker) echo "faker" ;;
    numpy) echo "numpy" ;;
    pytz) echo "pytz" ;;
    brotli) echo "brotli" ;;
    *) echo "$1" ;;
  esac
}
install_pip_pkg() {
  PKG_NAME="$1"
  [ -n "$PKG_NAME" ] || return 0
  echo "  pip install $PKG_NAME"
  pip3 install --no-cache-dir "$PKG_NAME" 2>&1 \
    | grep -E "^(Collecting|Building|Installing|Successfully|Requirement already satisfied|ERROR)" | tail -20
}
if [ -f requirements.txt ]; then
  echo "  Installing requirements.txt..."
  pip3 install --no-cache-dir -r requirements.txt 2>&1 \
    | grep -E "^(Collecting|Installing|Successfully|ERROR)" | tail -20 \
    || _fail "pyenv" "pip install gagal"
fi
if [ ! -f requirements.txt ] && { [ -f pyproject.toml ] || [ -f setup.py ]; }; then
  echo "  Installing project package..."
  pip3 install --no-cache-dir . 2>&1 \
    | grep -E "^(Processing|Preparing|Building|Installing|Successfully|ERROR)" | tail -20 \
    || _fail "pyenv" "pip install project gagal"
fi
if [ -f /tmp/_ub_py_mods.txt ]; then
  while IFS='|' read -r MOD_NAME PKG_NAME; do
    [ -n "$MOD_NAME" ] || continue
    if ! py_has_module "$MOD_NAME"; then
      echo "  Auto detect: $MOD_NAME -> $PKG_NAME"
      install_pip_pkg "$PKG_NAME" || true
    fi
  done < /tmp/_ub_py_mods.txt
fi
set +e
timeout 18s bash -lc "cd \"$UBOT_DIR\" && source \"$UBOT_DIR/venv/bin/activate\" && $entrypoint" >/tmp/_ubot_smoke.log 2>&1
SMOKE_EXIT=$?
set -e
if grep -q "ModuleNotFoundError: No module named" /tmp/_ubot_smoke.log 2>/dev/null; then
  echo "  Missing module detected from smoke test..."
  grep -oE "No module named '([^']+)'" /tmp/_ubot_smoke.log \
    | sed -E "s/No module named '([^']+)'/\1/" \
    | cut -d. -f1 | sort -u > /tmp/_ub_missing.txt
  while read -r MOD_NAME; do
    [ -n "$MOD_NAME" ] || continue
    PKG_NAME=$(map_missing_pkg "$MOD_NAME")
    echo "  Smoke fix: $MOD_NAME -> $PKG_NAME"
    install_pip_pkg "$PKG_NAME" || true
  done < /tmp/_ub_missing.txt
fi
echo "  Python: $(python3 --version)"
_ok "pyenv"
''');
    }

    if (info.isNode) {
      sb.writeln(r'''_step "nodepm"
echo "=== Node.js + npm ==="
if ! command -v node &>/dev/null; then
  echo "  Installing Node.js 20 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>&1 | tail -5
  apt-get install -y nodejs 2>&1 | tail -3 \
    || _fail "nodepm" "Gagal install nodejs"
fi
echo "  Node: $(node -v) | npm: $(npm -v)"
cd "$UBOT_DIR"
npm install 2>&1 | tail -5 \
  || _fail "nodepm" "npm install gagal"
_ok "nodepm"
''');
    }

    sb.writeln('_step "dotenv"');
    sb.writeln('echo "=== Configure .env ==="');
    sb.writeln('cd "\$UBOT_DIR"');

    if (envTmpl.isNotEmpty) {
      sb.writeln(
        '[ -f "\$UBOT_DIR/$envTmpl" ] && cp "\$UBOT_DIR/$envTmpl" "\$UBOT_DIR/.env" || true',
      );
    } else {
      sb.writeln(
        r'''for _TMPL in sample.env .env.example .env.sample example.env config.env; do
  if [ -f "$UBOT_DIR/$_TMPL" ]; then
    cp "$UBOT_DIR/$_TMPL" "$UBOT_DIR/.env"
    echo "  Template: $_TMPL"
    break
  fi
done || true''',
      );
    }

    if (info.fields.isNotEmpty) {
      sb.writeln("cat > \"\$UBOT_DIR/.env\" << 'MANTAENV'");
      for (final f in info.fields) {
        sb.writeln('${f.key}=${escVal(f.ctrl.text.trim())}');
      }
      sb.writeln('MANTAENV');
    } else {
      sb.writeln('touch "\$UBOT_DIR/.env"');
    }

    sb.writeln('echo "  .env: ${info.fields.length} variabel"');
    sb.writeln('_ok "dotenv"');
    sb.writeln('');

    if (info.isPython && info.hasExpiry) {
      sb.writeln(r'''_step "noexp"
echo "=== Disable Expiry System ==="
cd "$UBOT_DIR"
MAIN_PY=$(find . -name "__main__.py" -not -path "*/venv/*" 2>/dev/null | head -1)
if [ -n "$MAIN_PY" ] && grep -q "expiredUserbots" "$MAIN_PY" 2>/dev/null; then
  sed -i 's/await asyncio.gather(loadPlugins(), installPeer(), expiredUserbots())/await asyncio.gather(loadPlugins(), installPeer())/' "$MAIN_PY" 2>/dev/null \
    || sed -i 's/, expiredUserbots()//' "$MAIN_PY" 2>/dev/null || true
  echo "  ✓ expiredUserbots() dinonaktifkan"
else
  echo "  ✓ tidak ada expiry ditemukan"
fi
_ok "noexp"
''');
    }

    sb.writeln('_step "start"');
    sb.writeln('echo "=== Starting Userbot ==="');
    sb.writeln('cd "\$UBOT_DIR"');
    sb.writeln('screen -S ubot -X quit 2>/dev/null || true');
    sb.writeln('pkill -f "PyroUbot" 2>/dev/null || true');
    sb.writeln('pkill -f "ubot_start" 2>/dev/null || true');
    sb.writeln('sleep 1');
    sb.writeln('');

    sb.writeln("cat > /root/ubot_start.sh << 'UBSTARTEOF'");
    sb.writeln('#!/bin/bash');
    sb.writeln('cd /root/ubot');
    if (info.isPython) sb.writeln('source /root/ubot/venv/bin/activate');
    sb.writeln('while true; do');
    sb.writeln('  $entrypoint >> /root/ubot.log 2>&1');
    sb.writeln('  echo "[UBOT] Process exited, restarting in 5s..."');
    sb.writeln('  sleep 5');
    sb.writeln('done');
    sb.writeln('UBSTARTEOF');
    sb.writeln('chmod +x /root/ubot_start.sh');
    sb.writeln('');

    sb.writeln(
      r'''if command -v systemctl &>/dev/null && [ -d /etc/systemd/system ]; then
  cat > /etc/systemd/system/ubot.service << SVCSEOF
[Unit]
Description=Userbot
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
ExecStart=/bin/bash /root/ubot_start.sh
Restart=always
RestartSec=5
StartLimitBurst=0

[Install]
WantedBy=multi-user.target
SVCSEOF
  systemctl daemon-reload
  systemctl enable ubot
  systemctl restart ubot
  sleep 3
  if systemctl is-active --quiet ubot; then
    echo "  ✓ Userbot berjalan via systemd"
    echo "  journalctl -u ubot -f"
  else
    echo "  ⚠ systemd gagal, fallback nohup..."
    nohup bash /root/ubot_start.sh >> /root/ubot.log 2>&1 &
    disown
    sleep 2
    echo "  ✓ Userbot berjalan via nohup"
  fi
else
  nohup bash /root/ubot_start.sh >> /root/ubot.log 2>&1 &
  disown
  sleep 2
  echo "  ✓ Userbot berjalan via nohup"
  echo "  tail -f /root/ubot.log"
fi
_ok "start"

echo ""
echo "UBOT_INSTALL_COMPLETE"
rm -f /tmp/_ubs.b64 /tmp/_ubz.b64 /tmp/_ubs.sh /tmp/_ub.zip
''',
    );

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.025), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          ),
          child: switch (_phase) {
            2 => _buildTerminal(key: const ValueKey('t')),
            1 => _buildForm(key: const ValueKey('f')),
            _ => _buildUpload(key: const ValueKey('u')),
          },
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
      onPressed: () {
        if (_phase == 1)
          setState(() => _phase = 0);
        else if (_phase == 2 && (_finished || !_running)) {
          setState(() {
            _phase = 1;
            _sshCleanup();
          });
        } else {
          Navigator.maybePop(context);
        }
      },
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _glowIcon(Icons.smart_toy_outlined, _purple, size: 17),
        const SizedBox(width: 9),
        const Text(
          'Ubot Installer',
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
      if (_logs.isNotEmpty)
        _iconBtn(Icons.content_copy_rounded, 'Salin log', _copyLogs),
      if (_phase == 2 && _finished)
        _iconBtn(
          Icons.tune_rounded,
          'Edit config',
          () => setState(() {
            _phase = 1;
            _sshCleanup();
          }),
        ),
      const SizedBox(width: 4),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _border),
    ),
  );

  Widget _buildUpload({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _banner(),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _loadingZip ? null : _pickZip,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _zipError != null
                      ? _red.withOpacity(0.5)
                      : _purple.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: _purple.withOpacity(0.06), blurRadius: 24),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_purple.withOpacity(0.85), _blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _loadingZip
                        ? const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.upload_file_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingZip
                        ? 'Membaca & menganalisa ZIP…'
                        : 'Upload ZIP Repo Userbot',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Pilih file .zip repo userbot kamu\nSupport Python (PyroGram, Telethon, dll) & Node.js',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textSub,
                      fontSize: 12.5,
                      height: 1.65,
                    ),
                  ),
                  if (_zipError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _redDim,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _zipError!,
                        style: const TextStyle(color: _red, fontSize: 12.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _howItWorks(),
        ],
      ),
    );
  }

  Widget _banner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border2),
      boxShadow: [
        BoxShadow(
          color: _purple.withOpacity(0.05),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple.withOpacity(0.9), _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANTA Ubot Auto-Installer',
                style: TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Upload ZIP → Auto-detect config → Isi form → Install VPS\n'
                'Berjalan via systemd (auto-restart) atau nohup',
                style: TextStyle(color: _textSub, fontSize: 12, height: 1.65),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _howItWorks() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card2,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CARA KERJA',
          style: TextStyle(
            color: _textMute,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in [
          (
            _purple,
            Icons.upload_file_rounded,
            '1  Upload ZIP',
            'Pilih .zip repo userbot dari storage kamu',
          ),
          (
            _cyan,
            Icons.auto_fix_high_rounded,
            '2  Auto-detect',
            'Baca config.py / sample.env → buat form kolom otomatis',
          ),
          (
            _blue,
            Icons.edit_note_rounded,
            '3  Isi Config',
            'Masukkan IP VPS, SSH password, API ID, Bot Token, dll',
          ),
          (
            _green,
            Icons.rocket_launch_rounded,
            '4  Install & Run',
            'Upload ZIP → install deps → tulis .env → jalankan via systemd/nohup',
          ),
        ]) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _glowIcon(item.$2, item.$1, size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$4,
                      style: const TextStyle(
                        color: _textSub,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );

  Widget _buildForm({Key? key}) {
    final info = _zip!;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _zipInfoCard(info),
            const SizedBox(height: 22),

            _section(Icons.dns_outlined, 'Koneksi VPS'),
            const SizedBox(height: 14),
            _lbl('IP Address VPS'),
            _fld(
              _ctrlIp,
              '123.45.67.89',
              icon: Icons.router_outlined,
              kb: TextInputType.url,
              val: _req('IP VPS wajib diisi'),
            ),
            const SizedBox(height: 11),
            _lbl('Username SSH'),
            _fld(_ctrlUser, 'root', icon: Icons.person_outline_rounded),
            const SizedBox(height: 11),
            _lbl('Password SSH'),
            _pFld(
              _ctrlPass,
              'password root VPS',
              _showPass,
              () => setState(() => _showPass = !_showPass),
              val: _req('Password SSH wajib diisi'),
            ),
            const SizedBox(height: 28),

            if (info.fields.isNotEmpty) ...[
              Row(
                children: [
                  _section(Icons.tune_rounded, 'Konfigurasi Bot'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showSensitive = !_showSensitive),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _card2,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _border2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showSensitive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 12,
                            color: _textSub,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _showSensitive ? 'Sembunyikan' : 'Tampilkan token',
                            style: const TextStyle(
                              color: _textSub,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _detectedBadge(info),
              const SizedBox(height: 14),

              ...info.fields.map((f) {
                final isObscure = f.isSensitive && !_showSensitive;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _lbl(f.label)),
                          if (f.isRequired)
                            _pill(
                              'wajib',
                              _red.withOpacity(0.12),
                              _red.withOpacity(0.8),
                            )
                          else
                            _pill('opsional', _card2, _textSub),
                          if (f.isSensitive) ...[
                            const SizedBox(width: 5),
                            _pill('sensitive', _purpleDim, _purple),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      isObscure
                          ? _pFld(
                              f.ctrl,
                              f.defaultVal.isEmpty
                                  ? 'isi ${f.label}'
                                  : f.defaultVal,
                              false,
                              () {},
                              val: f.isRequired
                                  ? _req('${f.label} wajib diisi')
                                  : null,
                            )
                          : _fld(
                              f.ctrl,
                              f.defaultVal.isEmpty
                                  ? 'isi ${f.label}'
                                  : f.defaultVal,
                              val: f.isRequired
                                  ? _req('${f.label} wajib diisi')
                                  : null,
                            ),
                    ],
                  ),
                );
              }),
            ] else ...[
              _noConfigNote(),
            ],

            const SizedBox(height: 22),
            _warningCard(),
            const SizedBox(height: 18),

            GestureDetector(
              onTap: () {
                if (_formKey.currentState?.validate() ?? false) _startInstall();
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_purple.withOpacity(0.9), _blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Mulai Install Sekarang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zipInfoCard(_ZipInfo info) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _green.withOpacity(0.3)),
      boxShadow: [BoxShadow(color: _green.withOpacity(0.04), blurRadius: 14)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _glowIcon(Icons.check_circle_outline_rounded, _green, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                info.fileName,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _phase = 0),
              child: const Text(
                'Ganti ZIP',
                style: TextStyle(color: _cyan, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            if (info.isPython) _pill('🐍 Python', _purpleDim, _purple),
            if (info.isNode) _pill('⬡ Node.js', _greenDim, _green),
            if (info.hasFFmpeg)
              _pill('FFmpeg', _amber.withOpacity(0.12), _amber),
            if (info.hasExpiry)
              _pill('⏱ Expiry→OFF', _redDim, _red.withOpacity(0.8)),
            _pill('▶ ${info.entrypoint}', _cyanDim, _cyan),
            if (info.pythonModuleSpecs.isNotEmpty)
              _pill(
                'Py auto ${info.pythonModuleSpecs.length}',
                _greenDim,
                _green,
              ),
            if (info.envTemplateName.isNotEmpty)
              _pill('📄 ${info.envTemplateName}', _card2, _textSub),
            _pill('${info.fields.length} config fields', _blueDim, _blue),
            if (info.rootDir.isNotEmpty)
              _pill('📁 ${info.rootDir}/', _card2, _textSub),
          ],
        ),
      ],
    ),
  );

  Widget _detectedBadge(_ZipInfo info) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: _purple.withOpacity(0.06),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _purple.withOpacity(0.18)),
    ),
    child: Row(
      children: [
        Icon(
          Icons.auto_fix_high_rounded,
          color: _purple.withOpacity(0.9),
          size: 14,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${info.fields.length} variabel terdeteksi dari ZIP · '
            'Kolom "wajib" harus diisi sebelum install',
            style: const TextStyle(
              color: _textSub,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _noConfigNote() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _amber.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _amber.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: _amber.withOpacity(0.8),
          size: 15,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Tidak ditemukan file config (config.py / sample.env / .env.example).\n'
            'ZIP tetap akan diupload dan diinstall.',
            style: TextStyle(color: _textSub, fontSize: 12, height: 1.55),
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
            'Proses install 2–10 menit tergantung VPS & koneksi. Jangan tutup aplikasi.',
            style: TextStyle(color: _amber, fontSize: 12, height: 1.6),
          ),
        ),
      ],
    ),
  );

  Widget _buildTerminal({Key? key}) => Column(
    key: key,
    children: [
      _terminalHeader(),
      Expanded(child: _terminalLog()),
      _terminalAction(),
    ],
  );

  Widget _terminalHeader() {
    final total = _steps.length;
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              _statusBadge(),
              const Spacer(),
              Text(
                '$_doneCount / $total steps',
                style: const TextStyle(
                  color: _textSub,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_statusMsg.isNotEmpty) ...[
            const SizedBox(height: 5),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: _running ? _pulseAnim.value : 1.0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _statusMsg,
                    style: const TextStyle(color: _textSub, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressAnim.value,
                backgroundColor: _card2,
                valueColor: AlwaysStoppedAnimation(
                  _errored ? _red : (_finished ? _green : _purple),
                ),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (_, i) {
                final s = _steps[i];
                Color c;
                IconData ic;
                switch (s.status) {
                  case _SS.done:
                    c = _green;
                    ic = Icons.check_circle_rounded;
                    break;
                  case _SS.running:
                    c = _purple;
                    ic = s.icon;
                    break;
                  case _SS.failed:
                    c = _red;
                    ic = Icons.error_rounded;
                    break;
                  default:
                    c = _textMute;
                    ic = s.icon;
                }
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.withOpacity(s.status == _SS.idle ? 0.04 : 0.13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: c.withOpacity(s.status == _SS.idle ? 0.07 : 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      s.status == _SS.running
                          ? SizedBox(
                              width: 9,
                              height: 9,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: c,
                              ),
                            )
                          : Icon(ic, size: 10, color: c),
                      const SizedBox(width: 5),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: c,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalLog() => Container(
    color: _bg,
    child: ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: _logs.length,
      itemBuilder: (_, i) {
        final e = _logs[i];
        final Color c = switch (e.type) {
          _LT.ok => _lcOk,
          _LT.err => _lcErr,
          _LT.info => _lcInfo,
          _LT.sys => _lcSys,
          _LT.step => _lcStep,
          _LT.norm => _lcNorm,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 1.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ts(e.ts),
                style: const TextStyle(
                  color: _textMute,
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  e.msg,
                  style: TextStyle(
                    color: c,
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _terminalAction() {
    if (_finished && !_errored) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _greenDim,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _green.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: _green,
                    size: 16,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Userbot berhasil berjalan!\njournalctl -u ubot -f  |  tail -f /root/ubot.log',
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            _actionBtn(
              'Install Ubot Lain',
              Icons.add_rounded,
              () => setState(() {
                _phase = 0;
                _zip?.fields.forEach((f) => f.dispose());
                _zip = null;
                _logs.clear();
              }),
              color: _purple,
            ),
          ],
        ),
      );
    }
    if (_finished && _errored) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _actionBtn(
                'Kembali ke Form',
                Icons.arrow_back_rounded,
                () => setState(() {
                  _phase = 1;
                  _sshCleanup();
                }),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 2,
              child: _actionBtn('Coba Ulang', Icons.refresh_rounded, () {
                _sshCleanup();
                _startInstall();
              }, color: _red),
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _sshCleanup();
                  setState(() {
                    _running = false;
                    _finished = true;
                    _errored = true;
                  });
                  _addLog('✗ Dibatalkan oleh pengguna.', _LT.err);
                },
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
              'Sedang menginstall…  ($_doneCount/${_steps.length} langkah)',
              Icons.hourglass_top_rounded,
              null,
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _statusBadge() {
    if (_running && !_finished)
      return _badge('Installing', _purple, spin: true);
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
    final c = color ?? _purple;
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
                      : [_purple.withOpacity(0.85), _blue],
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

  Widget _section(IconData icon, String title) => Row(
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

  Widget _pill(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label, style: TextStyle(color: fg, fontSize: 10.5)),
  );

  String? Function(String?) _req(String msg) =>
      (v) => v!.trim().isEmpty ? msg : null;

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
      borderSide: BorderSide(color: _purple.withOpacity(0.7), width: 1.5),
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

  Widget _fld(
    TextEditingController c,
    String hint, {
    IconData? icon,
    TextInputType? kb,
    String? Function(String?)? val,
  }) => TextFormField(
    controller: c,
    style: const TextStyle(color: _text, fontSize: 13.5),
    keyboardType: kb,
    decoration: _deco(hint).copyWith(
      prefixIcon: icon != null ? Icon(icon, color: _textMute, size: 16) : null,
    ),
    validator: val,
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

  String _ts(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  void _copyLogs() {
    Clipboard.setData(
      ClipboardData(
        text: _logs.map((e) => '[${_ts(e.ts)}] ${e.msg}').join('\n'),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Log disalin ✓', style: TextStyle(fontSize: 13)),
        backgroundColor: _card2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
