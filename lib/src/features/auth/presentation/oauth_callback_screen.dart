import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
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
    final stateIsValid = await ref
        .read(oauthStateStoreProvider)
        .consume(provider: widget.provider, state: widget.state?.trim());
    if (!stateIsValid) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'This sign-in request has expired. Please start again.',
        );
      }
      return;
    }

    final oauthError = widget.error?.trim();
    if (oauthError != null && oauthError.isNotEmpty) {
      if (mounted) {
        setState(() => _errorMessage = 'OAuth authorization failed.');
      }
      return;
    }

    final callbackCode = widget.code?.trim();
    if (callbackCode == null || callbackCode.isEmpty) {
      if (mounted) {
        setState(() => _errorMessage = 'Missing OAuth callback code.');
      }
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithOAuth(
            provider: widget.provider,
            code: callbackCode,
            redirectUri: AppConfig.current.oauthRedirectUri(widget.provider),
          );
      if (mounted) {
        context.go('/me');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return AuthPageScaffold(
      title: '${_providerName(widget.provider)} sign in',
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
                        hasError ? 'OAuth login failed' : 'Signing you in',
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
                            : 'Completing ${widget.provider} authorization...',
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
                          label: const Text('Back to login'),
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
