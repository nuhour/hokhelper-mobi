import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    ref.watch(authSessionInvalidationProvider);
    final accessToken = await ref.read(tokenStoreProvider).readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      return const AuthUser(
        id: 0,
        username: 'Signed in',
        email: 'Signed in',
        displayName: 'Signed in',
      );
    }

    return null;
  }

  Future<void> login(String email, String password) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    try {
      final user = await repository.loginWithEmail(email, password);
      state = AsyncData(user);
    } on ApiError catch (error, stackTrace) {
      if (_shouldClearSession(error)) {
        await repository.logout();
      }
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  bool _shouldClearSession(ApiError error) {
    return error.kind == ApiErrorKind.authExpired ||
        error.kind == ApiErrorKind.forbidden;
  }
}
