import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/search/data/search_repository.dart';
import 'package:hok_helper_mobile/src/features/search/presentation/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSearchRepository extends SearchRepository {
  _FakeSearchRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  String? requestedKeyword;
  int? requestedRegionId;

  @override
  Future<Map<String, dynamic>> search(String keyword, int regionId) async {
    requestedKeyword = keyword;
    requestedRegionId = regionId;
    return const {
      'success': true,
      'message': 'ok',
      'result': {
        'data': {
          'heroes': [
            {'id': 166, 'name': 'Arthur', 'subtitle': 'Paladin captain'},
          ],
          'builds': [
            {
              'id': 9,
              'name': 'Arthur Clash Build',
              'subtitle': 'Warrior sustain setup',
              'url': '/about',
            },
          ],
        },
      },
    };
  }
}

void main() {
  testWidgets('search route query auto-runs global search', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeSearchRepository();
    final router = createAppRouter();
    router.go('/search?q=arthur');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(repository),
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 166, 'name': 'Arthur'},
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'arthur'), findsOneWidget);
    expect(repository.requestedKeyword, 'arthur');
    expect(repository.requestedRegionId, 2);
    expect(find.text('Heroes (1)'), findsOneWidget);
    expect(find.text('Arthur'), findsOneWidget);

    await tester.tap(find.text('Arthur'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/166');
    expect(find.text('Hero #166'), findsOneWidget);
  });

  testWidgets('search route submits global query and renders grouped results', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeSearchRepository();
    final router = createAppRouter();
    router.go('/search');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(repository),
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 166, 'name': 'Arthur'},
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global Search'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'arthur');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repository.requestedKeyword, 'arthur');
    expect(repository.requestedRegionId, 2);
    expect(find.text('Heroes (1)'), findsOneWidget);
    expect(find.text('Arthur'), findsOneWidget);
    expect(find.text('Paladin captain'), findsOneWidget);
    expect(find.text('Builds (1)'), findsOneWidget);
    expect(find.text('Arthur Clash Build'), findsOneWidget);

    await tester.tap(find.text('Arthur Clash Build'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/about');
    expect(find.text('About HOK Helper'), findsOneWidget);
    expect(find.text('Global Community Intel'), findsOneWidget);
  });
}
