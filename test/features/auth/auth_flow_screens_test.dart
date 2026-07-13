import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/storage/secure_token_store.dart';
import 'package:hok_helper_mobile/src/core/providers/core_providers.dart';
import 'package:hok_helper_mobile/src/features/auth/data/auth_repository.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/login_screen.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/oauth_callback_screen.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/register_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.tokenStore});

  @override
  final SecureTokenStore tokenStore;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  var didRegister = false;
  var didReset = false;
  var didOAuthLogin = false;
  var requestedOAuthProvider = '';
  var requestedOAuthRedirectUri = '';
  String? oauthProvider;
  String? oauthCode;
  String? oauthRedirectUri;

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String code,
    String? username,
  }) async {
    didRegister = true;
    return AuthUser(
      id: 12,
      username: username ?? 'registered',
      email: email,
      displayName: username,
    );
  }

  @override
  Future<void> resetForgottenPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    didReset = true;
  }

  @override
  Future<AuthUser> loginWithOAuth({
    required String provider,
    required String code,
    required String redirectUri,
  }) async {
    didOAuthLogin = true;
    oauthProvider = provider;
    oauthCode = code;
    oauthRedirectUri = redirectUri;
    return const AuthUser(
      id: 27,
      username: 'oauth-user',
      email: 'oauth@example.test',
      displayName: 'OAuth User',
    );
  }

  @override
  Future<String> getOAuthAuthorizationUrl({
    required String provider,
    required String redirectUri,
  }) async {
    requestedOAuthProvider = provider;
    requestedOAuthRedirectUri = redirectUri;
    return 'https://oauth.example.test/$provider?redirect_uri=$redirectUri';
  }
}

class _NoopTokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('login screen uses build-provided credential defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Email'))
          .controller!
          .text,
      AppConfig.loginEmail,
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Password'))
          .controller!
          .text,
      AppConfig.loginPassword,
    );
  });

  testWidgets('login screen links to register', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/me', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(_NoopTokenStore())],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final createAccountButton = find.widgetWithText(
      TextButton,
      'Create account',
    );
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/register');
  });

  testWidgets('login screen links to forgot password', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/me', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(_NoopTokenStore())],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final forgotPasswordButton = find.widgetWithText(
      TextButton,
      'Forgot password?',
    );
    await tester.ensureVisible(forgotPasswordButton);
    await tester.tap(forgotPasswordButton);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/forgot-password',
    );
  });

  testWidgets('login screen starts Google and Discord OAuth', (tester) async {
    final repository = _FakeAuthRepository(tokenStore: _NoopTokenStore());
    final openedUrls = <String>[];
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/me', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_NoopTokenStore()),
          authRepositoryProvider.overrideWithValue(repository),
          oauthUrlOpenerProvider.overrideWithValue((url) async {
            openedUrls.add(url);
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Sign in with Google'),
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Sign in with Google'),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.requestedOAuthProvider, 'google');
    expect(
      repository.requestedOAuthRedirectUri,
      'hokhelper://auth/google/callback',
    );
    expect(openedUrls.single, contains('https://oauth.example.test/google'));

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Sign in with Discord'),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.requestedOAuthProvider, 'discord');
    expect(
      repository.requestedOAuthRedirectUri,
      'hokhelper://auth/discord/callback',
    );
    expect(openedUrls.last, contains('https://oauth.example.test/discord'));
  });

  testWidgets('register screen submits email registration', (tester) async {
    final repository = _FakeAuthRepository(tokenStore: _NoopTokenStore());

    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(path: '/login', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/me', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_NoopTokenStore()),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'new@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Username'),
      'newbie',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Verification code'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'StrongPass1!',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Register'));
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.didRegister, isTrue);
  });

  testWidgets('forgot password screen submits reset', (tester) async {
    final repository = _FakeAuthRepository(tokenStore: _NoopTokenStore());

    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_NoopTokenStore()),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'lam@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Verification code'),
      '654321',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'NewStrongPass1!',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Reset password'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.didReset, isTrue);
  });

  testWidgets('OAuth callback exchanges code and opens me tab', (tester) async {
    final repository = _FakeAuthRepository(tokenStore: _NoopTokenStore());
    final router = GoRouter(
      initialLocation: '/auth/google/callback?code=mobile-code',
      routes: [
        GoRoute(
          path: '/auth/google/callback',
          builder: (_, state) => OAuthCallbackScreen(
            provider: 'google',
            code: state.uri.queryParameters['code'],
            error: state.uri.queryParameters['error'],
          ),
        ),
        GoRoute(path: '/me', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_NoopTokenStore()),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.didOAuthLogin, isTrue);
    expect(repository.oauthProvider, 'google');
    expect(repository.oauthCode, 'mobile-code');
    expect(repository.oauthRedirectUri, 'hokhelper://auth/google/callback');
    expect(router.routerDelegate.currentConfiguration.uri.path, '/me');
  });

  testWidgets('OAuth callback shows an error when code is missing', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(tokenStore: _NoopTokenStore());
    final router = GoRouter(
      initialLocation: '/auth/discord/callback',
      routes: [
        GoRoute(
          path: '/auth/discord/callback',
          builder: (_, state) => OAuthCallbackScreen(
            provider: 'discord',
            code: state.uri.queryParameters['code'],
            error: state.uri.queryParameters['error'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_NoopTokenStore()),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.didOAuthLogin, isFalse);
    expect(find.text('Missing OAuth callback code.'), findsOneWidget);
  });
}
