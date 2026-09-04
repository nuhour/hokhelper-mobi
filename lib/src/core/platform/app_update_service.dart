import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart' as play_update;
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);
typedef AndroidUpdateChecker = Future<play_update.AppUpdateInfo> Function();
typedef AndroidUpdateFlow = Future<play_update.AppUpdateResult> Function();
typedef AndroidUpdateCompleter = Future<void> Function();

enum AppUpdateOutcome {
  latest,
  updateStarted,
  updateDeclined,
  updateFailed,
  storeOpened,
  storeOpenFailed,
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.outcome,
    this.availableVersionCode,
    this.openedUri,
  });

  const AppUpdateCheckResult.latest({int? availableVersionCode})
    : this(
        outcome: AppUpdateOutcome.latest,
        availableVersionCode: availableVersionCode,
      );

  const AppUpdateCheckResult.updateStarted({int? availableVersionCode})
    : this(
        outcome: AppUpdateOutcome.updateStarted,
        availableVersionCode: availableVersionCode,
      );

  const AppUpdateCheckResult.updateDeclined({int? availableVersionCode})
    : this(
        outcome: AppUpdateOutcome.updateDeclined,
        availableVersionCode: availableVersionCode,
      );

  const AppUpdateCheckResult.updateFailed({int? availableVersionCode})
    : this(
        outcome: AppUpdateOutcome.updateFailed,
        availableVersionCode: availableVersionCode,
      );

  const AppUpdateCheckResult.storeOpened(Uri uri)
    : this(outcome: AppUpdateOutcome.storeOpened, openedUri: uri);

  const AppUpdateCheckResult.storeOpenFailed()
    : this(outcome: AppUpdateOutcome.storeOpenFailed);

  final AppUpdateOutcome outcome;
  final int? availableVersionCode;
  final Uri? openedUri;
}

class AppUpdateService {
  AppUpdateService({
    ExternalUrlLauncher? launchExternal,
    AndroidUpdateChecker? checkAndroid,
    AndroidUpdateFlow? startImmediateUpdate,
    AndroidUpdateFlow? startFlexibleUpdate,
    AndroidUpdateCompleter? completeFlexibleUpdate,
    bool? isAndroid,
  }) : _launchExternal = launchExternal ?? _launchWithExternalApplication,
       _checkAndroid = checkAndroid ?? play_update.InAppUpdate.checkForUpdate,
       _startImmediateUpdate =
           startImmediateUpdate ??
           play_update.InAppUpdate.performImmediateUpdate,
       _startFlexibleUpdate =
           startFlexibleUpdate ?? play_update.InAppUpdate.startFlexibleUpdate,
       _completeFlexibleUpdate =
           completeFlexibleUpdate ??
           play_update.InAppUpdate.completeFlexibleUpdate,
       _isAndroid =
           isAndroid ?? defaultTargetPlatform == TargetPlatform.android;

  static const packageName = 'com.bottlegame.hokhelper';

  final ExternalUrlLauncher _launchExternal;

  static Uri get playStoreMarketUri =>
      Uri.parse('market://details?id=$packageName');

  static Uri get playStoreWebUri =>
      Uri.https('play.google.com', '/store/apps/details', {'id': packageName});

  final AndroidUpdateChecker _checkAndroid;
  final AndroidUpdateFlow _startImmediateUpdate;
  final AndroidUpdateFlow _startFlexibleUpdate;
  final AndroidUpdateCompleter _completeFlexibleUpdate;
  final bool _isAndroid;

  Future<AppUpdateCheckResult> checkForUpdates() async {
    if (!_isAndroid) {
      return _openStoreResult();
    }

    try {
      final info = await _checkAndroid();
      final availableVersionCode = info.availableVersionCode;
      final updateIsAvailable =
          info.updateAvailability ==
              play_update.UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              play_update.UpdateAvailability.developerTriggeredUpdateInProgress;
      if (!updateIsAvailable) {
        return AppUpdateCheckResult.latest(
          availableVersionCode: availableVersionCode,
        );
      }

      if (info.immediateUpdateAllowed) {
        return _flowResult(
          await _startImmediateUpdate(),
          availableVersionCode: availableVersionCode,
        );
      }

      if (info.flexibleUpdateAllowed) {
        final flowResult = await _startFlexibleUpdate();
        if (flowResult == play_update.AppUpdateResult.success) {
          try {
            await _completeFlexibleUpdate();
          } on Object {
            return AppUpdateCheckResult.updateFailed(
              availableVersionCode: availableVersionCode,
            );
          }
        }
        return _flowResult(
          flowResult,
          availableVersionCode: availableVersionCode,
        );
      }

      return _openStoreResult();
    } on Object {
      // Play Core is only available for an app installed from Google Play.
      // Keep the action useful for debug, sideloaded, and older Play clients.
      return _openStoreResult();
    }
  }

  AppUpdateCheckResult _flowResult(
    play_update.AppUpdateResult result, {
    required int? availableVersionCode,
  }) {
    return switch (result) {
      play_update.AppUpdateResult.success => AppUpdateCheckResult.updateStarted(
        availableVersionCode: availableVersionCode,
      ),
      play_update.AppUpdateResult.userDeniedUpdate =>
        AppUpdateCheckResult.updateDeclined(
          availableVersionCode: availableVersionCode,
        ),
      play_update.AppUpdateResult.inAppUpdateFailed =>
        AppUpdateCheckResult.updateFailed(
          availableVersionCode: availableVersionCode,
        ),
    };
  }

  Future<AppUpdateCheckResult> _openStoreResult() async {
    final openedUri = await openStoreListing();
    return openedUri == null
        ? const AppUpdateCheckResult.storeOpenFailed()
        : AppUpdateCheckResult.storeOpened(openedUri);
  }

  Future<Uri?> openStoreListing() async {
    if (await _tryLaunch(playStoreMarketUri)) {
      return playStoreMarketUri;
    }
    if (await _tryLaunch(playStoreWebUri)) {
      return playStoreWebUri;
    }
    return null;
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await _launchExternal(uri);
    } on Object {
      return false;
    }
  }
}

Future<bool> _launchWithExternalApplication(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
