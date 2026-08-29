import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feedback/app_notice.dart';
import '../../../core/i18n/app_localizations.dart';
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
  Timer? _sendCooldownTimer;
  var _sendCooldownSeconds = 0;
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
    _sendCooldownTimer?.cancel();
    _emailController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading || _isSubmitting;
    final codeButtonDisabled =
        isLoading || _isSendingCode || _sendCooldownSeconds > 0;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError && mounted) {
        AppNotice.error(context, next.error!);
      }
      if (next.hasValue && next.value != null && mounted) {
        AppNotice.success(context, l10n.translate('authRegisterSuccess'));
        context.go('/me');
      }
    });

    return AuthPageScaffold(
      title: l10n.translate('authCreateAccountTitle'),
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
                  l10n.translate('authCreateAccountHeading'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.translate('authEmailLabel'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  enabled: !isLoading && !_isSendingCode,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: l10n.translate('authUsernameLabel'),
                    prefixIcon: const Icon(Icons.person_outline),
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
                        decoration: InputDecoration(
                          labelText: l10n.translate(
                            'authVerificationCodeLabel',
                          ),
                          prefixIcon: const Icon(Icons.verified_outlined),
                        ),
                        enabled: !isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: codeButtonDisabled ? null : _sendCode,
                        child: _isSendingCode
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _sendCooldownSeconds > 0
                            ? Text(
                                l10n.format('authResendIn', {
                                  'seconds': '$_sendCooldownSeconds',
                                }),
                              )
                            : Text(l10n.translate('authSend')),
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
                  decoration: InputDecoration(
                    labelText: l10n.translate('authPasswordLabel'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  enabled: !isLoading,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.translate('authRegister')),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading ? null : () => _backToLogin(context),
                  child: Text(l10n.translate('authAlreadyAccountLogin')),
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
    if (_sendCooldownSeconds > 0 || _isSendingCode) {
      return;
    }
    final email = _emailController.text.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);
    if (email.isEmpty) {
      AppNotice.error(
        context,
        StateError(l10n.translate('authEmailRequired')),
        fallbackKey: 'authEmailRequired',
      );
      return;
    }
    setState(() => _isSendingCode = true);
    try {
      final integrityProof = await _requestIntegrityProof(
        action: 'email_register_code',
        values: {'email': email},
      );
      await ref
          .read(authControllerProvider.notifier)
          .sendRegisterCode(
            email: email,
            integrityProof: integrityProof,
            languageCode: l10n.locale.languageCode,
          );
      if (mounted) {
        _startCodeCooldown();
        AppNotice.success(context, l10n.translate('authCodeSent'));
      }
    } catch (error) {
      if (mounted) {
        final retryAfter = retryAfterSeconds(error);
        if (retryAfter != null) {
          _startCodeCooldown(retryAfter);
        }
        AppNotice.error(context, error);
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
    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final code = _codeController.text.trim();
      final username = _usernameController.text.trim();
      final l10n = AppLocalizations.of(context);
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
            languageCode: l10n.locale.languageCode,
          );
    } catch (error) {
      if (mounted) {
        AppNotice.error(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _startCodeCooldown([int seconds = 60]) {
    final duration = seconds.clamp(1, 600).toInt();
    _sendCooldownTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _sendCooldownSeconds = duration);
    _sendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_sendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _sendCooldownSeconds = 0);
        return;
      }
      setState(() => _sendCooldownSeconds -= 1);
    });
  }

  Future<AppIntegrityProof?> _requestIntegrityProof({
    required String action,
    required Map<String, String> values,
  }) async {
    return AppIntegrityClient.instance.getProof(action: action, values: values);
  }
}
