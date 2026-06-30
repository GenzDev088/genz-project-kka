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

class InstagramDownloaderPage extends StatefulWidget {
  const InstagramDownloaderPage({super.key});

  @override
  State<InstagramDownloaderPage> createState() =>
      _InstagramDownloaderPageState();
}

class _InstagramDownloaderPageState extends State<InstagramDownloaderPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _mediaData;
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
      duration: const Duration(seconds: 8),
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

  Future<void> _downloadInstagram() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar("URL Instagram tidak boleh kosong.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    try {


      final headers = {
        'accept': 'application/json, text/plain, */*',
        'content-type': 'application/x-www-form-urlencoded',
        'origin': 'https://kol.id',
        'referer': 'https://kol.id/download-video/instagram',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',
        'x-requested-with': 'XMLHttpRequest',
      };

      final submitResponse = await http.post(
        Uri.parse('https://kol.id/api/v2/downloader/instagram'),
        headers: headers,
        body: {'url': url},
      );

      if (submitResponse.statusCode == 200 ||
          submitResponse.statusCode == 201) {
        final submitData = jsonDecode(submitResponse.body);
        final requestId =
            submitData['data']?['request_id'] ?? submitData['request_id'];

        if (requestId == null) {
          _showSnackBar(
            "Gagal menginisialisasi download (Request ID null).",
            isError: true,
          );
          return;
        }


        int attempts = 0;
        bool isCompleted = false;
        Map<String, dynamic>? finalData;

        while (attempts < 15 && !isCompleted) {
          await Future.delayed(const Duration(seconds: 2));
          attempts++;

          final statusResponse = await http.get(
            Uri.parse('https://kol.id/api/v2/downloader/status/$requestId'),
            headers: headers,
          );

          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            if (statusData['data']?['status'] == 'completed') {
              finalData = statusData['data'];
              isCompleted = true;
            } else if (statusData['data']?['status'] == 'failed') {
              _showSnackBar("Download gagal di server KOL.ID.", isError: true);
              return;
            }
          }
        }

        if (isCompleted && finalData != null) {
          String? dlLink = finalData['video_url'];


          if (dlLink == null &&
              finalData['slides'] != null &&
              (finalData['slides'] as List).isNotEmpty) {

            final slides = finalData['slides'] as List;
            final videoSlide = slides.firstWhere(
              (s) => s['type'] == 'video',
              orElse: () => slides[0],
            );
            dlLink = videoSlide['url'];
          }

          if (dlLink != null) {
            setState(() {
              _mediaData = {
                'url': dlLink,
                'thumbnail': finalData!['thumbnail'] ?? "",
                'type':
                    (finalData!['type'] == 'slide' &&
                            dlLink!.contains('.mp4')) ||
                        finalData!['video_url'] != null
                    ? 'video'
                    : 'image',
              };
            });

            if (_mediaData!['type'] == 'video') {
              _initializeVideoPlayer(videoUrl: dlLink!);
            }
          } else {
            _showSnackBar(
              "Media tidak ditemukan dalam response.",
              isError: true,
            );
          }
        } else {
          _showSnackBar(
            "Proses download terlalu lama. Coba lagi.",
            isError: true,
          );
        }
      } else {

        _showSnackBar(
          "Server KOL.ID Error: ${submitResponse.statusCode}",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        "Koneksi gagal. Coba ganti koneksi atau link.",
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeVideoPlayer({required String videoUrl}) {
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

  Future<void> _shareContent() async {
    if (_mediaData == null) return;

    _showSnackBar("Sedang menyiapkan konten...");

    try {
      final mediaUrl = _mediaData!['url'];
      final response = await http.get(Uri.parse(mediaUrl));
      final tempDir = await getTemporaryDirectory();
      final extension = _mediaData!['type'] == 'video' ? 'mp4' : 'jpg';
      final file = File(
        '${tempDir.path}/manta_ig_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Downloaded via Manta X2');
    } catch (e) {
      _showSnackBar("Gagal membagikan konten.", isError: true);
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
                  painter: _CyberPulsePainter(
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
                            Icons.camera_rounded,
                            color: accentCyan,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "INSTA SAVER",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: textMain,
                              ),
                            ),
                            Text(
                              "MANTA INSTAGRAM DOWNLOADER",
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
                          "MASUKKAN URL INSTAGRAM",
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
                            hintText: "https://www.instagram.com/...",
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
                          onTap: _isLoading ? null : _downloadInstagram,
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


                  if (_mediaData != null) ...[
                    const SizedBox(height: 24),
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.greenAccent,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "MEDIA TERDETEKSI",
                                style: TextStyle(
                                  color: textMain,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (_mediaData!['type'] == 'video')
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
                                    child: Chewie(
                                      controller: _chewieController!,
                                    ),
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
                              )
                          else if (_mediaData!['type'] == 'image')
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: bgDark,
                                border: Border.all(color: borderSoft),
                                image:
                                    _mediaData!['thumbnail'] != null &&
                                        _mediaData!['thumbnail'].isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          _mediaData!['thumbnail'],
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  _mediaData!['thumbnail'] == null ||
                                      _mediaData!['thumbnail'].isEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.image_rounded,
                                        color: accentCyan,
                                        size: 48,
                                      ),
                                    )
                                  : null,
                            ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _shareContent,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text(
                                "BAGIKAN KONTEN",
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


class _CyberPulsePainter extends CustomPainter {
  final double progress;
  _CyberPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = const Color(0xFF1E2B4B).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final paintPulse = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;


    double spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }


    double pulseY = (progress * size.height);
    canvas.drawLine(Offset(0, pulseY), Offset(size.width, pulseY), paintPulse);
    canvas.drawLine(
      Offset(0, (pulseY + 100) % size.height),
      Offset(size.width, (pulseY + 100) % size.height),
      paintPulse,
    );


    final orbPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      120,
      orbPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      150,
      orbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
