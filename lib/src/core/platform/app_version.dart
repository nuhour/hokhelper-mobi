import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../i18n/app_localizations.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();
    if (version.isEmpty) {
      return AppConfig.fallbackAppVersion;
    }
    if (buildNumber.isEmpty) {
      return version;
    }
    return '$version ($buildNumber)';
  } on Object {
    return AppConfig.fallbackAppVersion;
  }
});

class AppVersionLabel extends ConsumerWidget {
  const AppVersionLabel({this.style, super.key});

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).valueOrNull;
    final label = AppLocalizations.of(context).format('settingsVersionLabel', {
      'version': version ?? AppConfig.fallbackAppVersion,
    });
    return Text(label, key: const ValueKey('app-version-label'), style: style);
  }
}
