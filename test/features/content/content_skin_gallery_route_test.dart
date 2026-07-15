import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/skin_gallery_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) => const ContentScreen(),
        routes: [
          GoRoute(
            path: 'skins',
            builder: (context, state) => const SkinGalleryScreen(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('content screen opens skin gallery route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async => const []),
          skinGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 1001,
                kind: ContentKind.skin,
                title: 'Crimson Hunter',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Hunter Series',
                rating: 4.5,
                ratingCount: 12,
                viewCount: 0,
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Skin Gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Skin Gallery'), findsOneWidget);
    expect(find.text('Crimson Hunter'), findsOneWidget);
  });
}
