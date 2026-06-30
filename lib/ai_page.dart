import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AIPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const AIPage({
    Key? key,
    required this.sessionKey,
    required this.username,
    required this.role,
  }) : super(key: key);

  @override
  _AIPageState createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late Box _aiBox;


  static const Color midnight = Color(0xFF0D1117);
  static const Color charcoal = Color(0xFF161B22);
  static const Color cyanAccent = Color(0xFF00B4D8);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonGreen = Color(0xFF00F5D4);
  static const Color platinum = Color(0xFFE6EDF3);


  String get _systemPrompt =>
      "Kamu adalah MANTA AI, asisten digital canggih yang dikembangkan oleh OtaStoree. "
      "Kamu berbicara dalam Bahasa Indonesia dengan gaya futuristik dan profesional. "
      "Pengguna saat ini: ${widget.username} (role: ${widget.role}). "
      "Berikut SELURUH fitur aplikasi MANTA yang kamu kuasai:\n\n"

      "== TABUNGANKU (Manajemen Keuangan Lokal) ==\n"
      "Catat pemasukan & pengeluaran, target tabungan, budget planner, "
      "tantangan menabung (challenge), belanja (shopping list), "
      "kesehatan keuangan (health score), teman menabung (friends), "
      "statistik & grafik, pengaturan akun, data disimpan lokal via Hive.\n\n"

      "== HOSTING TOOLS ==\n"
      "Cpanel Manager (kelola hosting cPanel), "
      "Colong File & Sender (ambil file dari server), "
      "Buat VPS DigitalOcean (otomatis buat droplet), "
      "Install Panel Pterodactyl (auto setup game panel), "
      "Install Flutter di VPS, "
      "Build Flutter via Github (CI/CD APK builder), "
      "Install Ubot (auto deploy userbot Telegram).\n\n"

      "== GAME & AI ==\n"
      "Pacman, Ular Klasik (Snake), MANTA GAMES Retro Hub "
      "(Bomberman, Cyber Quest, Game 2048, Neon Runner, Space Invaders, Tetris, Tic Tac Toe), "
      "AI Assistant (MANTA AI — kamu sendiri).\n\n"

      "== DDOS & SERVER ==\n"
      "Attack Panel (stress test multi-method), "
      "Manage Server (kelola VPS list), "
      "Auto Detect Games (deteksi port game server otomatis).\n\n"

      "== NETWORK ==\n"
      "Spam NGL (anonymous message spam), "
      "WiFi Brute-Force (WPA/WPA2 cracking), "
      "Manta Mailer (kirim email massal/custom), "
      "WiFi Internal (deauth attack lokal), "
      "WiFi External (remote WiFi management, KINGZ/OWNER only), "
      "Spam Pair (pasangan spam call/SMS).\n\n"

      "== OSINT (Open Source Intelligence) ==\n"
      "NIK Detail (cek data kependudukan via NIK), "
      "Domain OSINT (whois, DNS, subdomain scanner), "
      "Phone Lookup (cari info nomor telepon), "
      "Email OSINT (cek kebocoran data email).\n\n"

      "== DOWNLOADER ==\n"
      "TikTok Downloader (download video tanpa watermark via ssstik.io), "
      "Instagram Downloader (download reels/video/foto via kol.id API dengan polling).\n\n"

      "== MANTARAT (Remote Administration) ==\n"
      "RAT Control — kontrol perangkat target: screenshot, screen record, kamera depan/belakang, "
      "ambil kontak, SMS, call logs, lokasi GPS, info perangkat, browser history, "
      "galeri, notifikasi, WhatsApp/Telegram messages, Google accounts, OTP, "
      "kirim SMS, getarkan, flash on/off/blink, ganti wallpaper, voice message, "
      "screen message, lock screen, set PIN, launch/uninstall app, overlay, ransomware, wipe. "
      "Auto Modifikasi Aplikasi (Manta Builder — inject payload ke APK).\n\n"

      "== GENERATOR ==\n"
      "iPhone Quote Creator (buat gambar quote gaya iPhone), "
      "Fake Story (generator fake Instagram story), "
      "Fake Tweet (generator fake tweet/X post), "
      "To URL (upload file jadi URL publik), "
      "QR Generator (buat QR code custom).\n\n"

      "== ANIME & ENTERTAINMENT ==\n"
      "Anime Streaming (nonton anime), "
      "Finance Manager (pencatatan keuangan alternatif), "
      "Spotify Music Player (streaming musik via Spotify embed).\n\n"

      "== DASHBOARD ==\n"
      "Chat Room (komunikasi real-time antar user MANTA), "
      "Telegram Report System (laporan & monitoring via bot Telegram), "
      "Custom Payload (buat payload kustom untuk testing), "
      "Bug Report/Bug Group (lapor bug & lihat daftar bug), "
      "Al-Quran (baca Al-Quran lengkap dengan terjemahan), "
      "Weather (ramalan cuaca berdasarkan lokasi), "
      "Jadwal Sholat (waktu sholat otomatis berdasarkan kota), "
      "Tes Function (debug & test fitur), "
      "Thanks To Page (kredit developer), "
      "Update Module (update aplikasi OTA).\n\n"

      "== NAVIGASI & AKUN ==\n"
      "Profile Page (foto profil, info akun), "
      "Change Password (ganti password akun), "
      "Send Notification (kirim push notif ke semua user, KINGZ only), "
      "Admin Page (management user & system, KINGZ/OWNER only), "
      "Landing Page (halaman awal sebelum login), "
      "Login Page (autentikasi user).\n\n"

      "Jawab dengan ringkas, informatif, dan selalu sapa pengguna dengan namanya. "
      "Kalau user tanya tentang fitur, jelaskan cara akses dan kegunaannya. "
      "Jangan pernah mengaku sebagai ChatGPT, Gemini, atau AI lain — kamu adalah MANTA AI.";

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _aiBox = await Hive.openBox('manta_ai_box');
    final storedMessages = _aiBox.get('chat_history');
    if (storedMessages != null) {
      setState(() {
        _messages.addAll(
          List<Map<String, dynamic>>.from(
            (storedMessages as List).map((e) => Map<String, dynamic>.from(e)),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _saveChat() {
    _aiBox.put('chat_history', _messages);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;

    final userMessage = prompt.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();
    _saveChat();

    try {

      final List<Map<String, String>> chatHistory = [
        {'role': 'system', 'content': _systemPrompt},
        ..._messages.map(
          (m) => {
            'role': m['role'].toString(),
            'content': m['content'].toString(),
          },
        ),
      ];

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.deepai.org/hacking_is_a_serious_crime'),
      );

      request.fields['chat_style'] = 'chat';
      request.fields['chatHistory'] = jsonEncode(chatHistory);
      request.fields['model'] = 'standard';
      request.fields['hacker_is_stinky'] = 'very_stinky';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final aiResponse = response.body;
        setState(() {
          _messages.add({'role': 'assistant', 'content': aiResponse});
        });
        _saveChat();
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Sistem mengalami gangguan teknis (Code: ${response.statusCode}).',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Koneksi ke Core AI terputus.',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: midnight,
      body: Stack(
        children: [

          Positioned(
            top: -100,
            right: -50,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cyanAccent.withOpacity(0.05),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 2.seconds)
                    .scale(begin: const Offset(0.5, 0.5)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _messages.isEmpty && !_isLoading
                      ? _buildEmptyState()
                      : _buildChatList(),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F1923),
            const Color(0xFF111D2B),
            const Color(0xFF0D1520),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1A2A3A), width: 1.5),
        ),
      ),
      child: Stack(
        children: [

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    cyanAccent,
                    neonPurple,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            bottom: 12,
            left: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cyanAccent.withOpacity(0.8),
                    neonPurple.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: Opacity(
              opacity: 0.06,
              child: SizedBox(
                width: 60,
                height: 40,
                child: CustomPaint(painter: _DotGridPainter()),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            child: Row(
              children: [

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E2C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cyanAccent.withOpacity(0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cyanAccent.withOpacity(0.08),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: cyanAccent,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [platinum, cyanAccent],
                            ).createShader(bounds),
                            child: const Text(
                              'MANTA AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cyanAccent.withOpacity(0.4),
                                    cyanAccent.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [

                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: neonGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: neonGreen.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              color: neonGreen.withOpacity(0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 1,
                            height: 10,
                            color: Colors.white12,
                          ),
                          Text(
                            'v2.0',
                            style: TextStyle(
                              color: platinum.withOpacity(0.35),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_messages.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: neonPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: neonPurple.withOpacity(0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          size: 10,
                          color: neonPurple.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_messages.length}',
                          style: const TextStyle(
                            color: neonPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                IconButton(
                  icon: Icon(
                    Icons.delete_sweep_rounded,
                    color: platinum.withOpacity(0.3),
                    size: 22,
                  ),
                  onPressed: () {
                    if (_messages.isEmpty) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF141E2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          'Hapus Riwayat',
                          style: TextStyle(
                            color: platinum,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        content: const Text(
                          'Semua riwayat percakapan akan dihapus permanen.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() => _messages.clear());
                              _saveChat();
                            },
                            child: const Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: charcoal,
                  shape: BoxShape.circle,
                  border: Border.all(color: cyanAccent.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: cyanAccent.withOpacity(0.05),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 60,
                  color: cyanAccent,
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 3.seconds, color: neonPurple.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text(
            'Halo, ${widget.username}!',
            style: const TextStyle(
              color: platinum,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'MANTA AI siap membantu.',
            style: TextStyle(
              color: cyanAccent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketik apapun untuk memulai percakapan.',
            style: TextStyle(color: platinum.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.1),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildLoadingIndicator().animate().fadeIn();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(msg['content'], isUser)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: isUser ? 0.1 : -0.1, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? cyanAccent.withOpacity(0.1) : charcoal,
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(24),
            bottomLeft: isUser
                ? const Radius.circular(24)
                : const Radius.circular(4),
          ),
          border: Border.all(
            color: isUser ? cyanAccent.withOpacity(0.3) : Colors.white10,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                  size: 14,
                  color: isUser ? cyanAccent : neonPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'YOU' : 'MANTA AI',
                  style: TextStyle(
                    color: isUser ? cyanAccent : neonPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: platinum,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: charcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: neonPurple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Memproses data...',
              style: TextStyle(color: platinum.withOpacity(0.5), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: midnight,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: platinum, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan Anda...',
                  hintStyle: TextStyle(color: platinum.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cyanAccent, neonPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: cyanAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const spacing = 8.0;
    const radius = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
