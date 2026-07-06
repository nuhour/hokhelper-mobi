import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/notifications/data/notifications_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final getCalls = <String>[];
  final postCalls = <String>[];
  final postBodies = <Object?>[];
  Map<String, dynamic>? lastQuery;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getCalls.add(path);
    lastQuery = query;
    if (path == '/notifications/unread-count') {
      return const {
        'success': true,
        'result': {'unread_count': 2},
      };
    }

    return const {
      'success': true,
      'result': {
        'total': 2,
        'page': 1,
        'pageSize': 50,
        'rows': [
          {
            'id': 10,
            'type': 'social',
            'target_type': 'community_post_comment',
            'target_id': '99',
            'title': '评论通知',
            'content': '有人评论了你的帖子',
            'link': '/community/post/99',
            'region_id': 2,
            'is_read': false,
            'created_at': '2026-07-03T08:30:00Z',
            'actor': {
              'id': 7,
              'username': 'coach',
              'first_name': 'Coach',
              'avatar': 'https://example.test/avatar.png',
            },
          },
          {
            'id': 11,
            'type': 'growth',
            'target_type': 'level_up',
            'target_id': '',
            'title': 'Level up',
            'content': 'You reached Lv.8',
            'link': '/profile',
            'region_id': 2,
            'is_read': true,
            'created_at': '2026-07-02T08:30:00Z',
            'actor': null,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postCalls.add(path);
    postBodies.add(body);
    return const {
      'success': true,
      'result': {'updated': 1},
    };
  }
}

void main() {
  test('loads notifications, unread count, and read mutations', () async {
    final apiClient = _FakeApiClient();
    final repository = NotificationsRepository(apiClient: apiClient);

    final page = await repository.loadNotifications(pageSize: 50);

    expect(apiClient.getCalls.first, '/notifications');
    expect(apiClient.lastQuery?['page'], 1);
    expect(apiClient.lastQuery?['pageSize'], 50);
    expect(page.total, 2);
    expect(page.rows.first.id, 10);
    expect(page.rows.first.actorId, 7);
    expect(page.rows.first.actorName, 'Coach');
    expect(page.rows.first.link, '/community/post/99');
    expect(page.rows.first.isRead, isFalse);
    expect(page.rows.last.type, 'growth');

    final unreadCount = await repository.loadUnreadCount();
    final marked = await repository.markRead([10]);
    final markedAll = await repository.markAllRead();

    expect(unreadCount, 2);
    expect(marked, 1);
    expect(markedAll, 1);
    expect(apiClient.postCalls, [
      '/notifications/read',
      '/notifications/read-all',
    ]);
    expect(apiClient.postBodies.first, {
      'ids': [10],
    });
    expect(apiClient.postBodies.last, isEmpty);
  });
}
