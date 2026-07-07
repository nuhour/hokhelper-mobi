import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/domain/leak_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

class _RouteCommunityRepository extends CommunityRepository {
  _RouteCommunityRepository() : super(apiClient: _NoopApiClient());

  String? requestedLeakCategory;
  String? requestedLeakPlatform;

  @override
  Future<List<LeakPostSummary>> loadLeaks(
    int regionId, {
    int page = 1,
    int pageSize = 30,
    String category = 'all',
    String platform = 'all',
  }) async {
    requestedLeakCategory = category;
    requestedLeakPlatform = platform;
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
  }
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(apiBaseUrl: '', apiPrefix: ''),
      );
}

void main() {
  testWidgets('community leaks route preserves search query', (tester) async {
    final router = createAppRouter();
    router.go('/community/leaks?q=Lam');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityPostsProvider.overrideWith((ref) async {
            return const <CommunityPostSummary>[];
          }),
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
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'leaks',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['q'],
      'Lam',
    );
    expect(find.text('Leak Search'), findsOneWidget);
    expect(find.text('Lam skin signal'), findsOneWidget);
    expect(find.text('Angela animation leak'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('community leaks route preserves category and platform filters', (
    tester,
  ) async {
    final repository = _RouteCommunityRepository();
    final router = createAppRouter();
    router.go('/community/leaks?category=skin&platform=youtube');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repository),
          communityPostsProvider.overrideWith((ref) async {
            return const <CommunityPostSummary>[];
          }),
          leakPostsRegionProvider.overrideWith((ref) async => 2),
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
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'leaks',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['category'],
      'skin',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['platform'],
      'youtube',
    );
    expect(repository.requestedLeakCategory, 'skin');
    expect(repository.requestedLeakPlatform, 'youtube');
    expect(find.text('Skin'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Lam skin signal'), findsOneWidget);
    expect(find.text('Angela animation leak'), findsNothing);
  });
}
