import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/core/i18n/translations/index.dart';

void main() {
  test('registers hokx language packs as separate dictionaries', () {
    expect(AppLocalizations.supportedLanguageCodes, [
      'en',
      'zh',
      'id',
      'fil',
      'pt',
      'es',
      'ar',
      'ru',
      'ms',
    ]);
    expect(
      appTranslationValues.keys,
      containsAll(AppLocalizations.supportedLanguageCodes),
    );
  });

  test('falls back to English for missing translated keys', () {
    const localizations = AppLocalizations(Locale('es'));

    expect(localizations.navHome, 'Inicio');
    expect(localizations.toolSubtitle('/tools/bp-simulator'), 'Draft schemes');
  });

  test('loads right-to-left and regional language labels', () {
    const arabic = AppLocalizations(Locale('ar'));
    const malay = AppLocalizations(Locale('ms'));

    expect(arabic.navTools, 'الأدوات');
    expect(malay.navHome, 'Laman Utama');
  });
}
