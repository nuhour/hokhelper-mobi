import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/heroes/data/heroes_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.postResponse})
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final Map<String, dynamic> postResponse;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }
}

void main() {
  test('loads hero relationships with region filter', () async {
    final apiClient = _FakeApiClient(
      postResponse: {
        'result': [
          {
            'id': 7,
            'hero1_id': 101,
            'hero1_name': 'Lam',
            'hero2_id': 202,
            'hero2_name': 'Angela',
            'title': 'Starlight Pact',
            'weight': 86,
            'description': 'They share a story arc.',
          },
        ],
      },
    );
    final repository = HeroesRepository(apiClient: apiClient);

    final relationships = await repository.loadHeroRelationships(2);

    expect(apiClient.postPath, '/hero/relationships');
    expect(apiClient.postBody, {
      'filterRules': [
        {'field': 'region_id', 'op': 'eq', 'value': 2},
      ],
    });
    expect(relationships, hasLength(1));
    expect(relationships.single.sourceHeroName, 'Lam');
    expect(relationships.single.targetHeroName, 'Angela');
    expect(relationships.single.title, 'Starlight Pact');
    expect(relationships.single.weight, 86);
    expect(relationships.single.description, 'They share a story arc.');
  });

  test('loads hero relationships from alternate rows envelopes', () async {
    final repository = HeroesRepository(
      apiClient: _FakeApiClient(
        postResponse: {
          'result': {
            'rows': [
              {
                'id': '8',
                'source': 301,
                'source_name': 'Dolia',
                'target': 302,
                'target_name': 'Yaria',
                'relationship_title': 'Song Bond',
                'score': '73',
              },
            ],
          },
        },
      ),
    );

    final relationships = await repository.loadHeroRelationships(3);

    expect(relationships.single.id, '8');
    expect(relationships.single.sourceHeroId, '301');
    expect(relationships.single.targetHeroId, '302');
    expect(relationships.single.title, 'Song Bond');
    expect(relationships.single.weight, 73);
  });
}
