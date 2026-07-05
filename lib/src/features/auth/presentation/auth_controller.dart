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

  Future<void> loginWithOAuth({
    required String provider,
    required String code,
    required String redirectUri,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    try {
      final user = await repository.loginWithOAuth(
        provider: provider,
        code: code,
        redirectUri: redirectUri,
      );
      state = AsyncData(user);
    } on ApiError catch (error, stackTrace) {
      if (_shouldClearSession(error)) {
        await repository.logout();
      }
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String code,
    String? username,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    try {
      final user = await repository.registerWithEmail(
        email: email,
        password: password,
        code: code,
        username: username,
      );
      state = AsyncData(user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> sendRegisterCode({
    required String email,
    required String turnstileToken,
  }) {
    return ref
        .read(authRepositoryProvider)
        .sendRegisterCode(email: email, turnstileToken: turnstileToken);
  }

  Future<void> sendVerificationCode(String email) {
    return ref.read(authRepositoryProvider).sendVerificationCode(email);
  }

  Future<void> verifyCode({required String email, required String code}) {
    return ref
        .read(authRepositoryProvider)
        .verifyCode(email: email, code: code);
  }

  Future<void> resetForgottenPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repository.resetForgottenPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      state = const AsyncData(null);
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
