import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_detail.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_post_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/public_profile_screen.dart';

class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository() : super(apiClient: _NoopApiClient());

  String? commentedPostId;
  String? commentContent;
  String? likedPostId;

  @override
  Future<CommunityCommentSummary> createComment(
    String postId, {
    required String content,
    String? parentId,
  }) async {
    commentedPostId = postId;
    commentContent = content;
    return CommunityCommentSummary(
      id: 'c3',
      content: content,
      authorName: 'Lam',
      authorAvatarUrl: '',
      createdAt: '2026-07-03T10:00:00Z',
      likeCount: 0,
      parentId: parentId ?? '',
      parentAuthorName: '',
    );
  }

  @override
  Future<CommunityLikeResult> togglePostLike(String postId) async {
    likedPostId = postId;
    return const CommunityLikeResult(isLiked: true, likeCount: 19);
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

GoRouter _buildDetailRouter() {
  return GoRouter(
    initialLocation: '/content/community/post/99',
    routes: [
      GoRoute(
        path: '/content/community/post/:postId',
        builder: (context, state) {
          return CommunityPostDetailScreen(
            postId: state.pathParameters['postId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          return PublicProfileScreen(
            userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? 0,
          );
        },
      ),
    ],
  );
}

void main() {
  testWidgets('renders community post detail and comment thread', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide', 'Jungle'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 2,
              ),
              content: 'Start blue, punish mid wave, then invade.',
              isLiked: true,
              comments: [
                CommunityCommentSummary(
                  id: 'c1',
                  content: 'Great route.',
                  authorName: 'Lam',
                  authorAvatarUrl: '',
                  createdAt: '2026-07-03T09:00:00Z',
                  likeCount: 3,
                  parentId: '',
                  parentAuthorName: '',
                ),
                CommunityCommentSummary(
                  id: 'c2',
                  content: 'What if red buff is invaded?',
                  authorName: 'Angela',
                  authorAvatarUrl: '',
                  createdAt: '2026-07-03T09:10:00Z',
                  likeCount: 1,
                  parentId: 'c1',
                  parentAuthorName: 'Lam',
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityPostDetailScreen(postId: '99')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best jungle rotation'), findsOneWidget);
    expect(
      find.text('Start blue, punish mid wave, then invade.'),
      findsOneWidget,
    );
    expect(find.text('230 views'), findsOneWidget);
    expect(find.text('18 likes'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('Great route.'), findsOneWidget);
    expect(find.text('What if red buff is invaded?'), findsOneWidget);
    expect(find.text('Reply to Lam'), findsOneWidget);
  });

  testWidgets('likes community post details through the backend', (
    tester,
  ) async {
    final repository = _FakeCommunityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 2,
              ),
              content: 'Start blue, punish mid wave, then invade.',
              isLiked: false,
              comments: [],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityPostDetailScreen(postId: '99')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Like'));
    await tester.pumpAndSettle();

    expect(repository.likedPostId, '99');
    expect(find.text('19 likes'), findsOneWidget);
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Post liked'), findsOneWidget);
  });

  testWidgets('copies community post share links from the detail screen', (
    tester,
  ) async {
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCall = call;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 2,
              ),
              content: 'Start blue, punish mid wave, then invade.',
              isLiked: false,
              comments: [],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityPostDetailScreen(postId: '99')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(clipboardCall, isNotNull);
    expect(clipboardCall!.arguments, {'text': '/community/post/99'});
    expect(find.text('Post link copied'), findsOneWidget);
  });

  testWidgets('creates comments from the mobile detail screen', (tester) async {
    final repository = _FakeCommunityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 2,
              ),
              content: 'Start blue, punish mid wave, then invade.',
              isLiked: false,
              comments: [],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommunityPostDetailScreen(postId: '99')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Try invading red after mid.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(repository.commentedPostId, '99');
    expect(repository.commentContent, 'Try invading red after mid.');
    expect(find.text('Try invading red after mid.'), findsOneWidget);
    expect(find.text('3 comments'), findsOneWidget);
    expect(find.text('Comment posted'), findsOneWidget);
  });

  testWidgets('opens comment authors from the mobile detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 1,
              ),
              content: 'Start blue, punish mid wave, then invade.',
              isLiked: false,
              comments: [
                CommunityCommentSummary(
                  id: 'c1',
                  content: 'Great route.',
                  authorId: 77,
                  authorName: 'Lam',
                  authorAvatarUrl: '',
                  createdAt: '2026-07-03T09:00:00Z',
                  likeCount: 3,
                  parentId: '',
                  parentAuthorName: '',
                ),
              ],
            );
          }),
          publicUserProfileProvider(77).overrideWith((ref) async {
            return const UserProfile(
              id: 77,
              username: 'lam',
              displayName: 'Lam',
              email: 'lam@example.test',
              avatar: '',
              level: 7,
              points: 1200,
              xpTotal: 1400,
              xpCurrentLevel: 260,
              xpToNextLevel: 740,
              levelProgress: 26,
              levelCap: false,
              bio: 'Comment strategist',
              socialLinks: {},
              stats: ProfileStats(
                posts: 3,
                following: 4,
                followers: 5,
                likes: 6,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildDetailRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Comment strategist'), findsOneWidget);
  });

  testWidgets('opens post authors from the mobile detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorId: 88,
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 0,
              ),
              content: 'Start blue, punish mid wave, then invade.',
              isLiked: false,
              comments: [],
            );
          }),
          publicUserProfileProvider(88).overrideWith((ref) async {
            return const UserProfile(
              id: 88,
              username: 'coach',
              displayName: 'Coach',
              email: 'coach@example.test',
              avatar: '',
              level: 8,
              points: 1800,
              xpTotal: 1800,
              xpCurrentLevel: 320,
              xpToNextLevel: 680,
              levelProgress: 32,
              levelCap: false,
              bio: 'Post detail author',
              socialLinks: {},
              stats: ProfileStats(
                posts: 8,
                following: 2,
                followers: 12,
                likes: 18,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildDetailRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('coach'));
    await tester.pumpAndSettle();

    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Post detail author'), findsOneWidget);
  });
}
