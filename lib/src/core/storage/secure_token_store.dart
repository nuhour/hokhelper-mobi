import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'auth_access_token';
  static const refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: refreshTokenKey);
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: accessTokenKey, value: access);
    await _storage.write(key: refreshTokenKey, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }
}
