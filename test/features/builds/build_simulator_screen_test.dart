import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_editor_asset.dart';
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
            buildSimEditorCatalogProvider.overrideWith((ref) async {
              return const BuildEditorCatalog(
                equips: [
                  BuildEquipSummary(id: 101, name: 'Storm Axe', iconUrl: ''),
                ],
                runes: [BuildRuneSummary(id: 201, name: 'Fate', color: 1)],
                summonerSkills: [
                  BuildSummonerSkillSummary(id: 12, name: 'Smite', iconUrl: ''),
                ],
              );
            }),
            buildSimSaveSchemeProvider.overrideWith((ref) {
              return (_) async {};
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

  testWidgets('selects initial hero from build simulator deep link', (
    tester,
  ) async {
    final requestedSlots = <int>[];

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
              HeroSummary(
                id: '166',
                heroId: '166',
                name: 'Angela',
                avatar: '',
                title: 'Blazing Mage',
              ),
            ];
          }),
          buildSimPublicSchemesProvider.overrideWith((ref) async => const []),
          buildSimUserSlotsProvider.overrideWith((ref, heroId) async {
            requestedSlots.add(heroId);
            return [
              BuildSchemeSummary(
                id: heroId,
                title: heroId == 166 ? 'Angela opener' : 'Lam opener',
                heroName: heroId == 166 ? 'Angela' : 'Lam',
                authorName: 'me',
                equipmentIcons: const [],
                likeCount: 0,
                favoriteCount: 0,
                cloneCount: 0,
                isPublic: false,
                slotIndex: 1,
              ),
              null,
              null,
            ];
          }),
          buildSimEditorCatalogProvider.overrideWith((ref) async {
            return const BuildEditorCatalog(
              equips: [],
              runes: [],
              summonerSkills: [],
            );
          }),
          buildSimSaveSchemeProvider.overrideWith((ref) {
            return (_) async {};
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BuildSimulatorScreen(initialHeroId: 166)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedSlots, contains(166));
    expect(find.text('Angela'), findsWidgets);
    expect(find.text('Angela opener'), findsOneWidget);
    expect(find.text('Blazing Mage'), findsOneWidget);
  });

  testWidgets('opens slot editor and saves a mobile build draft', (
    tester,
  ) async {
    BuildSchemeDraft? savedDraft;

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
          buildSimPublicSchemesProvider.overrideWith((ref) async => const []),
          buildSimUserSlotsProvider.overrideWith((ref, heroId) async {
            return const [null, null, null];
          }),
          buildSimEditorCatalogProvider.overrideWith((ref) async {
            return const BuildEditorCatalog(
              equips: [
                BuildEquipSummary(id: 101, name: 'Storm Axe', iconUrl: ''),
                BuildEquipSummary(id: 102, name: 'Swift Boots', iconUrl: ''),
              ],
              runes: [BuildRuneSummary(id: 201, name: 'Fate', color: 1)],
              summonerSkills: [
                BuildSummonerSkillSummary(id: 12, name: 'Smite', iconUrl: ''),
              ],
            );
          }),
          buildSimSaveSchemeProvider.overrideWith((ref) {
            return (draft) async {
              savedDraft = draft;
            };
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BuildSimulatorScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empty slot').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('Edit Build Slot 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mobile burst');
    await tester.tap(find.text('Storm Axe'));
    await tester.tap(find.text('Swift Boots'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move Swift Boots up'));
    await tester.tap(find.byTooltip('Remove Storm Axe'));
    await tester.tap(find.text('Public'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('Red Arcana Matrix'), findsOneWidget);
    expect(find.text('Blue Arcana Matrix'), findsOneWidget);
    expect(find.text('Green Arcana Matrix'), findsOneWidget);
    expect(find.text('0/10'), findsNWidgets(3));
    await tester.tap(find.text('Fate').last);
    await tester.pumpAndSettle();
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('0/10'), findsNWidgets(2));
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smite').last);
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Build').last);
    await tester.pumpAndSettle();

    expect(savedDraft?.heroId, 199);
    expect(savedDraft?.slotIndex, 1);
    expect(savedDraft?.title, 'Mobile burst');
    expect(savedDraft?.isPublic, true);
    expect(savedDraft?.equipIds, [102]);
    expect(savedDraft?.runeIds, [201]);
    expect(savedDraft?.summonerSkillId, 12);
  });

  testWidgets('runs community build like favorite and clone actions', (
    tester,
  ) async {
    final actions = <String>[];

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
            return const [null, null, null];
          }),
          buildSimEditorCatalogProvider.overrideWith((ref) async {
            return const BuildEditorCatalog(
              equips: [],
              runes: [],
              summonerSkills: [],
            );
          }),
          buildSimSaveSchemeProvider.overrideWith((ref) {
            return (_) async {};
          }),
          buildSimLikeSchemeProvider.overrideWith((ref) {
            return (scheme) async {
              actions.add('like:${scheme.id}');
            };
          }),
          buildSimFavoriteSchemeProvider.overrideWith((ref) {
            return (scheme) async {
              actions.add('favorite:${scheme.id}');
            };
          }),
          buildSimCloneSchemeProvider.overrideWith((ref) {
            return (scheme, slotIndex) async {
              actions.add('clone:${scheme.id}:$slotIndex');
            };
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BuildSimulatorScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -720));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Like'));
    await tester.tap(find.text('Favorite'));
    await tester.tap(find.text('Clone S2'));
    await tester.pumpAndSettle();

    expect(actions, ['like:7', 'favorite:7', 'clone:7:2']);
  });
}
