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
      'data': {
        'heroes': [
          {
            'hero_id': 42,
            'heroId': '199',
            'name': 'Lam',
            'mainJob': 'Assassin',
            'stats': {
              'win_rate': 0.5432,
              'pick_rate': 12.5,
              'ban_rate': 3.2,
              'mvp_rate': 0.21,
              'avg_kills': 8.4,
              'avg_assists': 5.6,
              'avg_grade_game': 13.1,
            },
          },
        ],
      },
    };
  }
}

void main() {
  test('loads hero rankings with backend-compatible query params', () async {
    final apiClient = _FakeApiClient();
    final repository = RankingsRepository(apiClient: apiClient);

    final entries = await repository.loadHeroRanking(1);

    expect(apiClient.getPath, '/ranking/heroes');
    expect(apiClient.getQuery, {
      'region_id': 1,
      'sort_by': 'win_rate',
      'order': 'desc',
      'limit': 20,
    });
    expect(entries, hasLength(1));
    expect(entries.single.heroId, 42);
    expect(entries.single.externalHeroId, '199');
    expect(entries.single.name, 'Lam');
    expect(entries.single.mainJob, 'Assassin');
    expect(entries.single.winRate, 0.5432);
    expect(entries.single.pickRate, 0.125);
    expect(entries.single.banRate, 0.032);
    expect(entries.single.mvpRate, 0.21);
    expect(entries.single.avgKills, 8.4);
    expect(entries.single.avgAssists, 5.6);
    expect(entries.single.avgGrade, 13.1);
  });
}
