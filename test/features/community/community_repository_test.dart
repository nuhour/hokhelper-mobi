import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final getQueries = <String, Map<String, dynamic>?>{};
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getQueries[path] = query;

    return switch (path) {
      '/community/posts' => const {
        'total': 1,
        'rows': [
          {
            'id': '101',
            'title': 'Best jungle rotation',
            'content_preview': 'Start blue, punish mid wave, then invade.',
            'author_name': 'coach',
            'author_avatar': 'https://example.test/coach.png',
            'tags': ['Guide', 'Jungle'],
            'region_code': 'en',
            'created_at': '2026-07-01T10:00:00Z',
            'view_count': 230,
            'like_count': 18,
            'comment_count': 7,
          },
        ],
      },
      '/leak/posts' => const {
        'total': 1,
        'rows': [
          {
            'id': '501',
            'category': 'skin',
            'platform': 'youtube',
            'title': 'New Lam skin teaser',
            'content_text': 'A cyber themed Lam skin appeared in preview.',
            'author_name': 'leaker',
            'author_handle': '@leaker',
            'author_avatar_url': 'https://example.test/leaker.png',
            'source_url': 'https://example.test/source',
            'media_url': 'https://example.test/leak.jpg',
            'media_type': 'image',
            'published_at': '2026-07-02T12:00:00Z',
            'like_count': 91,
            'view_count': 1200,
            'matched_keywords': ['Lam', 'skin'],
          },
        ],
      },
      _ => throw StateError('Unexpected path $path'),
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    if (path == '/community/posts/create') {
      return const {
        'id': '777',
        'title': 'Mobile macro notes',
        'content': 'Rotate after clearing mid and protect river vision.',
        'content_preview':
            'Rotate after clearing mid and protect river vision.',
        'author_id': 42,
        'author_name': 'Lam',
        'author_avatar': 'https://example.test/lam.png',
        'tags': ['Guide', 'Macro'],
        'created_at': '2026-07-06T09:00:00Z',
        'view_count': 0,
        'like_count': 0,
        'comment_count': 0,
      };
    }
    if (path.endsWith('/delete')) {
      return const {'message': 'deleted'};
    }
    if (path.endsWith('/comments')) {
      return const {
        'id': 'c3',
        'content': 'Try invading red after mid.',
        'author_name': 'Lam',
        'author_avatar': 'https://example.test/lam.png',
        'created_at': '2026-07-03T10:00:00Z',
        'like_count': 0,
        'parent': null,
      };
    }
    return const {'liked': true, 'like_count': 19};
  }
}

void main() {
  test('loads community posts with region filter', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final posts = await repository.loadPosts(2);

    expect(apiClient.getQueries['/community/posts'], {
      'page': 1,
      'pageSize': 30,
      'sort': 'new',
      'filterRules': '[{"field":"region_id","op":"eq","value":2}]',
    });
    expect(posts, hasLength(1));
    expect(posts.single.id, '101');
    expect(posts.single.title, 'Best jungle rotation');
    expect(posts.single.preview, 'Start blue, punish mid wave, then invade.');
    expect(posts.single.authorName, 'coach');
    expect(posts.single.tags, ['Guide', 'Jungle']);
    expect(posts.single.metricText, '18 likes · 7 comments');
  });

  test('loads community posts with requested page parameters', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    await repository.loadPosts(2, page: 2, pageSize: 15);

    expect(apiClient.getQueries['/community/posts'], {
      'page': 2,
      'pageSize': 15,
      'sort': 'new',
      'filterRules': '[{"field":"region_id","op":"eq","value":2}]',
    });
  });

  test(
    'loads community posts with hokx-compatible search and sorting',
    () async {
      final apiClient = _FakeApiClient();
      final repository = CommunityRepository(apiClient: apiClient);

      await repository.loadPosts(
        2,
        search: 'jungle',
        sort: CommunityPostSort.oldest,
      );

      expect(apiClient.getQueries['/community/posts'], {
        'page': 1,
        'pageSize': 30,
        'sort': 'old',
        'search': 'jungle',
        'filterRules': '[{"field":"region_id","op":"eq","value":2}]',
      });
    },
  );

  test('loads leak posts with region and all-category query', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final leaks = await repository.loadLeaks(3);

    expect(apiClient.getQueries['/leak/posts'], {
      'page': 1,
      'pageSize': 30,
      'region_id': 3,
      'category': 'all',
    });
    expect(leaks, hasLength(1));
    expect(leaks.single.id, '501');
    expect(leaks.single.title, 'New Lam skin teaser');
    expect(leaks.single.category, 'skin');
    expect(leaks.single.platform, 'youtube');
    expect(leaks.single.authorLabel, 'leaker · @leaker');
    expect(leaks.single.metricText, '91 likes · 1200 views');
    expect(leaks.single.keywords, ['Lam', 'skin']);
  });

  test('loads leak posts with requested page parameters', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    await repository.loadLeaks(3, page: 2, pageSize: 12);

    expect(apiClient.getQueries['/leak/posts'], {
      'page': 2,
      'pageSize': 12,
      'region_id': 3,
      'category': 'all',
    });
  });

  test('toggles community post like with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final result = await repository.togglePostLike('101');

    expect(apiClient.postPath, '/community/posts/101/like');
    expect(apiClient.postBody, isNull);
    expect(result.isLiked, isTrue);
    expect(result.likeCount, 19);
  });

  test('creates community comments with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final comment = await repository.createComment(
      '101',
      content: 'Try invading red after mid.',
    );

    expect(apiClient.postPath, '/community/posts/101/comments');
    expect(apiClient.postBody, {'content': 'Try invading red after mid.'});
    expect(comment.id, 'c3');
    expect(comment.content, 'Try invading red after mid.');
    expect(comment.authorName, 'Lam');
  });

  test('creates community posts with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final post = await repository.createPost(
      title: 'Mobile macro notes',
      content: 'Rotate after clearing mid and protect river vision.',
      tags: ['Guide', 'Macro'],
      regionId: 2,
    );

    expect(apiClient.postPath, '/community/posts/create');
    expect(apiClient.postBody, {
      'title': 'Mobile macro notes',
      'content': 'Rotate after clearing mid and protect river vision.',
      'tags': ['Guide', 'Macro'],
      'region_id': 2,
    });
    expect(post.id, '777');
    expect(post.title, 'Mobile macro notes');
    expect(post.preview, 'Rotate after clearing mid and protect river vision.');
    expect(post.tags, ['Guide', 'Macro']);
  });

  test('deletes community posts with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    await repository.deletePost('101');

    expect(apiClient.postPath, '/community/posts/101/delete');
    expect(apiClient.postBody, isEmpty);
  });
}
