import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response)
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final Map<String, dynamic> response;
  String? path;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    this.path = path;
    return response;
  }
}

class _FailingApiClient extends ApiClient {
  _FailingApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    throw StateError('stats task unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeRepository', () {
    test('loads home stats from the backend stats endpoint', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'message': 'Home stats ready',
        'result': {'heroes': 128, 'builds': 34},
      });
      final repository = HomeRepository(apiClient: apiClient);

      final stats = await repository.loadHomeStats();

      expect(apiClient.path, '/home/stats');
      expect(stats.success, isTrue);
      expect(stats.message, 'Home stats ready');
      expect(stats.result, {'heroes': 128, 'builds': 34});
    });

    test(
      'falls back to bundled home stats when the backend is unavailable',
      () async {
        final repository = HomeRepository(apiClient: _FailingApiClient());

        final stats = await repository.loadHomeStats();

        expect(stats.success, isTrue);
        expect(stats.result['season'], isA<Map>());
        expect(stats.result['hero_ranking_table'], isA<Map>());
        expect(stats.result['player_ranking'], isA<Map>());
        expect(stats.result['tier_list'], isA<List>());
      },
    );
  });
}
