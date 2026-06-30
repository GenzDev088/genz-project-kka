import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';

class SmartDigitalClock extends StatefulWidget {
  final bool isDarkMode;
  final double fontSize;
  const SmartDigitalClock({
    super.key,
    required this.isDarkMode,
    this.fontSize = 26,
  });

  @override
  State<SmartDigitalClock> createState() => _SmartDigitalClockState();
}

class _SmartDigitalClockState extends State<SmartDigitalClock> {
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('HH:mm:ss').format(_currentTime),
      style: GoogleFonts.comicNeue(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 2.0,
      ),
    );
  }
}

class SmartDateDisplay extends StatefulWidget {
  final bool isDarkMode;
  const SmartDateDisplay({super.key, required this.isDarkMode});

  @override
  State<SmartDateDisplay> createState() => _SmartDateDisplayState();
}

class _SmartDateDisplayState extends State<SmartDateDisplay> {
  DateTime _currentDate = DateTime.now();
  Timer? _timer;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initLocale();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && _currentDate.day != DateTime.now().day) {
        setState(() {
          _currentDate = DateTime.now();
        });
      }
    });
  }

  Future<void> _initLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Gagal inisialisasi locale id_ID: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const SizedBox(
        height: 12,
        width: 100,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    return Text(
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_currentDate),
      style: TextStyle(
        fontSize: 12,
        color: AppColors.primary.withValues(alpha: 0.8),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
