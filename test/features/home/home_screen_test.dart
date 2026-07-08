import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

Widget _buildHomeScreen(HomeStats stats) {
  return ProviderScope(
    overrides: [homeStatsProvider.overrideWith((ref) async => stats)],
    child: const MaterialApp(home: Scaffold(body: HomeScreen())),
  );
}

Finder _mainScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
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

    expect(find.text('电竞'), findsOneWidget);
    expect(find.text('皮肤'), findsOneWidget);
    expect(find.text('英雄'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('Dominate the Rift'), findsOneWidget);
    expect(find.text('Search heroes, items, guides...'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Trending Heroes'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('Trending Heroes'), findsOneWidget);
    expect(find.text('Angela'), findsAtLeastNWidgets(1));
    expect(find.text('View All'), findsOneWidget);

    expect(find.text('BP Simulator'), findsAtLeastNWidgets(1));
    expect(find.text('Tier List'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Latest Patch'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('Latest Patch'), findsOneWidget);
    expect(find.text('Patch 1.2'), findsAtLeastNWidgets(1));
    expect(find.text('Read Notes'), findsOneWidget);
  });

  testWidgets('home top tabs switch in place and support horizontal swipe', (
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

    expect(find.text('Dominate the Rift'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-3')),
      findsOneWidget,
    );

    await tester.tap(find.text('英雄'));
    await tester.pumpAndSettle();
    expect(find.text('英雄图鉴'), findsAtLeastNWidgets(1));
    expect(find.text('Dominate the Rift'), findsNothing);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-2')),
      findsOneWidget,
    );

    await tester.fling(find.byType(PageView), const Offset(700, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('皮肤图鉴'), findsAtLeastNWidgets(1));
    expect(find.text('英雄图鉴'), findsNothing);
    expect(
      find.byKey(const ValueKey('home-top-tab-indicator-1')),
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
              'rows': [
                {
                  'hero': {'name': 'Angela'},
                  'win_rate': 0.56,
                },
              ],
            },
            'tier_list': [
              {
                'tier': 'T0',
                'heroes': [
                  {'name': 'Dolia'},
                ],
              },
            ],
            'player_ranking': {
              'peak': [
                {'player_name': 'Top Player', 'peak_score': 2400},
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

    await tester.scrollUntilVisible(
      find.text('Hero Rankings'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('Hero Rankings'), findsOneWidget);
    expect(find.text('Angela'), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.text('Tier List Preview'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('Tier List Preview'), findsOneWidget);
    expect(find.text('Dolia'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Leaderboard'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Top Player'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Community Hot'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('Community Hot'), findsOneWidget);
    expect(find.text('Draft talk'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Latest Updates'),
      240,
      scrollable: _mainScrollable(),
    );
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

    expect(find.text('View Core Stats'), findsOneWidget);
    expect(find.text('Enter Tier List'), findsOneWidget);
    expect(find.text('BP Simulator'), findsAtLeastNWidgets(1));
    expect(find.text('Tier Editor'), findsOneWidget);
    expect(find.text('AI Prompts'), findsOneWidget);
    expect(find.text('Team Builder'), findsOneWidget);
    expect(find.text('Build Sim'), findsOneWidget);
    expect(find.text('Rank Fortune'), findsOneWidget);
    expect(find.text('Event Assistance'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('HOK World'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('HOK World'), findsOneWidget);
    expect(find.text('Enter HOK World Topic'), findsOneWidget);
  });

  testWidgets('compact viewport handles many backend stats without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildHomeScreen(
        HomeStats(
          success: true,
          message: 'Ready with a dense payload from the backend.',
          result: {
            for (var index = 0; index < 18; index++)
              'statistic_$index': 'value_$index',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('statistic_17'),
      240,
      scrollable: _mainScrollable(),
    );
    expect(find.text('statistic_17'), findsOneWidget);
  });
}
