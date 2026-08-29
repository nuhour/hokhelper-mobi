import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/data/oauth_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('creates a provider-bound state and consumes it once', () async {
    final store = OAuthStateStore();
    final state = await store.create('Google');

    expect(
      state,
      matches(RegExp(r'^hokhelper-mobile\.google\.[A-Za-z0-9_-]{43}$')),
    );
    expect(await store.consume(provider: 'google', state: state), isTrue);
    expect(await store.consume(provider: 'google', state: state), isFalse);
  });

  test('rejects a state created for another provider', () async {
    final store = OAuthStateStore();
    final state = await store.create('google');

    expect(await store.consume(provider: 'discord', state: state), isFalse);
  });

  test('stores and consumes a provider-bound PKCE verifier once', () async {
    final store = OAuthStateStore();
    await store.saveCodeVerifier(
      provider: 'Discord',
      codeVerifier: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO0123456789-._~',
    );

    expect(
      await store.consumeCodeVerifier('discord'),
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO0123456789-._~',
    );
    expect(await store.consumeCodeVerifier('discord'), isNull);
  });

  test(
    'stores and consumes the redirect URI for the same OAuth attempt',
    () async {
      final store = OAuthStateStore();
      await store.saveRedirectUri(
        provider: 'Discord',
        redirectUri: 'discord-123:/authorize/callback',
      );

      expect(
        await store.consumeRedirectUri('discord'),
        'discord-123:/authorize/callback',
      );
      expect(await store.consumeRedirectUri('discord'), isNull);
    },
  );

  test('clears verifier and redirect URI when state does not match', () async {
    final store = OAuthStateStore();
    await store.create('discord');
    await store.saveCodeVerifier(
      provider: 'discord',
      codeVerifier: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO0123456789-._~',
    );
    await store.saveRedirectUri(
      provider: 'discord',
      redirectUri: 'discord-123:/authorize/callback',
    );

    expect(
      await store.consume(provider: 'discord', state: 'wrong-state'),
      isFalse,
    );
    expect(await store.consumeCodeVerifier('discord'), isNull);
    expect(await store.consumeRedirectUri('discord'), isNull);
  });

  test('clearAll removes pending state from every OAuth provider', () async {
    final store = OAuthStateStore();
    final googleState = await store.create('google');
    final discordState = await store.create('discord');
    await store.saveCodeVerifier(
      provider: 'discord',
      codeVerifier: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO0123456789-._~',
    );

    await store.clearAll();

    expect(
      await store.consume(provider: 'google', state: googleState),
      isFalse,
    );
    expect(
      await store.consume(provider: 'discord', state: discordState),
      isFalse,
    );
    expect(await store.consumeCodeVerifier('discord'), isNull);
  });
}
