import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/stats/data/stats_repository.dart';

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
      'data': {
        'rows': [
          {
            'hero': {
              'id': 199,
              'name': 'Lam',
              'avatar_url': 'https://example.test/lam.png',
            },
            'win_rate': 0.561,
            'avg_grade_game': 13.8,
            'mvp_rate': 22.5,
            'hurt_rate': 0.314,
            'be_hurt_rate': 0.287,
            'money_share': 0.241,
          },
        ],
      },
    };
  }
}

void main() {
  test('loads hero trends with web-compatible stats query', () async {
    final apiClient = _FakeApiClient();
    final repository = StatsRepository(apiClient: apiClient);

    final rows = await repository.loadHeroTrends(regionCode: 'en');

    expect(apiClient.getPath, '/stats/table');
    expect(apiClient.getQuery, {
      'dimension': 'hero_rank',
      'baseline': 'peak_1000',
      'view': 'base',
      'region': 'en',
      'window_days': 30,
    });
    expect(rows, hasLength(1));
    expect(rows.single.id, 199);
    expect(rows.single.name, 'Lam');
    expect(rows.single.avatarUrl, 'https://example.test/lam.png');
    expect(rows.single.winRate, closeTo(56.1, 0.001));
    expect(rows.single.mvpScore, 13.8);
    expect(rows.single.mvpRate, 22.5);
    expect(rows.single.dmgShare, closeTo(31.4, 0.001));
    expect(rows.single.takeDmgShare, closeTo(28.7, 0.001));
    expect(rows.single.ecoShare, closeTo(24.1, 0.001));
  });
}
