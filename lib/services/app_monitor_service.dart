
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AppMonitorService {
  static const String MOBILE_LEGENDS_PACKAGE = 'com.mobile.legends';
  static const String MOBILE_LEGENDS_PACKAGE_INDONESIA =
      'com.mobile.legends.indonesia';

  final ValueNotifier<bool> isGameRunning = ValueNotifier(false);
  final ValueNotifier<String> detectedGamePackage = ValueNotifier('');
  final ValueNotifier<DateTime> lastDetection = ValueNotifier(DateTime.now());

  Timer? _monitorTimer;


  static const MethodChannel _channel = MethodChannel('app_monitor_channel');

  Future<void> startMonitoring() async {

    if (!await _checkPermissions()) return;


    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppForeground':
          final String packageName = call.arguments['package'] ?? '';
          final String appName = call.arguments['appName'] ?? '';
          _handleAppChange(packageName, appName);
          break;
        case 'onAppBackground':
          _handleAppBackground();
          break;
      }
    });


    try {
      await _channel.invokeMethod('startMonitoring');
      _startPeriodicCheck();
    } on PlatformException catch (e) {
      print("Failed to start monitoring: ${e.message}");
    }
  }

  void _handleAppChange(String packageName, String appName) {
    if (packageName == MOBILE_LEGENDS_PACKAGE ||
        packageName == MOBILE_LEGENDS_PACKAGE_INDONESIA) {
      isGameRunning.value = true;
      detectedGamePackage.value = packageName;
      lastDetection.value = DateTime.now();


      _triggerIPDetection();
    } else {
      isGameRunning.value = false;
    }
  }

  void _handleAppBackground() {
    isGameRunning.value = false;
    detectedGamePackage.value = '';
  }

  void _startPeriodicCheck() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {

      _channel.invokeMethod('checkForegroundApp');
    });
  }

  Future<bool> _checkPermissions() async {

    try {
      final bool hasUsageStats =
          await _channel.invokeMethod('checkUsageStatsPermission') ?? false;
      if (!hasUsageStats) {
        await _channel.invokeMethod('requestUsageStatsPermission');

        return false;
      }
    } catch (_) {

    }


    if (!await Permission.notification.isGranted) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }


    try {
      final bool vpnReady =
          await _channel.invokeMethod('checkVpnPermission') ?? false;
      if (!vpnReady) {
        await _channel.invokeMethod('requestVpnPermission');
        return false;
      }
    } catch (_) {

    }

    return true;
  }

  void _triggerIPDetection() {

    print("Mobile Legends terdeteksi! Memulai packet capture...");
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _channel.invokeMethod('stopMonitoring');
  }

  void dispose() {
    stopMonitoring();
    isGameRunning.dispose();
    detectedGamePackage.dispose();
    lastDetection.dispose();
  }
}
