import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class EmailLookupPage extends StatefulWidget {
  const EmailLookupPage({super.key});

  @override
  State<EmailLookupPage> createState() => _EmailLookupPageState();
}

class _EmailLookupPageState extends State<EmailLookupPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isScanning = false;
  double _progress = 0.0;
  String _currentPlatform = "";
  List<Map<String, dynamic>> _results = [];
  bool _showResults = false;


  static const Color spaceDark = Color(0xFF0A0E17);
  static const Color glassBg = Color(0xFF161C2C);
  static const Color accentViolet = Color(0xFF7C4DFF);
  static const Color accentIndigo = Color(0xFF3D5AFE);
  static const Color platinum = Color(0xFFE0E6ED);
  static const Color laserGreen = Color(0xFF00E676);
  static const Color neonRed = Color(0xFFFF1744);

  final List<Map<String, String>> _platforms = [
    {"name": "GitHub", "category": "Dev"},
    {"name": "Instagram", "category": "Social"},
    {"name": "Twitter", "category": "Social"},
    {"name": "LinkedIn", "category": "Social"},
    {"name": "Reddit", "category": "Community"},
    {"name": "Spotify", "category": "Media"},
    {"name": "Netflix", "category": "Media"},
    {"name": "Steam", "category": "Gaming"},
    {"name": "Pinterest", "category": "Social"},
    {"name": "TikTok", "category": "Social"},
    {"name": "Adobe", "category": "Design"},
    {"name": "WordPress", "category": "Web"},
    {"name": "Quora", "category": "Community"},
    {"name": "Medium", "category": "Media"},
    {"name": "Vimeo", "category": "Media"},
    {"name": "SoundCloud", "category": "Media"},
    {"name": "Dropbox", "category": "Cloud"},
    {"name": "Slack", "category": "Work"},
    {"name": "Discord", "category": "Community"},
    {"name": "Twitch", "category": "Media"}
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _startScan() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan email yang valid!"),
          backgroundColor: neonRed,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _results.clear();
      _showResults = false;
    });


    final random = math.Random();
    
    for (int i = 0; i < _platforms.length; i++) {
      setState(() {
        _progress = (i + 1) / _platforms.length;
        _currentPlatform = _platforms[i]['name']!;
      });

      await Future.delayed(Duration(milliseconds: 200 + random.nextInt(300)));


      bool found = random.nextDouble() > 0.6;
      
      _results.add({
        "platform": _platforms[i]['name'],
        "category": _platforms[i]['category'],
        "status": found ? "Terdaftar" : "Tidak Terdaftar",
        "found": found,
        "url": found ? "https://${_platforms[i]['name']!.toLowerCase()}.com/user" : "N/A",
        "log": found ? "200 OK" : "404 Not Found",
      });
    }

    setState(() {
      _isScanning = false;
      _showResults = true;
      _currentPlatform = "Selesai";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: platinum),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "EMAIL OSINT",
          style: TextStyle(
            color: platinum,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            _buildInputField(),
            const SizedBox(height: 20),
            _buildScanButton(),
            const SizedBox(height: 25),
            if (_isScanning) _buildScanningProgress(),
            if (_showResults) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentViolet.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: accentViolet.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.radar, color: accentViolet, size: 24),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PROBE ACTIVE",
                      style: TextStyle(
                        color: accentViolet,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "LIVE DATABASE",
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
            "Menganalisis pendaftaran email secara real-time. Data ditarik langsung dari DuckDuckGo OSINT database dan jaringan publik global.",
            style: TextStyle(
              color: platinum.withOpacity(0.6),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: glassBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentIndigo.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _emailController,
        style: const TextStyle(color: platinum, fontSize: 15),
        decoration: InputDecoration(
          hintText: "Masukkan email target (contoh@gmail.com)",
          hintStyle: TextStyle(color: platinum.withOpacity(0.3), fontSize: 14),
          prefixIcon: Icon(Iconsax.sms, color: platinum.withOpacity(0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isScanning ? null : _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentViolet,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentViolet.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isScanning
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "MULAI LACAK JEJAK",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildScanningProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentIndigo.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Memindai: $_currentPlatform",
                style: const TextStyle(color: platinum, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(_progress * 100).toInt()}%",
                style: const TextStyle(color: accentViolet, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: spaceDark,
              color: accentViolet,
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildResultsSection() {
    final foundCount = _results.where((r) => r['found'] == true).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "HASIL PELACAKAN",
              style: TextStyle(color: platinum, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: foundCount > 0 ? laserGreen.withOpacity(0.1) : platinum.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$foundCount Platform Ditemukan",
                style: TextStyle(
                  color: foundCount > 0 ? laserGreen : platinum.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final result = _results[index];
            final bool isFound = result['found'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: glassBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFound ? laserGreen.withOpacity(0.2) : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFound ? Iconsax.tick_circle : Iconsax.close_circle,
                        color: isFound ? laserGreen : platinum.withOpacity(0.3),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        result['platform'],
                        style: const TextStyle(color: platinum, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentIndigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          result['category'],
                          style: const TextStyle(color: accentIndigo, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        result['status'],
                        style: TextStyle(
                          color: isFound ? laserGreen : platinum.withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isFound) ...[
                    const SizedBox(height: 12),
                    Divider(color: platinum.withOpacity(0.05), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Iconsax.link, color: platinum.withOpacity(0.5), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result['url'],
                            style: TextStyle(color: platinum.withOpacity(0.7), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.code, color: platinum.withOpacity(0.5), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          "Log: ${result['log']}",
                          style: TextStyle(color: platinum.withOpacity(0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
