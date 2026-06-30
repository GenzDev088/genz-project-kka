import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class WeatherPage extends StatefulWidget {
  final Map<String, dynamic> fullData;

  const WeatherPage({super.key, required this.fullData});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool isEnglish = false; // Default to Indonesian as requested

  static const Color accentBlue = Color(0xFF00B4D8);
  static const Color bgDark = Color(0xFF0D1117);
  static const Color cardBg = Color(0xFF161B22);

  Map<String, String> get texts => isEnglish
      ? {
          'hourly': 'HOURLY FORECAST',
          'daily': '7-DAY OUTLOOK',
          'humidity': 'HUMIDITY',
          'wind': 'WIND',
          'direction': 'DIRECTION',
          'visibility': 'VISIBILITY',
        }
      : {
          'hourly': 'PRAKIRAAN PER JAM',
          'daily': 'PRAKIRAAN 7 HARI',
          'humidity': 'KELEMBAPAN',
          'wind': 'ANGIN',
          'direction': 'ARAH',
          'visibility': 'JARAK PANDANG',
        };

  @override
  Widget build(BuildContext context) {
    final location = widget.fullData['lokasi'];
    final data = widget.fullData['data'][0];
    final current = data['cuaca'][0][0];

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(location, current),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildMainStats(
                        current,
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                      const SizedBox(height: 32),
                      _buildSectionHeader(texts['hourly']!),
                      const SizedBox(height: 16),
                      _buildHourlyForecast(data['cuaca'][0]),
                      const SizedBox(height: 32),
                      _buildSectionHeader(texts['daily']!),
                      const SizedBox(height: 16),
                      _buildDailyForecast(data['cuaca']),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentBlue.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(duration: 3.seconds, curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _buildAppBar(dynamic location, dynamic current) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      backgroundColor: bgDark.withOpacity(0.8),
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isEnglish ? "EN" : "ID",
                style: const TextStyle(
                  color: accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onPressed: () => setState(() => isEnglish = !isEnglish),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentBlue.withOpacity(0.2), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  if (current['image'] != null)
                    SvgPicture.network(
                      current['image'],
                      width: 120,
                      height: 120,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    "${current['t']}°",
                    style: const TextStyle(
                      fontSize: 86,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  Text(
                    current['weather_desc']?.toUpperCase() ?? "",
                    style: TextStyle(
                      fontSize: 18,
                      color: accentBlue.withOpacity(0.9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${location['kotkab']}, ${location['provinsi']}",
                    style: const TextStyle(fontSize: 13, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMainStats(dynamic current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _statTile(
            Icons.water_drop_rounded,
            texts['humidity']!,
            "${current['hu']}%",
          ),
          _statTile(Icons.air_rounded, texts['wind']!, "${current['ws']} km/h"),
          _statTile(
            Icons.explore_rounded,
            texts['direction']!,
            "${current['wd']}",
          ),
          _statTile(
            Icons.visibility_rounded,
            texts['visibility']!,
            "${current['vs_text']}",
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: accentBlue, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(List<dynamic> hourly) {
    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final hour = hourly[index];
          final time = hour['local_datetime'].split(' ')[1].substring(0, 5);
          return Container(
            width: 85,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (hour['image'] != null)
                  SvgPicture.network(hour['image'], width: 32, height: 32),
                const SizedBox(height: 8),
                Text(
                  "${hour['t']}°",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(List<dynamic> daily) {
    return Column(
      children: List.generate(daily.length, (index) {
        final dayForecasts = daily[index];
        if (dayForecasts.isEmpty) return const SizedBox();
        final dayData = dayForecasts[0];
        final date = _formatDate(dayData['local_datetime'].split(' ')[0]);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    if (dayData['image'] != null)
                      SvgPicture.network(
                        dayData['image'],
                        width: 28,
                        height: 28,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      dayData['weather_desc'] ?? "",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${dayData['t']}°",
                style: const TextStyle(
                  color: accentBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = parts[2];
    final monthIdx = int.tryParse(parts[1]) ?? 1;
    final year = parts[0];

    final monthsEN = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    final monthsID = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MEI",
      "JUN",
      "JUL",
      "AGU",
      "SEP",
      "OKT",
      "NOV",
      "DES",
    ];

    return "$day ${isEnglish ? monthsEN[monthIdx - 1] : monthsID[monthIdx - 1]} $year";
  }
}
