import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String expiredDate;
  final String role;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.expiredDate,
    required this.role,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _profileImagePath;
  bool _obscurePassword = true;

  static const Color primaryCyan = Color(0xFF00B4D8);
  static const Color darkBg = Color(0xFF0D1117);
  static const Color surfaceCard = Color(0xFF161B22);
  static const Color accentPurple = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final localPath = result.files.single.path!;


        _showToast('Mencoba mengunggah gambar ke server...', primaryCyan);

        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/api/upload'),
          );
          request.files.add(
            await http.MultipartFile.fromPath('image', localPath),
          );

          var response = await request.send();
          if (response.statusCode == 200) {
            var responseData = await response.stream.bytesToString();
            var json = jsonDecode(responseData);
            String remoteUrl = json['url'];

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profile_image_path', remoteUrl);

            setState(() {
              _profileImagePath = remoteUrl;
            });

            if (mounted) {
              _showToast(
                'Foto profil berhasil diunggah ke server!',
                Colors.greenAccent,
              );
            }
          } else {
            if (mounted)
              _showToast(
                'Gagal mengunggah: ${response.statusCode}',
                Colors.redAccent,
              );

          }
        } catch (e) {
          if (mounted) _showToast('Kesalahan koneksi: $e', Colors.redAccent);
        }
      }
    } catch (e) {
      if (mounted) _showToast('Error picking image: $e', Colors.redAccent);
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [

          Positioned.fill(
            child: CustomPaint(
              painter: _ProfileBgPainter(primaryCyan.withOpacity(0.03)),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              SliverAppBar(
                expandedHeight: 280,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [primaryCyan.withOpacity(0.15), darkBg],
                          ),
                        ),
                      ),


                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryCyan,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryCyan.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: ClipOval(
                                      child: _profileImagePath != null
                                          ? (_profileImagePath!.startsWith(
                                                  'http',
                                                )
                                                ? Image.network(
                                                    _profileImagePath!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          Icons.error_outline,
                                                          color: Colors.red,
                                                        ),
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color:
                                                                      primaryCyan,
                                                                ),
                                                          );
                                                        },
                                                  )
                                                : Image.file(
                                                    File(_profileImagePath!),
                                                    fit: BoxFit.cover,
                                                  ))
                                          : Image.asset(
                                              'assets/images/logo.jpg',
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: primaryCyan,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: darkBg,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: darkBg,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().scale(
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            ),
                            const SizedBox(height: 15),
                            Text(
                                  widget.username.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                    shadows: [
                                      Shadow(
                                        color: primaryCyan,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideY(begin: 0.5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('INFO AKUNMU', primaryCyan),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      label: 'USERNAME',
                      value: widget.username,
                      icon: Icons.alternate_email_rounded,
                      accent: primaryCyan,
                      copyable: true,
                    ),
                    _buildInfoTile(
                      label: 'PASSWORD',
                      value: widget.password,
                      icon: Icons.vpn_key_outlined,
                      accent: primaryCyan,
                      isPassword: true,
                      copyable: true,
                    ),
                    _buildInfoTile(
                      label: 'SESSION ID',
                      value: widget.sessionKey,
                      icon: Icons.hub_outlined,
                      accent: primaryCyan,
                      copyable: true,
                    ),

                    const SizedBox(height: 30),
                    _buildSectionHeader('INFO TAMBAHAN', accentPurple),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      label: 'WAKTU EXPIRED (WIB)',
                      value: widget.expiredDate,
                      icon: Icons.timer_outlined,
                      accent: Colors.orangeAccent,
                    ),
                    _buildInfoTile(
                      label: 'ROLE',
                      value: widget.role.toUpperCase(),
                      icon: Icons.verified_user_rounded,
                      accent: Colors.greenAccent,
                    ),

                    const SizedBox(height: 40),


                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF161B22),
                                title: const Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  "Apakah Anda yakin ingin keluar?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      "Batal",
                                      style: TextStyle(color: Colors.white38),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "Keluar",
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'LOGOUT',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.5), blurRadius: 5),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.2);
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    bool isPassword = false,
    bool copyable = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPassword && _obscurePassword ? '••••••••••••' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          if (copyable)
            IconButton(
              icon: const Icon(
                Icons.copy_all_rounded,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                _showToast('$label copied!', accent);
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

class _ProfileBgPainter extends CustomPainter {
  final Color color;
  _ProfileBgPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (int i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }


    final hexPaint = Paint()
      ..color = color.withOpacity(0.02)
      ..style = PaintingStyle.stroke;

    final random = Random(42);
    for (int i = 0; i < 10; i++) {
      double cx = random.nextDouble() * size.width;
      double cy = random.nextDouble() * size.height;
      double r = 50 + random.nextDouble() * 100;

      final path = Path();
      for (int j = 0; j < 6; j++) {
        double angle = (pi / 3) * j;
        double x = cx + r * cos(angle);
        double y = cy + r * sin(angle);
        if (j == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, hexPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
