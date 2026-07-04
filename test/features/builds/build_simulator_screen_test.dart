import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_simulator_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';

void main() {
  testWidgets(
    'renders mobile build simulator hero slots and community builds',
    (tester) async {
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
                  title: 'Burst jungle',
                  heroName: 'Lam',
                  authorName: 'coach',
                  equipmentIcons: [],
                  likeCount: 12,
                  favoriteCount: 5,
                  cloneCount: 3,
                  isPublic: true,
                  slotIndex: 1,
                ),
              ];
            }),
            buildSimUserSlotsProvider.overrideWith((ref, heroId) async {
              return const [
                BuildSchemeSummary(
                  id: 8,
                  title: 'My Lam build',
                  heroName: 'Lam',
                  authorName: 'me',
                  equipmentIcons: [],
                  likeCount: 2,
                  favoriteCount: 1,
                  cloneCount: 0,
                  isPublic: false,
                  slotIndex: 1,
                ),
                null,
                null,
              ];
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BuildSimulatorScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Build Simulator'), findsOneWidget);
      expect(find.text('Lam'), findsWidgets);
      expect(find.text('My Slots'), findsOneWidget);
      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.text('My Lam build'), findsOneWidget);
      expect(find.text('Slot 2'), findsOneWidget);
      expect(find.text('Empty slot'), findsWidgets);
      await tester.drag(find.byType(ListView).first, const Offset(0, -720));
      await tester.pumpAndSettle();
      expect(find.text('Community Builds'), findsOneWidget);
      expect(find.text('Burst jungle'), findsOneWidget);
    },
  );
}
