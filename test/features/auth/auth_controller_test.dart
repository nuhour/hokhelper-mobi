import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';
import 'package:hok_helper_mobile/src/core/providers/core_providers.dart';
import 'package:hok_helper_mobile/src/core/storage/secure_token_store.dart';
import 'package:hok_helper_mobile/src/features/auth/data/auth_repository.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';

class _MemoryTokenStore extends SecureTokenStore {
  String? access;
  String? refresh;
  var didClear = false;

  @override
  Future<String?> readAccessToken() async {
    return access;
  }

  @override
  Future<String?> readRefreshToken() async {
    return refresh;
  }

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

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.tokenStore});

  @override
  final SecureTokenStore tokenStore;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  AuthUser? userToReturn;
  ApiError? errorToThrow;
  var didLogout = false;

  @override
  Future<AuthUser> loginWithEmail(String email, String password) async {
    final error = errorToThrow;
    if (error != null) {
      throw error;
    }

    return userToReturn ??
        const AuthUser(
          id: 99,
          username: 'lam',
          email: 'lam@example.test',
          displayName: 'Lam',
        );
  }

  @override
  Future<void> logout() async {
    didLogout = true;
    await tokenStore.clear();
  }
}

void main() {
  group('AuthController', () {
    test('restores a lightweight signed-in session when access token exists', () async {
      final tokenStore = _MemoryTokenStore()..access = 'access-token';
      final container = ProviderContainer(
        overrides: [tokenStoreProvider.overrideWithValue(tokenStore)],
      );
      addTearDown(container.dispose);

      final state = await container.read(authControllerProvider.future);

      expect(state, isNotNull);
      expect(state!.id, 0);
      expect(state.username, 'Signed in');
      expect(state.email, 'Signed in');
      expect(state.displayName, 'Signed in');
    });

    test('successful login updates auth state with returned user', () async {
      final tokenStore = _MemoryTokenStore();
      final repository = _FakeAuthRepository(tokenStore: tokenStore)
        ..userToReturn = const AuthUser(
          id: 7,
          username: 'mulan',
          email: 'mulan@example.test',
          displayName: 'Mulan',
        );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).login(
        'mulan@example.test',
        'secret',
      );

      final state = container.read(authControllerProvider);
      expect(state.valueOrNull?.id, 7);
      expect(state.valueOrNull?.displayName, 'Mulan');
    });

    test('auth expiry during login clears tokens and exposes error state', () async {
      final tokenStore = _MemoryTokenStore()
        ..access = 'access-token'
        ..refresh = 'refresh-token';
      final repository = _FakeAuthRepository(tokenStore: tokenStore)
        ..errorToThrow = const ApiError(
          kind: ApiErrorKind.authExpired,
          message: 'Expired',
          statusCode: 401,
        );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).login(
        'mulan@example.test',
        'secret',
      );

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(tokenStore.didClear, isTrue);
      expect(tokenStore.access, isNull);
      expect(tokenStore.refresh, isNull);
    });

    test('forbidden login clears tokens and exposes error state', () async {
      final tokenStore = _MemoryTokenStore()
        ..access = 'access-token'
        ..refresh = 'refresh-token';
      final repository = _FakeAuthRepository(tokenStore: tokenStore)
        ..errorToThrow = const ApiError(
          kind: ApiErrorKind.forbidden,
          message: 'Forbidden',
          statusCode: 403,
        );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).login(
        'mulan@example.test',
        'secret',
      );

      expect(container.read(authControllerProvider).hasError, isTrue);
      expect(tokenStore.didClear, isTrue);
      expect(tokenStore.access, isNull);
      expect(tokenStore.refresh, isNull);
    });

    test('logout clears user state', () async {
      final tokenStore = _MemoryTokenStore();
      final repository = _FakeAuthRepository(tokenStore: tokenStore)
        ..userToReturn = const AuthUser(
          id: 7,
          username: 'mulan',
          email: 'mulan@example.test',
        );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).login(
        'mulan@example.test',
        'secret',
      );
      await container.read(authControllerProvider.notifier).logout();

      expect(repository.didLogout, isTrue);
      expect(container.read(authControllerProvider).valueOrNull, isNull);
    });
  });
}
