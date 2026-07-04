import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/info/data/info_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? requestedPath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requestedPath = path;
    return const {
      'success': true,
      'total': 1,
      'rows': [
        {
          'id': 7,
          'name': 'HOK Lab',
          'url': 'https://hoklab.example',
          'description': 'Draft tools and hero research.',
          'logo': 'https://example.test/logo.png',
        },
      ],
    };
  }
}

void main() {
  test('loads public friend links from backend contract', () async {
    final apiClient = _FakeApiClient();
    final repository = InfoRepository(apiClient: apiClient);

    final links = await repository.loadFriendLinks();

    expect(apiClient.requestedPath, '/friendlink/list');
    expect(links.single.id, 7);
    expect(links.single.name, 'HOK Lab');
    expect(links.single.url, 'https://hoklab.example');
    expect(links.single.description, 'Draft tools and hero research.');
    expect(links.single.logoUrl, 'https://example.test/logo.png');
  });
}
