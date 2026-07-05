import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_editor_asset.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_simulator_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';

void main() {
  testWidgets('build simulator route focuses hero from hokx hero_id query', (
    tester,
  ) async {
    final requestedSlots = <int>[];
    final router = createAppRouter();

    router.go('/tools/build-sim?hero_id=166');

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
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/tools/build-sim');
    expect(requestedSlots, contains(166));
    expect(find.text('Angela opener'), findsOneWidget);
    expect(find.text('Blazing Mage'), findsOneWidget);
  });

  testWidgets('build simulator route pins shared scheme query', (tester) async {
    final router = createAppRouter();

    router.go('/tools/build-sim?scheme=42');

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
                title: 'Shared route build',
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
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -720));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/tools/build-sim');
    expect(find.text('Shared build'), findsOneWidget);
    expect(find.text('Shared route build'), findsOneWidget);
    expect(find.text('Angela · sharer'), findsOneWidget);
  });
}
