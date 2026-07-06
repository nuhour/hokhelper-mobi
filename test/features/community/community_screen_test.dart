import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/domain/auth_user.dart';
import 'package:hok_helper_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

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

void main() {
  testWidgets('renders community posts and leak tabs', (tester) async {
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
        ],
        child: const MaterialApp(home: Scaffold(body: CommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Best jungle rotation'), findsOneWidget);
    expect(find.text('coach'), findsOneWidget);
    expect(find.text('18 likes · 7 comments'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);

    await tester.tap(find.text('Leaks'));
    await tester.pumpAndSettle();

    expect(find.text('New Lam skin teaser'), findsOneWidget);
    expect(find.text('leaker · @leaker'), findsOneWidget);
    expect(find.text('91 likes · 1200 views'), findsOneWidget);
    expect(find.text('skin'), findsWidgets);
    expect(find.text('Lam'), findsOneWidget);
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

  testWidgets('filters posts from initial tag query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
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
          }),
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
}
