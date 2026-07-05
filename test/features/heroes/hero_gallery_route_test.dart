import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
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
}
