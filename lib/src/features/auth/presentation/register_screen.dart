import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_page_scaffold.dart';
import '../data/app_integrity_client.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  var _message = '';
  var _isSendingCode = false;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 提前预热令牌提供器，避免用户点击发送验证码后才开始初始化。
    unawaited(AppIntegrityClient.instance.prepare());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading || _isSubmitting;
    final error = authState.hasError ? authState.error.toString() : null;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null && mounted) {
        context.go('/me');
      }
    });

    return AuthPageScaffold(
      title: 'Create account',
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
                  'Create your account',
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
                  enabled: !isLoading && !_isSendingCode,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: !isLoading,
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
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
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
                      : const Text('Register'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading ? null : () => _backToLogin(context),
                  child: const Text('Already have an account? Login'),
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
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email first');
      return;
    }
    setState(() {
      _isSendingCode = true;
      _message = '';
    });
    try {
      final integrityProof = await _requestIntegrityProof(
        action: 'email_register_code',
        values: {'email': email},
      );
      await ref
          .read(authControllerProvider.notifier)
          .sendRegisterCode(email: email, integrityProof: integrityProof);
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
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = '';
    });
    try {
      final email = _emailController.text.trim().toLowerCase();
      final code = _codeController.text.trim();
      final username = _usernameController.text.trim();
      final integrityProof = await _requestIntegrityProof(
        action: 'email_register',
        values: {
          'email': email,
          'username': username,
          'code': code.toUpperCase(),
        },
      );
      await ref
          .read(authControllerProvider.notifier)
          .register(
            email: email,
            password: _passwordController.text,
            code: code,
            username: username,
            integrityProof: integrityProof,
          );
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<AppIntegrityProof?> _requestIntegrityProof({
    required String action,
    required Map<String, String> values,
  }) async {
    return AppIntegrityClient.instance.getProof(action: action, values: values);
  }
}
