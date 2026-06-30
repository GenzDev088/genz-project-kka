import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _pinKey = 'user_pin';
  static const String _sessionIdKey = 'session_id';
  static const String _userIdKey = 'user_id';
  static const String _tokenExpiryKey = 'token_expiry';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();


  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }


  Future<void> savePinHash(String pinHash) async {
    await _storage.write(key: _pinKey, value: pinHash);
  }

  Future<String?> getPinHash() async {
    return await _storage.read(key: _pinKey);
  }

  Future<void> deletePinHash() async {
    await _storage.delete(key: _pinKey);
  }


  Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: _sessionIdKey, value: sessionId);
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: _sessionIdKey);
  }

  Future<void> deleteSessionId() async {
    await _storage.delete(key: _sessionIdKey);
  }


  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }


  Future<void> saveTokenExpiry(String expiry) async {
    await _storage.write(key: _tokenExpiryKey, value: expiry);
  }

  Future<String?> getTokenExpiry() async {
    return await _storage.read(key: _tokenExpiryKey);
  }


  Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }


  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _sessionIdKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _tokenExpiryKey),
    ]);
  }


  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _sessionIdKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _tokenExpiryKey),
    ]);
  }


  Future<void> hardLogout() async {
    await clearAll();
    await _storage.delete(key: _pinKey);
  }
}
