import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DomainOsintPage extends StatefulWidget {
  const DomainOsintPage({super.key});

  @override
  State<DomainOsintPage> createState() => _DomainOsintPageState();
}

class _DomainOsintPageState extends State<DomainOsintPage>
    with TickerProviderStateMixin {
  final TextEditingController _domainController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _dnsData;
  List<Map<String, dynamic>> _certRecords = [];
  List<String> _uniqueSubdomains = [];
  String? _errorMessage;
  String? _scannedDomain;

  late final AnimationController _scanAnim;
  late final AnimationController _resultAnim;
  late final Animation<double> _scan;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  static const Color bg = Color(0xFF0F141B);
  static const Color surface = Color(0xFF161D25);
  static const Color surfaceHigh = Color(0xFF1D2732);
  static const Color surfaceSoft = Color(0xFF243240);
  static const Color primary = Color(0xFFC35D6C);
  static const Color primaryDeep = Color(0xFFA84F5C);
  static const Color primarySoft = Color(0xFFE6B0B8);
  static const Color accent = Color(0xFFD0B27D);
  static const Color info = Color(0xFF8EB7C7);
  static const Color success = Color(0xFF9FBEA7);
  static const Color ivory = Color(0xFFF3EEE7);
  static const Color muted = Color(0xFF97A3AF);
  static const Color divider = Color(0xFF283341);

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scan = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanAnim, curve: Curves.easeInOut));
    _fadeIn = CurvedAnimation(parent: _resultAnim, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _domainController.dispose();
    _scanAnim.dispose();
    _resultAnim.dispose();
    super.dispose();
  }

  Future<void> _checkDomain() async {
    final domain = _domainController.text.trim().toLowerCase();
    if (domain.isEmpty) {
      _setError('Masukkan nama domain terlebih dahulu.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dnsData = null;
      _certRecords = [];
      _uniqueSubdomains = [];
      _scannedDomain = domain;
    });
    _scanAnim.repeat();

    try {
      final results = await Future.wait([
        _fetchDns(domain),
        _fetchSubdomains(domain),
      ]);

      final dns = results[0] as Map<String, dynamic>?;
      final certs = results[1] as List<Map<String, dynamic>>;

      final subSet = <String>{};
      for (final c in certs) {
        final nm = c['name_value']?.toString() ?? '';
        final cn = c['common_name']?.toString() ?? '';
        for (final source in [nm, cn]) {
          if (source.isEmpty) {
            continue;
          }
          for (final part in source.split('\n')) {
            final value = part.trim();
            if (value.isNotEmpty) {
              subSet.add(value);
            }
          }
        }
      }
      final subList = subSet.toList()..sort();

      if (dns != null || certs.isNotEmpty) {
        setState(() {
          _dnsData = dns;
          _certRecords = certs;
          _uniqueSubdomains = subList;
        });
        _resultAnim.forward(from: 0);
      } else {
        _setError('Tidak ada data ditemukan untuk domain ini.');
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

  Future<Map<String, dynamic>?> _fetchDns(String domain) async {
    try {
      final url = Uri.parse(
        'https://api.siputzx.my.id/api/tools/dns?domain=$domain',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        return j['status'] == true ? j['data'] as Map<String, dynamic>? : null;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchSubdomains(String domain) async {
    try {
      final url = Uri.parse(
        'https://rynekoo-api.hf.space/tools/finder/subdomain-finder?domain=$domain',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j['success'] == true && j['result'] is List) {
          return (j['result'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  void _setError(String msg) {
    setState(() {
      _errorMessage = msg;
      _dnsData = null;
      _certRecords = [];
      _uniqueSubdomains = [];
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
        duration: const Duration(milliseconds: 1400),
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
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  '$label disalin',
                  style: const TextStyle(
                    color: ivory,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [surfaceHigh, surface]),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.travel_explore,
                    color: primarySoft,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DOMAIN OSINT',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 2.5,
                          color: ivory,
                        ),
                      ),
                      Text(
                        'Subdomain, DNS, dan SSL certificate scanner',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          color: muted,
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
                    'Lookup',
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  children: [
                    TextField(
                      controller: _domainController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(
                        color: ivory,
                        fontSize: 17,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                      decoration: InputDecoration(
                        hintText: 'contoh: example.com',
                        hintStyle: TextStyle(
                          color: muted.withOpacity(0.5),
                          fontFamily: 'Rajdhani',
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: bg.withOpacity(0.55),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 17,
                        ),
                        prefixIcon: Icon(
                          Icons.dns_rounded,
                          color: muted.withOpacity(0.9),
                          size: 20,
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
                      onSubmitted: (_) => _checkDomain(),
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AnimatedBuilder(
                            animation: _scan,
                            builder: (_, __) => CustomPaint(
                              painter: _ScanPainter(
                                progress: _scan.value,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _checkDomain,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  color: primarySoft,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'MEMINDAI...',
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
                                Icons.radar_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'SCAN DOMAIN',
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
              size: 19,
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
    String? badge,
  }) {
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
          Container(
            padding: const EdgeInsets.fromLTRB(18, 13, 18, 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.09), surface],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
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
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accentColor.withOpacity(0.15)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String? value, {
    bool copy = false,
    Color? valueColor,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: copy ? () => _copy(value, label) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  color: muted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ivory,
                  height: 1.35,
                ),
              ),
            ),
            if (copy)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.copy_all_rounded,
                  size: 13,
                  color: (valueColor ?? primary).withOpacity(0.45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() {
    return Container(height: 1, color: divider, margin: EdgeInsets.zero);
  }

  Widget _buildDnsSection() {
    if (_dnsData == null) {
      return const SizedBox.shrink();
    }
    final dns = _dnsData!;
    final records = dns['records'] as Map<String, dynamic>? ?? {};

    final rows = <Widget>[
      _buildRow('Domain', dns['unicodeDomain']?.toString(), copy: true),
      _rowDivider(),
      _buildRow('Punycode', dns['punycodeDomain']?.toString(), copy: true),
    ];

    final nsAnswers = records['ns']?['response']?['answer'] as List? ?? [];
    if (nsAnswers.isNotEmpty) {
      rows.add(_rowDivider());
      rows.add(_sectionLabel('Name Servers'));
      for (final ns in nsAnswers) {
        final target = ns['record']?['target']?.toString();
        if (target != null && target.isNotEmpty) {
          rows.add(_buildRow('NS', target, copy: true));
        }
      }
    }

    final aAnswers = records['a']?['response']?['answer'] as List? ?? [];
    if (aAnswers.isNotEmpty) {
      rows.add(_rowDivider());
      rows.add(_sectionLabel('A Records'));
      for (final a in aAnswers) {
        final data = a['record']?['data']?.toString();
        if (data != null && data.isNotEmpty) {
          rows.add(_buildRow('IP', data, copy: true, valueColor: info));
        }
      }
    }

    final soaAnswers = records['soa']?['response']?['answer'] as List? ?? [];
    if (soaAnswers.isNotEmpty) {
      final soa = soaAnswers.first['record'];
      rows.add(_rowDivider());
      rows.add(_sectionLabel('SOA Record'));
      rows.add(_buildRow('Primary NS', soa?['host']?.toString(), copy: true));
      rows.add(_buildRow('Admin', soa?['admin']?.toString(), copy: true));
      rows.add(_buildRow('Serial', soa?['serial']?.toString()));
      rows.add(_buildRow('Refresh', soa?['refresh']?.toString()));
      rows.add(_buildRow('Retry', soa?['retry']?.toString()));
      rows.add(_buildRow('Expire', soa?['expire']?.toString()));
      rows.add(_buildRow('Min TTL', soa?['minimum']?.toString()));
    }

    return _buildSection(
      title: 'DNS INFORMATION',
      icon: Icons.dns_rounded,
      accentColor: primary,
      children: rows,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: muted,
        ),
      ),
    );
  }

  Widget _buildSubdomainSection() {
    if (_uniqueSubdomains.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildSection(
      title: 'SUBDOMAINS',
      icon: Icons.language_rounded,
      accentColor: accent,
      badge: '${_uniqueSubdomains.length} found',
      children: [
        const SizedBox(height: 4),
        ..._uniqueSubdomains.map(_buildSubItem),
      ],
    );
  }

  Widget _buildSubItem(String sub) {
    return InkWell(
      onTap: () => _copy(sub, sub),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ivory,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.copy_all_rounded,
              size: 13,
              color: accent.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertSection() {
    if (_certRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final bySerial = <String, Map<String, dynamic>>{};
    for (final c in _certRecords) {
      final serial = c['serial_number']?.toString() ?? c['id'].toString();
      bySerial.putIfAbsent(serial, () => c);
    }
    final unique = bySerial.values.toList();

    return _buildSection(
      title: 'SSL CERTIFICATES',
      icon: Icons.verified_rounded,
      accentColor: info,
      badge: '${unique.length} certs',
      children: [const SizedBox(height: 4), ...unique.map(_buildCertCard)],
    );
  }

  Widget _buildCertCard(Map<String, dynamic> cert) {
    final cn = cert['common_name']?.toString() ?? '';
    final issuer = cert['issuer_name']?.toString() ?? '';
    final notBefore = _fmtDate(cert['not_before']?.toString());
    final notAfter = _fmtDate(cert['not_after']?.toString());
    final serial = cert['serial_number']?.toString() ?? '';
    final timestamp = _fmtDate(cert['entry_timestamp']?.toString());

    final expiry = cert['not_after']?.toString();
    var isExpired = false;
    if (expiry != null) {
      try {
        isExpired = DateTime.parse(expiry).isBefore(DateTime.now());
      } catch (_) {}
    }

    final statusColor = isExpired ? primarySoft : success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cn,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ivory,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.15)),
                ),
                child: Text(
                  isExpired ? 'EXPIRED' : 'VALID',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: divider),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 12, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _shortIssuer(issuer),
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    color: muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 12, color: muted),
              const SizedBox(width: 6),
              Text(
                '$notBefore  ->  $notAfter',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  color: statusColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          if (serial.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _copy(serial, 'Serial'),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, size: 12, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      serial,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 11,
                        color: muted,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: muted.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Logged: $timestamp',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 11,
                    color: muted.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _shortIssuer(String issuer) {
    final cnMatch = RegExp(r'CN=([^,]+)').firstMatch(issuer);
    final oMatch = RegExp(r'O=([^,]+)').firstMatch(issuer);
    if (cnMatch != null && oMatch != null) {
      return '${oMatch.group(1)} - ${cnMatch.group(1)}';
    }
    return issuer;
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    try {
      final dt = DateTime.parse(raw);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  Widget _buildSummaryBanner() {
    final subCount = _uniqueSubdomains.length;
    final certCount = (() {
      final seen = <String, bool>{};
      for (final c in _certRecords) {
        seen[c['serial_number']?.toString() ?? c['id'].toString()] = true;
      }
      return seen.length;
    })();
    final hasDns = _dnsData != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [surfaceHigh, surface, Color(0xFF131A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  border: Border.all(color: primary.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, color: accent, size: 13),
                    SizedBox(width: 6),
                    Text(
                      'SCAN SELESAI',
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
                Icons.language_rounded,
                size: 14,
                color: muted.withOpacity(0.6),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _scannedDomain ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    color: muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip(
                icon: Icons.language_rounded,
                label: 'Subdomains',
                value: subCount.toString(),
                color: accent,
              ),
              const SizedBox(width: 10),
              _statChip(
                icon: Icons.verified_rounded,
                label: 'Sertifikat',
                value: certCount.toString(),
                color: info,
              ),
              const SizedBox(width: 10),
              _statChip(
                icon: Icons.dns_rounded,
                label: 'DNS',
                value: hasDns ? 'OK' : '-',
                color: primarySoft,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 10,
                color: muted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResult =
        _dnsData != null ||
        _certRecords.isNotEmpty ||
        _uniqueSubdomains.isNotEmpty;

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
                size: 15,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.radar_rounded, color: primarySoft, size: 16),
            SizedBox(width: 8),
            Text(
              'DOMAIN OSINT',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w800,
                color: ivory,
                fontSize: 15,
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildInputCard()),
                ),
                if (_errorMessage != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildError()),
                  ),
                if (hasResult)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Column(
                            children: [
                              _buildSummaryBanner(),
                              _buildDnsSection(),
                              _buildSubdomainSection(),
                              _buildCertSection(),
                              const SizedBox(height: 28),
                            ],
                          ),
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
