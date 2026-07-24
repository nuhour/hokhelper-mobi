import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../data/native_google_sign_in.dart';
import 'auth_page_scaffold.dart';
import 'auth_controller.dart';

typedef OAuthUrlOpener =
    Future<void> Function({required String provider, required String url});

final oauthUrlOpenerProvider = Provider<OAuthUrlOpener>((ref) {
  return ({required provider, required url}) async {
    const channel = MethodChannel('hokhelper/open_url');
    final launched = await channel.invokeMethod<bool>('openOAuthUrl', {
      'provider': provider,
      'url': url,
    });
    if (launched != true) {
      throw StateError('Unable to open OAuth authorization URL.');
    }
  };
});

final nativeGoogleSignInProvider = Provider<NativeGoogleSignIn>((ref) {
  return GoogleFrameworkSignIn();
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

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
        context.go('/me');
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

    try {
      final repository = ref.read(authRepositoryProvider);
      final stateStore = ref.read(oauthStateStoreProvider);
      final state = await stateStore.create(provider);
      final redirectUri = AppConfig.current.oauthRedirectUri(provider);
      final authUrl = await repository.getOAuthAuthorizationUrl(
        provider: provider,
        redirectUri: redirectUri,
        state: state,
      );
      if (provider == 'google') {
        final nativeResult = await _tryNativeGoogleSignIn(
          repository: repository,
          authUrl: authUrl,
        );
        if (nativeResult == NativeGoogleSignInStatus.authenticated) {
          await stateStore.clear(provider);
          if (mounted) {
            context.go('/me');
          }
          return;
        }
        if (nativeResult == NativeGoogleSignInStatus.cancelled) {
          await stateStore.clear(provider);
          return;
        }
      }

      await ref.read(oauthUrlOpenerProvider)(provider: provider, url: authUrl);
    } catch (error) {
      await ref.read(oauthStateStoreProvider).clear(provider);
      if (mounted) {
        setState(() {
          _oauthError = 'Failed to start OAuth login. ${error.toString()}';
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

  Future<NativeGoogleSignInStatus> _tryNativeGoogleSignIn({
    required AuthRepository repository,
    required String authUrl,
  }) async {
    final serverClientId =
        Uri.tryParse(authUrl)?.queryParameters['client_id']?.trim() ?? '';
    final result = await ref
        .read(nativeGoogleSignInProvider)
        .authenticate(serverClientId: serverClientId);
    final idToken = result.idToken;
    if (result.status != NativeGoogleSignInStatus.authenticated ||
        idToken == null) {
      return result.status;
    }

    try {
      await repository.loginWithGoogleIdToken(idToken);
      ref.invalidate(authControllerProvider);
      return NativeGoogleSignInStatus.authenticated;
    } catch (_) {
      // Older server deployments may not accept native ID tokens yet.
      return NativeGoogleSignInStatus.unavailable;
    }
  }
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
