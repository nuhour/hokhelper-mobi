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
    if (path == '/ranking/players') {
      return const {
        'success': true,
        'data': {
          'players': [
            {
              'player_id': '1001',
              'player_name': 'Top Mid',
              'avatar_url': 'https://example.test/avatar.png',
              'peak_score': 2300.5,
              'rank_stars': 88,
              'win_rate': 0.6123,
              'avg_kda': 6.8,
              'play_cnt': 320,
              'grade': 14.2,
              'mvp': 90,
              'region': 2,
              'player_type_label': '职业',
              'rank_type': 'peak',
              'best_heroes': [
                {'hero_id': 199, 'play_cnt': 80, 'score': 99.5},
              ],
            },
          ],
          'region_options': [1, 2],
        },
      };
    }
    if (path == '/ranking/equips') {
      return const {
        'success': true,
        'data': {
          'equips': [
            {
              'equip_id': 501,
              'equip_name': 'Doombringer',
              'stats': {'pick_rate': 0.184, 'win_rate': 0.527},
            },
          ],
          'season_id': 9,
        },
      };
    }
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

  test('loads player rankings with backend-compatible query params', () async {
    final apiClient = _FakeApiClient();
    final repository = RankingsRepository(apiClient: apiClient);

    final entries = await repository.loadPlayerRanking(2);

    expect(apiClient.getPath, '/ranking/players');
    expect(apiClient.getQuery, {
      'region_id': 2,
      'rank_type': 'peak',
      'window_days': 999,
      'limit': 20,
    });
    expect(entries, hasLength(1));
    expect(entries.single.playerId, '1001');
    expect(entries.single.playerName, 'Top Mid');
    expect(entries.single.avatarUrl, 'https://example.test/avatar.png');
    expect(entries.single.peakScore, 2300.5);
    expect(entries.single.rankStars, 88);
    expect(entries.single.winRate, 0.6123);
    expect(entries.single.avgKda, 6.8);
    expect(entries.single.playCount, 320);
    expect(entries.single.grade, 14.2);
    expect(entries.single.mvpCount, 90);
    expect(entries.single.region, 2);
    expect(entries.single.playerTypeLabel, '职业');
    expect(entries.single.bestHeroes, hasLength(1));
    expect(entries.single.bestHeroes.single.heroId, 199);
    expect(entries.single.bestHeroes.single.playCount, 80);
    expect(entries.single.bestHeroes.single.score, 99.5);
  });

  test('loads equip rankings with backend-compatible query params', () async {
    final apiClient = _FakeApiClient();
    final repository = RankingsRepository(apiClient: apiClient);

    final entries = await repository.loadEquipRanking();

    expect(apiClient.getPath, '/ranking/equips');
    expect(apiClient.getQuery, {'sort_by': 'pick_rate', 'limit': 20});
    expect(entries, hasLength(1));
    expect(entries.single.equipId, 501);
    expect(entries.single.name, 'Doombringer');
    expect(entries.single.pickRate, 0.184);
    expect(entries.single.winRate, 0.527);
  });
}
