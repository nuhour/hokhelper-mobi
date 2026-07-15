import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'translations/index.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLanguageCodes = [
    'en',
    'zh',
    'id',
    'fil',
    'pt',
    'es',
    'ar',
    'ru',
    'ms',
  ];

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale('id'),
    Locale('fil'),
    Locale('pt'),
    Locale('es'),
    Locale('ar'),
    Locale('ru'),
    Locale('ms'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  String get appTitle => _t('appTitle');
  String get navHome => _t('navHome');
  String get navStats => _t('navStats');
  String get navCommunity => _t('navCommunity');
  String get navTools => _t('navTools');
  String get navMe => _t('navMe');
  String get settingsTitle => _t('settingsTitle');
  String get settingsRegionTitle => _t('settingsRegionTitle');
  String get settingsRegionSubtitle => _t('settingsRegionSubtitle');
  String get settingsLanguageTitle => _t('settingsLanguageTitle');
  String get settingsLanguageSubtitle => _t('settingsLanguageSubtitle');
  String get settingsThemeTitle => _t('settingsThemeTitle');
  String get settingsThemeSubtitle => _t('settingsThemeSubtitle');
  String get settingsClearCacheTitle => _t('settingsClearCacheTitle');
  String get settingsClearCacheSubtitle => _t('settingsClearCacheSubtitle');
  String get settingsClearCacheAction => _t('settingsClearCacheAction');
  String get settingsCacheCleared => _t('settingsCacheCleared');
  String get settingsUpdatesTitle => _t('settingsUpdatesTitle');
  String get settingsUpdatesSubtitle => _t('settingsUpdatesSubtitle');
  String get settingsCheckUpdatesAction => _t('settingsCheckUpdatesAction');
  String get settingsLatestVersion => _t('settingsLatestVersion');
  String get settingsAboutTitle => _t('settingsAboutTitle');
  String get settingsAboutSubtitle => _t('settingsAboutSubtitle');
  String get settingsAboutAction => _t('settingsAboutAction');
  String get settingsAboutDialogTitle => _t('settingsAboutDialogTitle');
  String get settingsAboutDialogBody => _t('settingsAboutDialogBody');
  String get settingsClose => _t('settingsClose');
  String get themeDark => _t('themeDark');
  String get themeLight => _t('themeLight');
  String get retry => _t('retry');
  String get back => _t('back');
  String get homeTabEsports => _t('homeTabEsports');
  String get homeTabSkins => _t('homeTabSkins');
  String get homeTabHeroes => _t('homeTabHeroes');
  String get homeTabHome => _t('homeTabHome');
  String get statsTabRankings => _t('statsTabRankings');
  String get statsTabTrends => _t('statsTabTrends');
  String get statsTabTier => _t('statsTabTier');
  String get communityTabLeaks => _t('communityTabLeaks');
  String get communityTabForum => _t('communityTabForum');
  String get communityTabEvents => _t('communityTabEvents');
  String get toolsTitle => _t('toolsTitle');
  String get toolsMore => _t('toolsMore');

  String toolTitle(String route) => _t('toolTitle:$route');
  String toolSubtitle(String route) => _t('toolSubtitle:$route');

  String _t(String key) {
    final languageCode = locale.languageCode;
    return appTranslationValues[languageCode]?[key] ??
        appTranslationValues['en']![key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
