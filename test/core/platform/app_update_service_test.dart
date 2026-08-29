import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/platform/app_update_service.dart';

void main() {
  test('opens the Play Store app listing first', () async {
    final launchedUris = <Uri>[];
    final service = AppUpdateService(
      launchExternal: (uri) async {
        launchedUris.add(uri);
        return true;
      },
    );

    expect(
      await service.openStoreListing(),
      AppUpdateService.playStoreMarketUri,
    );
    expect(launchedUris, [AppUpdateService.playStoreMarketUri]);
  });

  test(
    'falls back to the web listing when the Play Store app is unavailable',
    () async {
      final launchedUris = <Uri>[];
      final service = AppUpdateService(
        launchExternal: (uri) async {
          launchedUris.add(uri);
          return uri.scheme == 'https';
        },
      );

      expect(
        await service.openStoreListing(),
        AppUpdateService.playStoreWebUri,
      );
      expect(launchedUris, [
        AppUpdateService.playStoreMarketUri,
        AppUpdateService.playStoreWebUri,
      ]);
    },
  );

  test('returns null after both store entry points fail', () async {
    final service = AppUpdateService(launchExternal: (_) async => false);

    expect(await service.openStoreListing(), isNull);
  });
}
