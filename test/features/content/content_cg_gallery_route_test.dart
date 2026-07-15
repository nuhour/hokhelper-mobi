import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/cg_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) => const ContentScreen(),
        routes: [
          GoRoute(
            path: 'cgs',
            builder: (context, state) => const CgGalleryScreen(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('content screen opens cg gallery route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async => const []),
          cgGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 501,
                kind: ContentKind.cg,
                title: 'Lam Cinematic',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 4.8,
                ratingCount: 17,
                viewCount: 2300,
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'CG Gallery'));
    await tester.pumpAndSettle();

    expect(find.text('CG Center'), findsOneWidget);
    expect(find.text('Lam Cinematic'), findsOneWidget);
  });
}
