import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/info/domain/friend_link_summary.dart';
import 'package:hok_helper_mobile/src/features/info/presentation/info_center_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) => const ContentScreen(),
        routes: [
          GoRoute(
            path: 'community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: 'info',
            builder: (context, state) => const InfoCenterScreen(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('content screen opens the community route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async => const []),
          friendLinksProvider.overrideWith((ref) async => const []),
          communityPostsProvider.overrideWith((ref) async {
            return const [
              CommunityPostSummary(
                id: '101',
                title: 'Best jungle rotation',
                preview: 'Start blue, punish mid wave, then invade.',
                authorName: 'coach',
                authorAvatarUrl: '',
                tags: ['Guide'],
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
                keywords: ['Lam'],
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Community Hub'));
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Best jungle rotation'), findsOneWidget);
  });

  testWidgets('content screen opens the info center route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async => const []),
          friendLinksProvider.overrideWith((ref) async {
            return const [
              FriendLinkSummary(
                id: 7,
                name: 'HOK Lab',
                url: 'https://hoklab.example',
                description: 'Draft tools and hero research.',
                logoUrl: '',
              ),
            ];
          }),
          communityPostsProvider.overrideWith((ref) async => const []),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info Center'));
    await tester.pumpAndSettle();

    expect(find.text('About HOK Helper'), findsOneWidget);
    expect(find.text('HOK Lab'), findsOneWidget);
  });
}
