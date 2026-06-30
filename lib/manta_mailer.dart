import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;

class MantaMailerPage extends StatefulWidget {
  const MantaMailerPage({Key? key}) : super(key: key);

  @override
  State<MantaMailerPage> createState() => _MantaMailerPageState();
}

class _MantaMailerPageState extends State<MantaMailerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Box? _accountsBox;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: "465",
  );

  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _multiplierController = TextEditingController(
    text: "1",
  );
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _waSubjectController = TextEditingController();
  final TextEditingController _waBodyController = TextEditingController();
  
  String _selectedWaType = "Fix Merah";
  String _selectedWaMethod = "Default";

  List<Map<String, dynamic>> _savedAccounts = [];
  Map<String, dynamic>? _selectedAccount;

  bool _isSending = false;
  List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();


  static const Color bgDark = Color(0xFF0B101A);
  static const Color surfaceSolid = Color(0xFF131B2B);
  static const Color surfaceCard = Color(0xFF1A2438);
  static const Color borderSoft = Color(0xFF283655);
  static const Color textMain = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color accentPrimary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accentSecondary = Color(0xFF6366F1); // Indigo
  static const Color dangerSolid = Color(0xFFF43F5E);
  static const Color logBg = Color(0xFF06090F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initHive();
  }

  Future<void> _initHive() async {
    _accountsBox = await Hive.openBox('manta_mailer_accounts');
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      _savedAccounts = _accountsBox!.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (_savedAccounts.isNotEmpty && _selectedAccount == null) {
        _selectedAccount = _savedAccounts.first;
      }
    });
  }

  void _saveAccount() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _hostController.text.isEmpty) {
      _showSnackBar("⚠️ Lengkapi semua kolom yang tersedia", isError: true);
      return;
    }

    final newAccount = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'host': _hostController.text.trim(),
      'port': int.tryParse(_portController.text.trim()) ?? 465,
    };

    _accountsBox!.add(newAccount);
    _loadAccounts();

    _emailController.clear();
    _passwordController.clear();
    _hostController.clear();
    _portController.text = "465";

    _showSnackBar("Akun berhasil diamankan");
    FocusScope.of(context).unfocus();
  }

  void _deleteAccount(int index) {
    _accountsBox!.deleteAt(index);
    if (_selectedAccount == _savedAccounts[index]) {
      _selectedAccount = null;
    }
    _loadAccounts();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(
        "[${DateTime.now().toIso8601String().substring(11, 19)}] $message",
      );
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendEmail() async {
    if (_selectedAccount == null) {
      _showSnackBar("⚠️ Pilih akun pengirim terlebih dahulu", isError: true);
      return;
    }

    final targets = _toController.text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (targets.isEmpty) {
      _showSnackBar("⚠️ Masukkan minimal satu email penerima", isError: true);
      return;
    }

    setState(() => _isSending = true);
    FocusScope.of(context).unfocus();

    int multiplier = int.tryParse(_multiplierController.text.trim()) ?? 1;
    if (multiplier < 1) multiplier = 1;

    _logs.clear();
    _addLog(
      "Memulai eksekusi: ${targets.length} target x $multiplier pesan...",
    );

    final smtpServer = SmtpServer(
      _selectedAccount!['host'],
      port: _selectedAccount!['port'],
      username: _selectedAccount!['email'],
      password: _selectedAccount!['password'],
      ssl: _selectedAccount!['port'] == 465,
    );

    int successCount = 0;
    int failCount = 0;

    for (String target in targets) {
      if (!mounted) break;

      for (int i = 1; i <= multiplier; i++) {
        if (!mounted) break;

        final message = Message()
          ..from = Address(_selectedAccount!['email'], 'Manta Mailer')
          ..recipients.add(target)
          ..subject = _subjectController.text
          ..html = _bodyController.text;

        try {
          _addLog("📡 Mengirim ke $target [$i/$multiplier]...");
          await send(message, smtpServer);
          _addLog("✅ Sukses: $target [$i/$multiplier]");
          successCount++;
        } catch (e) {
          _addLog(
            "❌ Gagal: $target [$i/$multiplier] | Err: ${e.toString().split('\n').first}",
          );
          failCount++;
        }

        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    _addLog("🏁 Selesai. Total Sukses: $successCount | Gagal: $failCount");
    setState(() => _isSending = false);
  }

  Future<void> _sendUnbanWa() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar("⚠️ Masukkan nomor WhatsApp terlebih dahulu", isError: true);
      return;
    }
    

    final backupTo = _toController.text;
    final backupSub = _subjectController.text;
    final backupBody = _bodyController.text;

    _toController.text = "support@support.whatsapp.com, android_web@support.whatsapp.com, iphone_web@support.whatsapp.com, smb_web@support.whatsapp.com";
    
    String finalSubject = "";
    String finalBody = "";
    
    if (_selectedWaMethod == "Default") {
      if (_selectedWaType == "Fix Merah") {
        finalSubject = "Request for Review of WhatsApp Login Issue";
        finalBody = '''Hello WhatsApp Support Team,
I am currently experiencing an issue while trying to verify my WhatsApp number. During the login/verification process, the following message appears:

"Login not available right now. For security reasons, we can't log you in at the moment."

I believe this number belongs to me and has been used normally. I kindly request that the WhatsApp team review this restriction or issue so I can regain access to my account.
Details:
WhatsApp Number: \$number
Device: Android

I am willing to provide any additional information if needed to verify ownership of the account.

Thank you for your time and assistance.''';
      } else if (_selectedWaType == "Unban Biasa") {
        finalSubject = "Review Request: Banned WhatsApp Account";
        finalBody = '''Hello WhatsApp Support Team,

My WhatsApp account has been suspended/banned unexpectedly. I am not aware of any terms of service violation and I urgently need to use WhatsApp for my daily communication. 

Please review my account and restore my access.

WhatsApp Number: \$number
Device: Android

Thank you.''';
      }
    } else {
      finalSubject = _waSubjectController.text;
      finalBody = _waBodyController.text;
    }

    _subjectController.text = finalSubject;
    _bodyController.text = finalBody.replaceAll(RegExp(r'\$number'), _phoneController.text.trim());
    
    await _sendEmail();
    

    _toController.text = backupTo;
    _subjectController.text = backupSub;
    _bodyController.text = backupBody;
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? dangerSolid : surfaceCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isError ? Colors.transparent : borderSoft),
        ),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: surfaceSolid.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.mail_lock_rounded,
                color: accentPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "SPAM MAIL MANTA",
              style: TextStyle(
                color: textMain,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: textMain),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: textMuted),
            onPressed: _showInstructions,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderSoft, width: 1.5)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: accentPrimary,
              indicatorWeight: 3.0,
              labelColor: accentPrimary,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
              tabs: const [
                Tab(text: "EMAIL"),
                Tab(text: "MENU WA"),
                Tab(text: "DATABASE"),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [

          Positioned.fill(
            child: CustomPaint(painter: _GeometricBackgroundPainter()),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [_buildComposerTab(), _buildUnbanTab(), _buildAccountsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("PENGIRIM EMAIL", Icons.fingerprint_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSoft),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                dropdownColor: surfaceCard,
                icon: const Icon(Icons.unfold_more_rounded, color: textMuted),
                value: _selectedAccount,
                hint: const Text(
                  "Pilih akun pengirim...",
                  style: TextStyle(color: textMuted, fontSize: 14),
                ),
                items: _savedAccounts.map((acc) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: acc,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          color: accentPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          acc['email'],
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccount = val),
              ),
            ),
          ),

          const SizedBox(height: 28),
          _buildSectionHeader("TARGET EMAIL", Icons.radar_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _toController,
            hint: "Daftar email target (pisahkan koma atau enter)",
            maxLines: 3,
            icon: Icons.group_add_rounded,
          ),

          const SizedBox(height: 28),
          _buildSectionHeader("ISI EMAIL", Icons.code_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _subjectController,
            hint: "Subject Email",
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _bodyController,
            hint: "Isi Pesan (Mendukung HTML)",
            maxLines: 6,
          ),

          const SizedBox(height: 28),
          _buildSectionHeader("JUMLAH SPAM", Icons.bolt_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _multiplierController,
            hint: "Jumlah Spam Email",
            isNumber: true,
            icon: Icons.repeat_rounded,
          ),

          const SizedBox(height: 36),

          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [accentPrimary, accentSecondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "SPAM EMAIL",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 40),
          _buildSectionHeader("LIVE CONSOLE", Icons.terminal_rounded),
          const SizedBox(height: 12),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: logBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSoft),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      "Menunggu perintah operasi...",
                      style: TextStyle(
                        color: borderSoft,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color logColor = textMuted;
                      if (log.contains("Sukses"))
                        logColor = const Color(0xFF10B981);
                      if (log.contains("Gagal") || log.contains("Error"))
                        logColor = dangerSolid;
                      if (log.contains("Memulai")) logColor = accentPrimary;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: logColor,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUnbanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("PENGIRIM EMAIL", Icons.fingerprint_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSoft),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                dropdownColor: surfaceCard,
                icon: const Icon(Icons.unfold_more_rounded, color: textMuted),
                value: _selectedAccount,
                hint: const Text(
                  "Pilih akun pengirim...",
                  style: TextStyle(color: textMuted, fontSize: 14),
                ),
                items: _savedAccounts.map((acc) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: acc,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          color: accentPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          acc['email'],
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccount = val),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader("PILIH JENIS LAPORAN WA", Icons.assignment_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSoft),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: surfaceCard,
                icon: const Icon(Icons.unfold_more_rounded, color: textMuted),
                value: _selectedWaType,
                items: ["Fix Merah", "Unban Biasa"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == "Fix Merah" ? Icons.warning_rounded : Icons.lock_open_rounded,
                          color: value == "Fix Merah" ? dangerSolid : accentPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          value,
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedWaType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader("PILIH METODE PESAN", Icons.shield_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSoft),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: surfaceCard,
                icon: const Icon(Icons.unfold_more_rounded, color: textMuted),
                value: _selectedWaMethod,
                items: ["Default", "Custom / Buat Sendiri"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == "Default" ? Icons.security_rounded : Icons.edit_note_rounded,
                          color: value == "Default" ? const Color(0xFF10B981) : Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          value,
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedWaMethod = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader("TARGET NOMOR WHATSAPP", Icons.support_agent_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            hint: "Nomor WA (contoh: +628xxx)",
            icon: Icons.phone_android_rounded,
            isNumber: true,
          ),
          const SizedBox(height: 28),
          
          if (_selectedWaMethod == "Custom / Buat Sendiri") ...[
            _buildSectionHeader("KUSTOMISASI PESAN", Icons.edit_note_rounded),
            const SizedBox(height: 8),
            const Text(
              "Pastikan menyisipkan \$number agar sistem bisa memasukkan nomor target secara otomatis saat pengiriman.",
              style: TextStyle(color: textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _waSubjectController,
              hint: "Subject Email",
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _waBodyController,
              hint: "Isi Pesan",
              maxLines: 8,
            ),
            const SizedBox(height: 28),
          ],
          
          _buildSectionHeader("JUMLAH SPAM", Icons.bolt_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _multiplierController,
            hint: "Jumlah Spam Email",
            isNumber: true,
            icon: Icons.repeat_rounded,
          ),
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [accentPrimary, accentSecondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendUnbanWa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "KIRIM EMAIL",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader("LIVE CONSOLE", Icons.terminal_rounded),
          const SizedBox(height: 12),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: logBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSoft),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      "Menunggu perintah operasi...",
                      style: TextStyle(
                        color: borderSoft,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color logColor = textMuted;
                      if (log.contains("Sukses"))
                        logColor = const Color(0xFF10B981);
                      if (log.contains("Gagal") || log.contains("Error"))
                        logColor = dangerSolid;
                      if (log.contains("Memulai")) logColor = accentPrimary;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: logColor,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("ADD NEW NODE", Icons.add_circle_outline_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _emailController,
                  hint: "Alamat Email",
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: "App Password",
                  icon: Icons.password_rounded,
                  isObscure: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _hostController,
                        hint: "SMTP Host",
                        icon: Icons.dns_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _portController,
                        hint: "Port",
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentPrimary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        color: accentPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Pilih penyedia di bawah untuk melengkapi Host & Port secara otomatis.",
                          style: TextStyle(
                            color: accentPrimary,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildPresetChip("GMAIL", "smtp.gmail.com", "465"),
                    _buildPresetChip("YAHOO", "smtp.mail.yahoo.com", "465"),
                    _buildPresetChip("OUTLOOK", "smtp-mail.outlook.com", "587"),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPrimary.withOpacity(0.1),
                      foregroundColor: accentPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: accentPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      "SIMPAN KE BRANKAS",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildSectionHeader("SECURE VAULT", Icons.lock_outline_rounded),
          const SizedBox(height: 16),

          _savedAccounts.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderSoft,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: textMuted),
                      SizedBox(height: 16),
                      Text(
                        "Brankas Anda masih kosong",
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedAccounts.length,
                  itemBuilder: (context, index) {
                    final acc = _savedAccounts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSoft),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.email_rounded,
                            color: accentPrimary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          acc['email'],
                          style: const TextStyle(
                            color: textMain,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "${acc['host']} : ${acc['port']}",
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: dangerSolid,
                            size: 22,
                          ),
                          onPressed: () => _deleteAccount(index),
                          splashRadius: 24,
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accentPrimary, size: 18),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: accentPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String name, String host, String port) {
    return InkWell(
      onTap: () {
        setState(() {
          _hostController.text = host;
          _portController.text = port;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceSolid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderSoft),
        ),
        child: Text(
          name,
          style: const TextStyle(
            color: textMain,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool isObscure = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: isObscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
        color: textMain,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, color: textMuted, size: 20)
            : null,
        filled: true,
        fillColor: surfaceSolid,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentPrimary, width: 1.5),
        ),
      ),
    );
  }

  void _showInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          height:
              MediaQuery.of(context).size.height *
              0.75, // Make it taller for detail
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_rounded, color: accentPrimary, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Buku Panduan & Solusi Error",
                    style: TextStyle(
                      color: textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dangerSolid.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dangerSolid.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: dangerSolid,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "SOLUSI ERROR 534 (Authentication Failed)",
                                  style: TextStyle(
                                    color: dangerSolid,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Pihak Google/Yahoo MENOLAK password biasa. Anda WAJIB membuat App Password (Sandi Aplikasi).",
                              style: TextStyle(
                                color: textMain,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "1. Buka Akun Google (myaccount.google.com) > Keamanan.\n"
                              "2. Aktifkan 'Verifikasi 2 Langkah'.\n"
                              "3. Cari menu 'Sandi Aplikasi' (App Passwords).\n"
                              "4. Buat sandi baru (Pilih 'Aplikasi Lainnya').\n"
                              "5. Copy 16 digit huruf unik yang muncul.\n"
                              "6. Gunakan 16 digit tersebut sebagai Password di aplikasi ini.",
                              style: TextStyle(
                                color: textMain.withOpacity(0.8),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInstructionStep(
                        "01",
                        "Amankan Akun",
                        "Simpan email dan App Password rahasia Anda di tab DATABASE. Klik tombol preset di bawahnya (GMAIL/YAHOO) agar Host otomatis terisi.",
                      ),
                      _buildInstructionStep(
                        "02",
                        "Radar Target",
                        "Buka tab EMAIL. Tentukan alamat email korban/tujuan. Pisahkan dengan koma jika target lebih dari satu.",
                      ),
                      _buildInstructionStep(
                        "03",
                        "Payload & r",
                        "Ketik Subjek dan Pesan (Bisa format HTML). Tentukan 'Jumlah Spam' yang ingin dikirim ke tiap target.",
                      ),
                      _buildInstructionStep(
                        "04",
                        "Eksekusi",
                        "Tekan tombol SPAM EMAIL dan biarkan mesin menembak beruntun. Pantau pergerakannya di LIVE CONSOLE secara real-time.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "MENGERTI",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String no, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            no,
            style: const TextStyle(
              color: accentPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    height: 1.4,
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


class _GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF283655)
          .withOpacity(0.4) // Subtle line color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintFill1 = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final paintFill2 = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.02)
      ..style = PaintingStyle.fill;


    final path1 = Path()
      ..moveTo(size.width * 0.4, -size.height * 0.1)
      ..lineTo(size.width * 1.2, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..close();


    final path2 = Path()
      ..moveTo(-size.width * 0.2, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 1.1)
      ..lineTo(-size.width * 0.1, size.height * 1.2)
      ..close();


    final path3 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..close();

    canvas.drawPath(path1, paintFill1);
    canvas.drawPath(path1, paintLine);

    canvas.drawPath(path2, paintFill2);
    canvas.drawPath(path2, paintLine);

    canvas.drawPath(path3, paintFill1);
    canvas.drawPath(path3, paintLine);


    final dotPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(size.width * 0.4, -size.height * 0.1),
      Offset(size.width * 1.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(-size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 1.1),
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.7),
    ];

    for (var point in points) {
      canvas.drawCircle(point, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
