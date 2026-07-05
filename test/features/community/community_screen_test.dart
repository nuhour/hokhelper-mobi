import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

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
}
