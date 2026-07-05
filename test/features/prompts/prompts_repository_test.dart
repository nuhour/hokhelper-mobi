import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/prompts/data/prompts_repository.dart';

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
      'result': {
        'total': 1,
        'prompts': [
          {
            'id': '7',
            'title': 'Cyber skin concept',
            'content': 'Create a neon Honor of Kings skin splash art.',
            'tags': ['skin', 'cyber'],
            'is_public': true,
            'display_image_url': 'https://example.test/prompt.png',
            'language': 'English',
            'author_name': 'artist',
            'likes': 12,
            'favorites': 5,
            'created_at': '2026-07-01T10:00:00Z',
          },
        ],
      },
    };
  }
}

void main() {
  test('loads public prompt explorer list', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final prompts = await repository.loadExplorePrompts();

    expect(apiClient.getPath, '/prompt');
    expect(apiClient.getQuery, {
      'action': 'explore',
      'page': 1,
      'pageSize': 20,
      'sort': '-hot',
      'order': 'desc',
      'filterRules': '[{"field":"is_public","op":"eq","value":true}]',
    });
    expect(prompts, hasLength(1));
    expect(prompts.single.id, '7');
    expect(prompts.single.title, 'Cyber skin concept');
    expect(
      prompts.single.content,
      'Create a neon Honor of Kings skin splash art.',
    );
    expect(prompts.single.tags, ['skin', 'cyber']);
    expect(prompts.single.imageUrl, 'https://example.test/prompt.png');
    expect(prompts.single.authorName, 'artist');
    expect(prompts.single.likeCount, 12);
    expect(prompts.single.favoriteCount, 5);
  });

  test('loads prompt lists by backend action', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final prompts = await repository.loadPrompts(
      action: PromptListAction.favorites,
    );

    expect(apiClient.getPath, '/prompt');
    expect(apiClient.getQuery?['action'], 'favorites');
    expect(apiClient.getQuery?['page'], 1);
    expect(apiClient.getQuery?['pageSize'], 20);
    expect(apiClient.getQuery?['sort'], '-hot');
    expect(prompts.single.title, 'Cyber skin concept');
  });
}
