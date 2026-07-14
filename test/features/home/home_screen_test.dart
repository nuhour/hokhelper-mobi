import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    of: find.byType(BottomSheet),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
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

    expect(find.text('站点菜单'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('英雄'), findsWidgets);
    expect(find.text('图鉴'), findsWidgets);
    expect(find.text('梯度榜'), findsOneWidget);
    expect(find.text('强度趋势'), findsOneWidget);
    expect(find.text('皮肤'), findsWidgets);
    expect(find.text('CG'), findsOneWidget);
    expect(find.text('社区'), findsWidgets);
    expect(find.text('玩家排行榜'), findsOneWidget);
    expect(find.text('论坛'), findsOneWidget);
    expect(find.text('爆料'), findsOneWidget);
    expect(find.text('活动互助'), findsOneWidget);
    expect(find.text('赛事'), findsOneWidget);
    expect(find.text('赛程'), findsOneWidget);
    expect(find.text('赛事统计'), findsOneWidget);
    expect(find.text('战队'), findsOneWidget);
    expect(find.text('职业选手'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('工具'),
      180,
      scrollable: _portalMenuScrollable(),
    );
    expect(find.text('工具'), findsWidgets);
    expect(find.text('全局 BP 模拟器'), findsOneWidget);
    expect(find.text('梯度编辑器'), findsOneWidget);
    expect(find.text('AI 提示词'), findsOneWidget);
    expect(find.text('阵容搭配'), findsOneWidget);
    expect(find.text('出装方案'), findsOneWidget);
    expect(find.text('局内助手'), findsOneWidget);
    expect(find.text('上分运势'), findsOneWidget);

    expect(find.text('友链'), findsNothing);
    expect(find.text('关于站点'), findsNothing);
    expect(find.text('关系图谱'), findsNothing);
    expect(find.text('王者大陆'), findsNothing);
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
                {'id': 'hero', 'label': 'Hero', 'type': 'hero'},
                {'id': 'wr', 'label': 'Win Rate', 'type': 'percent'},
                {'id': 'pick_rate', 'label': 'Pick Rate', 'type': 'percent'},
              ],
              'rows': [
                {
                  'hero': {'id': 2625, 'name': 'Angela'},
                  'wr': 56.2,
                  'pick_rate': 12.4,
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
                  'region': 840,
                  'peak_score': 2400,
                },
              ],
            },
            'community_hot': [
              {'title': 'Draft talk', 'content_preview': 'Ban pick ideas'},
            ],
            'patch_notes': [
              {'title': 'Patch 1.2', 'content_preview': 'Balance update'},
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
      findsAtLeastNWidgets(2),
    );
    expect(find.text('Win Rate'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('home-hero-avatar-2625')),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('Angela'), findsNothing);

    await _scrollHomeUntilVisible(tester, find.text('Tier List Preview'));
    expect(find.text('Tier List Preview'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-hero-avatar-2624')),
      findsAtLeastNWidgets(1),
    );

    await _scrollHomeUntilVisible(tester, find.text('Leaderboard'));
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-player-avatar-top-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-player-flag-top-player')),
      findsOneWidget,
    );

    await _scrollHomeUntilVisible(tester, find.text('Community Hot'));
    expect(find.text('Community Hot'), findsOneWidget);
    expect(find.text('Draft talk'), findsOneWidget);

    await _scrollHomeUntilVisible(tester, find.text('Latest Updates'));
    expect(find.text('Latest Updates'), findsOneWidget);
    expect(find.text('Patch 1.2'), findsAtLeastNWidgets(1));
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
}
