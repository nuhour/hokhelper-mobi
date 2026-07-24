import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/skin_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_match_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_player_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_stat_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_team_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/presentation/esports_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

Widget _buildHomeScreen(HomeStats stats) {
  return ProviderScope(
    overrides: [homeStatsProvider.overrideWith((ref) async => stats)],
    child: const MaterialApp(home: Scaffold(body: HomeScreen())),
  );
}

Future<void> _scrollHomeUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 260,
  int maxScrolls = 16,
}) async {
  for (var attempt = 0; attempt < maxScrolls; attempt++) {
    if (tester.any(finder)) {
      return;
    }
    await tester.drag(
      find.byKey(const ValueKey('home-main-scroll-view')),
      Offset(0, -delta),
    );
    await tester.pumpAndSettle();
  }
}

Finder _portalMenuScrollable() {
  return find.descendant(
    of: find.byKey(const ValueKey('home-portal-menu-drawer')),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
}

Finder _portalMenuText(String text) {
  return find.descendant(
    of: find.byKey(const ValueKey('home-portal-menu-drawer')),
    matching: find.text(text),
  );
}

void main() {
  testWidgets('home screen follows the hokx mobile portal framework', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHomeScreen(
        const HomeStats(
          success: true,
          message: 'Home portal ready',
          result: {
            'hero_ranking_table': {
              'rows': [
                {
                  'hero': {'name': 'Angela', 'main_job': 'Mage'},
                  'win_rate': 0.56,
                },
              ],
            },
            'patch_notes': [
              {
                'title': 'Patch 1.2',
                'content_preview': 'Balance update',
                'version': '1.2',
              },
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esports'), findsWidgets);
    expect(find.text('Skins'), findsOneWidget);
    expect(find.text('Heroes'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('HOK HELPER'), findsOneWidget);
    expect(find.textContaining('Live Now'), findsOneWidget);
    expect(find.text('Core Stats'), findsOneWidget);
    expect(find.text('Tier List'), findsAtLeastNWidgets(1));

    expect(find.text('Trending Heroes'), findsNothing);
    expect(find.text('BP Simulator'), findsNothing);
    expect(find.text('Quick Tools'), findsNothing);
  });

  testWidgets('home top tabs are centered and switch pages in place', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(
          path: '/heroes',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/content/skins',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/esports/schedule',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async {
            return const HomeStats(
              success: true,
              message: 'Home portal ready',
              result: {},
            );
          }),
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                name: 'Angela',
                avatar: '',
                title: 'Arcane Mage',
              ),
            ];
          }),
          skinGalleryProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 1,
                kind: ContentKind.skin,
                title: 'Starlight',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Epic',
                rating: 4.8,
                ratingCount: 12,
                viewCount: 99,
              ),
            ];
          }),
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: 'm1',
                leagueName: 'KPL',
                stageName: 'Playoffs',
                teamAName: 'Team A',
                teamALogoUrl: '',
                teamBName: 'Team B',
                teamBLogoUrl: '',
                scoreA: 1,
                scoreB: 0,
                statusKey: 'live',
                startTime: '2026-07-08T12:00:00Z',
              ),
            ];
          }),
          esportsStatsProvider.overrideWith(
            (ref) async => const <EsportsStatSummary>[],
          ),
          esportsTeamsProvider.overrideWith(
            (ref) async => const <EsportsTeamSummary>[],
          ),
          esportsPlayersProvider.overrideWith(
            (ref) async => const <EsportsPlayerSummary>[],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-top-tab-strip')), findsOneWidget);
    expect(find.text('HOK HELPER'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-3')),
      findsOneWidget,
    );

    await tester.tap(find.text('Heroes'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Heroes'), findsWidgets);
    expect(find.text('Angela'), findsWidgets);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-2')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('home-tab-page-view')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Skin Gallery'), findsOneWidget);
    expect(find.text('Starlight'), findsWidgets);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Esports'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Esports'), findsWidgets);
    expect(find.text('Matches'), findsWidgets);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-0')),
      findsOneWidget,
    );
  });

  testWidgets('home menu lists filtered hokx portal menu groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHomeScreen(
        const HomeStats(
          success: true,
          message: 'Home portal ready',
          result: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-portal-menu-drawer')),
      findsOneWidget,
    );
    expect(find.text('站点菜单'), findsNothing);
    expect(_portalMenuText('Home'), findsNothing);
    expect(_portalMenuText('Heroes'), findsOneWidget);
    expect(_portalMenuText('Gallery'), findsWidgets);
    expect(_portalMenuText('Tier List'), findsOneWidget);
    expect(_portalMenuText('Power Trends'), findsOneWidget);
    expect(_portalMenuText('Skins'), findsOneWidget);
    expect(_portalMenuText('CG Center'), findsOneWidget);
    expect(_portalMenuText('Community'), findsOneWidget);
    expect(_portalMenuText('Player Leaderboard'), findsOneWidget);
    expect(_portalMenuText('Forum'), findsOneWidget);
    expect(_portalMenuText('Leaks'), findsOneWidget);
    expect(_portalMenuText('Event Help'), findsOneWidget);
    expect(_portalMenuText('Esports'), findsOneWidget);
    expect(_portalMenuText('Schedule'), findsOneWidget);
    expect(_portalMenuText('Esports Stats'), findsOneWidget);
    expect(_portalMenuText('Teams'), findsOneWidget);
    expect(_portalMenuText('Pro Players'), findsOneWidget);

    await tester.scrollUntilVisible(
      _portalMenuText('Tools'),
      180,
      scrollable: _portalMenuScrollable(),
    );
    expect(_portalMenuText('Tools'), findsOneWidget);
    expect(_portalMenuText('Global BP Simulator'), findsOneWidget);
    expect(_portalMenuText('Tier List Editor'), findsOneWidget);
    expect(_portalMenuText('AI Prompts'), findsOneWidget);
    expect(_portalMenuText('Team Builder'), findsOneWidget);
    expect(_portalMenuText('Builds'), findsOneWidget);
    expect(_portalMenuText('Game Assistant'), findsOneWidget);
    expect(_portalMenuText('Rank Fortune'), findsOneWidget);

    expect(find.text('友链'), findsNothing);
    expect(find.text('关于站点'), findsNothing);
    expect(find.text('关系图谱'), findsNothing);
    expect(find.text('王者大陆'), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-portal-menu-drawer')), findsNothing);
  });

  testWidgets('home screen renders hokx portal preview sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHomeScreen(
        const HomeStats(
          success: true,
          message: 'Home portal ready',
          result: {
            'hero_ranking_table': {
              'columns': [
                {'id': 'hero', 'label': '英雄', 'type': 'hero'},
                {'id': 'trend_smoothed', 'label': '胜率趋势', 'type': 'sparkline'},
                {'id': 'wr', 'label': '胜率', 'type': 'percent'},
                {'id': 'pick_rate', 'label': '出场率', 'type': 'percent'},
              ],
              'rows': [
                {
                  'hero': {'id': 2619, 'heroId': '563', 'name': 'Heino'},
                  'wr': 56.2,
                  'pick_rate': 12.4,
                  'trend_smoothed': [50.1, 51.4, 50.8, 53.2],
                },
              ],
            },
            'tier_list': [
              {
                'tier': 'T0',
                'heroes': [
                  {'id': 2624, 'name': 'Dolia'},
                ],
              },
            ],
            'player_ranking': {
              'peak': [
                {
                  'player_id': 'top-player',
                  'player_name': 'Top Player',
                  'avatar_url': 'https://example.test/top-player.jpg',
                  'region': 340,
                  'peak_score': 2400,
                  'avg_kda': 8.7,
                },
              ],
            },
            'community_hot': [
              {
                'title': '7月16日版本更新公告',
                'content_preview': '亲爱的玩家，本次版本即将更新。',
                'created_at': '2026-07-15T10:00:52Z',
                'view_count': 321,
                'like_count': 45,
                'comment_count': 6,
              },
            ],
            'patch_notes': [
              {
                'title': '7月16日版本更新公告',
                'content_preview': '英雄平衡性调整。',
                'publish_time': '2026-07-15T10:00:52Z',
              },
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollHomeUntilVisible(tester, find.text('Hero Rankings'));
    expect(find.text('Hero Rankings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-hero-ranking-fixed-header')),
      findsOneWidget,
    );
    expect(find.text('Win Rate'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('home-hero-avatar-2619')),
      findsAtLeastNWidgets(1),
    );
    final heinoImage = tester.widget<CachedNetworkImage>(
      find
          .descendant(
            of: find.byKey(const ValueKey('home-hero-avatar-2619')),
            matching: find.byType(CachedNetworkImage),
          )
          .first,
    );
    expect(heinoImage.imageUrl, endsWith('/static/game/hero/2619.png'));
    expect(find.text('Heino'), findsNothing);
    expect(find.byKey(const ValueKey('home-trend-2619')), findsOneWidget);

    await _scrollHomeUntilVisible(tester, find.text('Tier List'));
    expect(find.text('Tier List'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('home-hero-avatar-2624')),
      findsAtLeastNWidgets(1),
    );

    await _scrollHomeUntilVisible(tester, find.text('Leaderboard'));
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('KDA'), findsNothing);
    expect(
      find.byKey(const ValueKey('home-player-avatar-top-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-player-flag-top-player')),
      findsOneWidget,
    );
    expect(find.text('Honduras'), findsOneWidget);
    expect(find.text('PEAK SCORE'), findsOneWidget);
    expect(find.text('2400'), findsOneWidget);

    await _scrollHomeUntilVisible(tester, find.text('Community Hot'));
    expect(find.text('Community Hot'), findsOneWidget);
    expect(
      find.text('Honor of Kings Update · Jul 15, 2026'),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('亲爱的玩家'), findsNothing);
    expect(find.text('321'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    await _scrollHomeUntilVisible(tester, find.text('Latest Updates'));
    expect(find.text('Latest Updates'), findsOneWidget);
    expect(
      find.text('Honor of Kings Update · Jul 15, 2026'),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('英雄平衡性调整'), findsNothing);
  });

  testWidgets('home hero ranking opens hero detail inside the home portal', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: HomeScreen(
              initialPortalTab: state.uri.queryParameters['tab'],
              initialHeroId: state.uri.queryParameters['hero_id'],
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith(
            (ref) async => const HomeStats(
              success: true,
              message: 'Ready',
              result: {
                'hero_ranking_table': {
                  'columns': [
                    {'id': 'hero', 'label': 'Hero', 'type': 'hero'},
                    {'id': 'wr', 'label': 'Win Rate', 'type': 'percent'},
                  ],
                  'rows': [
                    {
                      'hero': {'id': 2619, 'heroId': '563', 'name': 'Heino'},
                      'wr': 51.2,
                    },
                  ],
                },
              },
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const ValueKey('home-hero-open-2619')),
    );

    await tester.tap(find.byKey(const ValueKey('home-hero-open-2619')));
    await tester.pump();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'heroes',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['hero_id'],
      '2619',
    );
  });

  testWidgets('home screen exposes hokx portal tool and topic entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHomeScreen(
        const HomeStats(
          success: true,
          message: 'Backend connected',
          result: {'heroes': 128},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Core Stats'), findsOneWidget);
    expect(find.text('Tier List'), findsAtLeastNWidgets(1));
    expect(find.text('BP Simulator'), findsNothing);
    expect(find.text('Quick Tools'), findsNothing);
    expect(find.text('HOK World'), findsAtLeastNWidgets(1));
    expect(find.text('Enter HOK World Topic'), findsNothing);
  });

  testWidgets(
    'compact viewport keeps the data-first home surface overflow-free',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildHomeScreen(
          const HomeStats(success: true, message: 'Ready', result: {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Backend connected'), findsNothing);
      expect(find.text('Ready'), findsNothing);
    },
  );

  testWidgets('long hero rankings keep the fixed hero column overflow-free', (
    tester,
  ) async {
    final rows = List.generate(
      20,
      (index) => {
        'hero': {'id': 2500 + index, 'name': 'Hero $index'},
        'wr': 50 + index / 10,
        'pick_rate': 10 + index / 10,
      },
    );

    await tester.pumpWidget(
      _buildHomeScreen(
        HomeStats(
          success: true,
          message: 'Ready',
          result: {
            'hero_ranking_table': {
              'columns': const [
                {'id': 'hero', 'label': 'Hero', 'type': 'hero'},
                {'id': 'wr', 'label': 'Win Rate', 'type': 'percent'},
                {'id': 'pick_rate', 'label': 'Pick Rate', 'type': 'percent'},
              ],
              'rows': rows,
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollHomeUntilVisible(tester, find.text('Hero Rankings'));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('home-hero-ranking-scroll-area')),
      findsOneWidget,
    );
  });
}
