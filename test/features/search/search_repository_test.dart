import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/search/data/search_repository.dart';
import 'package:hok_helper_mobile/src/features/search/domain/search_result.dart';

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
  test('searches globally with query text and region id', () async {
    final apiClient = _FakeApiClient();
    final repository = SearchRepository(apiClient: apiClient);

    await repository.search('arthur', 2);

    expect(apiClient.postPath, '/search/global');
    expect(apiClient.postBody, {
      'query': 'arthur',
      'region_id': 2,
      'limit_per_type': 6,
    });
  });

  test('infers hokx-compatible routes for typed search rows without urls', () {
    final groups = parseSearchResultGroups({
      'result': {
        'data': {
          'heroes': [
            {
              'id': 166,
              'name': 'Yaria',
              'subtitle': 'Forest Child',
              'avatar_url': 'https://example.test/yaria.png',
            },
          ],
          'skins': [
            {
              'id': 77,
              'name': 'Starlight Skin',
              'hero_name': 'Yaria',
              'additional_image_url': 'https://example.test/skin.png',
            },
          ],
          'equips': [
            {
              'id': 9,
              'equip_id': 1337,
              'name': 'Storm Blade',
              'icon_url': 'https://example.test/equip.png',
            },
          ],
          'posts': [
            {'id': 42, 'title': 'Patch Discussion'},
          ],
          'teams': [
            {
              'id': 'kpl-ag',
              'name': 'AG Super Play',
              'logo_url': 'https://example.test/ag.png',
              'league_name': 'KPL',
              'wins': 12,
              'losses': 3,
              'schedule': {'opponent_name': 'Wolves'},
            },
          ],
          'players': [
            {
              'player_id': 'ranked-1',
              'player_name': 'PeakPlayer',
              'region': 44,
              'rank_type': 'peak',
            },
          ],
          'pro_players': [
            {
              'player_id': 'cat',
              'player_name': 'Cat',
              'player_avatar': 'https://example.test/cat.png',
              'team_name': 'eStar',
              'position': 'Mid',
              'schedule': {'opponent_name': 'AG Super Play'},
            },
          ],
          'leaks': [
            {
              'id': 5,
              'title': 'Preview',
              'source_url': 'https://example.test/leak',
            },
          ],
        },
      },
    });

    String urlFor(String groupKey) {
      return groups
          .singleWhere((group) => group.key == groupKey)
          .items
          .single
          .url;
    }

    expect(urlFor('heroes'), '/hero-gallery/166');
    expect(urlFor('skins'), '/skin-gallery/77');
    expect(urlFor('equips'), '/stats?entry=equip_rank&equip_id=1337');
    expect(urlFor('posts'), '/content/community/post/42');
    expect(urlFor('players'), '/leaderboard?rank_type=peak&region_id=44');
    expect(urlFor('teams'), '/esports/teams/kpl-ag');
    expect(urlFor('pro_players'), '/esports/players/cat');
    expect(urlFor('leaks'), 'https://example.test/leak');

    SearchResultItem itemFor(String groupKey) {
      return groups.singleWhere((group) => group.key == groupKey).items.single;
    }

    expect(itemFor('players').title, 'PeakPlayer');
    expect(itemFor('players').subtitle, 'peak');
    expect(
      itemFor('players').actions.map((action) => action.label),
      contains('Player Rank'),
    );
    expect(
      itemFor('players').actions.map((action) => action.url),
      contains('/stats?entry=player_rank'),
    );
    expect(itemFor('pro_players').title, 'Cat');
    expect(itemFor('pro_players').subtitle, 'eStar · Mid · VS AG Super Play');
    expect(itemFor('heroes').imageUrl, 'https://example.test/yaria.png');
    expect(
      itemFor('heroes').actions.map((action) => action.label),
      containsAll(<String>['Trend', 'Build Sim']),
    );
    expect(
      itemFor('heroes').actions.map((action) => action.url),
      containsAll(<String>[
        '/trends?hero_id=166',
        '/tools/build-sim?hero_id=166',
      ]),
    );
    expect(itemFor('skins').imageUrl, 'https://example.test/skin.png');
    expect(
      itemFor('skins').actions.map((action) => action.url),
      contains('/skin-gallery/77'),
    );
    expect(itemFor('equips').imageUrl, 'https://example.test/equip.png');
    expect(
      itemFor('equips').actions.map((action) => action.url),
      contains('/stats?entry=equip_rank&equip_id=1337'),
    );
    expect(itemFor('teams').imageUrl, 'https://example.test/ag.png');
    expect(itemFor('teams').subtitle, 'KPL · 12-3 · VS Wolves');
    expect(
      itemFor('teams').actions.map((action) => action.url),
      contains('/esports/teams/kpl-ag'),
    );
    expect(itemFor('pro_players').imageUrl, 'https://example.test/cat.png');
    expect(
      itemFor('pro_players').actions.map((action) => action.url),
      contains('/esports/players/cat'),
    );
  });
}
