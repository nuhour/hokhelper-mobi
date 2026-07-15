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
        'players': [
          {
            'player_id': 'p-100',
            'player_name': 'Top Mid',
            'avatar_url': 'https://example.test/top-mid.png',
            'player_type_label': 'Pro',
            'peak_score': 2490,
            'rank_stars': 112,
            'win_rate': 0.684,
            'avg_kda': 7.2,
            'play_cnt': 380,
            'grade': 15.3,
            'mvp': 98,
            'region': 44,
            'rank_type': 'rank',
            'best_heroes': [
              {
                'hero_id': 131,
                'hero_name': 'Diaochan',
                'avatar_url': 'https://example.test/diaochan.png',
                'play_cnt': 72,
                'score': 99.1,
              },
            ],
          },
        ],
        'total': 1,
        'region_id': 0,
        'rank_type': 'rank',
        'region_options': [44, '62', 0, 'bad'],
      },
    };
  }
}

void main() {
  test(
    'loads standalone player leaderboard with web-compatible params',
    () async {
      final apiClient = _FakeApiClient();
      final repository = RankingsRepository(apiClient: apiClient);

      final result = await repository.loadPlayerLeaderboard(
        regionId: 0,
        rankType: 'rank',
        limit: 200,
      );

      expect(apiClient.getPath, '/ranking/players');
      expect(apiClient.getQuery, {
        'region_id': 0,
        'rank_type': 'rank',
        'limit': 200,
      });
      expect(result.total, 1);
      expect(result.regionId, 0);
      expect(result.rankType, 'rank');
      expect(result.regionOptions, [44, 62]);
      expect(result.players.single.playerName, 'Top Mid');
      expect(result.players.single.rankStars, 112);
      expect(result.players.single.bestHeroes.single.heroId, 131);
      expect(result.players.single.bestHeroes.single.heroName, 'Diaochan');
      expect(
        result.players.single.bestHeroes.single.avatarUrl,
        'https://example.test/diaochan.png',
      );
    },
  );
}
