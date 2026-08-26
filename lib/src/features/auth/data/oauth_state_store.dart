import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OAuthStateStore {
  OAuthStateStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyPrefix = 'oauth_pending_state_';
  static const _verifierKeyPrefix = 'oauth_pending_code_verifier_';
  static const _redirectUriKeyPrefix = 'oauth_pending_redirect_uri_';
  static const _statePrefix = 'hokhelper-mobile';

  final FlutterSecureStorage _storage;

  Future<String> create(String provider) async {
    final normalizedProvider = provider.trim().toLowerCase();
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final nonce = base64UrlEncode(bytes).replaceAll('=', '');
    final state = '$_statePrefix.$normalizedProvider.$nonce';
    await _storage.write(key: _key(normalizedProvider), value: state);
    // A new authorization attempt supersedes any interrupted attempt for the
    // same provider. This prevents a stale verifier or redirect URI from
    // being paired with a fresh callback.
    await _storage.delete(key: _verifierKey(normalizedProvider));
    await _storage.delete(key: _redirectUriKey(normalizedProvider));
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
    final isValid = expected != null && state != null && expected == state;
    if (!isValid) {
      // A mismatched callback must not leave a PKCE verifier available for a
      // later callback attempt.
      await _storage.delete(key: _verifierKey(normalizedProvider));
      await _storage.delete(key: _redirectUriKey(normalizedProvider));
    }
    return isValid;
  }

  Future<void> saveCodeVerifier({
    required String provider,
    required String codeVerifier,
  }) {
    return _storage.write(
      key: _verifierKey(provider.trim().toLowerCase()),
      value: codeVerifier,
    );
  }

  Future<String?> consumeCodeVerifier(String provider) async {
    final key = _verifierKey(provider.trim().toLowerCase());
    final verifier = await _storage.read(key: key);
    await _storage.delete(key: key);
    return verifier;
  }

  Future<void> clearCodeVerifier(String provider) {
    return _storage.delete(key: _verifierKey(provider.trim().toLowerCase()));
  }

  Future<void> saveRedirectUri({
    required String provider,
    required String redirectUri,
  }) {
    return _storage.write(
      key: _redirectUriKey(provider.trim().toLowerCase()),
      value: redirectUri,
    );
  }

  Future<String?> consumeRedirectUri(String provider) async {
    final key = _redirectUriKey(provider.trim().toLowerCase());
    final redirectUri = await _storage.read(key: key);
    await _storage.delete(key: key);
    return redirectUri;
  }

  Future<void> clear(String provider) async {
    final normalizedProvider = provider.trim().toLowerCase();
    await _storage.delete(key: _key(normalizedProvider));
    await _storage.delete(key: _verifierKey(normalizedProvider));
    await _storage.delete(key: _redirectUriKey(normalizedProvider));
  }

  String _key(String provider) => '$_keyPrefix$provider';

  String _verifierKey(String provider) => '$_verifierKeyPrefix$provider';

  String _redirectUriKey(String provider) => '$_redirectUriKeyPrefix$provider';
}
