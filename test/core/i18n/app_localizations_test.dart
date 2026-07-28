import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/constants/regions.dart';
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

  test('every language pack has the complete English key set', () {
    final englishKeys = appTranslationValues['en']!.keys.toSet();

    for (final entry in appTranslationValues.entries) {
      expect(
        entry.value.keys.toSet(),
        englishKeys,
        reason: '${entry.key} must not rely on an English fallback',
      );
      expect(
        entry.value.values,
        everyElement(isNotEmpty),
        reason: '${entry.key} must not contain empty translations',
      );
    }
  });

  test('loads localized strings outside the original three languages', () {
    const localizations = AppLocalizations(Locale('es'));
    const portuguese = AppLocalizations(Locale('pt'));
    const russian = AppLocalizations(Locale('ru'));

    expect(localizations.navHome, 'Inicio');
    expect(
      localizations.toolSubtitle('/tools/bp-simulator'),
      'Esquemas de draft',
    );
    expect(portuguese.settingsTitle, 'Configurações');
    expect(russian.profileLogin, 'Войти');
  });

  test('loads right-to-left and regional language labels', () {
    const arabic = AppLocalizations(Locale('ar'));
    const malay = AppLocalizations(Locale('ms'));

    expect(arabic.navTools, 'الأدوات');
    expect(malay.navHome, 'Utama');
  });

  test('maps languages to the same content regions as hokx', () {
    expect(hokRegionFromLanguageCode('zh'), HokRegion.cn);
    expect(hokRegionFromLanguageCode('id'), HokRegion.id);
    expect(hokRegionFromLanguageCode('en'), HokRegion.en);
    expect(hokRegionFromLanguageCode('fil'), HokRegion.fil);
    expect(hokRegionFromLanguageCode('pt'), HokRegion.pt);
    expect(hokRegionFromLanguageCode('es'), HokRegion.es);
    expect(hokRegionFromLanguageCode('ar'), HokRegion.ar);
    expect(hokRegionFromLanguageCode('ru'), HokRegion.ru);
    expect(hokRegionFromLanguageCode('ms'), HokRegion.ms);
  });
}
