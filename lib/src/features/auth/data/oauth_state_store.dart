import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OAuthStateStore {
  OAuthStateStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyPrefix = 'oauth_pending_state_';
  static const _statePrefix = 'hokhelper-mobile';

  final FlutterSecureStorage _storage;

  Future<String> create(String provider) async {
    final normalizedProvider = provider.trim().toLowerCase();
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final nonce = base64UrlEncode(bytes).replaceAll('=', '');
    final state = '$_statePrefix.$normalizedProvider.$nonce';
    await _storage.write(key: _key(normalizedProvider), value: state);
    return state;
  }

  Future<bool> consume({
    required String provider,
    required String? state,
  }) async {
    final normalizedProvider = provider.trim().toLowerCase();
    final key = _key(normalizedProvider);
    final expected = await _storage.read(key: key);
    await _storage.delete(key: key);
    return expected != null && state != null && expected == state;
  }

  Future<void> clear(String provider) {
    return _storage.delete(key: _key(provider.trim().toLowerCase()));
  }

  String _key(String provider) => '$_keyPrefix$provider';
}
