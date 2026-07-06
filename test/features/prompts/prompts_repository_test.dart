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
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    if (path == '/prompt/generate/config') {
      return const {
        'success': true,
        'result': {'enabled': false},
      };
    }
    if (path == '/prompt/quota') {
      return const {
        'success': true,
        'result': {'quota_used': 2, 'quota_total': 5},
      };
    }
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

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    if (path == '/prompt') {
      return const {
        'success': true,
        'result': {
          'prompt': {
            'id': '10',
            'title': 'Mobile prompt',
            'content': 'Generate a clean HOK hero portrait.',
            'tags': ['portrait', 'mobile', 'Lang:en'],
            'is_public': true,
            'author_name': 'me',
          },
        },
      };
    }
    if (path == '/prompt/7/update') {
      return const {
        'success': true,
        'result': {
          'prompt': {
            'id': '7',
            'title': 'Updated prompt',
            'content': 'Updated HOK prompt content.',
            'tags': ['updated', 'Lang:en'],
            'is_public': false,
            'author_name': 'me',
          },
        },
      };
    }
    if (path == '/prompt/7/delete') {
      return const {'success': true, 'result': {}};
    }
    if (path == '/prompt/generate') {
      return const {
        'success': true,
        'result': {
          'images': [
            'https://example.test/generated-1.png',
            {'generated': 'https://example.test/generated-2.png'},
          ],
          'quota_used': 3,
          'quota_total': 5,
        },
      };
    }
    if (path == '/prompt/7/set-image') {
      return const {
        'success': true,
        'result': {
          'prompt': {
            'id': '7',
            'title': 'Cyber skin concept',
            'content': 'Create a neon Honor of Kings skin splash art.',
            'tags': ['skin', 'cyber'],
            'is_public': true,
            'image_url': 'https://example.test/generated-1.png',
            'author_name': 'artist',
            'likes': 12,
            'favorites': 5,
          },
        },
      };
    }
    if (path == '/prompt/recharge') {
      return const {
        'success': true,
        'result': {'quota_used': 5, 'quota_total': 15, 'added': 10},
      };
    }
    if (path.endsWith('/like')) {
      return const {
        'success': true,
        'result': {'is_liked': true, 'likes': 13},
      };
    }
    return const {
      'success': true,
      'result': {'is_favorited': true, 'favorites': 6},
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

  test('toggles prompt favorite with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final result = await repository.toggleFavorite('7');

    expect(apiClient.postPath, '/prompt/7/favorite');
    expect(apiClient.postBody, isEmpty);
    expect(result.isFavorited, isTrue);
    expect(result.favoriteCount, 6);
  });

  test('toggles prompt like with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final result = await repository.toggleLike('7');

    expect(apiClient.postPath, '/prompt/7/like');
    expect(apiClient.postBody, isEmpty);
    expect(result.isLiked, isTrue);
    expect(result.likeCount, 13);
  });

  test('creates prompt with hokx request fields', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final created = await repository.createPrompt(
      const PromptDraft(
        title: 'Mobile prompt',
        content: 'Generate a clean HOK hero portrait.',
        tags: ['portrait', 'mobile'],
        isPublic: true,
        language: 'en',
      ),
    );

    expect(apiClient.postPath, '/prompt');
    expect(apiClient.postBody, {
      'title': 'Mobile prompt',
      'content': 'Generate a clean HOK hero portrait.',
      'tags': ['portrait', 'mobile', 'Lang:en'],
      'is_public': true,
      'source_image_url': '',
      'effect_image_url': '',
      'language': 'en',
    });
    expect(created.id, '10');
    expect(created.title, 'Mobile prompt');
  });

  test('updates prompt with hokx request fields', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final updated = await repository.updatePrompt(
      '7',
      const PromptDraft(
        title: 'Updated prompt',
        content: 'Updated HOK prompt content.',
        tags: ['updated'],
        isPublic: false,
        language: 'en',
      ),
    );

    expect(apiClient.postPath, '/prompt/7/update');
    expect(apiClient.postBody, {
      'title': 'Updated prompt',
      'content': 'Updated HOK prompt content.',
      'tags': ['updated', 'Lang:en'],
      'is_public': false,
      'source_image_url': '',
      'effect_image_url': '',
      'language': 'en',
    });
    expect(updated.id, '7');
    expect(updated.title, 'Updated prompt');
    expect(updated.isPublic, isFalse);
  });

  test('deletes prompt with hokx-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    await repository.deletePrompt('7');

    expect(apiClient.postPath, '/prompt/7/delete');
    expect(apiClient.postBody, isEmpty);
  });

  test('loads prompt image generation quota', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final quota = await repository.loadGenerationQuota();

    expect(apiClient.getPath, '/prompt/quota');
    expect(quota.used, 2);
    expect(quota.total, 5);
    expect(quota.remaining, 3);
  });

  test('loads prompt generation enabled config', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final enabled = await repository.loadGenerationEnabled();

    expect(apiClient.getPath, '/prompt/generate/config');
    expect(enabled, isFalse);
  });

  test('generates prompt images with hokx text mode payload', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final result = await repository.generateImages(
      promptId: '7',
      count: 2,
      customContent: 'Create a HOK splash art.',
    );

    expect(apiClient.postPath, '/prompt/generate');
    expect(apiClient.postBody, {
      'prompt_id': '7',
      'mode': 'text',
      'count': 2,
      'custom_content': 'Create a HOK splash art.',
    });
    expect(result.images, [
      'https://example.test/generated-1.png',
      'https://example.test/generated-2.png',
    ]);
    expect(result.quota.used, 3);
    expect(result.quota.remaining, 2);
  });

  test('sets generated prompt image as prompt cover', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final updated = await repository.setPromptImage(
      promptId: '7',
      imageData: 'https://example.test/generated-1.png',
    );

    expect(apiClient.postPath, '/prompt/7/set-image');
    expect(apiClient.postBody, {
      'image_data': 'https://example.test/generated-1.png',
    });
    expect(updated.id, '7');
    expect(updated.imageUrl, 'https://example.test/generated-1.png');
  });

  test('recharges prompt generation quota with hokx request fields', () async {
    final apiClient = _FakeApiClient();
    final repository = PromptsRepository(apiClient: apiClient);

    final result = await repository.rechargeGenerationQuota(
      planId: 'standard',
      paymentMethod: 'card',
    );

    expect(apiClient.postPath, '/prompt/recharge');
    expect(apiClient.postBody, {
      'plan_id': 'standard',
      'payment_method': 'card',
    });
    expect(result.quota.used, 5);
    expect(result.quota.total, 15);
    expect(result.quota.remaining, 10);
    expect(result.added, 10);
  });
}
