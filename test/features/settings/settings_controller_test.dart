import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/constants/regions.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/storage/preferences_store.dart';
import 'package:hok_helper_mobile/src/features/heroes/data/heroes_repository.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/settings/presentation/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        dio: Dio(),
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  Object? postBody;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postBody = body;
    return const {
      'success': true,
      'result': {'data': []},
    };
  }
}

void main() {
  test(
    'language restores and persists the matching region and theme',
    () async {
      SharedPreferences.setMockInitialValues({
        PreferencesStore.selectedRegionIdKey: HokRegion.en.id,
        PreferencesStore.selectedLanguageCodeKey: 'zh',
        PreferencesStore.selectedThemeKey: 'versus',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final restored = await container.read(
        appSettingsControllerProvider.future,
      );

      expect(restored.region, HokRegion.cn);
      expect(restored.languageCode, 'zh');
      expect(restored.theme, AppThemeMode.versus);

      await container
          .read(appSettingsControllerProvider.notifier)
          .setLanguageCode('id');
      await container
          .read(appSettingsControllerProvider.notifier)
          .setTheme(AppThemeMode.classic);

      final updated = container.read(appSettingsControllerProvider).valueOrNull;
      final preferences = await SharedPreferences.getInstance();

      expect(updated?.region, HokRegion.id);
      expect(updated?.languageCode, 'id');
      expect(updated?.theme, AppThemeMode.classic);
      expect(
        preferences.getInt(PreferencesStore.selectedRegionIdKey),
        HokRegion.id.id,
      );
      expect(
        preferences.getString(PreferencesStore.selectedLanguageCodeKey),
        'id',
      );
      expect(
        preferences.getString(PreferencesStore.selectedThemeKey),
        AppThemeMode.classic.storageValue,
      );
    },
  );

  test(
    'hero gallery provider uses the selected region from settings',
    () async {
      SharedPreferences.setMockInitialValues({
        PreferencesStore.selectedRegionIdKey: HokRegion.id.id,
        PreferencesStore.selectedLanguageCodeKey: 'id',
      });
      final apiClient = _FakeApiClient();
      final container = ProviderContainer(
        overrides: [
          heroesRepositoryProvider.overrideWithValue(
            HeroesRepository(apiClient: apiClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(heroGalleryProvider.future);

      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 60,
        'sort': 'created_at',
        'order': 'desc',
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': HokRegion.id.id},
        ],
      });
    },
  );
}
