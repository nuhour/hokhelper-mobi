import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/regions.dart';
import '../../../core/storage/preferences_store.dart';

enum AppThemeMode {
  classic('classic'),
  versus('versus');

  const AppThemeMode(this.storageValue);

  final String storageValue;
}

AppThemeMode appThemeModeFromStorage(String value) {
  for (final mode in AppThemeMode.values) {
    if (mode.storageValue == value) {
      return mode;
    }
  }

  return AppThemeMode.classic;
}

class AppSettings {
  const AppSettings({
    required this.region,
    required this.languageCode,
    required this.theme,
  });

  final HokRegion region;
  final String languageCode;
  final AppThemeMode theme;

  AppSettings copyWith({
    HokRegion? region,
    String? languageCode,
    AppThemeMode? theme,
  }) {
    return AppSettings(
      region: region ?? this.region,
      languageCode: languageCode ?? this.languageCode,
      theme: theme ?? this.theme,
    );
  }
}

final preferencesStoreProvider = FutureProvider<PreferencesStore>((ref) {
  return PreferencesStore.create();
});

final appSettingsControllerProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final store = await ref.watch(preferencesStoreProvider.future);
    final languageCode = store.selectedLanguageCode;
    return AppSettings(
      region: hokRegionFromLanguageCode(languageCode),
      languageCode: languageCode,
      theme: appThemeModeFromStorage(store.selectedTheme),
    );
  }

  Future<void> setLanguageCode(String languageCode) async {
    final previous = await future;
    final region = hokRegionFromLanguageCode(languageCode);
    state = AsyncData(
      previous.copyWith(region: region, languageCode: languageCode),
    );

    final store = await ref.read(preferencesStoreProvider.future);
    await store.setSelectedLanguageCode(languageCode);
    await store.setSelectedRegionId(region.id);
  }

  Future<void> setTheme(AppThemeMode theme) async {
    final previous = await future;
    state = AsyncData(previous.copyWith(theme: theme));

    final store = await ref.read(preferencesStoreProvider.future);
    await store.setSelectedTheme(theme.storageValue);
  }
}
