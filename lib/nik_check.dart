import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NikCheckerPage extends StatefulWidget {
  const NikCheckerPage({super.key});

  @override
  State<NikCheckerPage> createState() => _NikCheckerPageState();
}

class _NikCheckerPageState extends State<NikCheckerPage>
    with TickerProviderStateMixin {
  final TextEditingController _nikController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;
  String? _responseTime;

  late final AnimationController _resultAnim;
  late final AnimationController _scanAnim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _scanLine;

  static const Color bg = Color(0xFF0F141B);
  static const Color surface = Color(0xFF161D25);
  static const Color surfaceHigh = Color(0xFF1D2732);
  static const Color surfaceSoft = Color(0xFF243240);
  static const Color primary = Color(0xFFC35D6C);
  static const Color primaryDeep = Color(0xFFA84F5C);
  static const Color primarySoft = Color(0xFFE6B0B8);
  static const Color accent = Color(0xFFD0B27D);
  static const Color ivory = Color(0xFFF3EEE7);
  static const Color muted = Color(0xFF97A3AF);
  static const Color divider = Color(0xFF283341);

  @override
  void initState() {
    super.initState();

    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeIn = CurvedAnimation(parent: _resultAnim, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultAnim, curve: Curves.easeOutCubic));
    _scanLine = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nikController.dispose();
    _resultAnim.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  Future<void> _checkNik() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) {
      _setError('NIK tidak boleh kosong.');
      return;
    }
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      _setError('Format NIK tidak valid (harus 16 digit angka).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });
    _scanAnim.repeat();

    try {
      final url = Uri.parse(
        'https://rynekoo-api.hf.space/tools/nikparser?nik=$nik',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['result'] != null) {
          setState(() {
            _result = decoded['result'] as Map<String, dynamic>;
            _responseTime = decoded['responseTime']?.toString();
            _errorMessage = null;
          });
          _resultAnim.forward(from: 0);
        } else {
          _setError('Data tidak ditemukan untuk NIK tersebut.');
        }
      } else {
        _setError('Server error: ${response.statusCode}');
      }
    } catch (_) {
      _setError('Koneksi gagal. Periksa jaringan Anda.');
    } finally {
      _scanAnim.stop();
      _scanAnim.reset();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String msg) {
    setState(() {
      _errorMessage = msg;
      _result = null;
      _isLoading = false;
    });
    _scanAnim.stop();
    _scanAnim.reset();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: primarySoft,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$label disalin',
                  style: const TextStyle(
                    color: ivory,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [surfaceHigh, surface],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: primarySoft,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERIFIKASI NIK',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 2.3,
                          color: ivory,
                        ),
                      ),
                      Text(
                        'Nomor Induk Kependudukan 16 digit',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11.5,
                          color: muted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceSoft.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: const Text(
                    'Secure',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1,
                      color: primarySoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Stack(
                  children: [
                    TextField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      style: const TextStyle(
                        color: ivory,
                        fontSize: 22,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        hintText: '0000000000000000',
                        hintStyle: TextStyle(
                          color: muted.withOpacity(0.4),
                          fontFamily: 'Rajdhani',
                          fontSize: 22,
                          letterSpacing: 4,
                        ),
                        filled: true,
                        fillColor: bg.withOpacity(0.55),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        prefixIcon: Icon(
                          Icons.credit_card_rounded,
                          color: muted.withOpacity(0.9),
                          size: 22,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primary.withOpacity(0.85),
                            width: 1.4,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onSubmitted: (_) => _checkNik(),
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AnimatedBuilder(
                            animation: _scanLine,
                            builder: (_, __) => CustomPaint(
                              painter: _ScanPainter(
                                progress: _scanLine.value,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _isLoading ? null : _checkNik,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? const LinearGradient(
                              colors: [surfaceSoft, surfaceHigh],
                            )
                          : const LinearGradient(
                              colors: [primaryDeep, primary],
                            ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _isLoading
                            ? Colors.white.withOpacity(0.05)
                            : primary.withOpacity(0.22),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: primarySoft,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'MEMINDAI NIK...',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                  color: muted,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'VERIFIKASI NIK',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: primarySoft,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: ivory,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final r = _result!;

    final String nik = r['nik']?.toString() ?? _nikController.text.trim();
    final String kelamin = r['kelamin']?.toString() ?? '';
    final String lahir = r['lahir']?.toString() ?? '';
    final String lahirFull = r['lahir_lengkap']?.toString() ?? '';

    final Map provinsi = r['provinsi'] as Map? ?? {};
    final Map kotakab = r['kotakab'] as Map? ?? {};
    final Map kecamatan = r['kecamatan'] as Map? ?? {};
    final Map tambahan = r['tambahan'] as Map? ?? {};

    final String kodeWilayah = r['kode_wilayah']?.toString() ?? '';
    final String nomorUrut = r['nomor_urut']?.toString() ?? '';

    final String provinsiNama = provinsi['nama']?.toString() ?? '';
    final String provinsiKode = provinsi['kode']?.toString() ?? '';
    final String kotaJenis = kotakab['jenis']?.toString() ?? '';
    final String kotaNama = kotakab['nama']?.toString() ?? '';
    final String kotaKode = kotakab['kode']?.toString() ?? '';
    final String kecNama = kecamatan['nama']?.toString() ?? '';

    return Column(
      children: [
        _buildHeroCard(
          nik: nik,
          kelamin: kelamin,
          lahir: lahirFull.isNotEmpty ? lahirFull : lahir,
          usia: tambahan['usia']?.toString() ?? '',
          kategori: tambahan['kategori_usia']?.toString() ?? '',
        ),
        const SizedBox(height: 14),
        _buildSection(
          title: 'IDENTITAS',
          icon: Icons.badge_outlined,
          accentColor: primary,
          rows: [
            _RowItem('NIK', nik, copy: true),
            _RowItem('Jenis Kelamin', kelamin),
            _RowItem('Tanggal Lahir', lahirFull.isNotEmpty ? lahirFull : lahir),
            _RowItem('Usia', tambahan['usia']?.toString()),
            _RowItem('Kategori Usia', tambahan['kategori_usia']?.toString()),
            _RowItem('Ulang Tahun', tambahan['ultah']?.toString()),
          ],
        ),
        _buildSection(
          title: 'DOMISILI',
          icon: Icons.location_city_rounded,
          accentColor: accent,
          rows: [
            _RowItem('Provinsi', '$provinsiNama ($provinsiKode)'),
            _RowItem(
              'Kota/Kabupaten',
              '$kotaJenis $kotaNama ($kotaKode)'.trim(),
            ),
            _RowItem('Kecamatan', kecNama.isNotEmpty ? kecNama : null),
            _RowItem(
              'Kode Wilayah',
              kodeWilayah.isNotEmpty ? kodeWilayah : null,
            ),
            _RowItem('Nomor Urut', nomorUrut.isNotEmpty ? nomorUrut : null),
          ],
        ),
        _buildSection(
          title: 'INFO TAMBAHAN',
          icon: Icons.auto_awesome_rounded,
          accentColor: primarySoft,
          rows: [
            _RowItem('Zodiak', tambahan['zodiak']?.toString()),
            _RowItem('Pasaran', tambahan['pasaran']?.toString()),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: muted.withOpacity(0.6),
              ),
              const SizedBox(width: 5),
              Text(
                _responseTime != null
                    ? 'Diproses dalam $_responseTime'
                    : 'Tampilan data ringkas dan rapi',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 11.5,
                  color: muted.withOpacity(0.65),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeroCard({
    required String nik,
    required String kelamin,
    required String lahir,
    required String usia,
    required String kategori,
  }) {
    final isFemale = kelamin.contains('PEREMPUAN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [surfaceHigh, surface, Color(0xFF131A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, color: accent, size: 13),
                    SizedBox(width: 6),
                    Text(
                      'TERVERIFIKASI',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                isFemale ? Icons.face_4_rounded : Icons.face_6_rounded,
                color: muted,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                kelamin,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primarySoft,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatNik(nik),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 4.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (lahir.isNotEmpty) _heroChip(Icons.cake_rounded, lahir),
              if (usia.isNotEmpty)
                _heroChip(Icons.hourglass_bottom_rounded, usia),
              if (kategori.isNotEmpty)
                _heroChip(Icons.person_rounded, kategori),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primarySoft.withOpacity(0.9)),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ivory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<_RowItem> rows,
  }) {
    final visible = rows.where((r) {
      final value = r.value?.trim() ?? '';
      return value.isNotEmpty && value != ' ()' && value != '()';
    }).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.12)),
                  ),
                  child: Icon(icon, color: accentColor, size: 15),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 2,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
            child: Column(
              children: [
                for (int i = 0; i < visible.length; i++) ...[
                  _buildRow(visible[i], accentColor),
                  if (i < visible.length - 1)
                    Container(height: 1, color: divider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_RowItem row, Color accentColor) {
    return InkWell(
      onTap: row.copy ? () => _copy(row.value!, row.label) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(
                row.label,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              child: Text(
                row.value!,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ivory,
                  height: 1.3,
                ),
              ),
            ),
            if (row.copy)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 1),
                child: Icon(
                  Icons.copy_all_rounded,
                  size: 14,
                  color: accentColor.withOpacity(0.45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNik(String nik) {
    if (nik.length != 16) {
      return nik;
    }
    return '${nik.substring(0, 4)} ${nik.substring(4, 8)} '
        '${nik.substring(8, 12)} ${nik.substring(12, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: ivory,
                size: 16,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.shield_rounded, color: primarySoft, size: 16),
            SizedBox(width: 8),
            Text(
              'NIK CHECKER',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w800,
                color: ivory,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.02),
                    Colors.transparent,
                    Colors.black.withOpacity(0.12),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  sliver: SliverToBoxAdapter(child: _buildInputCard()),
                ),
                if (_errorMessage != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    sliver: SliverToBoxAdapter(child: _buildError()),
                  ),
                if (_result != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: _buildResults(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem {
  final String label;
  final String? value;
  final bool copy;

  const _RowItem(this.label, this.value, {this.copy = false});
}

class _ScanPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ScanPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.35),
          color.withOpacity(0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, y - 18, size.width, 36));
    canvas.drawRect(Rect.fromLTWH(0, y - 18, size.width, 36), paint);
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final accentPaint = Paint()
      ..color = const Color(0xFFC35D6C).withOpacity(0.03)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.18),
      Offset(size.width * 0.88, size.height * 0.18),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.82),
      Offset(size.width * 0.92, size.height * 0.82),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_BgPainter oldDelegate) => false;
}
