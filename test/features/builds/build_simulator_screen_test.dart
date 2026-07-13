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

      expect(find.text('Lam'), findsWidgets);
      expect(find.text('My Builds'), findsWidgets);
      expect(find.text('BUILD 1'), findsOneWidget);
      expect(find.text('My Lam build'), findsOneWidget);
      expect(find.text('Create Build 2'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -720));
      await tester.pumpAndSettle();
      expect(find.text('Explore Builds'), findsOneWidget);
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
  });

  testWidgets('pins shared community build from scheme deep link', (
    tester,
  ) async {
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
                id: 1,
                title: 'Public build 1',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: [],
                likeCount: 1,
                favoriteCount: 1,
                cloneCount: 1,
                isPublic: true,
              ),
              BuildSchemeSummary(
                id: 2,
                title: 'Public build 2',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: [],
                likeCount: 2,
                favoriteCount: 2,
                cloneCount: 2,
                isPublic: true,
              ),
              BuildSchemeSummary(
                id: 3,
                title: 'Public build 3',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: [],
                likeCount: 3,
                favoriteCount: 3,
                cloneCount: 3,
                isPublic: true,
              ),
              BuildSchemeSummary(
                id: 4,
                title: 'Public build 4',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: [],
                likeCount: 4,
                favoriteCount: 4,
                cloneCount: 4,
                isPublic: true,
              ),
              BuildSchemeSummary(
                id: 5,
                title: 'Public build 5',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: [],
                likeCount: 5,
                favoriteCount: 5,
                cloneCount: 5,
                isPublic: true,
              ),
              BuildSchemeSummary(
                id: 42,
                title: 'Shared target build',
                heroName: 'Angela',
                authorName: 'sharer',
                equipmentIcons: [],
                likeCount: 12,
                favoriteCount: 8,
                cloneCount: 4,
                isPublic: true,
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
        ],
        child: const MaterialApp(
          home: Scaffold(body: BuildSimulatorScreen(initialSchemeId: 42)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -2200));
    await tester.pumpAndSettle();

    expect(find.text('Shared build'), findsOneWidget);
    expect(find.text('Shared target build'), findsOneWidget);
    expect(find.textContaining('sharer'), findsOneWidget);
  });

  testWidgets('opens favorite builds from initial community filter', (
    tester,
  ) async {
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
                equipmentIcons: [],
                likeCount: 1,
                favoriteCount: 1,
                cloneCount: 1,
                isPublic: true,
              ),
            ];
          }),
          buildSimFavoriteSchemesProvider.overrideWith((ref) async {
            return const [
              BuildSchemeSummary(
                id: 42,
                title: 'Favorite mobile build',
                heroName: 'Angela',
                authorName: 'collector',
                equipmentIcons: [],
                likeCount: 12,
                favoriteCount: 9,
                cloneCount: 4,
                isPublic: true,
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
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BuildSimulatorScreen(
              initialCommunityFilter: BuildSimCommunityFilter.favorites,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -2200));
    await tester.pumpAndSettle();

    expect(find.text('Favorite Builds'), findsOneWidget);
    expect(find.text('Favorite mobile build'), findsOneWidget);
    expect(find.textContaining('collector'), findsOneWidget);
    expect(find.text('Public build'), findsNothing);
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

    await tester.tap(find.text('Create Build 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Arcana Matrix'), findsOneWidget);
    expect(find.text('Skill'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mobile burst');
    await tester.ensureVisible(find.bySemanticsLabel('Storm Axe'));
    await tester.tap(find.bySemanticsLabel('Storm Axe'));
    await tester.ensureVisible(find.bySemanticsLabel('Swift Boots'));
    await tester.tap(find.bySemanticsLabel('Swift Boots'));
    await tester.pump();
    await tester.tap(find.byTooltip('Private build'));
    await tester.tap(find.text('Arcana Matrix'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('0/10'), findsNWidgets(3));
    await tester.tap(find.text('Fate'));
    await tester.pump();
    expect(find.text('1/10'), findsOneWidget);
    await tester.tap(find.text('Skill'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Smite'));
    await tester.pump();
    await tester.tap(find.byTooltip('Save build'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(savedDraft?.heroId, 199);
    expect(savedDraft?.slotIndex, 1);
    expect(savedDraft?.title, 'Mobile burst');
    expect(savedDraft?.isPublic, true);
    expect(savedDraft?.equipIds, [101, 102]);
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

    await tester.drag(find.byType(ListView).first, const Offset(0, -2200));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Like build'));
    await tester.tap(find.byTooltip('Favorite build'));
    await tester.tap(find.byTooltip('Clone to slot 1'));
    await tester.pumpAndSettle();

    expect(actions, ['like:7', 'favorite:7', 'clone:7:1']);
  });

  testWidgets('shows liked favorite state and toggles community reactions', (
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
                isLiked: true,
                isFavorited: true,
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
              actions.add('${scheme.isLiked ? 'unlike' : 'like'}:${scheme.id}');
            };
          }),
          buildSimFavoriteSchemeProvider.overrideWith((ref) {
            return (scheme) async {
              actions.add(
                '${scheme.isFavorited ? 'unfavorite' : 'favorite'}:${scheme.id}',
              );
            };
          }),
          buildSimCloneSchemeProvider.overrideWith((ref) {
            return (_, _) async {};
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BuildSimulatorScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -2200));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unlike build'), findsOneWidget);
    expect(find.byTooltip('Unfavorite build'), findsOneWidget);

    await tester.tap(find.byTooltip('Unlike build'));
    await tester.tap(find.byTooltip('Unfavorite build'));
    await tester.pumpAndSettle();

    expect(actions, ['unlike:7', 'unfavorite:7']);
  });
}
