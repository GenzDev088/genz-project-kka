import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tabunganku_module.dart';
import 'profile_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_group_page.dart';
import 'notification_page.dart';
import 'chat_room_page.dart';
import 'telegram_report_system.dart';
import 'spotify_music_player.dart';
import 'custom_payload.dart';

import 'thanks_to_page.dart';
import 'spam_pair.dart';
import 'alquran.dart';
import 'send_notification_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'tes_func_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:io';
import 'main.dart';
import 'controller.dart';
import 'weather_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SholatService {
  String _getTimeZone(double longitude) {
    if (longitude >= 105 && longitude < 120) {
      return "WIB";
    } else if (longitude >= 120 && longitude < 135) {
      return "WITA";
    } else if (longitude >= 135 && longitude <= 150) {
      return "WIT";
    } else {
      return "WIB";
    }
  }

  Future<Map<String, dynamic>> getJadwalSholat(String cityId) async {
    try {
      final now = DateTime.now();

      final date =
          "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/jadwal/$cityId/$date'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      print('Error fetching sholat schedule: $e');
    }
    return {};
  }

  Future<List<dynamic>> searchKota(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/$query'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Error searching cities: $e');
    }
    return [];
  }

  Future<List<dynamic>> getKotaList() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCurrentLocationCity() async {
    try {
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) return null;

      if (!await Geolocator.isLocationServiceEnabled()) {
        print('📍 Location service tidak aktif');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final timeZone = _getTimeZone(position.longitude);

      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isEmpty) return null;

      final place = places.first;
      String? cityName =
          place.locality ??
          place.subLocality ??
          place.subAdministrativeArea ??
          place.administrativeArea;

      if (cityName == null) return null;

      print('📍 Location found: $cityName');
      String cleanName = cityName.toLowerCase();
      cleanName = cleanName
          .replaceAll('kabupaten', '')
          .replaceAll('kab.', '')
          .replaceAll('kota', '')
          .replaceAll('kab', '')
          .replaceAll('kot', '')
          .replaceAll('administrative', '')
          .replaceAll('area', '')
          .trim();
      List<dynamic> searchResults = [];
      searchResults = await searchKota(cleanName);
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final parts = cleanName.split(' ');
        for (var part in parts) {
          if (part.length > 3) {
            searchResults = await searchKota(part);
            if (searchResults.isNotEmpty) break;
          }
        }
      }
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final firstWord = cleanName.split(' ')[0];
        if (firstWord.length > 2) {
          searchResults = await searchKota(firstWord);
        }
      }
      if (searchResults.isEmpty) {
        final allCities = await getKotaList();
        Map<String, dynamic>? nearestCity;
        double minDistance = double.infinity;

        for (var city in allCities) {
          final cityLat =
              double.tryParse(city['lintang']?.toString() ?? '0') ?? 0;
          final cityLong =
              double.tryParse(city['bujur']?.toString() ?? '0') ?? 0;

          if (cityLat != 0 && cityLong != 0) {
            final distance = calculateDistance(
              position.latitude,
              position.longitude,
              cityLat,
              cityLong,
            );

            if (distance < minDistance) {
              minDistance = distance;
              nearestCity = city;
            }
          }
        }

        if (nearestCity != null) {
          print('📍 Using nearest city: ${nearestCity['lokasi']}');
          return {
            'cityId': nearestCity['id'].toString(),
            'cityName': nearestCity['lokasi']?.toString() ?? cityName,
            'timeZone': timeZone,
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        }
      }

      if (searchResults.isNotEmpty) {
        final cityData = searchResults[0];
        print('✅ City matched: ${cityData['lokasi']}');

        return {
          'cityId': cityData['id'].toString(),
          'cityName': cityData['lokasi']?.toString() ?? cityName,
          'timeZone': timeZone,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } else {
        print('⚠️ No matching city found in database');
        return null;
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -100, end: 100).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(_animation.value / 100, -0.5),
              radius: 1.5,
              colors: [
                Color(0xFF00B4D8).withOpacity(0.14),
                Color(0xFF4FC3F7).withOpacity(0.10),
                Colors.transparent,
              ],
              stops: [0.10, 0.42, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final Color bloodRed = const Color(0xFF00B4D8);
  final Color darkRed = const Color(0xFF0D1117);
  final Color lightRed = const Color(0xFFE6EDF3);
  final Color deepBlack = const Color(0xFF0D1117);
  final Color glassBlack = const Color(0xCC161B22);
  final Color primaryDark = const Color(0xFF161B22);
  final Color primaryPurple = const Color(0xFF1C2333);
  final Color accentPurple = const Color(0xFF4FC3F7);
  final Color lightPurple = const Color(0xFFE6EDF3);
  final Color primaryWhite = const Color(0xFFFFFFFF);

  Map<String, dynamic>? _jadwalSholat;
  List<dynamic> _cityList = [];
  String _selectedCityId = "1227";
  String _selectedCityName = "Jakarta";
  bool _isLoadingSholat = false;
  Timer? _sholatTimer;
  final SholatService _sholatService = SholatService();
  String? _currentLocation;
  bool _useCurrentLocation = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late WebSocketChannel channel;
  late DateTime _lastStatsUpdate;
  Timer? _healthCheckTimer;
  Timer? _timeTimer;
  Timer? _fetchTimer;
  DateTime _wibTime = DateTime.now();
  DateTime _witaTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _witTime = DateTime.now().add(const Duration(hours: 2));
  String _dayPeriod = "Morning";
  String _nextPrayerName = "";
  String _currentPrayerName = "";
  String _nextPrayerTimeStr = "";
  String _nextPrayerCountdown = "";
  final ValueNotifier<int> _prayerTicker = ValueNotifier(0);
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  late PackageInfo _packageInfo;
  bool _isChecking = false;
  String? _updateError;
  Map<String, dynamic>? _updateInfo;
  List<String> _changelog = [];
  bool _showUpdateBanner = false;
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  String? _profileImagePath;
  List<dynamic> notifications = [];
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  Timer? _realTimeClockTimer;
  String _currentTime = "00:00:00";
  String _currentTimeZoneDisplay = "WIB";
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  bool isLoading = false;
  ValueNotifier<bool> hasUnreadNotif = ValueNotifier(false);
  bool isNotifLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  List<dynamic> senderList = [];

  int _currentPage = 1;
  int _totalPages = 493;
  int onlineUsers = 0;
  int activeConnections = 0;
  final ValueNotifier<int> _carouselCurrentNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _quickActionNotifier = ValueNotifier<int>(0);
  bool _isLoadingNews = false;
  Map<String, dynamic>? _weatherInfo;
  Map<String, dynamic>? _fullWeatherData;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    AppConfig.sessionKey = widget.sessionKey;
    username = widget.username;
    AppConfig.username = widget.username;
    password = widget.password;
    role = widget.role;
    AppConfig.role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug ?? [];
    listDoos = widget.listDoos ?? [];
    newsList = widget.news ?? [];
    _initPackageInfo();
    _jadwalSholat = {
      'lokasi': 'Jakarta',
      'daerah': 'DKI Jakarta',
      'jadwal': {
        'imsak': '04:22',
        'subuh': '04:32',
        'terbit': '05:46',
        'dzuhur': '12:08',
        'ashar': '15:30',
        'maghrib': '18:20',
        'isya': '19:33',
      },
    };
    _selectedPage = _buildEnhancedNewsPage();
    _initAnimations();
    _initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealTimeSystems();
      }
    });
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimes();
      } else {
        timer.cancel();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fetchCnbcNews();
        _fetchWeatherData(_selectedCityName); // Initial fetch
      }
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _initSholatData();
      }
    });

    _realTimeClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRealTimeClock();
      } else {
        timer.cancel();
      }
    });
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileImagePath = prefs.getString('profile_image_path');
        print("📍 DASHBOARD PROFILE PATH: $_profileImagePath");
        if (_bottomNavIndex == 0) {
          _selectedPage = _buildEnhancedNewsPage();
        }
      });
    }
  }

  String _currentTimeZone = "WIB";
  String _timeZoneAbbreviation = "WIB";

  Future<void> _fetchCnbcNews({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoadingNews = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.siputzx.my.id/api/berita/cnbcindonesia'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawItems = decoded['data'] as List<dynamic>? ?? [];

        final mapped = rawItems.whereType<Map>().map<Map<String, dynamic>>((
          item,
        ) {
          final map = Map<String, dynamic>.from(item);
          return {
            'title': map['title']?.toString() ?? 'No Title',
            'link': map['link']?.toString() ?? '',
            'image': map['image']?.toString() ?? '',
            'category': map['category']?.toString() ?? '',
            'label': map['label']?.toString() ?? '',
            'date': map['date']?.toString() ?? '',
            'type': map['type']?.toString() ?? 'article',
          };
        }).toList();

        if (mounted && mapped.isNotEmpty) {
          setState(() {
            newsList = mapped;
          });
        }
      }
    } catch (e) {
      print('Error fetching CNBC news: $e');
    } finally {
      if (mounted && !silent) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  void _initRealTimeSystems() async {
    try {
      await _initAndroidIdAndConnect();
      await Future.delayed(const Duration(seconds: 2));
      await Future.wait([
        _fetchAdvancedStats(),
        _fetchSenders(),
        _fetchNotifications(),
      ]);
    } catch (e) {
      _startPollingFallback();
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token != null) {
        print("[FCM] Token retrieved: $token");
        await http.post(
          Uri.parse("$baseUrl/updateFCMToken"),
          body: {
            "key": sessionKey,
            "token": token,
          },
        );
      }
    } catch (fcmErr) {
      print("[FCM] Failed to setup FCM: $fcmErr");
    }
  }

  Future<void> _initPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _checkForUpdates();
    } catch (e) {}
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _updateError = null;
    });

    try {
      final response = await Dio()
          .get(
            '$baseUrl/api/check-update',
            queryParameters: {
              'version': _packageInfo.version,
              'build': _packageInfo.buildNumber,
              'platform': Platform.isAndroid ? 'android' : 'ios',
            },
            options: Options(
              headers: {'Authorization': 'Bearer ${widget.sessionKey}'},
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['error'] != null) {
          setState(() {
            _updateError = data['error'].toString();
            _updateInfo = null;
            _changelog = [];
            _showUpdateBanner = false;
          });
        } else if (data['has_update'] == true && data['update_info'] != null) {
          setState(() {
            _updateInfo = data['update_info'];
            _changelog = List<String>.from(
              data['update_info']['changelog'] ?? [],
            );
            _showUpdateBanner = true;
          });
          _showUpdateNotification(data['update_info']);
        } else {
          setState(() {
            _updateInfo = null;
            _changelog = [];
            _showUpdateBanner = false;
          });
        }
      } else {
        setState(() {
          _updateError = 'Server merespon dengan kode ${response.statusCode}';
          _showUpdateBanner = false;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = 'Gagal mengecek update: ${e.toString()}';
        _showUpdateBanner = false;
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _showUpdateNotification(Map<String, dynamic> updateInfo) {
    final version = updateInfo['version'] ?? 'terbaru';
    final isCritical = updateInfo['critical'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCritical
                    ? Icons.report_problem_rounded
                    : Icons.system_update_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCritical
                        ? 'Update Kritis Tersedia!'
                        : 'Update Baru Tersedia!',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  Text('Versi v$version telah tersedia',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SizedBox.shrink(),
                  ),
                );
              },
              child: const Text('UPDATE',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor:
            isCritical ? const Color(0xFFD32F2F) : const Color(0xFF00B4D8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 15),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 10,
      ),
    );
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  void _startWebSocketHealthCheck() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      try {
        if (channel.closeCode != null) {
          print("⚠️ WebSocket disconnected, reconnecting...");
          _reconnectWebSocket();
        }
      } catch (e) {

      }
    });
  }

  void _updateRealTimeClock() {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    if (mounted) {

      _currentTime = timeString;
      _currentTimeZoneDisplay = _timeZoneAbbreviation;
    }
  }

  Future<void> _initSholatData() async {
    if (_isLoadingSholat || !mounted) return;

    setState(() {
      _isLoadingSholat = true;
    });

    try {
      final locationData = await _sholatService.getCurrentLocationCity();

      if (locationData != null && mounted) {
        final cityId = locationData['cityId'];
        final cityName = locationData['cityName'];
        final timeZone = locationData['timeZone'];

        setState(() {
          _selectedCityId = cityId;
          _selectedCityName = cityName;
          _useCurrentLocation = true;
          _currentTimeZone = timeZone;
          _timeZoneAbbreviation = timeZone;
        });

        await _fetchSholatSchedule(cityId);
        _fetchWeatherData(cityName); // Trigger weather fetch
        _saveLocationPreference(cityId, cityName);
      } else {
        await _loadSavedLocation();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSholat = false;
        });
      }
    }
  }

  Future<void> _fetchWeatherData(String cityName) async {
    print("🌤️ FETCHING WEATHER FOR: $cityName");
    if (_isLoadingWeather || !mounted) return;

    setState(() => _isLoadingWeather = true);

    try {

      String adm4 = "31.71.01.1001";

      final lowerCity = cityName.toLowerCase();
      if (lowerCity.contains("surabaya")) {
        adm4 = "35.78.01.1001";
      } else if (lowerCity.contains("bandung")) {
        adm4 = "32.73.19.1001";
      } else if (lowerCity.contains("medan")) {
        adm4 = "12.71.01.1001";
      } else if (lowerCity.contains("makassar")) {
        adm4 = "73.71.01.1001";
      } else if (lowerCity.contains("denpasar")) {
        adm4 = "51.71.01.1001";
      } else if (lowerCity.contains("semarang")) {
        adm4 = "33.74.01.1001";
      } else if (lowerCity.contains("palembang")) {
        adm4 = "16.71.01.1001";
      } else if (lowerCity.contains("yogyakarta") ||
          lowerCity.contains("jogja")) {
        adm4 = "34.71.01.1001";
      }

      final response = await http.get(
        Uri.parse("https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=$adm4"),
      );

      print("🌤️ WEATHER API STATUS: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🌤️ WEATHER DATA RECEIVED: ${data['lokasi']}");
        if (data['data'] != null && data['data'].isNotEmpty) {
          final weatherList = data['data'][0]['cuaca'];
          if (weatherList != null && weatherList.isNotEmpty) {

            for (var dayForecasts in weatherList) {
              if (dayForecasts is List && dayForecasts.isNotEmpty) {
                setState(() {
                  _weatherInfo = dayForecasts[0];
                  _fullWeatherData = data;
                });
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print("❌ Weather Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _saveLocationPreference(String cityId, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city_id', cityId);
      await prefs.setString('last_city_name', cityName);
      await prefs.setBool('use_current_location', true);
    } catch (e) {}
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCityId = prefs.getString('last_city_id');
      final savedCityName = prefs.getString('last_city_name');
      final useCurrentLocation = prefs.getBool('use_current_location') ?? false;

      if (savedCityId != null && savedCityName != null) {
        setState(() {
          _selectedCityId = savedCityId;
          _selectedCityName = savedCityName;
          _useCurrentLocation = useCurrentLocation;
        });

        await _fetchSholatSchedule(savedCityId);
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    }
  }

  String _cleanCityName(String cityName) {
    if (cityName.isEmpty) return '';

    String cleaned = cityName.toLowerCase();
    List<String> prefixes = [
      'kecamatan',
      'kelurahan',
      'kota',
      'kab.',
      'kabupaten',
      'kab',
      'kec',
      'kel',
      'desa',
      'kabkota',
    ];

    for (var prefix in prefixes) {
      cleaned = cleaned.replaceAll(prefix, '').trim();
    }
    List<String> directions = ['selatan', 'utara', 'timur', 'barat'];
    for (var dir in directions) {
      cleaned = cleaned.replaceAll(' $dir', '').replaceAll('$dir ', '');
    }

    return cleaned.trim();
  }

  bool _isCityMatch(String apiCityName, String geocodingCityName) {
    if (apiCityName.isEmpty || geocodingCityName.isEmpty) return false;
    String cleanApi = apiCityName.replaceAll(RegExp(r'[^a-z]'), '');
    String cleanGeo = geocodingCityName.replaceAll(RegExp(r'[^a-z]'), '');
    return cleanApi.contains(cleanGeo) ||
        cleanGeo.contains(cleanApi) ||
        cleanApi == cleanGeo;
  }

  Future<void> _fetchSholatSchedule(String cityId) async {
    if (!mounted) return;

    try {
      _safeSetState(() {
        _isLoadingSholat = true;
      });

      final data = await _sholatService
          .getJadwalSholat(cityId)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              return {};
            },
          );

      if (mounted && data.isNotEmpty && data['status'] == true) {
        _safeSetState(() {
          _jadwalSholat = data['data'];
        });
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    } finally {
      if (mounted) {
        _safeSetState(() {
          _isLoadingSholat = false;
        });
      }
    }
  }

  void _setDefaultSholatSchedule() {
    if (mounted) {
      _safeSetState(() {
        _jadwalSholat = {
          'lokasi': 'Jakarta',
          'daerah': 'DKI Jakarta',
          'jadwal': {
            'imsak': '04:22',
            'subuh': '04:32',
            'terbit': '05:46',
            'dzuhur': '12:08',
            'ashar': '15:30',
            'maghrib': '18:20',
            'isya': '19:33',
          },
        };
        _isLoadingSholat = false;
      });
    }
  }

  String _getNextSholatTime() {
    if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null) {
      return "Mengambil jadwal...";
    }

    final jadwal = _jadwalSholat!['jadwal'];
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final sholatTimes = [
      {'name': 'Subuh', 'time': jadwal['subuh']?.toString() ?? '04:32'},
      {'name': 'Dzuhur', 'time': jadwal['dzuhur']?.toString() ?? '12:08'},
      {'name': 'Ashar', 'time': jadwal['ashar']?.toString() ?? '15:30'},
      {'name': 'Maghrib', 'time': jadwal['maghrib']?.toString() ?? '18:20'},
      {'name': 'Isya', 'time': jadwal['isya']?.toString() ?? '19:33'},
    ];

    for (var sholat in sholatTimes) {
      if (_isTimeLater(sholat['time']!, currentTime)) {
        return "Menuju ${sholat['name']} : ${sholat['time']}";
      }
    }

    final imsakTime = jadwal['imsak']?.toString() ?? '04:22';
    return "Menuju Imsak : $imsakTime";
  }

  bool _isTimeLater(String time1, String time2) {
    try {
      final t1 = time1.split(':');
      final t2 = time2.split(':');

      final hour1 = int.tryParse(t1[0]) ?? 0;
      final minute1 = int.tryParse(t1[1]) ?? 0;
      final hour2 = int.tryParse(t2[0]) ?? 0;
      final minute2 = int.tryParse(t2[1]) ?? 0;

      return hour1 > hour2 || (hour1 == hour2 && minute1 > minute2);
    } catch (e) {
      return false;
    }
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF061225), Color(0xFF0B1E35)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Color(0xFF00B4D8),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Pilih Lokasi Sholat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (mounted) {
                                setState(() {
                                  _isLoadingSholat = true;
                                });
                              }
                              await _initSholatData();
                            },
                            icon: Icon(Icons.gps_fixed),
                            label: Text('Gunakan Lokasi Saat Ini'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B4D8),
                              foregroundColor: Color(0xFF061225),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari kota/kabupaten...',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (value) async {
                            if (value.length > 2) {
                              final results = await _sholatService.searchKota(
                                value,
                              );
                              setState(() {
                                _cityList = results;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  Expanded(
                    child: _cityList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.white30,
                                  size: 50,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Cari kota atau kabupaten',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Minimal 3 karakter',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cityList.length,
                            itemBuilder: (context, index) {
                              final city = _cityList[index];
                              return Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.location_city,
                                    color: Color(0xFF00B4D8).withOpacity(0.7),
                                  ),
                                  title: Text(
                                    city['lokasi']?.toString() ?? 'Unknown',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: city['daerah'] != null
                                      ? Text(
                                          city['daerah'].toString(),
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing:
                                      _selectedCityId == city['id'].toString()
                                      ? Icon(
                                          Icons.check,
                                          color: Color(0xFF00B4D8),
                                        )
                                      : null,
                                  onTap: () async {
                                    if (mounted) {
                                      setState(() {
                                        _selectedCityId = city['id'].toString();
                                        _selectedCityName =
                                            city['lokasi']?.toString() ??
                                            'Jakarta';
                                        _useCurrentLocation = false;
                                        _isLoadingSholat = true;
                                      });
                                    }
                                    await _fetchSholatSchedule(
                                      city['id'].toString(),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingSholat = false;
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilih kota untuk mendapatkan jadwal sholat yang akurat',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSholatTimeItem(String name, String time, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Color(0xFF00B4D8).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? Color(0xFF00B4D8).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isActive
                  ? Color(0xFF00B4D8)
                  : Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isActive ? Color(0xFF00B4D8) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(fn);
          }
        });
      } catch (e) {
        print("⚠️ Error in setState: $e");
      }
    }
  }

  String _getSholatTime(String key) {
    if (_jadwalSholat == null ||
        _jadwalSholat!['jadwal'] == null ||
        _jadwalSholat!['jadwal'][key] == null) {
      return '--:--';
    }
    return _jadwalSholat!['jadwal'][key]?.toString() ?? '--:--';
  }

  Future<void> _fetchAdvancedStats({int retryCount = 3}) async {
    if (retryCount <= 0 || !mounted) return;

    try {
      final uri = Uri.parse("$baseUrl/api/stats/real-time?key=$sessionKey");

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $sessionKey',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          onlineUsers =
              data['online_users'] ??
              data['global_stats']?['online_users'] ??
              onlineUsers;

          activeConnections =
              data['connections_count'] ??
              data['personal_stats']?['active_connections'] ??
              activeConnections;

          _lastStatsUpdate = DateTime.now();
        });
        return;
      }

      if (response.statusCode == 401) {
        _handleInvalidSession("Session expired");
        return;
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 2));
    await _fetchAdvancedStats(retryCount: retryCount - 1);
  }

  Future<void> _fetchNotifications() async {
    if (isNotifLoading) return;

    setState(() {
      isNotifLoading = true;
    });

    try {
      final uri = Uri.parse("$baseUrl/notify/list").replace(
        queryParameters: {
          'key': sessionKey,
          'username': username,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $sessionKey',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            notifications = data;
            hasUnreadNotif.value = data.isNotEmpty;
          });
        } else if (data is Map) {
          final notifList = data['notifications'] ?? data['data'] ?? [];
          if (notifList is List) {
            setState(() {
              notifications = notifList;
              hasUnreadNotif.value = notifList.isNotEmpty;
            });
          }
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          isNotifLoading = false;
        });
      }
    }
  }

  void _openNotifications() {
    if (hasUnreadNotif.value) {
      hasUnreadNotif.value = false;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF0F1419),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Color(0xFF0F2540), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF091A2D),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF0F2540), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bloodRed.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: bloodRed,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notifikasi",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${notifications.length} pesan baru",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyNotifications()
                    : _buildNotificationsList(),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF091A2D),
                  border: Border(
                    top: BorderSide(color: Color(0xFF0F2540), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF3A3F45),
                            width: 1,
                          ),
                          color: Colors.white.withOpacity(0.03),
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          label: Text(
                            "Tandai Semua Dibaca",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: bloodRed.withOpacity(0.1),
                        border: Border.all(
                          color: bloodRed.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, size: 20, color: bloodRed),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _fetchNotifications();
                          _openNotifications();
                        },
                        tooltip: "Refresh",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 36,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Tidak Ada Notifikasi",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tidak ada notifikasi untuk ditampilkan saat ini",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 180,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF3A3F45), width: 1),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _fetchNotifications();
                  _openNotifications();
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Refresh",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchNotifications();
      },
      color: bloodRed,
      backgroundColor: Color(0xFF0F1419),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final title = notification["title"]?.toString() ?? "Notifikasi";
          final message = notification["message"]?.toString() ?? "-";
          final createdAt = notification["createdAt"]?.toString() ?? "";
          final isNew = index == 0;

          String formattedTime;
          try {
            final date = DateTime.parse(createdAt);
            final now = DateTime.now();
            final difference = now.difference(date);

            if (difference.inMinutes < 1) {
              formattedTime = "Baru saja";
            } else if (difference.inMinutes < 60) {
              formattedTime = "${difference.inMinutes}m yang lalu";
            } else if (difference.inHours < 24) {
              formattedTime = "${difference.inHours}j yang lalu";
            } else {
              formattedTime = "${difference.inDays}h yang lalu";
            }
          } catch (e) {
            formattedTime = "Waktu tidak diketahui";
          }

          return _buildNotificationItem(
            title: title,
            message: message,
            time: formattedTime,
            isNew: isNew,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required bool isNew,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          splashColor: bloodRed.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNew
                  ? Color(0xFF1565C0).withOpacity(0.08)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNew
                    ? Color(0xFF1565C0).withOpacity(0.25)
                    : Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNew)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF1565C0).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "BARU",
                          style: TextStyle(
                            color: bloodRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _showNotificationActions(context, index);
                        },
                        padding: EdgeInsets.zero,
                        splashRadius: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationActions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF091A2D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF0F2540), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.check_circle_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 22,
                      ),
                      title: Text(
                        "Tandai Dibaca",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    Divider(height: 1, color: Color(0xFF0F2540)),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.8),
                        size: 22,
                      ),
                      title: Text(
                        "Hapus Notifikasi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    Divider(height: 1, color: Color(0xFF0F2540)),
                    ListTile(
                      leading: Icon(
                        Icons.content_copy_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 22,
                      ),
                      title: Text(
                        "Salin Pesan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF091A2D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF0F2540), width: 1),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.cancel_outlined,
                    color: Colors.white.withOpacity(0.8),
                    size: 22,
                  ),
                  title: Text(
                    "Tutup",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/bg.mp4')
      ..initialize().then((_) {
        _videoController.setVolume(0.0);
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {
          _isVideoInitialized = true;
        });
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    if (kIsWeb) {
      androidId = "web_client";
    } else {
      try {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        androidId = deviceInfo.id;
      } catch (_) {
        androidId = "unknown_device";
      }
    }
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    try {
      print("🌐 Connecting to WebSocket...");
      const wsUrl = 'ws://96.9.212.22:3001/ws';

      channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['otax-protocol'],
      );

      print("✅ WebSocket connection established");

      channel.stream.listen(
        (dynamic message) {
          print(
            "📨 WebSocket message received: ${message.toString().substring(0, min(100, message.toString().length))}",
          );
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
          _reconnectWebSocket();
        },
        onDone: () {
          print("🔌 WebSocket connection closed");
          if (channel.closeCode != 1000) {
            _reconnectWebSocket();
          }
        },
        cancelOnError: true,
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (channel != null && channel.closeCode == null) {
          _sendWebSocketAuth();
        }
      });
    } catch (e) {
      _reconnectWebSocket();
    }
  }

  void _sendWebSocketAuth() {
    try {
      final authMessage = jsonEncode({
        "type": "auth",
        "token": sessionKey,
        "androidId": androidId,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });

      channel.sink.add(authMessage);
      print("✅ Authentication sent");
    } catch (e) {}
  }

  void _handleWebSocketMessage(dynamic event) {
    try {
      final data = jsonDecode(event.toString());
      final type = data['type']?.toString().toLowerCase();

      switch (type) {
        case 'stats_update':
        case 'stats':
          _handleStatsUpdate(data);
          break;

        case 'notification':
        case 'notify':
          _handleNewNotification(data);
          break;

        case 'connections_update':
        case 'senders':
          _handleConnectionsUpdate(data);
          break;

        case 'user_online':
        case 'online':
          _handleUserOnlineUpdate(data);
          break;

        case 'ping':
          channel.sink.add(
            jsonEncode({
              'type': 'pong',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          );
          break;

        case 'auth_success':
          print("✅ WebSocket authentication successful");
          channel.sink.add(
            jsonEncode({'type': 'get_initial_data', 'token': sessionKey}),
          );
          break;

        case 'rat_update':
          final msg =
              data['message'] ?? 'APK RAT terbaru telah diupload di server!';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.system_update_alt, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade800,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          break;

        default:
          print(
            "📨 Unknown message type: $type, data: ${data.toString().substring(0, min(100, data.toString().length))}",
          );
      }
    } catch (e) {}
  }

  void _handleStatsUpdate(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        onlineUsers =
            data['total_online_users'] ??
            data['onlineUsers'] ??
            data['online_count'] ??
            onlineUsers;

        activeConnections =
            data['your_active_connections'] ??
            data['myConnections'] ??
            data['connections_count'] ??
            activeConnections;
      });
    }
  }

  void _showInAppNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              notification['message'],
              style: TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification['type']),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _openNotifications();
            },
            child: Text('BUKA', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text('TUTUP', style: TextStyle(color: Colors.white70)),
          ),
        ],
        padding: EdgeInsets.all(16),
      ),
    );

    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange[800]!;
      case 'error':
        return Colors.red[800]!;
      case 'success':
        return Colors.green[800]!;
      case 'info':
      default:
        return Colors.blue[800]!;
    }
  }

  Color _getTimeZoneColor(String timeZone) {
    switch (timeZone) {
      case "WIB":
        return Color(0xFF2196F3);
      case "WITA":
        return Color(0xFF4CAF50);
      case "WIT":
        return Color(0xFFFF9800);
      default:
        return Color(0xFF00B4D8);
    }
  }

  bool _isCurrentSholat(String sholatName, String? sholatTime) {
    if (sholatTime == null) return false;

    try {
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final sholatTimeFormatted = sholatTime.length >= 5
          ? sholatTime.substring(0, 5)
          : sholatTime;

      return sholatTimeFormatted == currentTime;
    } catch (e) {
      return false;
    }
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    final notification = {
      'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'title': data['title'] ?? 'Notification',
      'message': data['message'] ?? '',
      'createdAt': data['timestamp'] ?? DateTime.now().toIso8601String(),
      'type': data['notification_type'] ?? 'info',
      'read': false,
    };

    if (mounted) {
      setState(() {
        notifications.insert(0, notification);
        hasUnreadNotif.value = true;

        if (notifications.length > 50) {
          notifications = notifications.sublist(0, 50);
        }
      });

      _showInAppNotification(notification);
    }
  }

  void _handleConnectionsUpdate(Map<String, dynamic> data) {
    final List<dynamic> connections = data['connections'] ?? [];
    if (mounted) {
      setState(() {
        senderList = connections.cast<Map<String, dynamic>>();
        activeConnections = connections.length;
      });
    }
  }

  void _handleUserOnlineUpdate(Map<String, dynamic> data) {
    final String action = data['action'] ?? 'update';
    final int count = data['count'] ?? onlineUsers;

    if (mounted) {
      setState(() {
        if (action == 'increment') {
          onlineUsers += 1;
        } else if (action == 'decrement') {
          onlineUsers -= 1;
          if (onlineUsers < 0) onlineUsers = 0;
        } else {
          onlineUsers = count;
        }
      });
    }
  }

  int _reconnectAttempts = 0;
  bool _isReconnecting = false;

  void _reconnectWebSocket() {
    if (_isReconnecting) return;

    _isReconnecting = true;
    _reconnectAttempts++;

    final delaySeconds = _reconnectAttempts <= 5
        ? pow(2, _reconnectAttempts).toInt()
        : 30;

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted) {
        _isReconnecting = false;
        _connectToWebSocket();
      }
    });
  }

  Widget _buildConnectionStatusIndicator() {
    final isConnected = channel?.closeCode == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: isConnected
                      ? Colors.green.withOpacity(0.8)
                      : Colors.orange.withOpacity(0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? "REAL-TIME CONNECTED" : "CONNECTING...",
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isConnected
                      ? "WebSocket connection active"
                      : "Attempting to reconnect...",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          if (!isConnected)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              color: Colors.orange,
              onPressed: _reconnectWebSocket,
            ),
        ],
      ),
    );
  }

  void _startPollingFallback() {
    Timer.periodic(Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (channel?.closeCode != null) {
        Future.wait([
          _fetchAdvancedStats(),
          _fetchSenders(),
          _fetchNotifications(),
        ]);
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: glassBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: bloodRed.withOpacity(0.5), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: bloodRed, size: 28),
              const SizedBox(width: 10),
              Text(
                "Session Expired",
                style: TextStyle(color: bloodRed, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: bloodRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildEnhancedNewsPage();
      } else if (index == 1) {
        _selectedPage = _buildWhatsAppMenuPage();
      } else if (index == 2) {
        try {
          _selectedPage = BugGroupPage(sessionKey: sessionKey, role: role);
        } catch (e) {
          print('Error creating BugGroupPage: $e');
          _selectedPage = Center(
            child: Text('Error: $e', style: TextStyle(color: Colors.red)),
          );
        }
      } else if (index == 3) {
        _selectedPage = ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          listDoos: listDoos,
          username: username,
        );
      }
    });
  }

  Widget _buildWhatsAppMenuPage() {
    final List<Map<String, dynamic>> menuOptions = [
      {
        'title': 'MANTA BUG',
        'subtitle': 'Bug tanpa custom',
        'description': 'Gunakan langsung tanpa custom delay dan loops',
        'icon': Icons.bug_report,
        'iconColor': Color(0xFFE6EDF3),
        'gradientColors': [
          Color(0xFF0D1117),
          Color(0xFF174056),
          Color(0xFF00B4D8),
        ],
        'badgeText': 'RECOMMENDED',
        'badgeColor': Color(0xFFA5E7FF),
        'features': [
          'Mudah digunakan',
          'Function terbaru',
          'All work gacor',
          'MANTA BUG',
        ],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              username: username,
              password: password,
              listBug: listBug,
              role: role,
              expiredDate: expiredDate,
              sessionKey: sessionKey,
            ),
          ),
        ),
      },
      {
        'title': 'CUSTOM BUG',
        'subtitle': 'Menu custom bug',
        'description': 'Buat menu bug, delay pengiriman dan loops',
        'icon': Icons.settings_applications,
        'iconColor': Color(0xFFDFF4FF),
        'gradientColors': [
          Color(0xFF101722),
          Color(0xFF1E4E7A),
          Color(0xFF4FC3F7),
        ],
        'badgeText': 'CUSTOM',
        'badgeColor': Color(0xFF7FDBFF),
        'features': [
          'Pengaturan Mudah',
          'Support Multi Bug',
          'Bebas Spam',
          'Gacor The Best',
        ],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomPayloadPage(
              sessionKey: sessionKey,
              username: username,
              role: role,
              listBug: listBug,
            ),
          ),
        ),
      },
      {
        'title': 'SPAM PAIR',
        'subtitle': 'Menu Spam Pairing',
        'description': 'Pairing Whatsapp dan OTP Telegram',
        'icon': Icons.mail,
        'iconColor': Color(0xFFEAF6FF),
        'gradientColors': [
          Color(0xFF121821),
          Color(0xFF215071),
          Color(0xFF74CFFF),
        ],
        'badgeText': 'SPAM',
        'badgeColor': Color(0xFF9EDDFF),
        'features': [
          'Mudah Digunakan',
          'Anti Gimmick',
          'Tanpa Sender',
          'Pengecekan Backend',
        ],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpamPairPage(
              sessionKey: sessionKey,
              username: username,
              role: role,
            ),
          ),
        ),
      },
    ];

    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    final isCompactWhatsAppLayout =
        shortestSide <= 430 || mediaQuery.devicePixelRatio >= 2.6;
    final double headerHeight = isCompactWhatsAppLayout ? 138 : 148;
    final double carouselViewport = 0.82;
    final double carouselEnlargeFactor = 0.35;
    final double topPadding = isCompactWhatsAppLayout ? 6 : 12;
    final double sectionSpacing = isCompactWhatsAppLayout ? 10 : 12;
    final double carouselHeight = isCompactWhatsAppLayout ? 490 : 520;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF111820),
              Color(0xFF162331),
              Color(0xFF0A0E14),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: AnimatedBackground()),
            Positioned.fill(
              child: _buildLuxuryBackdrop(
                primary: Color(0xFF00B4D8),
                secondary: Color(0xFF4FC3F7),
                tertiary: Color(0xFFA5E7FF),
                patternOpacity: 0.024,
              ),
            ),
            Positioned(
              top: -120,
              left: -90,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF00B4D8).withOpacity(0.14),
                      Color(0xFF4FC3F7).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF4FC3F7).withOpacity(0.12),
                      Color(0xFF00B4D8).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -60,
              left: -60,
              right: -60,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.15,
                    colors: [
                      Color(0xFF00B4D8).withOpacity(0.16),
                      Color(0xFF4FC3F7).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildWhatsAppHeader(
                  isCompact: isCompactWhatsAppLayout,
                  headerHeight: headerHeight,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: topPadding,
                      bottom: sectionSpacing,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: carouselHeight,
                          child: CarouselSlider.builder(
                            options: CarouselOptions(
                              height: carouselHeight,
                              viewportFraction: carouselViewport,
                              initialPage: 0,
                              enableInfiniteScroll: true,
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 4),
                              autoPlayAnimationDuration: Duration(
                                milliseconds: 850,
                              ),
                              autoPlayCurve: Curves.easeOutQuart,
                              enlargeCenterPage: true,
                              enlargeFactor: carouselEnlargeFactor,
                              scrollDirection: Axis.horizontal,
                              onPageChanged: (index, reason) {
                                _carouselCurrentNotifier.value = index;
                              },
                            ),
                            itemCount: menuOptions.length,
                            itemBuilder: (context, index, realIndex) {
                              return _buildCarouselCard(
                                menuOptions[index],
                                index,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        ValueListenableBuilder<int>(
                          valueListenable: _carouselCurrentNotifier,
                          builder: (context, activeIndex, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(menuOptions.length, (i) {
                                final bool active = i == activeIndex;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isCompactWhatsAppLayout ? 3 : 4,
                                  ),
                                  width: active
                                      ? (isCompactWhatsAppLayout ? 16 : 20)
                                      : 6,
                                  height: isCompactWhatsAppLayout ? 5 : 6,
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? LinearGradient(
                                            colors: [
                                              bloodRed,
                                              accentPurple,
                                              accentPink,
                                            ],
                                          )
                                        : null,
                                    color: active
                                        ? null
                                        : Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: accentPurple.withOpacity(
                                                0.45,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : [],
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        SizedBox(height: sectionSpacing),
                        _buildInfoPanel(isCompact: isCompactWhatsAppLayout),
                        SizedBox(height: sectionSpacing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppHeader({
    required bool isCompact,
    required double headerHeight,
  }) {
    final cyanAccent = Color(0xFF00B4D8);
    final neonPurple = Color(0xFF7209B7);
    final solidDark = Color(0xFF0F1923);

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: solidDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    cyanAccent,
                    neonPurple,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 20,
            bottom: 20,
            left: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cyanAccent.withOpacity(0.8),
                    neonPurple.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            right: 15,
            child: Opacity(
              opacity: 0.12,
              child: SizedBox(
                width: 80,
                height: 50,
                child: CustomPaint(painter: _DotGridPainter()),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 22),
              child: Row(
                children: [

                  Container(
                    width: isCompact ? 54 : 64,
                    height: isCompact ? 54 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A2633),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cyanAccent.withOpacity(0.25),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Center(
                          child: Icon(
                            Icons.chat,
                            color: cyanAccent,
                            size: isCompact ? 24 : 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 16 : 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "BUG MENU",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCompact ? 19 : 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: cyanAccent.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cyanAccent.withOpacity(0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            _buildWhatsAppHeaderChip(
                              "ONLINE v2.0",
                              Color(0xFF00D27A),
                              isCompact: isCompact,
                            ),
                            SizedBox(width: 8),
                            _buildWhatsAppHeaderChip(
                              "Elegant Edition",
                              accentGold,
                              isCompact: isCompact,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Pilih menu yang tersedia bosque!",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: isCompact ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> option, int index) {
    final gradientColors = option['gradientColors'] as List<Color>;
    final badgeColor = option['badgeColor'] as Color;
    final features = option['features'] as List<String>;
    final iconColor = option['iconColor'] as Color;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isCompact = shortestSide <= 430;

    return Animate(
      effects: [
        FadeEffect(duration: 350.ms, delay: (80 * index).ms),
        SlideEffect(
          begin: Offset(0, 0.04),
          end: Offset.zero,
          duration: 350.ms,
          delay: (80 * index).ms,
          curve: Curves.easeOut,
        ),
      ],
      child: GestureDetector(
        onTap: option['onTap'] as VoidCallback,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isCompact ? 5 : 6,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientColors[0], gradientColors[1], gradientColors[2]],
              stops: [0.0, 0.52, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[2].withOpacity(0.24),
                blurRadius: 34,
                spreadRadius: 2,
                offset: Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.transparent,
                          Colors.black.withOpacity(0.12),
                        ],
                        stops: [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: isCompact ? -20 : -28,
                  right: isCompact ? -14 : -18,
                  child: Container(
                    width: isCompact ? 82 : 100,
                    height: isCompact ? 82 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: isCompact ? -8 : -12,
                  right: isCompact ? -8 : -12,
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(
                      "MANTA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 52 : 66,
                        fontWeight: FontWeight.w900,
                        letterSpacing: isCompact ? 3 : 5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: isCompact ? -10 : -14,
                  left: isCompact ? -10 : -14,
                  child: Container(
                    width: isCompact ? 72 : 90,
                    height: isCompact ? 72 : 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.14),
                          Colors.white.withOpacity(0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: isCompact ? 56 : 68,
                  right: isCompact ? -4 : -6,
                  child: Container(
                    width: isCompact ? 44 : 58,
                    height: isCompact ? 44 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor.withOpacity(0.28)),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: isCompact ? 62 : 76,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 20,
                      isCompact ? 12 : 14,
                      isCompact ? 16 : 20,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: isCompact ? 44 : 52,
                              height: isCompact ? 44 : 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 14 : 16,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.24),
                                    Colors.white.withOpacity(0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.32),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withOpacity(0.28),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  option['icon'] as IconData,
                                  color: iconColor,
                                  size: isCompact ? 20 : 24,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 10,
                                vertical: isCompact ? 4 : 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    badgeColor.withOpacity(0.24),
                                    badgeColor.withOpacity(0.10),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: badgeColor.withOpacity(0.72),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withOpacity(0.18),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Text(
                                option['badgeText'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 8 : 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: isCompact ? 0.7 : 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 8 : 10),
                        Text(
                          option['title'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 15.5 : 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: isCompact ? 0.5 : 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? 2 : 3),
                        Text(
                          option['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: isCompact ? 10.2 : 11.4,
                            fontWeight: FontWeight.w500,
                            letterSpacing: isCompact ? 0.2 : 0.45,
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                badgeColor.withOpacity(0.85),
                                Colors.white.withOpacity(0.08),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Text(
                          option['description'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.90),
                            fontSize: isCompact ? 10.6 : 11.8,
                            height: isCompact ? 1.35 : 1.45,
                            letterSpacing: 0.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Wrap(
                          spacing: isCompact ? 5 : 6,
                          runSpacing: isCompact ? 5 : 6,
                          children: features
                              .take(2)
                              .map(
                                (f) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 7 : 8,
                                    vertical: isCompact ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.14),
                                        Colors.white.withOpacity(0.06),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: badgeColor,
                                        size: isCompact ? 10 : 11,
                                      ),
                                      SizedBox(width: isCompact ? 3 : 4),
                                      Text(
                                        f,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.92),
                                          fontSize: isCompact ? 8.6 : 9.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const Spacer(),
                        Container(
                          margin: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.24),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: option['onTap'] as VoidCallback,
                              splashColor: Colors.white.withOpacity(0.15),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompact ? 10 : 13,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "START MODULE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 10.4 : 11.8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: isCompact ? 1.0 : 1.4,
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 6 : 8),
                                    Container(
                                      width: isCompact ? 18 : 22,
                                      height: isCompact ? 18 : 22,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.22),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: isCompact ? 12 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppHeaderChip(
    String text,
    Color color, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.10), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.38)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 4 : 5,
            height: isCompact ? 4 : 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.55), blurRadius: 8),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 4 : 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: isCompact ? 7.6 : 8.4,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel({bool isCompact = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentPurple.withOpacity(0.14),
            accentPink.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        border: Border.all(color: accentGold.withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentPurple.withOpacity(0.10),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 30 : 34,
            height: isCompact ? 30 : 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentGold, accentPink, bloodRed],
              ),
              borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: darkRed,
              size: isCompact ? 14 : 16,
            ),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Semua menu telah diuji coba dan tanpa gimmick real work 100%",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: isCompact ? 10.2 : 11.2,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: isCompact ? 2 : 3),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accentGold, accentPink],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentPink.withOpacity(0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "MANTA TEAM",
                      style: TextStyle(
                        color: lightPurple.withOpacity(0.72),
                        fontSize: isCompact ? 8.8 : 9.4,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPage(sessionKey: sessionKey)),
    );
  }

  void _navigateToSellerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerPage(keyToken: sessionKey)),
    );
  }

  Future<void> _fetchSenders({bool refresh = false}) async {
    if (isLoading && !refresh) return;

    final now = DateTime.now();
    if (!refresh && AppConfig.cachedSenders != null && AppConfig.lastSendersFetch != null) {
      if (now.difference(AppConfig.lastSendersFetch!).inSeconds < 15) {
        if (mounted) {
          setState(() {
            senderList = List<dynamic>.from(AppConfig.cachedSenders!);
            activeConnections = senderList.length;
          });
        }
        return;
      }
    }

    if (!refresh && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final uri = Uri.parse("$baseUrl/mySender?key=$sessionKey");

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['valid'] == true) {
          final List connections = data['connections'] ?? [];

          if (!mounted) return;
          setState(() {
            senderList = List<Map<String, dynamic>>.from(connections);
            activeConnections = senderList.length;
          });
          AppConfig.cachedSenders = senderList;
          AppConfig.lastSendersFetch = DateTime.now();
        } else {
          if (!mounted) return;
          setState(() {
            senderList.clear();
            activeConnections = 0;
            errorMessage = "Data sender tidak valid";
          });
        }
        return;
      }

      if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          senderList.clear();
          activeConnections = 0;
          errorMessage = data['error'] ?? "Session expired";
        });
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Gagal mengambil data sender";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  final Color accentGrey = const Color(0xFF7D8590);
  final Color cardDark = const Color(0xFF161B22);
  final Color purpleGradientStart = const Color(0xFF0D1117);
  final Color purpleGradientEnd = const Color(0xFF1C2333);
  final Color accentGold = const Color(0xFFA5E7FF);
  final Color accentPink = const Color(0xFF4FC3F7);

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: lightPurple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                    shadows: valueColor == primaryWhite
                        ? [
                            Shadow(
                              color: primaryPurple.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRealTimeNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    final message = data['message']?.toString() ?? 'New notification';
    final title = data['title']?.toString() ?? 'Notification';

    setState(() {
      notifications.insert(0, {
        'title': title,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      });
      hasUnreadNotif.value = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bloodRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _fetchConnectionsFromBackend() async {
    try {
      channel.sink.add(
        jsonEncode({"type": "get_connections", "token": sessionKey}),
      );
      await _fetchSenders();
    } catch (e) {}
  }

  void _updateTimes() {
    if (!mounted) return;

    final nowLocal = DateTime.now();
    final nowUtc = nowLocal.toUtc();
    final hour = nowLocal.hour;
    if (hour >= 5 && hour < 10) {
      _dayPeriod = "Pagi 🌅";
    } else if (hour >= 10 && hour < 15) {
      _dayPeriod = "Siang ☀️";
    } else if (hour >= 15 && hour < 18) {
      _dayPeriod = "Sore 🌇";
    } else {
      _dayPeriod = "Malam 🌙";
    }
    _wibTime = nowUtc.add(const Duration(hours: 7));
    _witaTime = nowUtc.add(const Duration(hours: 8));
    _witTime = nowUtc.add(const Duration(hours: 9));

    final now = nowLocal; // Revert to device time for prayer logic


    if (_jadwalSholat != null && _jadwalSholat!['jadwal'] != null) {
      final jadwal = _jadwalSholat!['jadwal'];
      final sholatNames = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
      final displayNames = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

      DateTime? nextPrayer;
      String nextName = "";
      String nextTimeStr = "";

      for (int i = 0; i < sholatNames.length; i++) {
        final timeStr = jadwal[sholatNames[i]]?.toString() ?? "";
        if (timeStr.isEmpty) continue;

        final prayerParts = timeStr.split(':');
        if (prayerParts.length < 2) continue;

        final hour =
            int.tryParse(prayerParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final minute =
            int.tryParse(prayerParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

        if (prayerTime.isAfter(now)) {
          nextPrayer = prayerTime;
          nextName = displayNames[i];
          nextTimeStr = timeStr;
          break;
        }
      }

      if (nextPrayer == null) {
        final subuhParts = jadwal['subuh'].toString().split(':');
        final subuhHour =
            int.tryParse(subuhParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
        final subuhMin = subuhParts.length > 1
            ? (int.tryParse(subuhParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ??
                  32)
            : 32;

        nextPrayer = DateTime(
          now.year,
          now.month,
          now.day + 1,
          subuhHour,
          subuhMin,
        );
        nextName = "Subuh";
        nextTimeStr = jadwal['subuh'];
      }

      final diff = nextPrayer.difference(now);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;

      final countdown =
          "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";

      _nextPrayerName = nextName;


      String currentName = "";
      for (int i = 0; i < sholatNames.length; i++) {
        final timeStr = jadwal[sholatNames[i]]?.toString() ?? "";
        if (timeStr.isEmpty) continue;
        final currParts = timeStr.split(':');
        if (currParts.length < 2) continue;

        final cHour =
            int.tryParse(currParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final cMin =
            int.tryParse(currParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        final prayerTime = DateTime(now.year, now.month, now.day, cHour, cMin);

        if (prayerTime.isBefore(now) || prayerTime.isAtSameMomentAs(now)) {
          currentName = displayNames[i];
        }
      }
      if (currentName.isEmpty)
        currentName = "Isya"; // If before Subuh, current is Isya (yesterday)

      _currentPrayerName = currentName;
      _nextPrayerTimeStr = nextTimeStr;
      _nextPrayerCountdown = countdown;
      _prayerTicker.value++;
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Color _getTimeBackgroundColor(String period) {
    if (period.contains("Pagi")) {
      return const Color(0xFF0F2027);
    } else if (period.contains("Siang")) {
      return const Color(0xFF0B1929);
    } else if (period.contains("Sore")) {
      return const Color(0xFF0D2040);
    } else {
      return const Color(0xFF060F1A);
    }
  }

  Color _getTimeAccentColor(String period) {
    if (period.contains("Pagi")) {
      return const Color(0xFF00B4D8);
    } else if (period.contains("Siang")) {
      return const Color(0xFFF9C74F);
    } else if (period.contains("Sore")) {
      return const Color(0xFFE76F51);
    } else {
      return const Color(0xFF7209B7);
    }
  }

  Widget _buildCompactTimeZone({
    required String timeZone,
    required DateTime time,
    required Color primaryColor,
    required Color accentColor,
  }) {
    String periodText = '';
    IconData periodIcon = Icons.wb_sunny;

    final hour = time.hour;
    if (hour >= 5 && hour < 10) {
      periodText = '🌅';
      periodIcon = Icons.wb_twilight;
    } else if (hour >= 10 && hour < 15) {
      periodText = '☀️';
      periodIcon = Icons.wb_sunny;
    } else if (hour >= 15 && hour < 18) {
      periodText = '🌇';
      periodIcon = Icons.nights_stay;
    } else {
      periodText = '🌙';
      periodIcon = Icons.nightlight_round;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeZone,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(periodIcon, color: accentColor, size: 14),
              const SizedBox(width: 4),
              Text(
                periodText,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${time.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "OWNER":
        return Colors.red;
      case "TK":
        return primaryPurple;
      case "PT":
        return Colors.green;
      case "RESELLER":
        return Colors.orange;
      default:
        return lightPurple;
    }
  }

  Widget _buildVideoBackground() {
    if (_isVideoInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      );
    } else {
      return Container(color: deepBlack);
    }
  }

  Widget _buildRealTimeStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isLive = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
            if (isLive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isLive)
          Container(
            margin: EdgeInsets.only(top: 4),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Text(
              "LIVE",
              style: TextStyle(
                color: Colors.green,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DEBUG INFO",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "WebSocket: ${channel?.closeCode == null ? 'CONNECTED ✅' : 'DISCONNECTED ❌'}",
            style: TextStyle(color: Colors.white),
          ),
          Text(
            "Online Users: $onlineUsers",
            style: TextStyle(color: Colors.white),
          ),
          Text(
            "Active Connections: $activeConnections",
            style: TextStyle(color: Colors.white),
          ),
          Text(
            "Notifications: ${notifications.length}",
            style: TextStyle(color: Colors.white),
          ),
          Text(
            "Has Unread: $hasUnreadNotif",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _fetchAdvancedStats();
                  _fetchSenders();
                  _fetchNotifications();
                },
                child: Text("Refresh Data"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _reconnectWebSocket,
                child: Text("Reconnect WS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackdropOrb({
    required double size,
    required Color innerColor,
    required Color outerColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [innerColor, outerColor, Colors.transparent],
          stops: [0.0, 0.46, 1.0],
        ),
      ),
    );
  }

  Widget _buildBackdropFrame({
    required double width,
    required double height,
    required Color strokeColor,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              strokeColor.withOpacity(0.10),
              Colors.white.withOpacity(0.02),
              Colors.transparent,
            ],
          ),
          border: Border.all(color: strokeColor.withOpacity(0.14), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: strokeColor.withOpacity(0.06),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryBackdrop({
    required Color primary,
    required Color secondary,
    Color? tertiary,
    double patternOpacity = 0.022,
  }) {
    final accent = tertiary ?? primary;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.jpg'),
                    repeat: ImageRepeat.repeat,
                    scale: 6.2,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.10),
                      BlendMode.srcATop,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _LuxuryBackdropPainter(
                primary: primary,
                secondary: secondary,
                tertiary: accent,
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -84,
            child: _buildBackdropOrb(
              size: 260,
              innerColor: primary.withOpacity(0.22),
              outerColor: secondary.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: 128,
            right: -34,
            child: _buildBackdropFrame(
              width: 168,
              height: 168,
              strokeColor: secondary,
              angle: 0.62,
            ),
          ),
          Positioned(
            top: 272,
            left: -42,
            child: _buildBackdropFrame(
              width: 118,
              height: 230,
              strokeColor: accent,
              angle: -0.44,
            ),
          ),
          Positioned(
            bottom: 178,
            right: -26,
            child: _buildBackdropFrame(
              width: 132,
              height: 244,
              strokeColor: primary,
              angle: 0.46,
            ),
          ),
          Positioned(
            bottom: -120,
            right: -74,
            child: _buildBackdropOrb(
              size: 232,
              innerColor: secondary.withOpacity(0.18),
              outerColor: accent.withOpacity(0.04),
            ),
          ),
          Positioned(
            bottom: 132,
            left: 16,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.12), width: 1),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: 0.16,
              child: Container(
                height: 1,
                margin: EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      primary.withOpacity(0.30),
                      secondary.withOpacity(0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNewsPage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          isRefreshing = true;
        });
        await Future.wait([
          _fetchSenders(),
          _fetchNotifications(),
          _fetchCnbcNews(silent: true),
        ]);
        setState(() {
          isRefreshing = false;
        });
      },
      color: Colors.white,
      backgroundColor: Color(0xFF020408),
      child: Container(
        decoration: BoxDecoration(color: Color(0xFF020408)),
        child: Stack(
          children: [
            Positioned.fill(child: AnimatedBackground()),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bloodRed.withOpacity(0.05),
                    accentPink.withOpacity(0.04),
                    accentPurple.withOpacity(0.06),
                    Colors.transparent,
                    Colors.black.withOpacity(0.56),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(painter: _AestheticLinesPainter()),
              ),
            ),
            Positioned.fill(
              child: _buildLuxuryBackdrop(
                primary: Color(0xFF00B4D8).withOpacity(0.1),
                secondary: Color(0xFF4FC3F7).withOpacity(0.05),
                tertiary: Color(0xFFA5E7FF).withOpacity(0.02),
              ),
            ),
            CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: false,
                  floating: false,
                  stretch: true,
                  backgroundColor: Color(0xFF020408),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading: const SizedBox.shrink(),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF020408),
                            Color(0xFF051B20), // Deep Dark Teal base
                            Color(0xFF020408),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [

                          Positioned(
                            top: -40,
                            left: -40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(
                                      0xFF00B4D8,
                                    ).withOpacity(0.2), // Surrounding Teal
                                    blurRadius: 100,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            right: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(
                                      0xFF4FC3F7,
                                    ).withOpacity(0.15), // Surrounding Sky Blue
                                    blurRadius: 80,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),


                          Positioned.fill(
                            child: Opacity(
                              opacity:
                                  0.3, // Increased visibility for "busier" look
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _AestheticLinesPainter(),
                                ),
                              ),
                            ),
                          ),


                          Positioned.fill(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [

                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(
                                                  0xFFFFFFFF,
                                                ), // Top Face Highlight
                                                Color(0xFFE0F2F1), // Mid Face
                                                Color(
                                                  0xFFB2DFDB,
                                                ), // Bottom Face Shadow
                                              ],
                                            ).createShader(bounds),
                                        child: Text(
                                          "manta",
                                          style: TextStyle(
                                            fontSize: 72,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 8,
                                            fontFamily: 'Aktura',
                                            color: Colors.white,
                                            shadows: [

                                              Shadow(
                                                offset: Offset(0.5, 0.5),
                                                color: Color(0xFF004D40),
                                                blurRadius: 0,
                                              ),
                                              Shadow(
                                                offset: Offset(1.0, 1.0),
                                                color: Color(0xFF004D40),
                                                blurRadius: 0,
                                              ),
                                              Shadow(
                                                offset: Offset(1.5, 1.5),
                                                color: Color(0xFF004D40),
                                                blurRadius: 0,
                                              ),
                                              Shadow(
                                                offset: Offset(2.0, 2.0),
                                                color: Color(0xFF004D40),
                                                blurRadius: 0,
                                              ),

                                              Shadow(
                                                offset: Offset(4, 4),
                                                color: Colors.black.withOpacity(
                                                  0.6,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),


                                  const SizedBox(height: 4),
                                  Opacity(
                                    opacity: 0.8,
                                    child: Text(
                                      "Design By OTA and Enjoy For Use This Apps",
                                      style: TextStyle(
                                        color: Color(0xFF00B4D8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 4.5,
                                        fontFamily: 'Orbitron',
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(0, 1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),


                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2.0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(
                                      0xFF00B4D8,
                                    ).withOpacity(0.8), // Vibrant Teal
                                    Color(
                                      0xFF4FC3F7,
                                    ).withOpacity(0.6), // Sky Blue
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.45, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        if (_showUpdateBanner && _updateInfo != null)
                          _buildUpdateBanner(),
                        Container(
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: -10,
                                  right: -10,
                                  child: Opacity(
                                    opacity: 0.06,
                                    child: CustomPaint(
                                      size: Size(180, 180),
                                      painter: _HexPainter(color: accentPink),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -10,
                                  left: -10,
                                  child: Opacity(
                                    opacity: 0.05,
                                    child: CustomPaint(
                                      size: Size(130, 130),
                                      painter: _HexPainter(color: bloodRed),
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProfilePage(
                                                  username: username,
                                                  password: password,
                                                  sessionKey: sessionKey,
                                                  expiredDate: expiredDate,
                                                  role: role,
                                                ),
                                              ),
                                            );
                                            _loadProfileImage(); // Refresh dashboard image
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  accentGold,
                                                  accentPink,
                                                  bloodRed,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accentPink.withOpacity(
                                                    0.22,
                                                  ),
                                                  blurRadius: 24,
                                                  spreadRadius: 3,
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 28,
                                              backgroundColor:
                                                  Colors.transparent,
                                              backgroundImage:
                                                  _profileImagePath != null &&
                                                      _profileImagePath!
                                                          .isNotEmpty
                                                  ? (_profileImagePath!
                                                            .startsWith('http')
                                                        ? NetworkImage(
                                                            _profileImagePath!,
                                                          )
                                                        : FileImage(
                                                                File(
                                                                  _profileImagePath!,
                                                                ),
                                                              )
                                                              as ImageProvider)
                                                  : null,
                                              child:
                                                  (_profileImagePath == null ||
                                                      _profileImagePath!
                                                          .isEmpty)
                                                  ? Icon(
                                                      Icons.verified_user,
                                                      color: Colors.white,
                                                      size: 26,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Ahlan Wa Sahlan!!,",
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  fontFamily: 'Orbitron',
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getRoleColor(
                                                    role,
                                                  ).withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _getRoleColor(
                                                      role,
                                                    ).withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  role.toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getRoleColor(role),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                primaryDark,
                                                Color(0xFF24245E),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 10,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.timer,
                                            color: accentGold,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            accentPurple.withOpacity(0.14),
                                            accentPink.withOpacity(0.10),
                                            Colors.transparent,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: accentGold.withOpacity(0.20),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "MANTA'X DASHBOARD",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: lightRed,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Divider(
                                      color: Colors.white.withOpacity(0.1),
                                      height: 1,
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildRealTimeStatChip(
                                          icon: Icons.people,
                                          value: '$onlineUsers',
                                          label: "Online Users",
                                          color: Color(0xFF4CAF50),
                                          isLive: onlineUsers > 0,
                                        ),
                                        _buildRealTimeStatChip(
                                          icon: Icons.link,
                                          value: '$activeConnections',
                                          label: "Active Connections",
                                          color: Color(0xFF2196F3),
                                          isLive: activeConnections > 0,
                                        ),
                                        _buildStatChip(
                                          icon: Icons.calendar_today,
                                          value: expiredDate,
                                          label: "Expiration",
                                          color: Color(0xFFFF9800),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ), // syntax fix
                        ValueListenableBuilder<int>(
                          valueListenable: _prayerTicker,
                          builder: (context, _, __) {
                            if (_isLoadingSholat) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accentGold,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      "Menentukan Jam Sholat...",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (_jadwalSholat == null ||
                                _jadwalSholat!['jadwal'] == null) {
                              return const SizedBox.shrink();
                            }
                            final jadwal = _jadwalSholat!['jadwal'];
                            final List<Map<String, dynamic>> prayerItems = [
                              {
                                'n': 'Subuh',
                                't': jadwal['subuh'],
                                'i': Icons.nights_stay_rounded,
                                'c': const Color(0xFF4FC3F7),
                              },
                              {
                                'n': 'Dzuhur',
                                't': jadwal['dzuhur'],
                                'i': Icons.wb_sunny_rounded,
                                'c': const Color(0xFFFFD54F),
                              },
                              {
                                'n': 'Ashar',
                                't': jadwal['ashar'],
                                'i': Icons.wb_cloudy_rounded,
                                'c': const Color(0xFFFF8A65),
                              },
                              {
                                'n': 'Maghrib',
                                't': jadwal['maghrib'],
                                'i': Icons.nightlight_round,
                                'c': const Color(0xFFBA68C8),
                              },
                              {
                                'n': 'Isya',
                                't': jadwal['isya'],
                                'i': Icons.bedtime_rounded,
                                'c': const Color(0xFF7986CB),
                              },
                            ];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF162536),
                                    Color(0xFF0D1117),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.mosque_rounded,
                                              color: accentGold,
                                              size: 18,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              "JADWAL SHOLAT",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                color: accentPink,
                                                size: 12,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "MENUJU ${_nextPrayerName.toUpperCase()} : ",
                                                style: TextStyle(
                                                  color: accentPink.withOpacity(
                                                    0.9,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _nextPrayerCountdown,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
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
                                  SizedBox(height: 16),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 16),
                                        ...prayerItems.map((p) {
                                          final bool isCurrent =
                                              _currentPrayerName == p['n'];
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 500,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: isCurrent
                                                  ? LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        p['c'].withOpacity(0.4),
                                                        p['c'].withOpacity(
                                                          0.15,
                                                        ),
                                                      ],
                                                    )
                                                  : null,
                                              color: isCurrent
                                                  ? null
                                                  : Colors.black.withOpacity(
                                                      0.25,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isCurrent
                                                    ? p['c'].withOpacity(0.8)
                                                    : Colors.white.withOpacity(
                                                        0.08,
                                                      ),
                                                width: isCurrent ? 1.5 : 1,
                                              ),
                                              boxShadow: isCurrent
                                                  ? [
                                                      BoxShadow(
                                                        color: p['c']
                                                            .withOpacity(0.2),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  p['i'] as IconData,
                                                  size: 16,
                                                  color: isCurrent
                                                      ? p['c']
                                                      : Colors.white38,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  p['n']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: isCurrent
                                                        ? p['c']
                                                        : Colors.white30,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  p['t'].toString(),
                                                  style: TextStyle(
                                                    color: isCurrent
                                                        ? Colors.white
                                                        : Colors.white60,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'ShareTechMono',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: _showCitySelector,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            color: Color(0xFF00B4D8),
                                            size: 14,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            (_jadwalSholat?['lokasi'] ??
                                                    _selectedCityName)
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white30,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (newsList.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.newspaper,
                                      color: accentPink,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "BERITA TERKINI",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accentPink.withOpacity(0.20),
                                            accentGold.withOpacity(0.12),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: accentPink.withOpacity(0.30),
                                        ),
                                      ),
                                      child: Text(
                                        "${newsList.length} Berita",
                                        style: TextStyle(
                                          color: accentPink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                height: 260,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: newsList.length,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, i) {
                                    final item = newsList[i];
                                    return _buildNewsCard(item, i);
                                  },
                                ),
                              ),
                              SizedBox(height: 30),
                            ],
                          ),
                        ], // syntax fix
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.03),
                                        Colors.white.withOpacity(0.01),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accentPurple.withOpacity(0.34),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentGold.withOpacity(0.88),
                                              accentPink.withOpacity(0.72),
                                              bloodRed.withOpacity(0.76),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentPink.withOpacity(
                                                0.26,
                                              ),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.bolt_rounded,
                                            color: Colors.white,
                                            size: 24,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "QUICK ACTIONS",
                                              style: TextStyle(
                                                color: lightPurple,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.5,
                                                fontFamily: 'Orbitron',
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Beberapa Menu Tambahan",
                                              style: TextStyle(
                                                color: accentGrey,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              bloodRed.withOpacity(0.16),
                                              accentPurple.withOpacity(0.12),
                                              accentPink.withOpacity(0.08),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: primaryWhite.withOpacity(
                                              0.1,
                                            ),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: bloodRed.withOpacity(0.08),
                                              blurRadius: 12,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: Duration(
                                                milliseconds: 1000,
                                              ),
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    bloodRed,
                                                    accentPurple,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: bloodRed.withOpacity(
                                                      0.5,
                                                    ),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "MANTA",
                                              style: TextStyle(
                                                color: lightPurple,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2,
                                                shadows: [
                                                  Shadow(
                                                    color: bloodRed.withOpacity(
                                                      0.2,
                                                    ),
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.1),

                            const SizedBox(height: 24),
                            CarouselSlider.builder(
                              options: CarouselOptions(
                                height: 190,
                                aspectRatio: 16 / 9,
                                viewportFraction: 0.78,
                                initialPage: 0,
                                enableInfiniteScroll: true,
                                reverse: false,
                                autoPlay: true,
                                autoPlayInterval: Duration(seconds: 5),
                                autoPlayAnimationDuration: Duration(
                                  milliseconds: 800,
                                ),
                                autoPlayCurve: Curves.fastOutSlowIn,
                                enlargeCenterPage: true,
                                enlargeFactor: 0.35,
                                scrollDirection: Axis.horizontal,
                                onPageChanged: (index, reason) {
                                  _quickActionNotifier.value = index;
                                },
                              ),
                              itemCount: 6,
                              itemBuilder: (context, index, realIndex) {
                                final actions = [
                                  _ModernActionCard(
                                    title: "TabunganKu",
                                    subtitle: "Manage Duit",
                                    icon: Iconsax.wallet_3,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF00C853),
                                        Color(0xFF00E676),
                                        Color(0xFF69F0AE),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TabunganKuModule(),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Manage Bug Sender",
                                    subtitle: "Pairing & Configuration",
                                    icon: Icons.bug_report_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF8E24AA),
                                        Color(0xFFE91E63),
                                        Color(0xFFFF5252),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>
                                              BugSenderPage(
                                                sessionKey: sessionKey,
                                                username: username,
                                                role: role,
                                              ),
                                          transitionsBuilder:
                                              (_, animation, __, child) {
                                                return FadeTransition(
                                                  opacity: CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeInOut,
                                                  ),
                                                  child: child,
                                                );
                                              },
                                          transitionDuration: Duration(
                                            milliseconds: 400,
                                          ),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Chat Room",
                                    subtitle: "Global Communication",
                                    icon: Icons.chat_bubble_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1565C0),
                                        Color(0xFF2196F3),
                                        Color(0xFF03A9F4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>
                                              ChatRoomPage(username: username),
                                          transitionsBuilder:
                                              (_, animation, __, child) {
                                                return SlideTransition(
                                                  position:
                                                      Tween<Offset>(
                                                        begin: Offset(1, 0),
                                                        end: Offset.zero,
                                                      ).animate(
                                                        CurvedAnimation(
                                                          parent: animation,
                                                          curve: Curves
                                                              .easeOutCubic,
                                                        ),
                                                      ),
                                                  child: child,
                                                );
                                              },
                                          transitionDuration: Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Telegram Report",
                                    subtitle: "MANTA Report System",
                                    icon: Icons.send,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0088cc),
                                        Color(0xFF00A8E8),
                                        Color(0xFF4FC3F7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>
                                              MultiProvider(
                                                providers: [
                                                  ChangeNotifierProvider<
                                                    SessionProvider
                                                  >(
                                                    create: (_) {
                                                      final provider =
                                                          SessionProvider();
                                                      provider.initialize();
                                                      return provider;
                                                    },
                                                  ),
                                                ],
                                                child:
                                                    const DashboardPageTelegram(),
                                              ),
                                          transitionsBuilder:
                                              (_, animation, __, child) {
                                                final curvedAnimation =
                                                    CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.easeInOut,
                                                    );
                                                return FadeTransition(
                                                  opacity: curvedAnimation,
                                                  child: ScaleTransition(
                                                    scale: Tween<double>(
                                                      begin: 0.9,
                                                      end: 1.0,
                                                    ).animate(curvedAnimation),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                          transitionDuration: Duration(
                                            milliseconds: 400,
                                          ),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "TES FUNC",
                                    subtitle: "Test Function & Message",
                                    icon: Icons.code_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0097A7),
                                        Color(0xFF00BCD4),
                                        Color(0xFF4DD0E1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TesFuncPage(
                                            sessionKey: sessionKey,
                                            username: username,
                                            role: role,
                                          ),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Al-QURAN",
                                    subtitle:
                                        "Alquran Lengkap Beserta Terjemahan",
                                    icon: Icons.menu_book_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF43A047),
                                        Color(0xFF66BB6A),
                                        Color(0xFF81C784),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AlQuranPage(),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                ];
                                return actions[index];
                              },
                            ),

                            const SizedBox(height: 20),
                            ValueListenableBuilder<int>(
                              valueListenable: _quickActionNotifier,
                              builder: (context, activeIndex, _) {
                                return Center(
                                  child: Wrap(
                                    spacing: 6,
                                    children: List.generate(6, (i) {
                                      final bool isActive = i == activeIndex;
                                      return AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        width: isActive ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: isActive
                                              ? bloodRed
                                              : Colors.white.withOpacity(0.16),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: bloodRed.withOpacity(
                                                      0.45,
                                                    ),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ],
                        ), // syntax fix
                        const SizedBox(height: 20),

                        const SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(0xFF091B30),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.connect_without_contact,
                                    color: Color(0xFFE91E63),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "CONNECT WITH MANTA TEAM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialButton(
                                    icon: Icons.send,
                                    color: Color(0xFF0088CC),
                                    label: "Telegram",
                                    url: 'https://t.me/Otapengenkawin',
                                  ),
                                  _buildSocialButton(
                                    icon: Icons.video_library,
                                    color: Color(0xFFFF0000),
                                    label: "YouTube",
                                    url: 'https://youtube.com',
                                  ),
                                  _buildSocialButton(
                                    icon: Icons.music_note,
                                    color: Color(0xFF000000),
                                    label: "TikTok",
                                    url:
                                        'https://www.tiktok.com/@otaxpengenkawin',
                                  ),

                                  _buildSocialButton(
                                    icon: Icons.favorite,
                                    color: Color(0xFFE91E63),
                                    label: "Thanks To",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ThanksToPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Selalu nantikan project terbaru dari TEAM MANTA",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeQuote(String period) {
    if (period.contains("Pagi")) {
      return "“مَنْ أَصْبَحَ مِنْكُمْ آمِنًا فِي سِرْبِهِ، مُعَافًى فِي جَسَدِهِ، عِنْدَهُ قُوتُ يَوْمِهِ، فَكَأَنَّمَا حِيزَتْ لَهُ الدُّنْيَا.” (رواه الترمذي)\n— Barang siapa yang bangun pagi dalam keadaan aman, sehat, dan cukup makan, maka seakan-akan dunia telah diberikan kepadanya.";
    } else if (period.contains("Siang")) {
      return "“اغْتَنِمْ خَمْسًا قَبْلَ خَمْسٍ...” (رواه الحاكم)\n— Manfaatkanlah lima perkara sebelum lima perkara: termasuk waktu luang sebelum sibuk.";
    } else if (period.contains("Sore")) {
      return "“نِعْمَتَانِ مَغْبُونٌ فِيهِمَا كَثِيرٌ مِنَ النَّاسِ: الصِّحَّةُ وَالْفَرَاغُ.” (رواه البخاري)\n— Dua kenikmatan yang sering dilalaikan manusia: kesehatan dan waktu luang.";
    } else {
      return "“بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.” (رواه البخاري)\n— Dengan nama-Mu ya Allah aku hidup dan aku mati.";
    }
  }

  Widget _buildPrayerTimeCard({
    required String prayerName,
    required String time,
    required IconData icon,
    Gradient? gradient,
    Color? accentColor,
    required bool isNext,
  }) {
    final LinearGradient resolvedGradient = gradient is LinearGradient
        ? gradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (accentColor ?? const Color(0xFF4FC3F7)).withOpacity(0.95),
              (accentColor ?? const Color(0xFF4FC3F7)).withOpacity(0.55),
            ],
          );

    return Container(
      width: 118,
      decoration: BoxDecoration(
        gradient: resolvedGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: resolvedGradient.colors.first.withOpacity(0.26),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                    ),
                    Spacer(),
                    if (isNext)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  prayerName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isNext
                            ? Colors.green
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isNext ? "NEXT" : "SHOLAT",
                      style: TextStyle(
                        color: isNext
                            ? Colors.green
                            : Colors.white.withOpacity(0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSholatCarouselCard({
    required String name,
    required String time,
    required IconData icon,
    required Gradient gradient,
    required bool isNext,
  }) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                    ),
                    Spacer(),
                    if (isNext)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.8),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12),

                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),

                SizedBox(height: 4),

                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isNext
                            ? Colors.green
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      isNext ? "SELANJUTNYA" : "SHOLAT",
                      style: TextStyle(
                        color: isNext
                            ? Colors.green
                            : Colors.white.withOpacity(0.7),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner() {
    final isCritical = _updateInfo?['critical'] == true;
    final version = _updateInfo?['version'] ?? 'terbaru';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SizedBox.shrink(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCritical
                ? [Color(0xFFD32F2F), Color(0xFFB71C1C)]
                : [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical ? Colors.red[300]! : Colors.blue[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCritical
                  ? Colors.red.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 3,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(
                  isCritical ? Icons.warning : Icons.system_update,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isCritical ? 'UPDATE KRITIS' : 'UPDATE TERSEDIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'v$version',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Versi terbaru telah tersedia. Ketuk untuk mengupdate aplikasi.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                  if (_changelog.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Fitur baru:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._changelog
                        .take(2)
                        .map(
                          (change) => Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    change,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item, int index) {
    final newsLink = item['link']?.toString() ?? '';
    final newsDate = _formatNewsDate(item['date']?.toString());

    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openNewsLink(newsLink),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2137), Color(0xFF091A2B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        if (item['image'] != null)
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(item['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: Color(0xFFFF5722),
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "BACA",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title'] ?? 'No Title',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white.withOpacity(0.5),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              newsDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFFFF5722),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNewsLink(String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link berita tidak tersedia')),
      );
      return;
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link berita tidak valid')));
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gagal membuka link berita')));
  }

  String _formatNewsDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Berita terbaru';
    }

    try {
      final parsed = DateTime.parse(raw).toLocal();
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
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastUpdate(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildStatusIndicator({
    required String title,
    required String status,
    required Color color,
    required int value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Expanded(
                flex: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(flex: 100 - value, child: SizedBox()),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          "$value%",
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    String? url,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () async {
            if (url != null) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                await launchUrl(uri);
              }
            }
          },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required List<String> features,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 3,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(icon, color: iconColor, size: 32),
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
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: features.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                feature,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "TAP TO OPEN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
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

  Widget _buildMiniActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Center(child: Icon(icon, color: color, size: 28)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContactActions() {
    return [
      _contactActionButton(
        icon: Icons.send,
        label: "Telegram",
        url: 'https://t.me/Otapengenkawin',
        color: lightRed,
      ),
      _contactActionButton(
        icon: Icons.send,
        label: "Channel",
        url: 'https://t.me/',
        color: lightRed,
      ),
      _contactActionButton(
        icon: Icons.music_note,
        label: "TikTok",
        url: 'https://www.tiktok.com/Otax',
        color: lightRed,
      ),
    ];
  }

  Widget _contactActionButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          await launchUrl(uri);
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _enhancedGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardDark.withOpacity(0.94),
            primaryPurple.withOpacity(0.88),
            accentPurple.withOpacity(0.28),
            accentPink.withOpacity(0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentGold.withOpacity(0.14), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: bloodRed.withOpacity(0.10),
            blurRadius: 20,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: accentPurple.withOpacity(0.10),
            blurRadius: 24,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: accentPink.withOpacity(0.08),
            blurRadius: 28,
            spreadRadius: -3,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _enhancedInfoRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentPurple.withOpacity(0.10),
            accentPink.withOpacity(0.06),
            primaryWhite.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGold.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bloodRed.withOpacity(0.20),
                  accentPurple.withOpacity(0.12),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bloodRed, size: 20),
          ),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(color: accentGrey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MantaDrawer(
        username: username,
        password: widget.password, // Added password
        role: role,
        expiredDate: expiredDate,
        sessionKey: sessionKey,
        onNavigateToAdmin: _navigateToAdminPage,
        onProfileUpdated: _loadProfileImage,
      ),
      backgroundColor: deepBlack,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 150,
        leading: Builder(
          builder: (context) => SizedBox(
            height: 56,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    if (_weatherInfo != null)
                      GestureDetector(
                        onTap: () {
                          if (_fullWeatherData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WeatherPage(fullData: _fullWeatherData!),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.network(
                              _weatherInfo!['image'],
                              width: 24,
                              height: 24,
                              placeholderBuilder: (context) => Icon(
                                Icons.wb_cloudy_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${_weatherInfo!['t']}°C",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_isLoadingWeather)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00B4D8),
                            ),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Colors.white38,
                        ),
                        onPressed: () => _fetchWeatherData(_selectedCityName),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF0F141B), const Color(0xFF162333)],
            ),
          ),
          child: CustomPaint(painter: _AestheticLinesPainter()),
        ),

        title: Container(
          height: 70,
          child: Image.asset(
            'assets/images/MANTAlogo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, Colors.white],
                ).createShader(bounds),
                child: const Text(
                  "MANTA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.music_note_rounded, color: lightPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: deepBlack,
                    body: SpotifyMusicPlayer(
                      sessionKey: sessionKey,
                      username: username,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: ValueListenableBuilder<bool>(
              valueListenable: hasUnreadNotif,
              builder: (context, hasNew, child) {
                return Stack(
                  children: [
                    child!,
                    if (hasNew)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: bloodRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: bloodRed.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
              child: Icon(Icons.notifications_none_rounded, color: lightPurple),
            ),
            onPressed: _openNotifications,
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    username: username,
                    password: password,
                    sessionKey: sessionKey,
                    expiredDate: expiredDate,
                    role: role,
                  ),
                ),
              );
              _loadProfileImage();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: lightPurple.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: cardDark,
                  backgroundImage:
                      _profileImagePath != null && _profileImagePath!.isNotEmpty
                      ? (_profileImagePath!.startsWith('http')
                            ? NetworkImage(_profileImagePath!)
                            : FileImage(File(_profileImagePath!))
                                  as ImageProvider)
                      : null,
                  child:
                      (_profileImagePath == null || _profileImagePath!.isEmpty)
                      ? Icon(Icons.person_rounded, size: 16, color: lightPurple)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          FadeTransition(opacity: _animation, child: _selectedPage),

          Positioned(
            bottom: 62,
            left: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(
                  size: Size(110, 110),
                  painter: _HexPainter(color: bloodRed),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 62,
            right: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(
                  size: Size(100, 100),
                  painter: _HexPainter(color: accentPurple),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildGlassBottomNavBar(),
    );
  }



  Widget _buildGlassBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 85 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            deepBlack.withOpacity(0.80),
            primaryPurple.withOpacity(0.18),
            deepBlack.withOpacity(0.98),
          ],
        ),
      ),
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardDark.withOpacity(0.98),
              primaryPurple.withOpacity(0.94),
              accentPink.withOpacity(0.14),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: accentGold.withOpacity(0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 32,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accentPurple.withOpacity(0.10),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryWhite.withOpacity(0.03),
                    accentPurple.withOpacity(0.04),
                    primaryWhite.withOpacity(0.01),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left:
                        (_bottomNavIndex *
                        (MediaQuery.of(context).size.width - 40) /
                        4),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 40) / 4,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            bloodRed.withOpacity(0.18),
                            accentPurple.withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        activeIcon: Icons.home_filled,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.chat,
                        activeIcon: Icons.chat_bubble,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.group,
                        activeIcon: Icons.group_work,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.build_circle_outlined,
                        activeIcon: Icons.build_circle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    bool isActive = _bottomNavIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 40) / 4,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          bloodRed.withOpacity(0.32),
                          accentPurple.withOpacity(0.16),
                          Colors.transparent,
                        ],
                        radius: 0.7,
                      ),
                    ),
                  ),

                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              bloodRed.withOpacity(0.26),
                              accentPurple.withOpacity(0.18),
                              accentPink.withOpacity(0.14),
                            ],
                          )
                        : null,
                    color: isActive ? null : Colors.transparent,
                    border: Border.all(
                      color: isActive
                          ? accentGold.withOpacity(0.24)
                          : Colors.transparent,
                      width: isActive ? 1.5 : 0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: accentPurple.withOpacity(0.18),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isActive ? activeIcon : icon,
                        key: ValueKey<bool>(isActive),
                        color: isActive
                            ? lightRed
                            : Colors.white.withOpacity(0.7),
                        size: isActive ? 22 : 20,
                      ),
                    ),
                  ),
                ),

                if (isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accentGold, accentPink],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentPink.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox.shrink(),

            if (isActive)
              Container(
                margin: EdgeInsets.only(top: 4),
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentGold, accentPink, bloodRed],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: accentPink.withOpacity(0.55),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: bloodRed.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1565C0).withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bloodRed.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [bloodRed, lightRed],
                  ).createShader(bounds),
                  child: const Text(
                    "Account Info",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _enhancedInfoRow(Icons.person, "Username", username),
                _enhancedInfoRow(Icons.shield, "Role", role),
                _enhancedInfoRow(Icons.calendar_today, "Expired", expiredDate),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [bloodRed, darkRed]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _timeTimer?.cancel();

      _fetchTimer?.cancel();
      _healthCheckTimer?.cancel();
      _sholatTimer?.cancel();
      _realTimeClockTimer?.cancel();
    } catch (e) {}
    try {
      channel.sink.close(1000, 'App disposed');
    } catch (e) {}
    _videoController?.dispose();
    _controller?.dispose();
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith(".mp4") ||
      url.endsWith(".webm") ||
      url.endsWith(".mov") ||
      url.endsWith(".mkv");

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Center(child: CircularProgressIndicator(color: Colors.red));
      }
    } else {
      return Image.network(widget.url, fit: BoxFit.cover);
    }
  }
}

class _ModernActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Gradient gradient;
  final VoidCallback onTap;
  final int index;

  const _ModernActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        ScaleEffect(
          duration: 400.ms,
          curve: Curves.easeOutBack,
          delay: (100 * index).ms,
        ),
        FadeEffect(duration: 400.ms),
      ],
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            "Tap →",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
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
}

class _StarPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF29B6F6).withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final random = Random(42);
    for (int i = 0; i < 55; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 2.5 + 0.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LuxuryBackdropPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const _LuxuryBackdropPainter({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryLine = Paint()
      ..color = primary.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final secondaryLine = Paint()
      ..color = secondary.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final accentLine = Paint()
      ..color = tertiary.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final dotPaint = Paint()
      ..color = primary.withOpacity(0.14)
      ..style = PaintingStyle.fill;

    final softDotPaint = Paint()
      ..color = secondary.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final pathOne = Path()
      ..moveTo(-24, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.03,
        size.width * 0.50,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.34,
        size.width + 28,
        size.height * 0.14,
      );
    canvas.drawPath(pathOne, primaryLine);

    final pathTwo = Path()
      ..moveTo(size.width * 0.06, size.height * 0.56)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.44,
        size.width * 0.42,
        size.height * 0.74,
        size.width * 0.64,
        size.height * 0.60,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.48,
        size.width + 16,
        size.height * 0.68,
      );
    canvas.drawPath(pathTwo, secondaryLine);

    final pathThree = Path()
      ..moveTo(-20, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.72,
        size.width * 0.36,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height,
        size.width * 0.90,
        size.height * 0.86,
      )
      ..quadraticBezierTo(
        size.width * 1.02,
        size.height * 0.80,
        size.width + 24,
        size.height * 0.88,
      );
    canvas.drawPath(pathThree, accentLine);

    final ringCenters = [
      Offset(size.width * 0.16, size.height * 0.30),
      Offset(size.width * 0.76, size.height * 0.26),
      Offset(size.width * 0.24, size.height * 0.76),
      Offset(size.width * 0.82, size.height * 0.72),
    ];
    final ringRadii = [24.0, 18.0, 28.0, 22.0];
    final ringPaints = [primaryLine, secondaryLine, accentLine, secondaryLine];

    for (int i = 0; i < ringCenters.length; i++) {
      canvas.drawCircle(ringCenters[i], ringRadii[i], ringPaints[i]);
    }

    void drawDiamond(Offset center, double radius, Paint paint) {
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy)
        ..close();
      canvas.drawPath(path, paint);
    }

    drawDiamond(Offset(size.width * 0.32, size.height * 0.18), 10, accentLine);
    drawDiamond(Offset(size.width * 0.68, size.height * 0.58), 12, primaryLine);
    drawDiamond(
      Offset(size.width * 0.88, size.height * 0.40),
      9,
      secondaryLine,
    );

    final random = Random(27);
    for (int i = 0; i < 26; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.4 + 0.8;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        i.isEven ? dotPaint : softDotPaint,
      );
    }

    final linkPaint = Paint()
      ..color = tertiary.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.62),
      Offset(size.width * 0.22, size.height * 0.54),
      linkPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.54),
      Offset(size.width * 0.30, size.height * 0.60),
      linkPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.34),
      Offset(size.width * 0.82, size.height * 0.28),
      linkPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.28),
      Offset(size.width * 0.90, size.height * 0.36),
      linkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexPainter extends CustomPainter {
  final Color color;
  const _HexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final r2 = r * 0.6;
    final path2 = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r2 * cos(angle);
      final y = cy + r2 * sin(angle);
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AestheticLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tealPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.12)
      ..strokeWidth = 0.8;

    final bluePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.08)
      ..strokeWidth = 0.5;


    for (double i = -size.width; i < size.width * 2; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        tealPaint,
      );
    }


    for (double i = 0; i < size.width * 2; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        bluePaint,
      );
    }


    final accentPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final rng = Random(42);
    for (int i = 0; i < 15; i++) {
      double x = rng.nextDouble() * size.width;
      double y = rng.nextDouble() * size.height;
      double len = 30 + rng.nextDouble() * 50;


      canvas.drawLine(
        Offset(x, y),
        Offset(x + len, y),
        tealPaint..strokeWidth = 1.2,
      );


      canvas.drawCircle(Offset(x + len, y), 2, accentPaint);


      if (rng.nextBool()) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + 20),
          tealPaint..strokeWidth = 0.8,
        );
      }
    }


    for (int i = 0; i < 5; i++) {
      double y = rng.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        bluePaint..strokeWidth = 0.3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1E88E5).withOpacity(0.05)
      ..strokeWidth = 0.5;

    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}



class _AstronomyBanner extends StatefulWidget {
  const _AstronomyBanner();

  @override
  State<_AstronomyBanner> createState() => _AstronomyBannerState();
}

class _AstronomyBannerState extends State<_AstronomyBanner>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _twinkleController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _twinkleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbitController, _twinkleController]),
      builder: (context, _) {
        return Stack(
          children: [

            Positioned.fill(
              child: CustomPaint(
                painter: _AstronomyPainter(
                  orbitAngle: _orbitController.value * 2 * pi,
                  twinkle: _twinkleController.value,
                ),
              ),
            ),

            Positioned.fill(
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFFFFFFFF),
                      Color(0xFF00B4D8),
                      Color(0xFFFF6B9D),
                      Color(0xFFFFFFFF),
                    ],
                    stops: const [0.0, 0.35, 0.70, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    "manta",
                    style: TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      fontFamily: 'Aktura',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AstronomyPainter extends CustomPainter {
  final double orbitAngle;
  final double twinkle;

  const _AstronomyPainter({required this.orbitAngle, required this.twinkle});


  void _drawPlanet(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color base,
    required Color light,
    required Color dark,
    required Color atmosphere,
    bool hasRing = false,
    Color ringColor = const Color(0x44FFFFFF),
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);


    canvas.drawCircle(
      center,
      radius * 2.2,
      Paint()
        ..color = atmosphere.withOpacity(0.06)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.2),
    );

    canvas.drawCircle(
      center,
      radius * 1.25,
      Paint()
        ..color = atmosphere.withOpacity(0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6),
    );


    if (hasRing) {
      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.35;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 3.4,
          height: radius * 0.7,
        ),
        ringPaint,
      );
    }


    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        radius: 1.1,
        colors: [light, base, dark],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, spherePaint);


    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.18
        ..color = dark.withOpacity(0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15),
    );


    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.22,
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    canvas.drawCircle(
      Offset(center.dx - radius * 0.18, center.dy - radius * 0.18),
      radius * 0.38,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {

    if (size.isEmpty || size.width <= 0 || size.height <= 0) return;


    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF030710), Color(0xFF060E1C), Color(0xFF0A1428)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final cx = size.width / 2;
    final cy = size.height / 2;


    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 320, height: 130),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.07),
                const Color(0xFF4A0072).withOpacity(0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(
              Rect.fromCenter(center: Offset(cx, cy), width: 320, height: 130),
            ),
    );


    final rng = Random(73);
    for (int i = 0; i < 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final base = rng.nextDouble() * 0.55 + 0.1;
      final phase = rng.nextDouble() * pi * 2;
      final opacity = (base * (0.45 + 0.55 * sin(twinkle * pi + phase))).clamp(
        0.0,
        1.0,
      );
      final r = rng.nextDouble() * 1.3 + 0.2;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }



    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 230, height: 58),
      Paint()
        ..color = const Color(0xFFD4AF37).withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 320, height: 80),
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );


    final p1x = cx + 115 * cos(orbitAngle);
    final p1y = cy + 29.0 * sin(orbitAngle);
    _drawPlanet(
      canvas,
      Offset(p1x, p1y),
      11.0,
      base: const Color(0xFFB8860B),
      light: const Color(0xFFFFE082),
      dark: const Color(0xFF4E3000),
      atmosphere: const Color(0xFFFFD700),
      hasRing: true,
      ringColor: const Color(0x55D4AF37),
    );


    final p2x = cx + 160 * cos(-orbitAngle * 0.52 + pi * 0.6);
    final p2y = cy + 40.0 * sin(-orbitAngle * 0.52 + pi * 0.6);
    _drawPlanet(
      canvas,
      Offset(p2x, p2y),
      9.0,
      base: const Color(0xFFB71C1C),
      light: const Color(0xFFFF8A65),
      dark: const Color(0xFF4A0000),
      atmosphere: const Color(0xFFFF5252),
    );


    final sparkles = [
      Offset(cx - 100, cy - 16),
      Offset(cx + 105, cy + 14),
      Offset(cx - 45, cy - 30),
      Offset(cx + 60, cy - 26),
    ];
    for (int i = 0; i < sparkles.length; i++) {
      final op = (0.25 + 0.6 * sin(twinkle * pi + i * 1.2)).clamp(0.0, 1.0);
      final sp = sparkles[i];
      const arm = 4.5;
      final p = Paint()
        ..color = Colors.white.withOpacity(op)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(sp.dx - arm, sp.dy),
        Offset(sp.dx + arm, sp.dy),
        p,
      );
      canvas.drawLine(
        Offset(sp.dx, sp.dy - arm),
        Offset(sp.dx, sp.dy + arm),
        p,
      );
      const dArm = 2.8;
      final p2 = Paint()
        ..color = Colors.white.withOpacity((op * 0.45).clamp(0.0, 1.0))
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(sp.dx - dArm, sp.dy - dArm),
        Offset(sp.dx + dArm, sp.dy + dArm),
        p2,
      );
      canvas.drawLine(
        Offset(sp.dx + dArm, sp.dy - dArm),
        Offset(sp.dx - dArm, sp.dy + dArm),
        p2,
      );
    }
  }

  @override
  bool shouldRepaint(_AstronomyPainter old) =>
      old.orbitAngle != orbitAngle || old.twinkle != twinkle;
}


class MantaDrawer extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final VoidCallback onNavigateToAdmin;
  final VoidCallback onProfileUpdated;

  const MantaDrawer({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.onNavigateToAdmin,
    required this.onProfileUpdated,
  });

  @override
  State<MantaDrawer> createState() => _MantaDrawerState();
}

class _MantaDrawerState extends State<MantaDrawer> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileImagePath = prefs.getString('profile_image_path');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color darkRed = Color(0xFF0D1117);
    final Color bloodRed = Color(0xFF00B4D8);
    final Color accentRed = bloodRed;
    final Color accentPurple = Color(0xFF4FC3F7);
    final Color accentPink = Colors.pinkAccent;
    final Color accentGold = Color(0xFFFFD700);

    return RepaintBoundary(
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF161B22).withOpacity(0.98),
                const Color(0xFF0D1117).withOpacity(0.99),
                const Color(0xFF111820).withOpacity(0.99),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 36,
                spreadRadius: 1,
                offset: const Offset(10, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: [
                          accentPurple.withOpacity(0.08),
                          accentPink.withOpacity(0.05),
                          accentRed.withOpacity(0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            username: widget.username,
                            password: widget.password,
                            sessionKey: widget.sessionKey,
                            expiredDate: widget.expiredDate,
                            role: widget.role,
                          ),
                        ),
                      );
                      _loadProfileImage(); // Refresh drawer image
                      widget.onProfileUpdated(); // Refresh dashboard image
                    },
                    child: _buildDrawerHeader(
                      context,
                      darkRed,
                      accentRed,
                      accentGold,
                      accentPink,
                      accentPurple,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (widget.role == "KINGZ" || widget.role == "OWNER")
                          _DrawerMenuItem(
                            icon: Icons.admin_panel_settings,
                            title: 'Admin Page',
                            accentRed: accentRed,
                            darkRed: darkRed,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onNavigateToAdmin();
                            },
                          ),
                        if (widget.role == "KINGZ")
                          _DrawerMenuItem(
                            icon: Icons.notifications_active,
                            title: 'Kirim Notifikasi',
                            accentRed: accentRed,
                            darkRed: darkRed,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SendNotificationPage(
                                    sessionKey: widget.sessionKey,
                                    username: widget.username,
                                  ),
                                ),
                              );
                            },
                          ),
                        _DrawerMenuItem(
                          icon: Iconsax.wallet_3,
                          title: 'TabunganKu',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TabunganKuModule(),
                              ),
                            );
                          },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.lock_reset,
                          title: 'Change Password',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangePasswordPage(
                                  username: widget.username,
                                  sessionKey: widget.sessionKey,
                                ),
                              ),
                            );
                          },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.fingerprint,
                          title: 'NIK Check',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NikCheckerPage(),
                              ),
                            );
                          },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.system_update_alt,
                          title: 'Update App',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SizedBox.shrink(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'MANTA © 2026',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    Color darkRed,
    Color accentRed,
    Color accentGold,
    Color accentPink,
    Color accentPurple,
  ) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(40)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2333).withOpacity(0.95),
            const Color(0xFF20384F).withOpacity(0.90),
            const Color(0xFF28516E).withOpacity(0.88),
            darkRed.withOpacity(0.98),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentRed.withOpacity(0.18),
                    accentPink.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -10,
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _HexPainter(color: accentRed),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentGold, accentPink, accentRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentPink.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkRed,
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: darkRed,
                    backgroundImage: _profileImagePath != null
                        ? (_profileImagePath!.startsWith('http')
                              ? NetworkImage(_profileImagePath!)
                              : FileImage(File(_profileImagePath!))
                                    as ImageProvider)
                        : const AssetImage('assets/images/logo.jpg'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, accentGold, accentPink],
                ).createShader(bounds),
                child: const Text(
                  'MANTA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 10,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accentRed.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  widget.username.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentRed.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentRed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ACCESS UNTIL: ${widget.expiredDate}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 4)],
      ),
    );
  }
}


class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentRed;
  final Color darkRed;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.accentRed,
    required this.darkRed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentRed.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        darkRed.withOpacity(0.4),
                        accentRed.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: accentRed, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: accentRed.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const spacing = 8.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

