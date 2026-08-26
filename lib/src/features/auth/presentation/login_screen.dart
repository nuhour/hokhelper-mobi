import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../data/native_apple_sign_in.dart';
import '../data/native_google_sign_in.dart';
import '../data/oauth_pkce.dart';
import 'auth_page_scaffold.dart';
import 'auth_controller.dart';

typedef OAuthUrlOpener =
    Future<void> Function({required String provider, required String url});

final oauthUrlOpenerProvider = Provider<OAuthUrlOpener>((ref) {
  return ({required provider, required url}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw StateError('Invalid OAuth authorization URL.');
    }

    var launched = false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        const channel = MethodChannel('hokhelper/open_url');
        launched =
            await channel.invokeMethod<bool>('openOAuthUrl', {
              'provider': provider,
              'url': url,
            }) ??
            false;
      } on MissingPluginException {
        launched = false;
      }
    }
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!launched) {
      throw StateError('Unable to open OAuth authorization URL.');
    }
  };
});

final nativeGoogleSignInProvider = Provider<NativeGoogleSignIn>((ref) {
  return GoogleFrameworkSignIn();
});

final nativeAppleSignInProvider = Provider<NativeAppleSignIn>((ref) {
  return AppleFrameworkSignIn();
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _emailController = TextEditingController(
    text: AppConfig.loginEmail,
  );
  late final _passwordController = TextEditingController(
    text: AppConfig.loginPassword,
  );
  String? _oauthLoadingProvider;
  String? _oauthError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isOAuthLoading = _oauthLoadingProvider != null;
    final error = authState.hasError ? authState.error.toString() : null;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null && mounted) {
        context.go(_safeReturnRoute(widget.returnTo));
      }
    });

    return AuthPageScaffold(
      title: 'Sign in',
      fallbackRoute: '/me',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome to HOK Helper',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to sync your builds, tier lists, and community activity.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.hokTheme.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.hokTheme.surfaceSlate,
                      border: Border.all(color: context.hokTheme.outlineSoft),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quick sign in',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceStrong,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Continue securely with your existing account.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceMuted,
                              ),
                        ),
                        const SizedBox(height: 14),
                        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                          IgnorePointer(
                            ignoring: isLoading || isOAuthLoading,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 160),
                              opacity: isLoading || isOAuthLoading ? 0.55 : 1,
                              child: SignInWithAppleButton(
                                onPressed: () => _startOAuth('apple'),
                                style:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? SignInWithAppleButtonStyle.white
                                    : SignInWithAppleButtonStyle.black,
                                height: 54,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _OAuthButton(
                          provider: 'google',
                          label: 'Continue with Google',
                          isLoading: _oauthLoadingProvider == 'google',
                          enabled: !isLoading && !isOAuthLoading,
                          onPressed: () => _startOAuth('google'),
                        ),
                        const SizedBox(height: 10),
                        _OAuthButton(
                          provider: 'discord',
                          label: 'Continue with Discord',
                          isLoading: _oauthLoadingProvider == 'discord',
                          enabled: !isLoading && !isOAuthLoading,
                          onPressed: () => _startOAuth('discord'),
                        ),
                        if (_oauthError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _oauthError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with email',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceMuted,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    enabled: !isLoading,
                    onSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: isLoading || isOAuthLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'New to HOK Helper?',
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go('/register'),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    ref.read(authControllerProvider.notifier).login(email, password);
  }

  Future<void> _startOAuth(String provider) async {
    setState(() {
      _oauthLoadingProvider = provider;
      _oauthError = null;
    });

    String? nativeGoogleError;
    try {
      final repository = ref.read(authRepositoryProvider);
      if (provider == 'apple') {
        final result = await ref.read(nativeAppleSignInProvider).authenticate();
        if (result.status == NativeAppleSignInStatus.cancelled) {
          return;
        }
        if (result.status != NativeAppleSignInStatus.authenticated ||
            result.identityToken == null ||
            result.rawNonce == null) {
          throw StateError(
            result.error ?? 'Sign in with Apple is unavailable.',
          );
        }
        await repository.loginWithAppleIdentityToken(
          identityToken: result.identityToken!,
          rawNonce: result.rawNonce!,
          name: result.name,
        );
        ref.invalidate(authControllerProvider);
        if (mounted) {
          context.go(_safeReturnRoute(widget.returnTo));
        }
        return;
      }
      if (provider == 'google') {
        final nativeResult = await _tryNativeGoogleSignIn(
          repository: repository,
          serverClientId: AppConfig.googleServerClientId,
        );
        if (nativeResult.status == NativeGoogleSignInStatus.authenticated) {
          if (mounted) {
            context.go(_safeReturnRoute(widget.returnTo));
          }
          return;
        }
        // Credential Manager may report a configuration error as "canceled".
        // Continue to the web flow for both cases instead of leaving the user
        // on the login page with no visible response.
        nativeGoogleError = nativeResult.error;
      }

      final stateStore = ref.read(oauthStateStoreProvider);
      final state = await stateStore.create(provider);
      final redirectUri = AppConfig.current.oauthRedirectUri(provider);
      await stateStore.saveRedirectUri(
        provider: provider,
        redirectUri: redirectUri,
      );
      String? codeVerifier;
      if (provider == 'discord') {
        codeVerifier = OAuthPkce.generateCodeVerifier();
        await stateStore.saveCodeVerifier(
          provider: provider,
          codeVerifier: codeVerifier,
        );
      }
      final authUrl = await repository.getOAuthAuthorizationUrl(
        provider: provider,
        redirectUri: redirectUri,
        state: state,
        codeChallenge: codeVerifier == null
            ? null
            : OAuthPkce.createCodeChallenge(codeVerifier),
      );

      if (provider == 'discord' &&
          codeVerifier != null &&
          !_hasOAuthQueryParameter(authUrl, 'code_challenge')) {
        // Keep the custom callback for an older deployed API, but do not send
        // a verifier to its token exchange because that API did not include
        // the challenge in Discord's authorization request.
        await stateStore.clearCodeVerifier(provider);
      }

      await ref.read(oauthUrlOpenerProvider)(provider: provider, url: authUrl);
    } catch (error) {
      await ref.read(oauthStateStoreProvider).clear(provider);
      if (mounted) {
        setState(() {
          final nativeDetail = nativeGoogleError == null
              ? ''
              : ' $nativeGoogleError';
          _oauthError =
              'Failed to start OAuth login.$nativeDetail ${error.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _oauthLoadingProvider = null;
        });
      }
    }
  }

  Future<NativeGoogleSignInResult> _tryNativeGoogleSignIn({
    required AuthRepository repository,
    required String serverClientId,
  }) async {
    final result = await ref
        .read(nativeGoogleSignInProvider)
        .authenticate(serverClientId: serverClientId)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => const NativeGoogleSignInResult.unavailable(
            'Google sign-in timed out. Continuing with browser sign-in.',
          ),
        );
    final idToken = result.idToken;
    if (result.status != NativeGoogleSignInStatus.authenticated ||
        idToken == null) {
      // Device-side Google configuration differs between stores and debug
      // signatures. Keep the browser OAuth path available when Play Services
      // cannot issue an ID token instead of leaving the user at a dead end.
      return result;
    }

    try {
      await repository.loginWithGoogleIdToken(idToken);
      ref.invalidate(authControllerProvider);
      return result;
    } catch (error) {
      // A token can be issued before an older backend has been deployed with
      // the ID-token endpoint. Continue with the web flow in that case.
      return NativeGoogleSignInResult.unavailable(
        'Native Google sign-in could not be completed: $error',
      );
    }
  }
}

bool _hasOAuthQueryParameter(String url, String name) {
  final uri = Uri.tryParse(url);
  return uri != null && uri.queryParameters.containsKey(name);
}

String _safeReturnRoute(String? value) {
  final route = value?.trim() ?? '';
  return route.startsWith('/') && !route.startsWith('//') ? route : '/me';
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.provider,
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final String provider;
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider == 'google';
    final backgroundColor = isGoogle ? Colors.white : const Color(0xFF5865F2);
    final foregroundColor = isGoogle ? const Color(0xFF202124) : Colors.white;

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
        disabledForegroundColor: foregroundColor.withValues(alpha: 0.65),
        side: BorderSide(
          color: isGoogle ? const Color(0xFFDADCE0) : const Color(0xFF7289DA),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      icon: isLoading
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor,
              ),
            )
          : isGoogle
          ? const _GoogleMark()
          : const Icon(Icons.discord_rounded, size: 22),
      label: Text(label),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 22,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
