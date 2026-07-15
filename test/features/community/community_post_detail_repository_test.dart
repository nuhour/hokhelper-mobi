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
    return const {
      'post': {
        'id': '99',
        'title': 'Best jungle rotation',
        'content': 'Start blue, punish mid wave, then invade.',
        'content_preview': 'Start blue, punish mid wave.',
        'author_name': 'coach',
        'author_avatar': 'https://example.test/avatar.png',
        'tags': ['Guide', 'Jungle'],
        'created_at': '2026-07-03T08:30:00Z',
        'view_count': 230,
        'like_count': 18,
        'comment_count': 2,
        'is_liked': true,
      },
      'comments': [
        {
          'id': 'c1',
          'content': 'Great route.',
          'author_id': 77,
          'author_name': 'Lam',
          'author_avatar': '',
          'created_at': '2026-07-03T09:00:00Z',
          'like_count': 3,
          'parent': null,
        },
        {
          'id': 'c2',
          'content': 'What if red buff is invaded?',
          'author_name': 'Angela',
          'author_avatar': '',
          'created_at': '2026-07-03T09:10:00Z',
          'like_count': 1,
          'parent': 'c1',
          'parent_author_name': 'Lam',
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return const {
      'id': 'c3',
      'content': 'Reply with river vision.',
      'author_id': 78,
      'author_name': 'Ming',
      'author_avatar': '',
      'created_at': '2026-07-03T10:00:00Z',
      'like_count': 0,
      'parent': 'c1',
      'parent_author_name': 'Lam',
    };
  }
}

void main() {
  test('loads community post detail and comments', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final detail = await repository.loadPostDetail('99', regionId: 2);

    expect(apiClient.getPath, '/community/posts/99');
    expect(apiClient.getQuery?['region_id'], 2);
    expect(detail.post.id, '99');
    expect(detail.post.title, 'Best jungle rotation');
    expect(detail.content, 'Start blue, punish mid wave, then invade.');
    expect(detail.post.likeCount, 18);
    expect(detail.isLiked, isTrue);
    expect(detail.comments, hasLength(2));
    expect(detail.comments.first.authorId, 77);
    expect(detail.comments.first.authorName, 'Lam');
    expect(detail.comments.last.parentId, 'c1');
    expect(detail.comments.last.parentAuthorName, 'Lam');
  });

  test('creates community replies with hokx-compatible parent field', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final comment = await repository.createComment(
      '99',
      content: 'Reply with river vision.',
      parentId: 'c1',
    );

    expect(apiClient.postPath, '/community/posts/99/comments');
    expect(apiClient.postBody, {
      'content': 'Reply with river vision.',
      'parent': 'c1',
    });
    expect(comment.id, 'c3');
    expect(comment.parentId, 'c1');
    expect(comment.parentAuthorName, 'Lam');
  });
}
