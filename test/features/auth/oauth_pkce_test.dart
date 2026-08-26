import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/data/oauth_pkce.dart';

void main() {
  test('creates a URL-safe verifier and S256 challenge', () {
    final verifier = OAuthPkce.generateCodeVerifier();
    final challenge = OAuthPkce.createCodeChallenge('a' * 43);

    expect(verifier, hasLength(86));
    expect(verifier, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(challenge, 'ZtNPunH49FD35FWYhT5Tv8I7vRKQJ8uxMaL0_9eHjNA');
    expect(challenge, isNot(contains('=')));
  });
}
