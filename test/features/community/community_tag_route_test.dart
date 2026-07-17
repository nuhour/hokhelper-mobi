import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

class _RouteCommunityRepository extends CommunityRepository {
  _RouteCommunityRepository(this.posts)
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  final List<CommunityPostSummary> posts;

  @override
  Future<List<CommunityPostSummary>> loadPosts(
    int regionId, {
    int page = 1,
    int pageSize = 30,
    String search = '',
    String tag = '',
    CommunityPostSort sort = CommunityPostSort.newest,
  }) async {
    return posts;
  }
}

void main() {
  testWidgets('web community route preserves tag query', (tester) async {
    final router = createAppRouter();
    router.go('/community?tag=update');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(
            _RouteCommunityRepository(const [
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
            ]),
          ),
          communityPostsRegionProvider.overrideWith((ref) async => 2),
          leakPostsProvider.overrideWith((ref) async => const []),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tag'],
      'update',
    );
    expect(find.text('Tag Filter'), findsOneWidget);
    expect(find.text('Patch update notes'), findsOneWidget);
    expect(find.text('General draft chat'), findsNothing);
  });
}
