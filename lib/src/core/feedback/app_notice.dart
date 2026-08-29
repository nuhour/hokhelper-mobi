import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../network/api_error.dart';

/// 统一的用户可见提示入口。
///
/// 网络层保留完整错误供日志和调试使用，界面层只通过这里展示本地化、
/// 面向用户的消息，避免把 ApiError、HTTP 状态码或服务端内部文案泄露给用户。
class AppNotice {
  const AppNotice._();

  static void show(BuildContext context, String message, {bool error = false}) {
    if (!context.mounted || message.trim().isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? Theme.of(context).colorScheme.errorContainer
              : null,
          content: Text(
            message,
            style: error
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  )
                : null,
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message);
  }

  static void failure(
    BuildContext context, {
    String fallbackKey = 'authRequestFailed',
  }) {
    show(
      context,
      AppLocalizations.of(context).translate(fallbackKey),
      error: true,
    );
  }

  static void error(BuildContext context, Object cause, {String? fallbackKey}) {
    show(
      context,
      friendlyErrorMessage(context, cause, fallbackKey: fallbackKey),
      error: true,
    );
  }
}

const _apiErrorTranslationKeys = <String, String>{
  'AUTH_EMAIL_REQUIRED': 'authEmailRequired',
  'AUTH_EMAIL_ALREADY_REGISTERED': 'authEmailAlreadyRegistered',
  'AUTH_EMAIL_NOT_REGISTERED': 'authEmailNotRegistered',
  'AUTH_PASSWORD_REQUIRED': 'authPasswordRequired',
  'AUTH_NEW_PASSWORD_REQUIRED': 'authNewPasswordRequired',
  'AUTH_PASSWORD_TOO_SHORT': 'authPasswordTooShort',
  'AUTH_VERIFY_CODE_REQUIRED': 'authCodeRequired',
  'AUTH_VERIFY_CODE_EXPIRED': 'authCodeExpired',
  'AUTH_VERIFY_CODE_INVALID': 'authCodeInvalid',
  'AUTH_INVALID_CREDENTIALS': 'authInvalidCredentials',
  'AUTH_ACCOUNT_DISABLED': 'authAccountDisabled',
  'AUTH_LOGIN_BLOCKED': 'authLoginBlocked',
  'AUTH_LOGIN_FAILED': 'authLoginFailed',
  'AUTH_REGISTER_FAILED': 'authRegisterFailed',
  'AUTH_RESET_PASSWORD_FAILED': 'authResetFailed',
  'AUTH_EMAIL_SEND_FAILED': 'authEmailSendFailed',
  'AUTH_CAPTCHA_REQUIRED': 'authCaptchaRequired',
  'AUTH_CAPTCHA_UNAVAILABLE': 'authCaptchaUnavailable',
  'AUTH_CAPTCHA_INVALID': 'authCaptchaInvalid',
  'AUTH_APP_INTEGRITY_REQUIRED': 'authIntegrityRequired',
  'AUTH_APP_INTEGRITY_UNAVAILABLE': 'authIntegrityUnavailable',
  'AUTH_APP_INTEGRITY_INVALID': 'authIntegrityInvalid',
  'AUTH_EMAIL_CODE_RATE_LIMITED': 'authCodeRateLimited',
  'AUTH_VERIFY_FAILED': 'authCodeVerifyFailed',
};

String friendlyErrorMessage(
  BuildContext context,
  Object cause, {
  String? fallbackKey,
}) {
  final l10n = AppLocalizations.of(context);
  if (cause is ApiError) {
    final codeKey = cause.code == null
        ? null
        : _apiErrorTranslationKeys[cause.code!];
    if (codeKey != null) {
      return l10n.translate(codeKey);
    }
    return switch (cause.kind) {
      ApiErrorKind.network => l10n.translate('authNetworkError'),
      ApiErrorKind.authExpired => l10n.translate('authSessionExpired'),
      ApiErrorKind.forbidden => l10n.translate('authPermissionDenied'),
      ApiErrorKind.validation => l10n.translate('authRequestFailed'),
      ApiErrorKind.backend => l10n.translate(
        fallbackKey ?? 'authRequestFailed',
      ),
      ApiErrorKind.unknown => l10n.translate(
        fallbackKey ?? 'authUnexpectedError',
      ),
    };
  }

  if (cause is TimeoutException || _looksLikeTimeout(cause)) {
    return l10n.serviceSlow;
  }
  return l10n.translate(fallbackKey ?? 'authUnexpectedError');
}

int? retryAfterSeconds(Object cause) {
  if (cause is! ApiError) {
    return null;
  }
  final value = cause.params?['retry_after'] ?? cause.params?['seconds'];
  final seconds = value is num ? value.ceil() : int.tryParse('$value');
  return seconds != null && seconds > 0 ? seconds : null;
}

bool _looksLikeTimeout(Object cause) {
  final text = cause.toString().toLowerCase();
  return text.contains('timeout') || text.contains('timed out');
}
