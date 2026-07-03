import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/search/data/search_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return const {
      'success': true,
      'result': {'data': []},
    };
  }
}

void main() {
  test('searches globally with query text and region id', () async {
    final apiClient = _FakeApiClient();
    final repository = SearchRepository(apiClient: apiClient);

    await repository.search('arthur', 2);

    expect(apiClient.postPath, '/search/global');
    expect(apiClient.postBody, {
      'query': 'arthur',
      'region_id': 2,
      'limit_per_type': 10,
    });
  });
}
