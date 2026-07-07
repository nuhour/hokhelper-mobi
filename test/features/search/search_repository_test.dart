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
      'limit_per_type': 10,
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
            },
          ],
          'players': [
            {
              'player_id': 'ranked-1',
              'player_name': 'PeakPlayer',
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
    expect(urlFor('posts'), '/community/post/42');
    expect(urlFor('teams'), '/esports/teams/kpl-ag');
    expect(urlFor('pro_players'), '/esports/players/cat');
    expect(urlFor('leaks'), 'https://example.test/leak');

    SearchResultItem itemFor(String groupKey) {
      return groups.singleWhere((group) => group.key == groupKey).items.single;
    }

    expect(itemFor('players').title, 'PeakPlayer');
    expect(itemFor('players').subtitle, 'peak');
    expect(itemFor('pro_players').title, 'Cat');
    expect(itemFor('pro_players').subtitle, 'eStar · Mid');
    expect(itemFor('heroes').imageUrl, 'https://example.test/yaria.png');
    expect(itemFor('skins').imageUrl, 'https://example.test/skin.png');
    expect(itemFor('equips').imageUrl, 'https://example.test/equip.png');
    expect(itemFor('teams').imageUrl, 'https://example.test/ag.png');
    expect(itemFor('pro_players').imageUrl, 'https://example.test/cat.png');
  });
}
