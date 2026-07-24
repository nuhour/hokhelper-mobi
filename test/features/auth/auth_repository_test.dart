import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';
import 'package:hok_helper_mobile/src/core/storage/secure_token_store.dart';
import 'package:hok_helper_mobile/src/features/auth/data/auth_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient([this.response = const {}])
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final Map<String, dynamic> response;
  String? path;
  Object? body;
  final calls = <({String path, Object? body})>[];

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    calls.add((path: path, body: body));
    return response;
  }
}

class _MemoryTokenStore extends SecureTokenStore {
  String? access;
  String? refresh;
  var didClear = false;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    didClear = true;
    access = null;
    refresh = null;
  }
}

void main() {
  group('AuthRepository', () {
    test('logs in with email and stores returned tokens', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'message': 'ok',
        'result': {
          'access': 'access-token',
          'refresh': 'refresh-token',
          'user': {
            'id': 42,
            'username': 'lam',
            'email': 'lam@example.test',
            'display_name': 'Lam',
            'avatar': 'https://example.test/avatar.png',
          },
        },
      });
      final tokenStore = _MemoryTokenStore();
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      );

      final user = await repository.loginWithEmail(
        'lam@example.test',
        'secret',
      );

      expect(apiClient.path, '/auth/email/login');
      expect(apiClient.body, {
        'email': 'lam@example.test',
        'password': 'secret',
      });
      expect(tokenStore.access, 'access-token');
      expect(tokenStore.refresh, 'refresh-token');
      expect(user.id, 42);
      expect(user.username, 'lam');
      expect(user.email, 'lam@example.test');
      expect(user.displayName, 'Lam');
      expect(user.avatar, 'https://example.test/avatar.png');
    });

    test('falls back to the top-level json when result is null', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'message': 'ok',
        'access': 'access-token',
        'refresh': 'refresh-token',
        'user': {'id': '7', 'username': 'top', 'email': 'top@example.test'},
      });
      final tokenStore = _MemoryTokenStore();
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      );

      final user = await repository.loginWithEmail(
        'top@example.test',
        'secret',
      );

      expect(tokenStore.access, 'access-token');
      expect(tokenStore.refresh, 'refresh-token');
      expect(user.id, 7);
      expect(user.displayName, isNull);
      expect(user.avatar, isNull);
    });

    test('preserves failed envelope message before parsing tokens', () async {
      final tokenStore = _MemoryTokenStore();
      final repository = AuthRepository(
        apiClient: _FakeApiClient({
          'success': false,
          'message': 'Invalid email or password',
          'result': null,
        }),
        tokenStore: tokenStore,
      );

      await expectLater(
        repository.loginWithEmail('lam@example.test', 'wrong'),
        throwsA(
          isA<ApiError>()
              .having((error) => error.kind, 'kind', ApiErrorKind.backend)
              .having(
                (error) => error.message,
                'message',
                'Invalid email or password',
              ),
        ),
      );
      expect(tokenStore.access, isNull);
      expect(tokenStore.refresh, isNull);
    });

    test('uses fallback message for failed envelope without message', () async {
      final repository = AuthRepository(
        apiClient: _FakeApiClient({'success': false}),
        tokenStore: _MemoryTokenStore(),
      );

      await expectLater(
        repository.loginWithEmail('lam@example.test', 'wrong'),
        throwsA(
          isA<ApiError>()
              .having((error) => error.kind, 'kind', ApiErrorKind.backend)
              .having((error) => error.message, 'message', 'Login failed'),
        ),
      );
    });

    test('logout clears token storage', () async {
      final tokenStore = _MemoryTokenStore()
        ..access = 'access-token'
        ..refresh = 'refresh-token';
      final repository = AuthRepository(
        apiClient: _FakeApiClient({}),
        tokenStore: tokenStore,
      );

      await repository.logout();

      expect(tokenStore.didClear, isTrue);
      expect(tokenStore.access, isNull);
      expect(tokenStore.refresh, isNull);
    });

    test('sends register code with turnstile token', () async {
      final apiClient = _FakeApiClient({'success': true});
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: _MemoryTokenStore(),
      );

      await repository.sendRegisterCode(
        email: 'lam@example.test',
        turnstileToken: 'turnstile-token',
      );

      expect(apiClient.path, '/auth/email/send_register_code');
      expect(apiClient.body, {
        'email': 'lam@example.test',
        'turnstile_token': 'turnstile-token',
      });
    });

    test('registers with email and stores returned tokens', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'result': {
          'access': 'access-token',
          'refresh': 'refresh-token',
          'user': {
            'id': 8,
            'username': 'new-user',
            'email': 'new@example.test',
            'first_name': 'Newbie',
          },
        },
      });
      final tokenStore = _MemoryTokenStore();
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      );

      final user = await repository.registerWithEmail(
        email: 'new@example.test',
        password: 'StrongPass1!',
        code: '123456',
        username: 'new-user',
      );

      expect(apiClient.path, '/auth/email/register');
      expect(apiClient.body, {
        'email': 'new@example.test',
        'password': 'StrongPass1!',
        'code': '123456',
        'username': 'new-user',
      });
      expect(tokenStore.access, 'access-token');
      expect(tokenStore.refresh, 'refresh-token');
      expect(user.id, 8);
      expect(user.displayName, 'Newbie');
    });

    test('requests OAuth URL with HTTPS callback and state', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'result': {'auth_url': 'https://accounts.example.test/authorize'},
      });
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: _MemoryTokenStore(),
      );

      final authUrl = await repository.getOAuthAuthorizationUrl(
        provider: 'Google',
        redirectUri: 'https://hokhelper.com/auth/google/callback',
        state: 'hokhelper-mobile.google.nonce',
      );

      expect(authUrl, 'https://accounts.example.test/authorize');
      expect(apiClient.path, '/auth/google/auth_url');
      expect(apiClient.body, {
        'redirect_uri': 'https://hokhelper.com/auth/google/callback',
        'state': 'hokhelper-mobile.google.nonce',
      });
    });

    test('logs in with OAuth provider callback code', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'result': {
          'access': 'oauth-access',
          'refresh': 'oauth-refresh',
          'user': {
            'id': 10,
            'username': 'oauth-user',
            'email': 'oauth@example.test',
          },
        },
      });
      final tokenStore = _MemoryTokenStore();
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      );

      final user = await repository.loginWithOAuth(
        provider: 'Google',
        code: 'callback-code',
        redirectUri: 'https://hokhelper.com/auth/google/callback',
      );

      expect(apiClient.path, '/auth/google/login');
      expect(apiClient.body, {
        'code': 'callback-code',
        'redirect_uri': 'https://hokhelper.com/auth/google/callback',
      });
      expect(tokenStore.access, 'oauth-access');
      expect(tokenStore.refresh, 'oauth-refresh');
      expect(user.id, 10);
      expect(user.username, 'oauth-user');
    });

    test('logs in with a native Google ID token', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'result': {
          'access': 'native-access',
          'refresh': 'native-refresh',
          'user': {
            'id': 11,
            'username': 'google-user',
            'email': 'google@example.test',
          },
        },
      });
      final tokenStore = _MemoryTokenStore();
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      );

      final user = await repository.loginWithGoogleIdToken('google-id-token');

      expect(apiClient.path, '/auth/google/login');
      expect(apiClient.body, {'id_token': 'google-id-token'});
      expect(tokenStore.access, 'native-access');
      expect(tokenStore.refresh, 'native-refresh');
      expect(user.id, 11);
    });

    test('rejects unsupported OAuth providers before calling API', () async {
      final apiClient = _FakeApiClient({'success': true});
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStore: _MemoryTokenStore(),
      );

      await expectLater(
        repository.loginWithOAuth(
          provider: 'github',
          code: 'callback-code',
          redirectUri: 'https://hokhelper.com/auth/github/callback',
        ),
        throwsA(
          isA<ApiError>().having(
            (error) => error.message,
            'message',
            'Unsupported OAuth provider',
          ),
        ),
      );
      expect(apiClient.calls, isEmpty);
    });

    test(
      'sends and verifies forgot password code then resets password',
      () async {
        final apiClient = _FakeApiClient({'success': true});
        final repository = AuthRepository(
          apiClient: apiClient,
          tokenStore: _MemoryTokenStore(),
        );

        await repository.sendVerificationCode('lam@example.test');
        await repository.verifyCode(email: 'lam@example.test', code: '654321');
        await repository.resetForgottenPassword(
          email: 'lam@example.test',
          code: '654321',
          newPassword: 'NewStrongPass1!',
        );

        expect(apiClient.calls.map((call) => call.path), [
          '/auth/email/send_verification_code',
          '/auth/email/verify_code',
          '/auth/email/forgot_password_reset',
        ]);
        expect(apiClient.calls[0].body, {'email': 'lam@example.test'});
        expect(apiClient.calls[1].body, {
          'email': 'lam@example.test',
          'code': '654321',
        });
        expect(apiClient.calls[2].body, {
          'email': 'lam@example.test',
          'code': '654321',
          'new_password': 'NewStrongPass1!',
        });
      },
    );
  });
}
