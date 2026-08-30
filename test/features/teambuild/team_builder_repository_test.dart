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
              'synergy_available': true,
              'counter_available': true,
            },
          ],
          'fit_recommendations': [
            {
              'hero_id': 99,
              'heroId': '199',
              'hero_name': 'Dolia',
              'mainJob': 6,
              'minorJob': 4,
              'score': 88.5,
              'reason': 'Strong synergy with Lam',
              'pick_rate': 12.5,
              'ban_rate': 4.0,
              'synergy': 0.72,
              'counter': 0.31,
              'protect': 0.66,
              'deny': 0.18,
              'role_fit': 0.9,
              'confidence': 0.8,
              'components': {'synergy': 0.72, 'role_fit': 0.9},
              'reason_codes': ['strong_synergy'],
            },
          ],
          'counter_recommendations': [
            {
              'hero_id': 7,
              'heroId': '107',
              'hero_name': 'Marco Polo',
              'mainJob': 5,
              'score': 81.0,
              'reason': 'Counters the enemy',
              'pick_rate': 8.0,
              'ban_rate': 5.0,
              'synergy': 0.25,
              'counter': 0.86,
              'confidence': 0.7,
            },
          ],
          'phase': 'early_pick',
          'model_version': 'draft-v2.1',
          'stats_snapshot': '2026-08-30',
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
        'pageSize': 200,
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
        mainJob: 3,
        limit: 50,
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
        'limit': 50,
        'main_job': 3,
      });
      expect(result.recommendations, hasLength(1));
      expect(result.recommendations.single.heroId, 99);
      expect(result.recommendations.single.name, 'Dolia');
      expect(result.recommendations.single.score, 88.5);
      expect(result.recommendations.single.reason, 'Strong synergy with Lam');
      expect(result.recommendations.single.pickRate, 0.125);
      expect(result.recommendations.single.synergy, 0.72);
      expect(result.recommendations.single.synergyAvailable, isTrue);
      expect(result.recommendations.single.counterAvailable, isTrue);
      expect(result.fitRecommendations.single.protect, 0.66);
      expect(result.fitRecommendations.single.minorJob, 4);
      expect(result.fitRecommendations.single.components['role_fit'], 0.9);
      expect(result.fitRecommendations.single.reasonCodes, ['strong_synergy']);
      expect(result.counterRecommendations.single.heroId, 7);
      expect(result.counterRecommendations.single.counter, 0.86);
      expect(result.phase, 'early_pick');
      expect(result.modelVersion, 'draft-v2.1');
      expect(result.sideWinRates?.blue, 0.57);
      expect(result.sideWinRates?.red, 0.43);
    });

    test('sends explicit DraftState v2 and keeps both result lists', () async {
      final apiClient = _FakeApiClient();
      final repository = TeamBuilderRepository(apiClient: apiClient);

      final result = await repository.loadRecommendations(
        regionId: 2,
        blueBans: const [11],
        redBans: const [12],
        bluePicks: const [42],
        redPicks: const [7],
        activeSide: 'red',
        activeSlotType: 'ban',
        activeSlotIndex: 2,
        limit: 50,
      );

      final body = apiClient.postBody! as Map<String, Object?>;
      expect(body['blue_bans'], [11]);
      expect(body['red_bans'], [12]);
      expect(body['blue_picks'], [42]);
      expect(body['red_picks'], [7]);
      expect(body['active_side'], 'red');
      expect(body['active_slot_type'], 'ban');
      expect(body['active_slot_index'], 2);
      expect(body['my_picks'], [7]);
      expect(body['enemy_picks'], [42]);
      expect(body['recommend_type'], 'balanced');
      expect(result.fitRecommendations, hasLength(1));
      expect(result.counterRecommendations, hasLength(1));
    });
  });
}
