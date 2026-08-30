import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/feedback/app_notice.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isOAuthLoading = _oauthLoadingProvider != null;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError && mounted) {
        AppNotice.error(context, next.error!);
      }
      if (next.hasValue && next.value != null && mounted) {
        context.go(_safeReturnRoute(widget.returnTo));
      }
    });

    return AuthPageScaffold(
      title: l10n.translate('authSignInTitle'),
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
                    _formatWelcomeTitle(l10n.translate('authWelcome')),
                    key: const ValueKey('auth-welcome-title'),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.translate('authSignInSubtitle'),
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
                          l10n.translate('authQuickSignIn'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceStrong,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.translate('authContinueSecurely'),
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
                          label: l10n.translate('authContinueGoogle'),
                          isLoading: _oauthLoadingProvider == 'google',
                          enabled: !isLoading && !isOAuthLoading,
                          onPressed: () => _startOAuth('google'),
                        ),
                        const SizedBox(height: 10),
                        _OAuthButton(
                          provider: 'discord',
                          label: l10n.translate('authContinueDiscord'),
                          isLoading: _oauthLoadingProvider == 'discord',
                          enabled: !isLoading && !isOAuthLoading,
                          onPressed: () => _startOAuth('discord'),
                        ),
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
                          l10n.translate('authOrContinueWithEmail'),
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
                    decoration: InputDecoration(
                      labelText: l10n.translate('authEmailLabel'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l10n.translate('authPasswordLabel'),
                      prefixIcon: const Icon(Icons.lock_outline),
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
                      child: Text(l10n.translate('authForgotPassword')),
                    ),
                  ),
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
                        : Text(l10n.translate('authLogin')),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.translate('authNewToHok'),
                        style: TextStyle(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go('/register'),
                        child: Text(l10n.translate('authCreateAccount')),
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
    ref
        .read(authControllerProvider.notifier)
        .login(
          email,
          password,
          languageCode: Localizations.localeOf(context).languageCode,
        );
  }

  Future<void> _startOAuth(String provider) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _oauthLoadingProvider = provider;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final stateStore = ref.read(oauthStateStoreProvider);
      await stateStore.clearAll();
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
          languageCode: languageCode,
        );
        ref.invalidate(authControllerProvider);
        if (mounted) {
          context.go(_safeReturnRoute(widget.returnTo));
        }
        return;
      }
      if (provider == 'google') {
        final nativeResult = await _tryNativeGoogleSignIn(
          serverClientId: AppConfig.googleServerClientId,
          languageCode: languageCode,
        );
        if (nativeResult.status == NativeGoogleSignInStatus.authenticated) {
          if (mounted) {
            context.go(_safeReturnRoute(widget.returnTo));
          }
          return;
        }
        // Android/iOS 的 Google 登录只走系统原生凭据链。这里停止而不是
        // 回退到网站浏览器，避免浏览器里残留的 Discord 会话被当成结果。
        if (nativeResult.status == NativeGoogleSignInStatus.cancelled &&
            (nativeResult.error == null || nativeResult.error!.isEmpty)) {
          return;
        }
        throw StateError(
          nativeResult.error ??
              'Google sign-in is unavailable. Please update the app and try again.',
        );
      }

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
        languageCode: languageCode,
      );

      if (provider == 'discord' &&
          codeVerifier != null &&
          !_hasOAuthQueryParameter(authUrl, 'code_challenge')) {
        // Discord 的移动端自定义回调必须使用 PKCE；当前后端未返回
        // challenge 时不启动一个不完整的授权请求。
        throw StateError('Discord mobile OAuth is not ready.');
      }

      await ref.read(oauthUrlOpenerProvider)(provider: provider, url: authUrl);
    } catch (error) {
      await ref.read(oauthStateStoreProvider).clear(provider);
      if (mounted) {
        AppNotice.error(context, error, fallbackKey: 'authOAuthStartFailed');
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
    required String serverClientId,
    required String languageCode,
  }) async {
    final result = await ref
        .read(nativeGoogleSignInProvider)
        .authenticate(serverClientId: serverClientId)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => const NativeGoogleSignInResult.unavailable(
            'Google sign-in timed out. Please try again.',
          ),
        );
    final idToken = result.idToken;
    if (result.status != NativeGoogleSignInStatus.authenticated ||
        idToken == null) {
      return result;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithGoogleIdToken(idToken, languageCode: languageCode);
      return result;
    } catch (error) {
      return NativeGoogleSignInResult.unavailable(
        'Native Google sign-in could not be completed.',
      );
    }
  }
}

String _formatWelcomeTitle(String value) {
  final title = value.trim();
  const brand = 'HOK Helper';
  final brandStart = title.toLowerCase().lastIndexOf(brand.toLowerCase());
  if (brandStart <= 0) return title;

  final introduction = title.substring(0, brandStart).trimRight();
  return introduction.isEmpty ? title : '$introduction\n$brand';
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
