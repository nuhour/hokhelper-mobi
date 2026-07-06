import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/community/domain/community_post_summary.dart';
import 'package:hok_helper_mobile/src/features/community/presentation/community_screen.dart';

void main() {
  testWidgets('web community likes route opens liked mobile posts', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/community?view=likes');

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
      'likes',
    );
    expect(find.text('Liked Posts'), findsOneWidget);
    expect(find.text('Liked build notes'), findsOneWidget);
    expect(find.text('Unliked draft'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
