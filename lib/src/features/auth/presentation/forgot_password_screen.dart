import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_page_scaffold.dart';
import 'auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  var _message = '';
  var _isSendingCode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return AuthPageScaffold(
      title: 'Reset password',
      fallbackRoute: '/login',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(
                  'Reset password',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email, verification code, and a new password.',
                  style: Theme.of(context).textTheme.bodyMedium,
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
                  enabled: !isLoading && !_isSendingCode,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                        enabled: !isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: isLoading || _isSendingCode
                            ? null
                            : _sendCode,
                        child: _isSendingCode
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  enabled: !isLoading,
                  onSubmitted: (_) => _submit(),
                ),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(_message),
                ],
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
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset password'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading ? null : () => _backToLogin(context),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backToLogin(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSendingCode = true;
      _message = '';
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendVerificationCode(_emailController.text.trim());
      if (mounted) {
        setState(() => _message = 'Verification code sent');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .resetForgottenPassword(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
    if (mounted && !ref.read(authControllerProvider).hasError) {
      setState(() => _message = 'Password reset complete');
    }
  }
}
