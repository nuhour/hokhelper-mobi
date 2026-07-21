import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_simulator_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';

void main() {
  testWidgets('guest explores builds without loading private slots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(432, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requestedPrivateSlots = false;
    var cloned = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildSimHeroesProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '199',
                heroId: '199',
                name: 'Lam',
                avatar: '',
                title: 'Shark Blade',
              ),
            ];
          }),
          buildSimPublicSchemesProvider.overrideWith((ref) async {
            return const [
              BuildSchemeSummary(
                id: 7,
                title: 'Public build',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: ['/static/game/equip/101.png'],
                likeCount: 1,
                favoriteCount: 2,
                cloneCount: 3,
                isPublic: true,
              ),
            ];
          }),
          buildSimUserSlotsProvider.overrideWith((ref, heroId) async {
            requestedPrivateSlots = true;
            return const [];
          }),
          buildSimCloneSchemeProvider.overrideWith((ref) {
            return (scheme, slotIndex) async => cloned = true;
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BuildSimulatorScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Builds'), findsNothing);
    expect(find.text('Public build'), findsOneWidget);
    expect(requestedPrivateSlots, isFalse);

    final cloneButton = find.byTooltip('Choose clone slot');
    await tester.ensureVisible(cloneButton);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(cloneButton);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Sign in to save or interact with builds'),
      findsOneWidget,
    );
    expect(cloned, isFalse);
  });
}
