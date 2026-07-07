import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_detail.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_post_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/public_profile_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content/community',
    routes: [
      GoRoute(
        path: '/content/community',
        builder: (context, state) => const CommunityScreen(),
        routes: [
          GoRoute(
            path: 'post/:postId',
            builder: (context, state) {
              return CommunityPostDetailScreen(
                postId: state.pathParameters['postId'] ?? '',
              );
            },
          ),
        ],
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
  testWidgets('legacy community post_id route opens the post detail', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/community?post_id=99&source=home');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const <CommunityPostSummary>[];
          }),
          leakPostsProvider.overrideWith(
            (ref) async => const <LeakPostSummary>[],
          ),
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
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community/post/99',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['source'],
      'home',
    );
    expect(
      find.text('Start blue, punish mid wave, then invade.'),
      findsOneWidget,
    );
    expect(find.text('Comments'), findsOneWidget);
  });

  testWidgets('community post cards open the detail route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
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
            ];
          }),
          leakPostsProvider.overrideWith(
            (ref) async => const <LeakPostSummary>[],
          ),
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
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Best jungle rotation'));
    await tester.pumpAndSettle();

    expect(
      find.text('Start blue, punish mid wave, then invade.'),
      findsOneWidget,
    );
    expect(find.text('Comments'), findsOneWidget);
  });

  testWidgets('community post authors open public profile routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorId: 77,
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 2,
              ),
            ];
          }),
          leakPostsProvider.overrideWith(
            (ref) async => const <LeakPostSummary>[],
          ),
          publicUserProfileProvider(77).overrideWith((ref) async {
            return const UserProfile(
              id: 77,
              username: 'coach',
              displayName: 'Coach',
              email: 'coach@example.test',
              avatar: '',
              level: 6,
              points: 900,
              xpTotal: 900,
              xpCurrentLevel: 180,
              xpToNextLevel: 720,
              levelProgress: 20,
              levelCap: false,
              bio: 'Community guide author',
              socialLinks: {},
              stats: ProfileStats(
                posts: 12,
                following: 3,
                followers: 9,
                likes: 21,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('coach'));
    await tester.pumpAndSettle();

    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Community guide author'), findsOneWidget);
  });

  testWidgets('community post author avatars open public profile routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorId: 77,
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
                createdAt: '2026-07-03T08:30:00Z',
                viewCount: 230,
                likeCount: 18,
                commentCount: 2,
              ),
            ];
          }),
          leakPostsProvider.overrideWith(
            (ref) async => const <LeakPostSummary>[],
          ),
          postDetailProvider('99').overrideWith((ref) async {
            return const CommunityPostDetail(
              post: CommunityPostSummary(
                id: '99',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave.',
                authorId: 77,
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
          publicUserProfileProvider(77).overrideWith((ref) async {
            return const UserProfile(
              id: 77,
              username: 'coach',
              displayName: 'Coach',
              email: 'coach@example.test',
              avatar: '',
              level: 6,
              points: 900,
              xpTotal: 900,
              xpCurrentLevel: 180,
              xpToNextLevel: 720,
              levelProgress: 20,
              levelCap: false,
              bio: 'Community guide author',
              socialLinks: {},
              stats: ProfileStats(
                posts: 12,
                following: 3,
                followers: 9,
                likes: 21,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.image_not_supported_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Community guide author'), findsOneWidget);
    expect(find.text('Comments'), findsNothing);
  });
}
