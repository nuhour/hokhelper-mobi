import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/feedback/app_notice.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_page_scaffold.dart';
import 'auth_controller.dart';

class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({
    required this.provider,
    required this.code,
    required this.error,
    required this.state,
    super.key,
  });

  final String provider;
  final String? code;
  final String? error;
  final String? state;

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_exchangeCode);
  }

  Future<void> _exchangeCode() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final stateIsValid = await ref
        .read(oauthStateStoreProvider)
        .consume(provider: widget.provider, state: widget.state?.trim());
    if (!stateIsValid) {
      _showLocalizedError('authOAuthExpired');
      return;
    }

    final stateStore = ref.read(oauthStateStoreProvider);
    // Keep both values from the exact authorization attempt. This matters for
    // Discord because the app can use either its custom callback or the web
    // callback while the backend is being rolled forward.
    final redirectUri =
        await stateStore.consumeRedirectUri(widget.provider) ??
        AppConfig.current.oauthRedirectUri(widget.provider);
    // The mobile Discord flow keeps its PKCE verifier in secure storage. It is
    // consumed only after state validation and before the one-time code swap.
    final codeVerifier = await stateStore.consumeCodeVerifier(widget.provider);

    final oauthError = widget.error?.trim();
    if (oauthError != null && oauthError.isNotEmpty) {
      _showLocalizedError('authOAuthAuthorizationFailed');
      return;
    }

    final callbackCode = widget.code?.trim();
    if (callbackCode == null || callbackCode.isEmpty) {
      _showLocalizedError('authOAuthMissingCode');
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithOAuth(
            provider: widget.provider,
            code: callbackCode,
            redirectUri: redirectUri,
            codeVerifier: codeVerifier,
            languageCode: languageCode,
          );
      if (mounted) {
        context.go('/me');
      }
    } catch (error) {
      _showErrorCause(error);
    }
  }

  void _showLocalizedError(String key) {
    if (!mounted) {
      return;
    }
    final message = AppLocalizations.of(context).translate(key);
    setState(() => _errorMessage = message);
    AppNotice.show(context, message, error: true);
  }

  void _showErrorCause(Object cause) {
    if (!mounted) {
      return;
    }
    final message = friendlyErrorMessage(
      context,
      cause,
      fallbackKey: 'authOAuthAuthorizationFailed',
    );
    setState(() => _errorMessage = message);
    AppNotice.show(context, message, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasError = _errorMessage != null;

    return AuthPageScaffold(
      title:
          '${_providerName(widget.provider)} ${l10n.translate('authSignInTitle')}',
      fallbackRoute: '/login',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.hokTheme.surfaceSlate,
                  border: Border.all(color: context.hokTheme.outlineSoft),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasError)
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 36,
                        )
                      else
                        const SizedBox.square(
                          dimension: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        hasError
                            ? l10n.translate('authOAuthLoginFailed')
                            : l10n.translate('authSigningIn'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.hokTheme.onSurfaceStrong,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasError
                            ? _errorMessage!
                            : l10n.format('authCompletingAuthorization', {
                                'provider': _providerName(widget.provider),
                              }),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                      if (hasError) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login),
                          label: Text(l10n.translate('authOAuthBackToLogin')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _providerName(String provider) {
  if (provider.isEmpty) return 'Third-party';
  return '${provider[0].toUpperCase()}${provider.substring(1)}';
}
