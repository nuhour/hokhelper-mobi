import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_detail.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_post_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository() : super(apiClient: _NoopApiClient());

  String? likedPostId;

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
}
