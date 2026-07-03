class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.apiPrefix});

  // Defaults keep local desktop runs predictable. Android emulator/device builds
  // should pass HOK_API_BASE_URL with --dart-define, such as https://10.0.2.2:8000.
  static const current = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'HOK_API_BASE_URL',
      defaultValue: 'https://localhost:8000',
    ),
    apiPrefix: String.fromEnvironment('HOK_API_PREFIX', defaultValue: '/hokx'),
  );

  final String apiBaseUrl;
  final String apiPrefix;

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
}
