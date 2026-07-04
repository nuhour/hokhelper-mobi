import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_detail.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_post_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

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
    ],
  );
}

void main() {
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
}
