import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/feedback/app_notice.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';

void main() {
  testWidgets('friendly API errors use the selected locale', (tester) async {
    String? englishMessage;
    String? chineseMessage;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            englishMessage = friendlyErrorMessage(
              context,
              const ApiError(
                kind: ApiErrorKind.backend,
                message: 'ApiError[backend]: internal detail',
                code: 'AUTH_VERIFY_CODE_INVALID',
              ),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chineseMessage = friendlyErrorMessage(
              context,
              const ApiError(
                kind: ApiErrorKind.backend,
                message: 'ApiError[backend]: internal detail',
                code: 'AUTH_VERIFY_CODE_INVALID',
              ),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    expect(englishMessage, contains('verification code'));
    expect(englishMessage, isNot(contains('ApiError')));
    expect(chineseMessage, contains('验证码'));
  });

  test('retryAfterSeconds reads the server retry parameter', () {
    const error = ApiError(
      kind: ApiErrorKind.backend,
      message: 'wait',
      code: 'AUTH_EMAIL_CODE_RATE_LIMITED',
      params: {'retry_after': 59.2},
    );

    expect(retryAfterSeconds(error), 60);
  });
}
