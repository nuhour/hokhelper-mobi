import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';
import 'package:hok_helper_mobile/src/core/storage/secure_token_store.dart';
import 'package:hok_helper_mobile/src/features/auth/data/auth_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response)
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final Map<String, dynamic> response;
  String? path;
  Object? body;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
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
  });
}
