import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE helpers for mobile OAuth callbacks.
class OAuthPkce {
  const OAuthPkce._();

  static String generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String createCodeChallenge(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}
