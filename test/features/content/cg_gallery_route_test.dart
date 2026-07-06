import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/cg_gallery_screen.dart';

void main() {
  testWidgets('web cg gallery route preserves search query', (tester) async {
    final router = createAppRouter();
    router.go('/cg?q=Lam');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
              ContentItemSummary(
                id: 502,
                kind: ContentKind.cg,
                title: 'Angela Trailer',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 3.9,
                ratingCount: 6,
                viewCount: 900,
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/cg');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['q'],
      'Lam',
    );
    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Lam Cinematic'), findsOneWidget);
    expect(find.text('Angela Trailer'), findsNothing);
  });

  testWidgets('web cg gallery route preserves hero filter query', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/cg?hero_id=199');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cgGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 501,
                kind: ContentKind.cg,
                title: 'Lam Cinematic',
                heroName: 'Lam',
                heroId: 199,
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 4.8,
                ratingCount: 17,
                viewCount: 2300,
              ),
              ContentItemSummary(
                id: 502,
                kind: ContentKind.cg,
                title: 'Angela Trailer',
                heroName: 'Angela',
                heroId: 111,
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 3.9,
                ratingCount: 6,
                viewCount: 900,
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/cg');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['hero_id'],
      '199',
    );
    expect(find.text('Focused hero CGs'), findsOneWidget);
    expect(find.text('Lam Cinematic'), findsOneWidget);
    expect(find.text('Angela Trailer'), findsNothing);
  });
}
