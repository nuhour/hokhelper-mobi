import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/notifications/data/notifications_repository.dart';
import 'package:hok_helper_mobile/src/features/notifications/domain/notification_summary.dart';
import 'package:hok_helper_mobile/src/features/notifications/presentation/notifications_screen.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this.user);

  final AuthUser? user;

  @override
  Future<AuthUser?> build() async => user;
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository()
    : page = const NotificationPage(
        total: 2,
        rows: [
          NotificationSummary(
            id: 10,
            type: 'social',
            targetType: 'community_post_comment',
            title: 'Comment',
            content: 'Coach commented on your post',
            link: '/community/post/99',
            isRead: false,
            createdAt: '2026-07-03T08:30:00Z',
            actorName: 'Coach',
            actorAvatar: '',
            actorId: 7,
          ),
          NotificationSummary(
            id: 11,
            type: 'growth',
            targetType: 'level_up',
            title: 'Level up',
            content: 'You reached Lv.8',
            link: '/profile',
            isRead: true,
            createdAt: '2026-07-02T08:30:00Z',
            actorName: '',
            actorAvatar: '',
            actorId: 0,
          ),
        ],
      ),
      super(apiClient: _NoopApiClient());

  NotificationPage page;
  List<int>? markedIds;
  bool markedAll = false;
  final requestedPages = <int>[];
  NotificationPage Function(int page)? loadPage;

  @override
  Future<NotificationPage> loadNotifications({
    int page = 1,
    int pageSize = 50,
    String type = '',
    bool unreadOnly = false,
  }) async {
    requestedPages.add(page);
    final pageLoader = loadPage;
    if (pageLoader != null && page > 1) {
      return pageLoader(page);
    }
    return this.page;
  }

  @override
  Future<int> markRead(List<int> ids) async {
    markedIds = ids;
    page = NotificationPage(
      total: page.total,
      rows: [
        for (final row in page.rows)
          ids.contains(row.id) ? row.copyWith(isRead: true) : row,
      ],
    );
    return ids.length;
  }

  @override
  Future<int> markAllRead() async {
    markedAll = true;
    page = NotificationPage(
      total: page.total,
      rows: [for (final row in page.rows) row.copyWith(isRead: true)],
    );
    return page.rows.length;
  }
}

void main() {
  testWidgets('shows login prompt when signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController(null)),
        ],
        child: MaterialApp(
          routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
          home: const Scaffold(body: NotificationsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login to view notifications'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
  });

  testWidgets('renders notifications and marks items read', (tester) async {
    final repository = _FakeNotificationsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              const AuthUser(
                id: 42,
                username: 'lam',
                email: 'lam@example.test',
                displayName: 'Lam',
              ),
            ),
          ),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.text('Coach commented on your post'), findsOneWidget);
    expect(find.text('You reached Lv.8'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Mark read'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, [10]);
    expect(find.text('0 unread'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Mark all read'));
    await tester.pumpAndSettle();

    expect(repository.markedAll, isTrue);
  });

  testWidgets('uses portal-style fallback text for Chinese notification rows', (
    tester,
  ) async {
    final repository = _FakeNotificationsRepository();
    repository.page = const NotificationPage(
      total: 1,
      rows: [
        NotificationSummary(
          id: 14,
          type: 'social',
          targetType: 'community_post_comment',
          title: '评论通知',
          content: '有人评论了你的帖子',
          link: '/community/post/99',
          isRead: false,
          createdAt: '2026-07-03T08:30:00Z',
          actorName: 'Coach',
          actorAvatar: '',
          actorId: 7,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              const AuthUser(
                id: 42,
                username: 'lam',
                email: 'lam@example.test',
                displayName: 'Lam',
              ),
            ),
          ),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification'), findsOneWidget);
    expect(find.text('Coach commented on your post'), findsOneWidget);
    expect(find.text('评论通知'), findsNothing);
    expect(find.text('有人评论了你的帖子'), findsNothing);
  });

  testWidgets('opens like notifications at actor profile after marking read', (
    tester,
  ) async {
    final repository = _FakeNotificationsRepository();
    repository.page = const NotificationPage(
      total: 1,
      rows: [
        NotificationSummary(
          id: 12,
          type: 'social',
          targetType: 'community_post_like',
          title: 'Like',
          content: 'Arthur liked your post',
          link: '/community/post/201',
          isRead: false,
          createdAt: '2026-07-04T08:30:00Z',
          actorName: 'Arthur',
          actorAvatar: '',
          actorId: 77,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) =>
              Scaffold(body: Text('Profile ${state.pathParameters['userId']}')),
        ),
        GoRoute(
          path: '/community/post/:postId',
          builder: (context, state) =>
              Scaffold(body: Text('Post ${state.pathParameters['postId']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              const AuthUser(
                id: 42,
                username: 'lam',
                email: 'lam@example.test',
                displayName: 'Lam',
              ),
            ),
          ),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'View'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, [12]);
    expect(router.routeInformationProvider.value.uri.path, '/profile/77');
    expect(find.text('Profile 77'), findsOneWidget);
  });

  testWidgets('loads more notifications after the first page', (tester) async {
    final repository = _FakeNotificationsRepository();
    var pageTwoRequested = false;
    repository.page = NotificationPage(
      total: 51,
      rows: List.generate(
        50,
        (index) => NotificationSummary(
          id: index + 1,
          type: 'system',
          targetType: 'notice',
          title: 'Notification ${index + 1}',
          content: 'First page item ${index + 1}',
          link: '',
          isRead: true,
          createdAt: '2026-07-05T08:30:00Z',
          actorName: '',
          actorAvatar: '',
          actorId: 0,
        ),
        growable: false,
      ),
    );

    repository.loadPage = (page) {
      pageTwoRequested = page == 2;
      return NotificationPage(
        total: 51,
        rows: [
          NotificationSummary(
            id: 51,
            type: 'system',
            targetType: 'notice',
            title: 'Notification 51',
            content: 'Second page item',
            link: '',
            isRead: true,
            createdAt: '2026-07-05T08:31:00Z',
            actorName: '',
            actorAvatar: '',
            actorId: 0,
          ),
        ],
      );
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              const AuthUser(
                id: 42,
                username: 'lam',
                email: 'lam@example.test',
                displayName: 'Lam',
              ),
            ),
          ),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification 1'), findsOneWidget);
    expect(find.text('Notification 51'), findsNothing);

    final loadMoreButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Load more'),
    );
    await tester.runAsync(() async {
      loadMoreButton.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(pageTwoRequested, isTrue);
    expect(repository.requestedPages, [1, 2]);
    expect(find.text('Notification 51'), findsOneWidget);
  });

  testWidgets('opens external notification links in the mobile link route', (
    tester,
  ) async {
    final repository = _FakeNotificationsRepository();
    repository.page = const NotificationPage(
      total: 1,
      rows: [
        NotificationSummary(
          id: 13,
          type: 'system',
          targetType: 'external',
          title: 'Event link',
          content: 'Open the official event page',
          link: 'https://example.test/event?id=9',
          isRead: false,
          createdAt: '2026-07-05T08:30:00Z',
          actorName: '',
          actorAvatar: '',
          actorId: 0,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/external-link',
          builder: (context, state) =>
              Scaffold(body: Text(state.uri.queryParameters['url'] ?? '')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              const AuthUser(
                id: 42,
                username: 'lam',
                email: 'lam@example.test',
                displayName: 'Lam',
              ),
            ),
          ),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'View'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, [13]);
    expect(router.routeInformationProvider.value.uri.path, '/external-link');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['url'],
      'https://example.test/event?id=9',
    );
    expect(find.text('https://example.test/event?id=9'), findsOneWidget);
  });

  testWidgets('opens portal hash notification links inside the app', (
    tester,
  ) async {
    final repository = _FakeNotificationsRepository();
    repository.page = const NotificationPage(
      total: 1,
      rows: [
        NotificationSummary(
          id: 14,
          type: 'social',
          targetType: 'community_post_comment',
          title: 'Reply',
          content: 'Coach replied to your post',
          link: '#/content/community/post/99',
          isRead: false,
          createdAt: '2026-07-06T08:30:00Z',
          actorName: 'Coach',
          actorAvatar: '',
          actorId: 7,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/content/community/post/:postId',
          builder: (context, state) =>
              Scaffold(body: Text('Post ${state.pathParameters['postId']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              const AuthUser(
                id: 42,
                username: 'lam',
                email: 'lam@example.test',
                displayName: 'Lam',
              ),
            ),
          ),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'View'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, [14]);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community/post/99',
    );
    expect(find.text('Post 99'), findsOneWidget);
  });
}
