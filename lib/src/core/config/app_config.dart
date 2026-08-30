import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiPrefix,
    this.mediaBaseUrl = 'https://hokhelper.com',
    this.httpProxy = '',
    this.playIntegrityProjectNumber = playIntegrityCloudProjectNumber,
  });

  // Installed builds use the public API by default. A local backend is opt-in
  // through --dart-define=HOK_API_BASE_URL=https://your-host:8000.
  static const current = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'HOK_API_BASE_URL',
      defaultValue: 'https://api.hokhelper.com',
    ),
    apiPrefix: String.fromEnvironment('HOK_API_PREFIX', defaultValue: '/hokx'),
    mediaBaseUrl: String.fromEnvironment(
      'HOK_MEDIA_BASE_URL',
      defaultValue: 'https://hokhelper.com',
    ),
    httpProxy: String.fromEnvironment('HOK_HTTP_PROXY'),
  );

  // PackageInfo 不可用时使用构建清单中的版本作为显示兜底。
  static const fallbackAppVersion = String.fromEnvironment(
    'HOK_APP_VERSION',
    defaultValue: '1.0.3 (4)',
  );

  // Debug credentials are injected at build time and deliberately have no
  // source-controlled defaults.
  static const loginEmail = String.fromEnvironment('HOK_LOGIN_EMAIL');
  static const loginPassword = String.fromEnvironment('HOK_LOGIN_PASSWORD');
  static const allowExternalDigitalPayments = bool.fromEnvironment(
    'HOK_ALLOW_EXTERNAL_DIGITAL_PAYMENTS',
    defaultValue: false,
  );
  // OAuth client IDs are public identifiers. Supplying the backend web client
  // ID at build time lets Google Play Services start before any API request.
  static const googleServerClientId = String.fromEnvironment(
    'HOK_GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '623444676083-gdsoou9vr9ujsn0r1c7npohutjpakbd9.apps.googleusercontent.com',
  );
  // 应用完整性预热需要云项目编号；它不是凭据，可在构建时覆盖。
  static const playIntegrityCloudProjectNumber = String.fromEnvironment(
    'HOK_PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER',
    defaultValue: '623444676083',
  );
  // Discord 的应用 ID 是公开标识符；移动端回调 scheme 必须与开发者后台
  // 注册的 discord-<application-id>:/authorize/callback 完全一致。
  static const discordApplicationId = String.fromEnvironment(
    'HOK_DISCORD_APPLICATION_ID',
    defaultValue: '1459515499649175663',
  );

  final String apiBaseUrl;
  final String apiPrefix;
  final String mediaBaseUrl;
  final String httpProxy;
  final String playIntegrityProjectNumber;

  String get apiRoot {
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final prefix = apiPrefix
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp(r'/+$'), '');

    if (prefix.isEmpty) {
      return base;
    }

    return '$base/$prefix';
  }

  String oauthRedirectUri(String provider, {bool? mobile}) {
    final normalizedProvider = provider.trim().toLowerCase();
    final useMobileRedirect =
        mobile ??
        (!kIsWeb &&
            normalizedProvider == 'discord' &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS));
    if (useMobileRedirect && normalizedProvider == 'discord') {
      return 'discord-$discordApplicationId:/authorize/callback';
    }

    final base = mediaBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$base/auth/$normalizedProvider/callback';
  }
}
