import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/rankings/data/rankings_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? getPath;
  Map<String, dynamic>? getQuery;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return const {
      'success': true,
      'result': {'data': []},
    };
  }
}

void main() {
  test('loads hero rankings with backend-compatible query params', () async {
    final apiClient = _FakeApiClient();
    final repository = RankingsRepository(apiClient: apiClient);

    await repository.loadHeroRanking(1);

    expect(apiClient.getPath, '/ranking/heroes');
    expect(apiClient.getQuery, {'region_id': 1, 'limit': 20});
  });
}
