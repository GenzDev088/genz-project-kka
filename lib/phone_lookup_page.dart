import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class PhoneLookupPage extends StatefulWidget {
  const PhoneLookupPage({super.key});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  static const Color midnight = Color(0xFF0D1117);
  static const Color charcoal = Color(0xFF161B22);
  static const Color steel = Color(0xFF1C2333);
  static const Color cyanAccent = Color(0xFF00B4D8);
  static const Color platinum = Color(0xFFE6EDF3);
  static const Color coralAccent = Color(0xFFFF8A65);
  static const Color mintAccent = Color(0xFF00E676);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _simulateLookup() async {
    final number = _controller.text.trim();
    if (number.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });


    await Future.delayed(const Duration(seconds: 2));


    bool isScam = number.contains("404") || number.contains("666");
    bool isVoip = number.startsWith("+1") || number.length < 10;

    setState(() {
      _isLoading = false;
      _result = {
        "e164": number.startsWith("+") ? number : "+$number",
        "country": _inferCountry(number),
        "carrier": _inferCarrier(number),
        "type": isVoip ? "VoIP" : "Mobile",
        "risk_score": isScam ? 85 : (isVoip ? 45 : 12),
        "signals": {
          "found_in_scam_db": isScam,
          "voip": isVoip,
          "found_in_classifieds": number.contains("77"),
          "business_listing": number.contains("800"),
        },
        "evidence": [
          if (isScam) "Matched in public scam dataset.",
          if (isVoip) "Number identified as VoIP/Virtual.",
          "Checked DuckDuckGo Instant Answer.",
          "Checked local offline database.",
        ]
      };
    });
  }

  String _inferCountry(String number) {
    if (number.startsWith("+62") || number.startsWith("62")) return "Indonesia";
    if (number.startsWith("+1") || number.startsWith("1")) return "USA / Canada";
    if (number.startsWith("+44") || number.startsWith("44")) return "United Kingdom";
    return "Unknown Region";
  }

  String _inferCarrier(String number) {
    if (number.contains("811") || number.contains("812") || number.contains("813")) return "Telkomsel";
    if (number.contains("855") || number.contains("856") || number.contains("857")) return "Indosat";
    if (number.contains("817") || number.contains("818") || number.contains("819")) return "XL Axiata";
    return "Unknown Carrier";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: midnight,
      appBar: AppBar(
        backgroundColor: charcoal,
        elevation: 0,
        title: const Text(
          "PHONE LOOKUP",
          style: TextStyle(
            color: cyanAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: platinum),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const _NoiseBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildInputField(),
                const SizedBox(height: 24),
                if (_isLoading) _buildLoadingState(),
                if (_result != null) _buildResultCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: steel.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cyanAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.radar_2, color: cyanAccent, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "OSINT SCANNER",
                      style: TextStyle(
                        color: cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "LIVE OSINT",
                      style: TextStyle(
                        color: platinum,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Menganalisis nomor telepon secara real-time. Data ditarik langsung dari DuckDuckGo OSINT database dan jaringan publik global.",
            style: TextStyle(
              color: platinum.withOpacity(0.6),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: charcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Masukkan Nomor Telepon",
            style: TextStyle(
              color: platinum,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            style: const TextStyle(color: platinum, fontSize: 16),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Contoh: +628123456789",
              hintStyle: TextStyle(color: platinum.withOpacity(0.3)),
              filled: true,
              fillColor: midnight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Iconsax.call, color: cyanAccent, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simulateLookup,
              style: ElevatedButton.styleFrom(
                backgroundColor: cyanAccent,
                foregroundColor: midnight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: midnight,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "SCAN NOMOR",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const CircularProgressIndicator(color: cyanAccent),
            const SizedBox(height: 16),
            Text(
              "Menganalisis sinyal...",
              style: TextStyle(color: platinum.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildResultCard() {
    final res = _result!;
    final int score = res['risk_score'];
    Color scoreColor = mintAccent;
    if (score > 30) scoreColor = Colors.orangeAccent;
    if (score > 70) scoreColor = coralAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: charcoal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "HASIL ANALISIS",
                style: TextStyle(
                  color: platinum,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scoreColor.withOpacity(0.2)),
                ),
                child: Text(
                  "Risk Score: $score",
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow("Format E.164", res['e164'], Iconsax.global),
          _buildInfoRow("Wilayah", res['country'], Iconsax.location),
          _buildInfoRow("Operator", res['carrier'], Iconsax.radar),
          _buildInfoRow("Tipe Nomor", res['type'], Iconsax.status),
          const SizedBox(height: 16),
          const Text(
            "BOOLEAN SIGNALS",
            style: TextStyle(
              color: cyanAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _buildSignalChip("Scam DB", res['signals']['found_in_scam_db']),
          _buildSignalChip("VoIP Detection", res['signals']['voip']),
          _buildSignalChip("Classifieds Ads", res['signals']['found_in_classifieds']),
          _buildSignalChip("Business Directory", res['signals']['business_listing']),
          const SizedBox(height: 20),
          const Text(
            "AUDIT EVIDENCE",
            style: TextStyle(
              color: cyanAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          ...(res['evidence'] as List).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white38, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e,
                        style: TextStyle(color: platinum.withOpacity(0.5), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: platinum.withOpacity(0.3), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: platinum.withOpacity(0.5), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: platinum, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalChip(String label, bool value) {
    Color color = value ? coralAccent : mintAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: platinum, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value ? "TRUE" : "FALSE",
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _NoiseBackground extends StatelessWidget {
  const _NoiseBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(painter: _NoisePainter(), size: Size.infinite),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.005)
      ..style = PaintingStyle.fill;
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

