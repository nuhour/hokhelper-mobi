import 'package:in_app_update/in_app_update.dart' as play_update;
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

  test('reports the latest Play version without opening the store', () async {
    final launchedUris = <Uri>[];
    final service = AppUpdateService(
      isAndroid: true,
      launchExternal: (uri) async {
        launchedUris.add(uri);
        return true;
      },
      checkAndroid: () async => _updateInfo(
        updateAvailability: play_update.UpdateAvailability.updateNotAvailable,
      ),
    );

    final result = await service.checkForUpdates();

    expect(result.outcome, AppUpdateOutcome.latest);
    expect(result.availableVersionCode, 4);
    expect(launchedUris, isEmpty);
  });

  test('starts an allowed immediate Play update', () async {
    var startCalled = false;
    final service = AppUpdateService(
      isAndroid: true,
      checkAndroid: () async => _updateInfo(immediateAllowed: true),
      startImmediateUpdate: () async {
        startCalled = true;
        return play_update.AppUpdateResult.success;
      },
    );

    final result = await service.checkForUpdates();

    expect(startCalled, isTrue);
    expect(result.outcome, AppUpdateOutcome.updateStarted);
  });

  test('completes an allowed flexible Play update', () async {
    var completeCalled = false;
    final service = AppUpdateService(
      isAndroid: true,
      checkAndroid: () async => _updateInfo(flexibleAllowed: true),
      startFlexibleUpdate: () async => play_update.AppUpdateResult.success,
      completeFlexibleUpdate: () async {
        completeCalled = true;
      },
    );

    final result = await service.checkForUpdates();

    expect(completeCalled, isTrue);
    expect(result.outcome, AppUpdateOutcome.updateStarted);
  });

  test('falls back to the store when Play Core is unavailable', () async {
    final launchedUris = <Uri>[];
    final service = AppUpdateService(
      isAndroid: true,
      launchExternal: (uri) async {
        launchedUris.add(uri);
        return true;
      },
      checkAndroid: () async => throw StateError('Play Core unavailable'),
    );

    final result = await service.checkForUpdates();

    expect(result.outcome, AppUpdateOutcome.storeOpened);
    expect(launchedUris, [AppUpdateService.playStoreMarketUri]);
  });
}

play_update.AppUpdateInfo _updateInfo({
  play_update.UpdateAvailability updateAvailability =
      play_update.UpdateAvailability.updateAvailable,
  bool immediateAllowed = false,
  bool flexibleAllowed = false,
}) {
  return play_update.AppUpdateInfo(
    updateAvailability: updateAvailability,
    immediateUpdateAllowed: immediateAllowed,
    immediateAllowedPreconditions: const [],
    flexibleUpdateAllowed: flexibleAllowed,
    flexibleAllowedPreconditions: const [],
    availableVersionCode: 4,
    installStatus: play_update.InstallStatus.unknown,
    packageName: AppUpdateService.packageName,
    clientVersionStalenessDays: null,
    updatePriority: 0,
  );
}
