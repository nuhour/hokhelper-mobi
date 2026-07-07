import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/search/data/search_repository.dart';
import 'package:hok_helper_mobile/src/features/search/presentation/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSearchRepository extends SearchRepository {
  _FakeSearchRepository({this.resultData = _defaultResultData})
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
  final Map<String, dynamic> resultData;

  static const _defaultResultData = {
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
  };

  @override
  Future<Map<String, dynamic>> search(String keyword, int regionId) async {
    requestedKeyword = keyword;
    requestedRegionId = regionId;
    return {
      'success': true,
      'message': 'ok',
      'result': {'data': resultData},
    };
  }
}

void main() {
  testWidgets('hero search results expose hokx quick actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeSearchRepository();
    final router = GoRouter(
      initialLocation: '/search?q=arthur',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) =>
              SearchScreen(initialQuery: state.uri.queryParameters['q']),
        ),
        GoRoute(
          path: '/trends',
          builder: (context, state) =>
              Text('Trend hero ${state.uri.queryParameters['hero_id']}'),
        ),
        GoRoute(
          path: '/tools/build-sim',
          builder: (context, state) =>
              Text('Build hero ${state.uri.queryParameters['hero_id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('Build Sim'), findsOneWidget);

    await tester.tap(find.text('Trend'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/trends');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['hero_id'],
      '166',
    );
    expect(find.text('Trend hero 166'), findsOneWidget);
  });

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

  testWidgets('ranked player search results open the player leaderboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeSearchRepository(
      resultData: const {
        'players': [
          {
            'player_id': 'peak-1',
            'player_name': 'PeakPlayer',
            'rank_type': 'peak',
            'region': 44,
          },
        ],
      },
    );
    final router = GoRouter(
      initialLocation: '/search?q=peak',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) =>
              SearchScreen(initialQuery: state.uri.queryParameters['q']),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => Text(
            'Leaderboard ${state.uri.queryParameters['rank_type']} ${state.uri.queryParameters['region_id']}',
          ),
        ),
        GoRoute(
          path: '/tools/stats',
          builder: (context, state) =>
              Text('Stats ${state.uri.queryParameters['entry']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Players (1)'), findsOneWidget);
    expect(find.text('PeakPlayer'), findsOneWidget);
    expect(find.text('Player Rank'), findsOneWidget);

    await tester.tap(find.text('PeakPlayer'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/leaderboard');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['rank_type'],
      'peak',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['region_id'],
      '44',
    );
    expect(find.text('Leaderboard peak 44'), findsOneWidget);

    router.go('/search?q=peak');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Player Rank'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/tools/stats');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['entry'],
      'player_rank',
    );
    expect(find.text('Stats player_rank'), findsOneWidget);
  });
}
