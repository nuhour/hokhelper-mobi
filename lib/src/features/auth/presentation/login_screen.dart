import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

typedef OAuthUrlOpener = Future<void> Function(String url);

final oauthUrlOpenerProvider = Provider<OAuthUrlOpener>((ref) {
  return (url) async {
    const channel = MethodChannel('hokhelper/open_url');
    final launched = await channel.invokeMethod<bool>('openUrl', {'url': url});
    if (launched != true) {
      throw StateError('Unable to open OAuth authorization URL.');
    }
  };
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
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
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading || isOAuthLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                _OAuthButton(
                  label: 'Sign in with Google',
                  icon: Icons.g_mobiledata_rounded,
                  isLoading: _oauthLoadingProvider == 'google',
                  enabled: !isLoading && !isOAuthLoading,
                  onPressed: () => _startOAuth('google'),
                ),
                const SizedBox(height: 10),
                _OAuthButton(
                  label: 'Sign in with Discord',
                  icon: Icons.discord_rounded,
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.go('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => context.go('/register'),
                  child: const Text('Create account'),
                ),
              ],
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
      final redirectUri = 'hokhelper://auth/$provider/callback';
      final authUrl = await repository.getOAuthAuthorizationUrl(
        provider: provider,
        redirectUri: redirectUri,
      );
      await ref.read(oauthUrlOpenerProvider)(authUrl);
    } catch (_) {
      if (mounted) {
        setState(() {
          _oauthError = 'Failed to start OAuth login.';
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
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
