import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/teambuild/data/team_builder_repository.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_recommendation.dart';

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
    if (path == '/teambuild/recommend') {
      return const {
        'success': true,
        'data': {
          'recommendations': [
            {
              'hero_id': 99,
              'heroId': '199',
              'hero_name': 'Dolia',
              'mainJob': 6,
              'score': 88.5,
              'reason': 'Strong synergy with Lam',
              'pick_rate': 12.5,
              'ban_rate': 4.0,
              'synergy': 0.72,
              'counter': 0.31,
            },
          ],
          'total': 1,
          'side_win_rates': {
            'blue': 0.57,
            'red': 0.43,
            'my_side': 'blue',
            'my_side_rate': 0.57,
            'enemy_side_rate': 0.43,
          },
        },
      };
    }

    return const {
      'success': true,
      'data': {
        'data': [
          {
            'id': 42,
            'heroId': '142',
            'name': 'Lam',
            'mainJob': 3,
            'avatar_url': 'https://example.test/lam.png',
          },
        ],
      },
    };
  }
}

void main() {
  group('TeamBuilderRepository', () {
    test('loads team builder heroes with region filter', () async {
      final apiClient = _FakeApiClient();
      final repository = TeamBuilderRepository(apiClient: apiClient);

      final heroes = await repository.loadHeroes(2);

      expect(apiClient.postPath, '/teambuild/heroes');
      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 80,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': 2},
        ],
      });
      expect(heroes, hasLength(1));
      expect(heroes.single.id, 42);
      expect(heroes.single.externalHeroId, '142');
      expect(heroes.single.name, 'Lam');
      expect(heroes.single.mainJob, 3);
      expect(heroes.single.avatarUrl, 'https://example.test/lam.png');
    });

    test('loads recommendations with current draft context', () async {
      final apiClient = _FakeApiClient();
      final repository = TeamBuilderRepository(apiClient: apiClient);

      final result = await repository.loadRecommendations(
        regionId: 2,
        myPicks: const [42],
        enemyPicks: const [7],
        bans: const [11],
        recommendType: TeamRecommendType.balanced,
      );

      expect(apiClient.postPath, '/teambuild/recommend');
      expect(apiClient.postBody, {
        'bans': [11],
        'my_picks': [42],
        'enemy_picks': [7],
        'my_side': 'blue',
        'slot_type': 'pick',
        'slot_index': 0,
        'region_id': 2,
        'recommend_type': 'balanced',
        'limit': 10,
      });
      expect(result.recommendations, hasLength(1));
      expect(result.recommendations.single.heroId, 99);
      expect(result.recommendations.single.name, 'Dolia');
      expect(result.recommendations.single.score, 88.5);
      expect(result.recommendations.single.reason, 'Strong synergy with Lam');
      expect(result.recommendations.single.pickRate, 0.125);
      expect(result.recommendations.single.synergy, 0.72);
      expect(result.sideWinRates?.blue, 0.57);
      expect(result.sideWinRates?.red, 0.43);
    });
  });
}
