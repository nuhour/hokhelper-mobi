class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiPrefix,
    this.mediaBaseUrl = 'https://hokhelper.com',
    this.httpProxy = '',
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

  // Debug credentials are injected at build time and deliberately have no
  // source-controlled defaults.
  static const loginEmail = String.fromEnvironment('HOK_LOGIN_EMAIL');
  static const loginPassword = String.fromEnvironment('HOK_LOGIN_PASSWORD');

  final String apiBaseUrl;
  final String apiPrefix;
  final String mediaBaseUrl;
  final String httpProxy;

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

  String oauthRedirectUri(String provider) {
    final base = mediaBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$base/auth/${provider.trim().toLowerCase()}/callback';
  }
}
