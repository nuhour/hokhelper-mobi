import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';

void main() {
  testWidgets('web hero gallery route preserves search query', (tester) async {
    final router = createAppRouter();
    router.go('/hero-gallery?q=Lam');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                name: 'Lam',
                avatar: '',
                title: 'Shark Rider',
              ),
              HeroSummary(
                id: '2',
                name: 'Angela',
                avatar: '',
                title: 'Arcane Mage',
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['q'],
      'Lam',
    );
    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Shark Rider'), findsOneWidget);
    expect(find.text('Angela'), findsNothing);
  });

  testWidgets('web hero history tab deep link focuses mobile history', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/hero-gallery/166?tab=history');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': 166, 'name': 'Lam', 'title': 'Shark Rider'},
              'history': [
                {
                  'version': '1.2.3',
                  'date': '2026-07-01',
                  'type': 'buff',
                  'title': 'Jungle tuning',
                  'content': 'Improved early clear speed.',
                },
              ],
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/166');
    expect(find.text('Patch history focus'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Jungle tuning'),
      320,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Jungle tuning'), findsOneWidget);
  });
}
