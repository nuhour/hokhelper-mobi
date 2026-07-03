import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';

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
  group('ContentRepository', () {
    test('loads skins with region filter', () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      await repository.loadSkins(2);

      expect(apiClient.postPath, '/skin/list');
      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 20,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': 2},
        ],
      });
    });

    test('loads CGs with region filter', () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      await repository.loadCgs(3);

      expect(apiClient.postPath, '/cg/list');
      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 20,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': 3},
        ],
      });
    });
  });
}
