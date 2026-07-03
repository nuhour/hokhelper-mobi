class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.apiPrefix});

  // Defaults keep local desktop runs predictable. Android emulator debug builds
  // should pass an explicit host URL with --dart-define.
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
