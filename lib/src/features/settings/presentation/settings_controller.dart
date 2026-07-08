import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/regions.dart';
import '../../../core/storage/preferences_store.dart';

enum AppThemeMode {
  classic('classic', 'Dark'),
  versus('versus', 'Light');

  const AppThemeMode(this.storageValue, this.label);

  final String storageValue;
  final String label;
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
    return AppSettings(
      region: hokRegionFromId(store.selectedRegionId),
      languageCode: store.selectedLanguageCode,
      theme: appThemeModeFromStorage(store.selectedTheme),
    );
  }

  Future<void> setRegion(HokRegion region) async {
    final previous = await future;
    state = AsyncData(previous.copyWith(region: region));

    final store = await ref.read(preferencesStoreProvider.future);
    await store.setSelectedRegionId(region.id);
  }

  Future<void> setLanguageCode(String languageCode) async {
    final previous = await future;
    state = AsyncData(previous.copyWith(languageCode: languageCode));

    final store = await ref.read(preferencesStoreProvider.future);
    await store.setSelectedLanguageCode(languageCode);
  }

  Future<void> setTheme(AppThemeMode theme) async {
    final previous = await future;
    state = AsyncData(previous.copyWith(theme: theme));

    final store = await ref.read(preferencesStoreProvider.future);
    await store.setSelectedTheme(theme.storageValue);
  }
}
