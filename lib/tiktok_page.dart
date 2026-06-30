import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;

class TiktokDownloaderPage extends StatefulWidget {
  const TiktokDownloaderPage({super.key});

  @override
  State<TiktokDownloaderPage> createState() => _TiktokDownloaderPageState();
}

class _TiktokDownloaderPageState extends State<TiktokDownloaderPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isSharing = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  late AnimationController _bgAnimationController;


  static const Color bgDark = Color(0xFF090D14);
  static const Color surfaceSolid = Color(0xFF111827);
  static const Color surfaceCard = Color(0xFF1A2438);
  static const Color borderSoft = Color(0xFF212B3D);
  static const Color accentCyan = Color(0xFF0EA5E9);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color textMain = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _downloadTiktok() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar("URL TikTok tidak boleh kosong.", isError: true);
      return;
    }

    if (!url.contains("tiktok.com")) {
      _showSnackBar("Link TikTok tidak valid.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    try {
      final downloadUrl = Uri.parse('https://ssstik.io/abc?url=dl');

      final response = await http.post(
        downloadUrl,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'hx-current-url': 'https://ssstik.io/en',
          'hx-request': 'true',
          'hx-target': 'target',
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36',
        },
        body: {'id': url, 'locale': 'en', 'tt': 'UVh4Z3Z4'},
      );

      if (response.statusCode == 200) {
        final html = response.body;


        final regExp = RegExp(r'href="(https://tikcdn\.io/ssstik/[^"]+)"');
        final match = regExp.firstMatch(html);

        if (match != null && match.group(1) != null) {
          final dlLink = match.group(1)!;


          final titleRegExp = RegExp(r'<p class="maintext">([^<]+)</p>');
          final titleMatch = titleRegExp.firstMatch(html);
          final title = titleMatch?.group(1) ?? "Manta Video Content";

          setState(() {
            _videoData = {
              'title': title,
              'videoUrl': dlLink,
              'thumbnail':
                  "", // ssstik html might have it but let's keep it simple
              'creator': "TikTok User",
            };
          });

          _initializeVideoPlayer();
        } else {
          _showSnackBar(
            "Gagal mendapatkan link download. Coba lagi nanti.",
            isError: true,
          );
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Koneksi gagal: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeVideoPlayer() {
    if (_videoData?['videoUrl'] != null && _videoData!['videoUrl'].isNotEmpty) {
      final videoUrl = _videoData!['videoUrl'];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
              showControls: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: accentCyan,
                handleColor: accentIndigo,
                backgroundColor: Colors.white.withOpacity(0.1),
                bufferedColor: Colors.white.withOpacity(0.2),
              ),
            );
          });
        });
    }
  }

  Future<void> _shareVideo() async {
    if (_videoData == null) return;
    setState(() => _isSharing = true);

    try {
      String? videoUrl = _videoData!['videoUrl'];
      if (videoUrl == null || videoUrl.isEmpty) {
        _showSnackBar("Link video rusak", isError: true);
        return;
      }

      final response = await http.get(Uri.parse(videoUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/manta_tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Downloaded via Manta X2 - Creator: ${_videoData!['creator']}');
    } catch (e) {
      _showSnackBar("Gagal membagikan: $e", isError: true);
    } finally {
      setState(() => _isSharing = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.redAccent : accentIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HexagonGridPainter(
                    progress: _bgAnimationController.value,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_motion_rounded,
                            color: accentCyan,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TIKTOK SAVER",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: textMain,
                              ),
                            ),
                            Text(
                              "HIGH-SPEED DOWNLOADER",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: accentCyan,
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
                          "PASTE TARGET URL",
                          style: TextStyle(
                            color: accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: accentCyan,
                          decoration: InputDecoration(
                            hintText: "https://vt.tiktok.com/...",
                            hintStyle: const TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.link_rounded,
                              color: textMuted,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: bgDark.withOpacity(0.5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: accentCyan,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _isLoading ? null : _downloadTiktok,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [accentCyan, accentIndigo],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentCyan.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "DOWNLOAD & SIMPAN",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                  if (_videoData != null) ...[
                    const SizedBox(height: 24),
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bgDark,
                                  image:
                                      _videoData!['thumbnail'] != null &&
                                          _videoData!['thumbnail'].isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            _videoData!['thumbnail'],
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  border: Border.all(
                                    color: accentCyan,
                                    width: 1.5,
                                  ),
                                ),
                                child:
                                    _videoData!['thumbnail'] == null ||
                                        _videoData!['thumbnail'].isEmpty
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: accentCyan,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _videoData!['creator'],
                                      style: const TextStyle(
                                        color: textMain,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Text(
                                      "Media Stream Ready",
                                      style: TextStyle(
                                        color: accentCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_chewieController != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderSoft),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: Chewie(controller: _chewieController!),
                                ),
                              ),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: accentCyan,
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSharing ? null : _shareVideo,
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: accentCyan,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.share_rounded, size: 18),
                              label: const Text(
                                "EXPORT & SHARE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bgDark,
                                foregroundColor: textMain,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: borderSoft),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _HexagonGridPainter extends CustomPainter {
  final double progress;
  _HexagonGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2B4B).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    double hexSize = 40.0;
    double width = hexSize * math.sqrt(3);
    double height = hexSize * 2;

    for (double y = -height; y < size.height + height; y += height * 0.75) {
      double xOffset = ((y / (height * 0.75)).round() % 2 == 0) ? 0 : width / 2;
      for (double x = -width; x < size.width + width; x += width) {
        _drawHexagon(canvas, Offset(x + xOffset, y), hexSize, paint);


        if ((x + y) % 3 == 0) {
          canvas.drawCircle(Offset(x + xOffset, y), 2.0, dotPaint);
        }
      }
    }


    final orbPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(
      Offset(
        size.width * 0.5 + math.sin(progress * math.pi * 2) * 50,
        size.height * 0.5 + math.cos(progress * math.pi * 2) * 50,
      ),
      150,
      orbPaint,
    );
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    var path = Path();
    for (var i = 0; i < 6; i++) {
      double angle = (math.pi / 180) * (60 * i + 30);
      double x = center.dx + size * math.cos(angle);
      double y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
