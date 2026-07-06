import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/stats/data/stats_repository.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_dashboard.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final queries = <String, Map<String, dynamic>?>{};

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    queries['$path:${query?['dimension'] ?? ''}:${query?['view'] ?? ''}'] =
        query;

    if (path == '/stats/table' && query?['dimension'] == 'hero_rank') {
      return const {
        'success': true,
        'data': {
          'dimension': 'hero_rank',
          'label': 'Hero Rank',
          'baseline': 'peak_1000',
          'view': 'base',
          'columns': [],
          'rows': [
            {
              'hero_id': 199,
              'hero_name': 'Lam',
              'hero_avatar_url': 'https://example.test/lam.png',
              'win_rate': 0.561,
              'pick_rate': 0.18,
              'ban_rate': 0.07,
              'score': 91.4,
            },
          ],
          'available_views': [],
          'available_baselines': ['peak_1000'],
        },
      };
    }

    if (path == '/stats/table' && query?['dimension'] == 'tier_rank') {
      return const {
        'success': true,
        'data': {
          'dimension': 'tier_rank',
          'label': 'Tier Rank',
          'baseline': 'peak_1000',
          'view': 'main',
          'columns': [],
          'rows': [
            {
              'hero_id': 133,
              'hero_name': 'Augran',
              'hero_avatar_url': 'https://example.test/augran.png',
              'win_rate': 0.62,
              'pick_rate': 0.16,
              'ban_rate': 0.23,
              'score': 96.8,
            },
          ],
          'available_views': [],
          'available_baselines': ['peak_1000'],
        },
      };
    }

    if (path == '/stats/table' && query?['dimension'] == 'power_rank') {
      return const {
        'success': true,
        'data': {
          'dimension': 'power_rank',
          'label': 'Power Rank',
          'baseline': 'peak_1000',
          'view': 'main',
          'columns': [],
          'rows': [
            {
              'hero_id': 144,
              'hero_name': 'Arli',
              'hero_avatar_url': 'https://example.test/arli.png',
              'win_rate': 0.58,
              'pick_rate': 0.21,
              'ban_rate': 0.12,
              'power_score': 98.1,
            },
          ],
          'available_views': [],
          'available_baselines': ['peak_1000'],
        },
      };
    }

    if (path == '/stats/table' && query?['dimension'] == 'equip_rank') {
      return const {
        'success': true,
        'data': {
          'dimension': 'equip_rank',
          'label': 'Equipment Rank',
          'baseline': 'peak_1000',
          'view': 'base',
          'columns': [],
          'rows': [
            {
              'equip_id': 88,
              'equip_name': 'Doomsday',
              'equip_icon_url': 'https://example.test/doomsday.png',
              'pick_rate': 0.22,
              'win_rate': 0.53,
            },
          ],
          'available_views': [],
          'available_baselines': ['peak_1000'],
        },
      };
    }

    if (path == '/stats/table' && query?['dimension'] == 'hero_combo') {
      return const {
        'success': true,
        'data': {
          'dimension': 'hero_combo',
          'label': 'Hero Combos',
          'baseline': 'peak_1000',
          'view': 'synergy',
          'columns': [],
          'rows': [
            {
              'hero_a_name': 'Lam',
              'hero_b_name': 'Yaria',
              'combo_matches': 1200,
              'win_rate': 0.59,
              'synergy_score': 88.5,
            },
          ],
          'available_views': [],
          'available_baselines': ['peak_1000'],
        },
      };
    }

    throw StateError('Unexpected request $path $query');
  }
}

void main() {
  test(
    'loads stats dashboard tables with backend-compatible queries',
    () async {
      final apiClient = _FakeApiClient();
      final repository = StatsRepository(apiClient: apiClient);

      final dashboard = await repository.loadDashboard(regionCode: 'en');

      expect(apiClient.queries['/stats/table:hero_rank:base'], {
        'dimension': 'hero_rank',
        'baseline': 'peak_1000',
        'view': 'base',
        'region': 'en',
        'lite': 1,
      });
      expect(apiClient.queries['/stats/table:equip_rank:base'], {
        'dimension': 'equip_rank',
        'baseline': 'peak_1000',
        'view': 'base',
        'region': 'en',
        'lite': 1,
      });
      expect(apiClient.queries['/stats/table:hero_combo:synergy'], {
        'dimension': 'hero_combo',
        'baseline': 'peak_1000',
        'view': 'synergy',
        'region': 'en',
        'lite': 1,
      });

      expect(dashboard.heroes.single.name, 'Lam');
      expect(dashboard.heroes.single.winRateText, '56.1%');
      expect(dashboard.equips.single.name, 'Doomsday');
      expect(dashboard.equips.single.pickRateText, '22.0%');
      expect(dashboard.combos.single.title, 'Lam + Yaria');
      expect(dashboard.combos.single.winRateText, '59.0%');
    },
  );

  test('loads tier rank entry with the hokx tier_rank main table', () async {
    final apiClient = _FakeApiClient();
    final repository = StatsRepository(apiClient: apiClient);

    final dashboard = await repository.loadDashboard(
      regionCode: 'en',
      entry: StatsDashboardEntry.tierRank,
    );

    expect(apiClient.queries['/stats/table:tier_rank:main'], {
      'dimension': 'tier_rank',
      'baseline': 'peak_1000',
      'view': 'main',
      'region': 'en',
      'lite': 1,
    });
    expect(apiClient.queries.containsKey('/stats/table:hero_rank:base'), false);
    expect(dashboard.heroes.single.name, 'Augran');
    expect(dashboard.heroes.single.scoreText, '96.8');
  });

  test('loads power rank entry with the hokx power_rank main table', () async {
    final apiClient = _FakeApiClient();
    final repository = StatsRepository(apiClient: apiClient);

    final dashboard = await repository.loadDashboard(
      regionCode: 'en',
      entry: StatsDashboardEntry.powerRank,
    );

    expect(apiClient.queries['/stats/table:power_rank:main'], {
      'dimension': 'power_rank',
      'baseline': 'peak_1000',
      'view': 'main',
      'region': 'en',
      'lite': 1,
    });
    expect(apiClient.queries.containsKey('/stats/table:hero_rank:base'), false);
    expect(dashboard.heroes.single.name, 'Arli');
    expect(dashboard.heroes.single.scoreText, '98.1');
  });
}
