import 'package:shared_preferences/shared_preferences.dart';

import '../constants/regions.dart';

class PreferencesStore {
  const PreferencesStore(this._preferences);

  static const selectedRegionIdKey = 'selected_region_id';
  static const selectedLanguageCodeKey = 'selected_language_code';
  static const selectedThemeKey = 'selected_theme';

  final SharedPreferences _preferences;

  static Future<PreferencesStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesStore(preferences);
  }

  int get selectedRegionId {
    return _preferences.getInt(selectedRegionIdKey) ?? HokRegion.en.id;
  }

  Future<void> setSelectedRegionId(int regionId) {
    return _preferences.setInt(selectedRegionIdKey, regionId);
  }

  String get selectedLanguageCode {
    return _preferences.getString(selectedLanguageCodeKey) ??
        HokRegion.en.languageCode;
  }

  Future<void> setSelectedLanguageCode(String languageCode) {
    return _preferences.setString(selectedLanguageCodeKey, languageCode);
  }

  String get selectedTheme {
    return _preferences.getString(selectedThemeKey) ?? 'classic';
  }

  Future<void> setSelectedTheme(String theme) {
    return _preferences.setString(selectedThemeKey, theme);
  }
}
