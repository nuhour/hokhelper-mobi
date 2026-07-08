import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/activity/domain/event_assistance_record.dart';
import 'package:hok_helper_mobile/src/features/activity/presentation/event_assistance_screen.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async {
    return const AuthUser(
      id: 42,
      username: 'lam',
      email: 'lam@example.test',
      displayName: 'Lam',
    );
  }
}

class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository() : super(apiClient: _NoopApiClient());

  String? createdContent;
  int? createdRegionId;
  List<String>? createdTags;
  String? createdTitle;
  String? deletedPostId;
  String? likedPostId;
  String? requestedPostSearch;
  String? requestedPostTag;
  CommunityPostSort? requestedPostSort;
  String? requestedLeakCategory;
  String? requestedLeakPlatform;
  final requestedPostPages = <int>[];
  final requestedLeakPages = <int>[];
  List<CommunityPostSummary> Function(int page, int pageSize)? loadPostsPage;
  List<LeakPostSummary> Function(int page, int pageSize)? loadLeaksPage;

  @override
  Future<List<CommunityPostSummary>> loadPosts(
    int regionId, {
    int page = 1,
    int pageSize = 30,
    String search = '',
    String tag = '',
    CommunityPostSort sort = CommunityPostSort.newest,
  }) async {
    requestedPostPages.add(page);
    requestedPostSearch = search;
    requestedPostTag = tag;
    requestedPostSort = sort;
    final loader = loadPostsPage;
    if (loader == null) {
      return const [];
    }
    return loader(page, pageSize);
  }

  @override
  Future<List<LeakPostSummary>> loadLeaks(
    int regionId, {
    int page = 1,
    int pageSize = 30,
    String category = 'all',
    String platform = 'all',
  }) async {
    requestedLeakPages.add(page);
    requestedLeakCategory = category;
    requestedLeakPlatform = platform;
    final loader = loadLeaksPage;
    if (loader == null) {
      return const [];
    }
    return loader(page, pageSize);
  }

  @override
  Future<CommunityPostSummary> createPost({
    required String title,
    required String content,
    required List<String> tags,
    required int regionId,
  }) async {
    createdTitle = title;
    createdContent = content;
    createdTags = tags;
    createdRegionId = regionId;
    return CommunityPostSummary(
      id: '777',
      title: title,
      preview: content,
      authorId: 42,
      authorName: 'Lam',
      authorAvatarUrl: '',
      tags: tags,
      createdAt: '2026-07-06T09:00:00Z',
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
    );
  }

  @override
  Future<CommunityLikeResult> togglePostLike(String postId) async {
    likedPostId = postId;
    return const CommunityLikeResult(isLiked: true, likeCount: 19);
  }

  @override
  Future<void> deletePost(String postId) async {
    deletedPostId = postId;
  }
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

Finder _scrollableUnder(ValueKey<String> key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
}

void main() {
  testWidgets('renders community top tabs with forum default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '101',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave, then invade.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide', 'Jungle'],
                createdAt: '2026-07-01T10:00:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 7,
              ),
            ];
          }),
          leakPostsProvider.overrideWith((ref) async {
            return const [
              LeakPostSummary(
                id: '501',
                title: 'New Lam skin teaser',
                content: 'A cyber themed Lam skin appeared in preview.',
                category: 'skin',
                platform: 'youtube',
                authorName: 'leaker',
                authorHandle: '@leaker',
                authorAvatarUrl: '',
                mediaUrl: '',
                mediaType: 'image',
                publishedAt: '2026-07-02T12:00:00Z',
                likeCount: 91,
                viewCount: 1200,
                keywords: ['Lam', 'skin'],
              ),
            ];
          }),
          eventAssistanceRecordsProvider.overrideWith((ref) async {
            return const [
              EventAssistanceRecord(
                id: '1',
                content: 'Join my activity code ABCD.',
                eventTime: '2026-07-08T10:00:00Z',
                isReported: false,
                rawText: 'Help with weekly code ABCD.',
                regionId: 2,
                sharedBy: 'helper',
                createdAt: '2026-07-08T10:00:00Z',
                updatedAt: '2026-07-08T10:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-top-tab-strip')),
      findsOneWidget,
    );
    expect(find.text('论坛'), findsOneWidget);
    expect(find.text('爆料'), findsOneWidget);
    expect(find.text('活动互助'), findsOneWidget);
    expect(find.text('Best jungle rotation'), findsOneWidget);
    expect(find.text('coach'), findsOneWidget);
    expect(find.text('18 likes · 7 comments'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);

    await tester.tap(find.text('爆料'));
    await tester.pumpAndSettle();

    expect(find.text('New Lam skin teaser'), findsOneWidget);
    expect(find.text('leaker · @leaker'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '91'), findsOneWidget);
    expect(find.text('1200 views'), findsOneWidget);
    expect(find.text('skin'), findsWidgets);
    expect(find.text('Lam'), findsOneWidget);

    await tester.tap(find.text('活动互助'));
    await tester.pumpAndSettle();

    expect(find.text('Event Assistance'), findsOneWidget);
    expect(find.text('Join my activity code ABCD.'), findsOneWidget);
  });

  testWidgets('can open directly on the leaks tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async {
            return const [
              LeakPostSummary(
                id: '502',
                title: 'Direct leak entry',
                content: 'Opened from a legacy leak route.',
                category: 'skin',
                platform: 'youtube',
                authorName: 'leaker',
                authorHandle: '@leaker',
                authorAvatarUrl: '',
                mediaUrl: '',
                mediaType: 'image',
                publishedAt: '2026-07-02T12:00:00Z',
                likeCount: 12,
                viewCount: 99,
                keywords: ['skin'],
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityScreen(initialTabIndex: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Direct leak entry'), findsOneWidget);
    expect(find.text('No community posts found'), findsNothing);
  });

  testWidgets('toggles leak likes locally like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async {
            return const [
              LeakPostSummary(
                id: '501',
                title: 'New Lam skin teaser',
                content: 'A cyber themed Lam skin appeared in preview.',
                category: 'skin',
                platform: 'youtube',
                authorName: 'leaker',
                authorHandle: '@leaker',
                authorAvatarUrl: '',
                mediaUrl: '',
                mediaType: 'image',
                publishedAt: '2026-07-02T12:00:00Z',
                likeCount: 91,
                viewCount: 1200,
                keywords: ['Lam', 'skin'],
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityScreen(initialTabIndex: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, '91'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '91'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, '92'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '92'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, '91'), findsOneWidget);
  });

  testWidgets('filters leaks from initial search query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async {
            return const [
              LeakPostSummary(
                id: '502',
                title: 'Lam skin signal',
                content: 'A cyber themed Lam skin appeared in preview.',
                category: 'skin',
                platform: 'youtube',
                authorName: 'leaker',
                authorHandle: '@leaker',
                authorAvatarUrl: '',
                mediaUrl: '',
                mediaType: 'image',
                publishedAt: '2026-07-02T12:00:00Z',
                likeCount: 12,
                viewCount: 99,
                keywords: ['Lam', 'skin'],
              ),
              LeakPostSummary(
                id: '503',
                title: 'Angela animation leak',
                content: 'A mage animation appeared in preview.',
                category: 'hero',
                platform: 'x',
                authorName: 'scout',
                authorHandle: '@scout',
                authorAvatarUrl: '',
                mediaUrl: '',
                mediaType: 'image',
                publishedAt: '2026-07-02T12:00:00Z',
                likeCount: 8,
                viewCount: 77,
                keywords: ['Angela'],
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CommunityScreen(initialTabIndex: 1, initialLeakQuery: 'Lam'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leak Search'), findsOneWidget);
    expect(find.text('Showing leaks matching "Lam".'), findsOneWidget);
    expect(find.text('Lam skin signal'), findsOneWidget);
    expect(find.text('Angela animation leak'), findsNothing);
  });

  testWidgets('filters leaks by category and platform like the hokx portal', (
    tester,
  ) async {
    final repository = _FakeCommunityRepository();
    repository.loadLeaksPage = (page, pageSize) {
      return const [
        LeakPostSummary(
          id: '502',
          title: 'Lam skin signal',
          content: 'A cyber themed Lam skin appeared in preview.',
          category: 'skin',
          platform: 'youtube',
          authorName: 'leaker',
          authorHandle: '@leaker',
          authorAvatarUrl: '',
          mediaUrl: '',
          mediaType: 'image',
          publishedAt: '2026-07-02T12:00:00Z',
          likeCount: 12,
          viewCount: 99,
          keywords: ['Lam', 'skin'],
        ),
        LeakPostSummary(
          id: '503',
          title: 'Angela animation leak',
          content: 'A mage animation appeared in preview.',
          category: 'hero',
          platform: 'x',
          authorName: 'scout',
          authorHandle: '@scout',
          authorAvatarUrl: '',
          mediaUrl: '',
          mediaType: 'image',
          publishedAt: '2026-07-02T12:00:00Z',
          likeCount: 8,
          viewCount: 77,
          keywords: ['Angela'],
        ),
      ];
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityScreen(initialTabIndex: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Platforms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube').last);
    await tester.pumpAndSettle();

    expect(repository.requestedLeakCategory, 'skin');
    expect(repository.requestedLeakPlatform, 'youtube');
    expect(find.text('Lam skin signal'), findsOneWidget);
    expect(find.text('Angela animation leak'), findsNothing);
  });

  testWidgets('filters posts from initial tag query', (tester) async {
    final repository = _FakeCommunityRepository();
    repository.loadPostsPage = (page, pageSize) {
      return const [
        CommunityPostSummary(
          id: '301',
          title: 'Patch update notes',
          preview: 'Lam receives jungle tuning.',
          authorName: 'Analyst',
          authorAvatarUrl: '',
          tags: ['Update', 'Patch'],
          createdAt: '2026-07-03T10:00:00Z',
          viewCount: 45,
          likeCount: 6,
          commentCount: 2,
        ),
        CommunityPostSummary(
          id: '302',
          title: 'General draft chat',
          preview: 'Pick front line first.',
          authorName: 'Coach',
          authorAvatarUrl: '',
          tags: ['Draft'],
          createdAt: '2026-07-03T11:00:00Z',
          viewCount: 99,
          likeCount: 12,
          commentCount: 4,
        ),
      ];
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsRegionProvider.overrideWith((ref) async => 2),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityScreen(initialPostTag: 'update')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tag Filter'), findsOneWidget);
    expect(find.text('Showing posts tagged "update".'), findsOneWidget);
    expect(find.text('Patch update notes'), findsOneWidget);
    expect(find.text('General draft chat'), findsNothing);
    expect(repository.requestedPostTag, 'update');
  });

  testWidgets('my posts mode filters posts to the signed-in author', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController()),
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '201',
                title: 'My roaming notes',
                preview: 'Rotate after clearing mid.',
                authorId: 42,
                authorName: 'Lam',
                authorAvatarUrl: '',
                tags: ['Roam'],
                createdAt: '2026-07-03T10:00:00Z',
                viewCount: 45,
                likeCount: 6,
                commentCount: 2,
              ),
              CommunityPostSummary(
                id: '202',
                title: 'Someone else draft',
                preview: 'Pick front line first.',
                authorId: 7,
                authorName: 'Coach',
                authorAvatarUrl: '',
                tags: ['Draft'],
                createdAt: '2026-07-03T11:00:00Z',
                viewCount: 99,
                likeCount: 12,
                commentCount: 4,
              ),
            ];
          }),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CommunityScreen(initialView: CommunityInitialView.myPosts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Posts'), findsOneWidget);
    expect(find.text('My roaming notes'), findsOneWidget);
    expect(find.text('Someone else draft'), findsNothing);
  });

  testWidgets('liked posts mode filters posts to liked items', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '401',
                title: 'Liked build notes',
                preview: 'A strong jungle opening.',
                authorName: 'Coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-04T10:00:00Z',
                viewCount: 45,
                likeCount: 6,
                commentCount: 2,
                isLiked: true,
              ),
              CommunityPostSummary(
                id: '402',
                title: 'Unliked draft',
                preview: 'Pick front line first.',
                authorName: 'Scout',
                authorAvatarUrl: '',
                tags: ['Draft'],
                createdAt: '2026-07-04T11:00:00Z',
                viewCount: 99,
                likeCount: 12,
                commentCount: 4,
              ),
            ];
          }),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CommunityScreen(initialView: CommunityInitialView.likedPosts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Liked Posts'), findsOneWidget);
    expect(find.text('Showing posts you liked on HOK Helper.'), findsOneWidget);
    expect(find.text('Liked build notes'), findsOneWidget);
    expect(find.text('Unliked draft'), findsNothing);
  });

  testWidgets('searches and sorts community posts like the hokx portal', (
    tester,
  ) async {
    final repository = _FakeCommunityRepository();
    repository.loadPostsPage = (page, pageSize) {
      return const [
        CommunityPostSummary(
          id: '101',
          title: 'Best jungle rotation',
          preview: 'Start blue, punish mid wave, then invade.',
          authorName: 'coach',
          authorAvatarUrl: '',
          tags: ['Guide', 'Jungle'],
          createdAt: '2026-07-01T10:00:00Z',
          viewCount: 230,
          likeCount: 18,
          commentCount: 7,
        ),
      ];
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsRegionProvider.overrideWith((ref) async => 2),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search posts'),
      'jungle',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest'));
    await tester.pumpAndSettle();

    expect(repository.requestedPostSearch, 'jungle');
    expect(repository.requestedPostSort, CommunityPostSort.oldest);
  });

  testWidgets('likes community post cards through the backend', (tester) async {
    final repository = _FakeCommunityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '101',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave, then invade.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide', 'Jungle'],
                createdAt: '2026-07-01T10:00:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 7,
              ),
            ];
          }),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Like'));
    await tester.pumpAndSettle();

    expect(repository.likedPostId, '101');
    expect(find.text('19 likes · 7 comments'), findsOneWidget);
    expect(find.text('Post liked'), findsOneWidget);
  });

  testWidgets('loads more community posts after the first page', (
    tester,
  ) async {
    final repository = _FakeCommunityRepository();
    repository.loadPostsPage = (page, pageSize) {
      final startId = ((page - 1) * pageSize) + 1;
      final count = page == 1 ? pageSize : 1;
      return List.generate(count, (index) {
        final id = startId + index;
        return CommunityPostSummary(
          id: '$id',
          title: 'Paged post $id',
          preview: 'Community post page $page item $id.',
          authorName: 'Coach',
          authorAvatarUrl: '',
          tags: const ['Guide'],
          createdAt: '2026-07-05T10:00:00Z',
          viewCount: id,
          likeCount: 0,
          commentCount: 0,
        );
      });
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsRegionProvider.overrideWith((ref) async => 2),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paged post 1'), findsOneWidget);
    expect(find.text('Paged post 31'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Load more', skipOffstage: false),
      900,
      scrollable: _scrollableUnder(
        const ValueKey('community-posts-scroll-view'),
      ),
    );
    final loadMore = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Load more'),
    );
    await tester.runAsync(() async {
      loadMore.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(repository.requestedPostPages, [1, 2]);
    expect(find.text('Paged post 31'), findsOneWidget);
  });

  testWidgets('loads more leak posts after the first page', (tester) async {
    final repository = _FakeCommunityRepository();
    repository.loadLeaksPage = (page, pageSize) {
      final startId = ((page - 1) * pageSize) + 1;
      final count = page == 1 ? pageSize : 1;
      return List.generate(count, (index) {
        final id = startId + index;
        return LeakPostSummary(
          id: '$id',
          title: 'Paged leak $id',
          content: 'Leak page $page item $id.',
          category: 'skin',
          platform: 'youtube',
          authorName: 'Scout',
          authorHandle: '@scout',
          authorAvatarUrl: '',
          mediaUrl: '',
          mediaType: 'image',
          publishedAt: '2026-07-05T10:00:00Z',
          likeCount: 0,
          viewCount: id,
          keywords: const ['Lam'],
        );
      });
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityScreen(initialTabIndex: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paged leak 1'), findsOneWidget);
    expect(find.text('Paged leak 31'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Load more'),
      900,
      scrollable: _scrollableUnder(
        const ValueKey('community-leaks-scroll-view'),
      ),
    );
    final loadMore = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Load more'),
    );
    await tester.runAsync(() async {
      loadMore.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(repository.requestedLeakPages, [1, 2]);
    expect(find.text('Paged leak 31'), findsOneWidget);
  });

  testWidgets('creates community posts from the mobile posts tab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_region_id': 2});
    final repository = _FakeCommunityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Post'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Mobile macro notes',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Content'),
      'Rotate after clearing mid and protect river vision.',
    );
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.pump();
    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create').last,
    );
    submitButton.onPressed!();
    await tester.pumpAndSettle();

    expect(repository.createdTitle, 'Mobile macro notes');
    expect(
      repository.createdContent,
      'Rotate after clearing mid and protect river vision.',
    );
    expect(repository.createdTags, ['Ranked Tips']);
    expect(repository.createdRegionId, isNotNull);
    expect(find.text('Mobile macro notes'), findsOneWidget);
    expect(
      find.text('Rotate after clearing mid and protect river vision.'),
      findsOneWidget,
    );
    expect(find.text('Post created'), findsOneWidget);
  });

  testWidgets('creates community posts with recommended and custom tags', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_region_id': 2});
    final repository = _FakeCommunityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hero Matchups'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Custom tag'),
      'Squad Finder',
    );
    final addTagButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Add Tag'),
    );
    addTagButton.onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Mobile tag notes',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Content'),
      'Use multiple labels so the post lands in the right community filters.',
    );
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.pump();
    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create').last,
    );
    submitButton.onPressed!();
    await tester.pumpAndSettle();

    expect(repository.createdTags, [
      'Ranked Tips',
      'Hero Matchups',
      'Squad Finder',
    ]);
    expect(find.text('Hero Matchups'), findsWidgets);
    expect(find.text('Squad Finder'), findsWidgets);
  });

  testWidgets('deletes own community posts from my posts mode', (tester) async {
    final repository = _FakeCommunityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController()),
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '201',
                title: 'My roaming notes',
                preview: 'Rotate after clearing mid.',
                authorId: 42,
                authorName: 'Lam',
                authorAvatarUrl: '',
                tags: ['Roam'],
                createdAt: '2026-07-03T10:00:00Z',
                viewCount: 45,
                likeCount: 6,
                commentCount: 2,
              ),
            ];
          }),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CommunityScreen(initialView: CommunityInitialView.myPosts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Delete', skipOffstage: false),
      300,
      scrollable: _scrollableUnder(
        const ValueKey('community-posts-scroll-view'),
      ),
    );
    final deleteButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Delete'),
    );
    deleteButton.onPressed!();
    await tester.pumpAndSettle();

    expect(repository.deletedPostId, '201');
    expect(find.text('My roaming notes'), findsNothing);
    expect(find.text('Post deleted'), findsOneWidget);
  });
}
