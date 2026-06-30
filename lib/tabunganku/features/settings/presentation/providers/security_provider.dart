import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>(
  (ref) {
    return SecurityNotifier();
  },
);

class SecurityState {
  final bool isBiometricEnabled;
  final bool hasPin;
  final bool isAuthenticating;
  final bool isInitialized;
  final String? error;
  final DateTime? lastAuthenticatedAt;
  final bool isAuthorized;
  final bool isExternalOperationInProgress;

  SecurityState({
    this.isBiometricEnabled = false,
    this.hasPin = false,
    this.isAuthenticating = false,
    this.isInitialized = false,
    this.error,
    this.lastAuthenticatedAt,
    this.isAuthorized = false,
    this.isExternalOperationInProgress = false,
  });

  SecurityState copyWith({
    bool? isBiometricEnabled,
    bool? hasPin,
    bool? isAuthenticating,
    bool? isInitialized,
    String? error,
    DateTime? lastAuthenticatedAt,
    bool? isAuthorized,
    bool? isExternalOperationInProgress,
  }) {
    return SecurityState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      hasPin: hasPin ?? this.hasPin,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      isExternalOperationInProgress:
          isExternalOperationInProgress ?? this.isExternalOperationInProgress,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier() : super(SecurityState()) {
    _loadSettings();
  }

  final LocalAuthentication _auth = LocalAuthentication();
  static const _biometricKey = 'biometric_enabled';
  static const _pinKey = 'user_pin_code';

  Future<void> _loadSettings() async {

    state = state.copyWith(
      isBiometricEnabled: false,
      hasPin: false,
      isInitialized: true,
    );
  }

  Future<bool> canCheckBiometrics() async {
    return false;
  }

  Future<bool> authenticate() async {

    recordSuccessAuth();
    return true;
  }

  void recordSuccessAuth() {
    state = state.copyWith(
      lastAuthenticatedAt: DateTime.now(),
      isAuthorized: true,
    );
  }

  void deauthorize() {
    state = state.copyWith(isAuthorized: false);
  }

  Future<void> toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await authenticate();
      if (!authenticated) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
    state = state.copyWith(isBiometricEnabled: value);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    state = state.copyWith(hasPin: true);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_biometricKey, false);
    state = state.copyWith(hasPin: false, isBiometricEnabled: false);
  }

  Future<bool> verifyPin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);
    return savedPin == inputPin;
  }

  void setExternalOperation(bool value) {
    state = state.copyWith(isExternalOperationInProgress: value);
  }
}
