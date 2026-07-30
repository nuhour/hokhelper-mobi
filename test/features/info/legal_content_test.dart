import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/features/info/domain/legal_content.dart';

void main() {
  test('legal copy covers every supported app language', () {
    expect(
      appLegalCopy.keys.toSet(),
      AppLocalizations.supportedLanguageCodes.toSet(),
    );

    for (final languageCode in AppLocalizations.supportedLanguageCodes) {
      final copy = legalCopyFor(Locale(languageCode));
      expect(copy.privacy.title, isNotEmpty);
      expect(copy.privacy.updated, isNotEmpty);
      expect(copy.privacy.sections, hasLength(8));
      expect(copy.terms.title, isNotEmpty);
      expect(copy.terms.sections, hasLength(8));
      expect(copy.accountDeletionLink, isNotEmpty);
    }
  });

  test('unknown locale falls back to English', () {
    expect(legalCopyFor(const Locale('ja')), same(appLegalCopy['en']));
  });
}
