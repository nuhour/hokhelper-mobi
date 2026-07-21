import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_relationship.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_relationships_screen.dart';

void main() {
  testWidgets('opens the unrestricted global relationship network', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRelationshipsProvider.overrideWith((ref) async {
            return const [
              HeroRelationship(
                id: '1',
                sourceHeroId: '101',
                sourceHeroName: 'Lam',
                targetHeroId: '202',
                targetHeroName: 'Angela',
                title: 'Starlight Pact',
                weight: 86,
                description: 'They share a story arc.',
              ),
              HeroRelationship(
                id: '2',
                sourceHeroId: '303',
                sourceHeroName: 'Arthur',
                targetHeroId: '101',
                targetHeroName: 'Lam',
                title: 'Battle Memory',
                weight: 44,
                description: 'Old battlefield connection.',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: HeroRelationshipsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.byTooltip('Reset view'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('2 links'), findsNothing);
    expect(find.text('Starlight Pact'), findsNothing);
    expect(find.text('Battle Memory'), findsNothing);

    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('relationship-network-focus')),
      findsOneWidget,
    );
    expect(find.byTooltip('Reset view'), findsNothing);

    await tester.tap(find.text('Lam').first);
    await tester.pumpAndSettle();

    expect(find.text('Relationships'), findsOneWidget);
    expect(find.text('Starlight Pact'), findsOneWidget);
  });

  testWidgets('hydrates focused hero from initial hero id', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRelationshipsProvider.overrideWith((ref) async {
            return const [
              HeroRelationship(
                id: '1',
                sourceHeroId: '166',
                sourceHeroName: 'Lam',
                targetHeroId: '202',
                targetHeroName: 'Angela',
                title: 'Starlight Pact',
                weight: 86,
                description: 'They share a story arc.',
              ),
              HeroRelationship(
                id: '2',
                sourceHeroId: '303',
                sourceHeroName: 'Arthur',
                targetHeroId: '404',
                targetHeroName: 'Dolia',
                title: 'River Memory',
                weight: 44,
                description: 'A distant connection.',
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: HeroRelationshipsScreen(initialHeroId: '166'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
