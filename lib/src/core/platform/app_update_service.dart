import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class AppUpdateService {
  AppUpdateService({ExternalUrlLauncher? launchExternal})
    : _launchExternal = launchExternal ?? _launchWithExternalApplication;

  static const packageName = 'com.hokhelper.hok_helper_mobile';

  final ExternalUrlLauncher _launchExternal;

  static Uri get playStoreMarketUri =>
      Uri.parse('market://details?id=$packageName');

  static Uri get playStoreWebUri =>
      Uri.https('play.google.com', '/store/apps/details', {'id': packageName});

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
