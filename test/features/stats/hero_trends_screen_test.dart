import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_image.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_trends.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';

import 'stats_trends_fixture.dart';

void main() {
  testWidgets('renders metadata driven filters, views, groups, and columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith((ref, query) async {
            return sampleStatsTrendTable(
              dimension: query.dimension,
              view: query.view,
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero'), findsWidgets);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Tier'), findsOneWidget);
    expect(find.text('Base Stats'), findsNothing);
    expect(find.text('Preparation'), findsNothing);
    expect(find.text('Trend Detail'), findsNothing);
    expect(find.text('All metrics'), findsNothing);
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('KDA'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    expect(find.text('56.10%'), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-signal-hero-199')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-best-skill-199')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-best-equip-199')), findsOneWidget);
    final skillImage = tester.widget<AppImage>(
      find
          .descendant(
            of: find.byKey(const ValueKey('trend-best-skill-199')),
            matching: find.byType(AppImage),
          )
          .first,
    );
    final equipImage = tester.widget<AppImage>(
      find
          .descendant(
            of: find.byKey(const ValueKey('trend-best-equip-199')),
            matching: find.byType(AppImage),
          )
          .first,
    );
    expect(skillImage.width, 17);
    expect(skillImage.height, 17);
    expect(skillImage.borderRadius, 999);
    expect(equipImage.width, 17);
    expect(equipImage.height, 17);
    expect(equipImage.borderRadius, 999);
    expect(find.text('🔥'), findsNWidgets(2));
    expect(find.text('热'), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_up_rounded), findsWidgets);
  });

  testWidgets('localizes backend Chinese metric headers in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith((ref, query) async {
            return sampleStatsTrendTable(
              columns: const [
                {'id': 'hero', 'label': '英雄', 'type': 'hero', 'sortable': true},
                {
                  'id': 'avg_total_hero_hurt_cnt',
                  'label': '对人伤害',
                  'type': 'number',
                  'sortable': true,
                  'group': '输出',
                },
                {
                  'id': 'avg_total_behurt_cnt_per_min',
                  'label': '分均承伤',
                  'type': 'number',
                  'sortable': true,
                  'group': '承伤',
                },
                {
                  'id': 'avg_money',
                  'label': '全部经济',
                  'type': 'number',
                  'sortable': true,
                  'group': '经济',
                },
              ],
              rows: const [
                {
                  'hero': {'id': 199, 'heroId': '199', 'name': 'Lam'},
                  'avg_total_hero_hurt_cnt': 100,
                  'avg_total_behurt_cnt_per_min': 200,
                  'avg_money': 300,
                },
              ],
            );
          }),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          home: Scaffold(body: HeroTrendsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero Damage'), findsOneWidget);
    expect(find.text('Taken / Min'), findsOneWidget);
    expect(find.text('Total Gold'), findsOneWidget);
    expect(find.text('Damage'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Economy'), findsOneWidget);
    expect(find.text('对人伤害'), findsNothing);
    expect(find.text('分均承伤'), findsNothing);
    expect(find.text('全部经济'), findsNothing);
  });

  testWidgets('renders player main hero images from camp hero ids', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith((ref, query) async {
            return sampleStatsTrendTable(
              dimension: 'player_rank',
              view: 'peak',
              columns: const [
                {
                  'id': 'player',
                  'label': '玩家',
                  'type': 'player',
                  'sortable': true,
                },
                {
                  'id': 'best_heroes',
                  'label': '常用英雄',
                  'type': 'hero_list',
                  'sortable': false,
                },
              ],
              rows: const [
                {
                  'player': {
                    'id': '13336883548184068654',
                    'name': 'Top Player',
                    'avatar_url': 'https://example.test/player.png',
                  },
                  'best_heroes': [
                    {'hero_id': 522, 'top_fight': 1234},
                    {
                      'hero_id': 150,
                      'avatar_url': 'https://example.test/han-xin.png',
                    },
                  ],
                },
              ],
            );
          }),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          home: Scaffold(body: HeroTrendsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mainHeroImages = tester
        .widgetList<AppImage>(find.byType(AppImage))
        .where((image) => image.width == 24 && image.height == 24)
        .map((image) => image.url)
        .toList(growable: false);
    expect(mainHeroImages, contains('https://img.nourhr.cc/heroes/522.png'));
    expect(mainHeroImages, contains('https://example.test/han-xin.png'));
    expect(find.text('1234'), findsOneWidget);
  });

  testWidgets('marks only the two largest seven-day rises and falls', (
    tester,
  ) async {
    final rows = <Object?>[
      _trendFixtureRow(1, [50, 51, 52, 54, 57, 59, 62]),
      _trendFixtureRow(2, [50, 51, 53, 55, 57, 58, 60]),
      _trendFixtureRow(3, [50, 50, 51, 51, 52, 52, 53]),
      _trendFixtureRow(4, [60, 58, 55, 53, 50, 47, 44]),
      _trendFixtureRow(5, [60, 59, 57, 55, 53, 51, 49]),
      _trendFixtureRow(6, [60, 60, 59, 59, 58, 58, 57]),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(rows: rows),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🔥'), findsNWidgets(2));
    expect(find.text('🧊'), findsNWidgets(2));
    expect(find.text('热'), findsNothing);
    final fireCenter = tester.getCenter(find.text('🔥').first);
    final trendCenter = tester.getCenter(
      find.byKey(const ValueKey('trend-signal-hero-1')),
    );
    expect((fireCenter.dy - trendCenter.dy).abs(), lessThan(10));
  });

  testWidgets('changes dimension and sends the matching table query', (
    tester,
  ) async {
    final dimensions = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith((ref, query) async {
            dimensions.add(query.dimension);
            return sampleStatsTrendTable(
              dimension: query.dimension,
              view: query.view,
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Power'));
    await tester.pumpAndSettle();

    expect(dimensions, contains('hero_rank'));
    expect(dimensions, contains('power_rank'));
  });

  testWidgets('opens the complete trend scope filters without asset errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Top 1000'));
    await tester.pumpAndSettle();

    expect(find.text('Trend scope'), findsOneWidget);
    expect(find.text('Lane'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.startsWith(
              'assets/lane-icons/',
            ),
      ),
      findsNWidgets(5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar opens preparation details instead of trend details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith(
            (ref, request) async => sampleStatsTrendDetail(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-avatar-hero-199')));
    await tester.pumpAndSettle();

    expect(find.text('Hero'), findsWidgets);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Single Equip'), findsOneWidget);
    expect(find.text('Builds'), findsOneWidget);
    await tester.tap(find.text('Single Equip'));
    await tester.pumpAndSettle();
    // HOKX 单件装备矩阵表：分组表头 + 排序列 + 槽位份额/胜率格。
    expect(find.text('Slot Distribution'), findsOneWidget);
    expect(find.text('Pick'), findsOneWidget);
    expect(find.text('70.24%'), findsOneWidget);
    expect(find.text('3790'), findsOneWidget);
    expect(find.text('61.40%'), findsOneWidget);
    expect(find.text('56.80%'), findsOneWidget);
    // 100% 去小数避免 88px 格内截断。
    expect(find.text('100%'), findsOneWidget);
    // 行内最大值高亮：份额黄粗、胜率玫红粗。
    final shareText = tester.widget<Text>(find.text('61.40%'));
    expect(shareText.style?.color, const Color(0xFFFACC15));
    expect(shareText.style?.fontWeight, FontWeight.w900);
    final winText = tester.widget<Text>(find.text('56.80%'));
    expect(winText.style?.color, const Color(0xFFF43F5E));
    expect(winText.style?.fontWeight, FontWeight.w900);
    expect(
      tester
          .widgetList<AppImage>(find.byType(AppImage))
          .any((image) => image.semanticLabel == 'Venomous Staff'),
      isTrue,
    );

    // HOKX 默认按出场率降序：Venomous Staff(场次 3790) 在 Boots(9999) 之上。
    expect(
      tester.getCenter(find.text('3790')).dy,
      lessThan(tester.getCenter(find.text('9999')).dy),
    );

    // 点击 Count 表头切为按场次降序：Boots(9999) 升到最上。
    await tester.tap(find.text('Count'));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('9999')).dy,
      lessThan(tester.getCenter(find.text('3790')).dy),
    );
    await tester.drag(
      find.byKey(const ValueKey('hero-preparation-tabs')),
      const Offset(-500, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Pro Builds'), findsOneWidget);
    expect(find.text('Skill Flow'), findsOneWidget);
    expect(find.text('BP'), findsOneWidget);
    expect(find.text('Matchups'), findsNothing);
  });

  testWidgets('curve opens the separate trend details tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith(
            (ref, request) async => sampleStatsTrendDetail(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-curve-hero-199')));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Playstyle'), findsOneWidget);
    expect(find.text('Equipment'), findsWidgets);
    await tester.drag(
      find.byKey(const ValueKey('trend-detail-tabs')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Matchups'), findsOneWidget);
    expect(find.text('Single Equip'), findsNothing);
    // HOKX「综合」tab：大图表 + 最新快照日期 + WR/P/B/BP 指标卡。
    expect(find.text('BP'), findsWidgets);
    expect(find.text('31.40%'), findsOneWidget);
    expect(find.text('13.00%'), findsOneWidget);

    // Matchups：适配/克制改用二级 tab 切换查看。
    await tester.tap(find.text('Matchups'));
    await tester.pumpAndSettle();
    expect(find.text('Synergy (0)'), findsOneWidget);
    expect(find.text('Counter (0)'), findsOneWidget);
    expect(find.text('Synergy Picks'), findsOneWidget);
    expect(find.text('Counter Picks'), findsNothing);
    await tester.tap(find.text('Counter (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Counter Picks'), findsOneWidget);
    expect(find.text('Synergy Picks'), findsNothing);
  });

  testWidgets(
    'localizes equipment trend series and keeps icons when names are untranslated',
    (tester) async {
      final detail = StatsTrendDetail.fromJson({
        'equip_trend_series': [
          {
            'equip_id': 12211,
            'equip': {'id': 12211, 'name': '梦魇之牙', 'name_en': 'Venomous Staff'},
            'pick_rate': 70.24,
            'win_rate': 54.2,
            'points': [
              {
                'snapshot_date': '2026-07-15',
                'pick_rate': 70.24,
                'win_rate': 54.2,
              },
            ],
          },
          {
            'equip_id': 12345,
            'equip': {'id': 12345, 'name': '抵抗之靴'},
            'pick_rate': 45.1,
            'win_rate': 60.0,
            'points': [
              {
                'snapshot_date': '2026-07-15',
                'pick_rate': 45.1,
                'win_rate': 60.0,
              },
            ],
          },
        ],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heroTrendTableProvider.overrideWith(
              (ref, query) async => sampleStatsTrendTable(),
            ),
            heroTrendDetailProvider.overrideWith(
              (ref, request) async => detail,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HeroTrendsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('trend-curve-hero-199')));
      await tester.pumpAndSettle();
      final equipmentTab = find.descendant(
        of: find.byKey(const ValueKey('trend-detail-tabs')),
        matching: find.text('Equipment'),
      );
      await tester.tap(equipmentTab);
      await tester.pumpAndSettle();

      expect(find.text('Venomous Staff'), findsNWidgets(2));
      expect(find.text('梦魇之牙'), findsNothing);
      expect(find.text('抵抗之靴'), findsNothing);
      expect(find.text('Pick Rate 70.24%'), findsOneWidget);
      expect(find.text('Win Rate 54.20%'), findsOneWidget);

      final images = tester.widgetList<AppImage>(find.byType(AppImage));
      expect(
        images
            .where(
              (image) =>
                  image.url ==
                  'https://hokhelper.com/static/game/equip/12211.png',
            )
            .length,
        greaterThanOrEqualTo(2),
      );
      expect(
        images.any((image) => image.semanticLabel == 'Equipment #12345'),
        isTrue,
      );
    },
  );

  testWidgets('equip avatar opens the single equip matrix table', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleEquipStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith(
            (ref, request) async => sampleEquipStatsTrendDetail(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-avatar-equip-12211')));
    await tester.pumpAndSettle();

    // 「趋势」tab：胜率/出场率双指标卡与双线图。
    // 'Win Rate' 三处：背景主表表头 + 抽屉指标卡 + 图表图例。
    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('Equipment details'), findsOneWidget);
    expect(find.text('Win Rate'), findsNWidgets(3));
    expect(find.text('Pick Rate'), findsNWidgets(3));
    expect(find.text('54.20%'), findsNWidgets(2));
    expect(find.text('70.24%'), findsNWidgets(2));
    // HOKX 装备抽屉没有窗口天数切换。
    expect(find.byKey(const ValueKey('trend-window-select')), findsNothing);

    await tester.tap(find.text('Single Equip'));
    await tester.pumpAndSettle();

    // 「单件装备」tab：HOKX 槽位矩阵表，每行英雄头像 + 装备角标。
    expect(find.text('Slot Distribution'), findsOneWidget);
    expect(find.text('3790'), findsOneWidget);
    expect(find.text('61.40%'), findsOneWidget);
    expect(find.text('56.80%'), findsOneWidget);
    final images = tester.widgetList<AppImage>(find.byType(AppImage));
    expect(images.any((image) => image.semanticLabel == 'Lam'), isTrue);
    expect(images.any((image) => image.semanticLabel == 'Yaria'), isTrue);
    // 每行都带所选装备角标（主表识别列 1 处 + 抽屉两行角标 2 处）。
    expect(
      images.where((image) => image.semanticLabel == 'Venomous Staff').length,
      greaterThanOrEqualTo(2),
    );

    // 默认按出场率降序：Lam(场次 3790) 在 Yaria(9999) 之上。
    expect(
      tester.getCenter(find.text('3790')).dy,
      lessThan(tester.getCenter(find.text('9999')).dy),
    );
  });

  testWidgets('single equip table sorts the full list before truncation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleEquipStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith(
            (ref, request) async => sampleWideEquipStatsTrendDetail(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-avatar-equip-12211')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Single Equip'));
    await tester.pumpAndSettle();

    bool hasHero(String label) => tester
        .widgetList<AppImage>(find.byType(AppImage))
        .any((image) => image.semanticLabel == label);

    // 默认按出场率降序截断 30 行：pick 第 31 名不可见。
    expect(hasHero('Hero1'), isTrue);
    expect(hasHero('Hero31'), isFalse);

    // 切到 Win 降序后应对全量行重排：胜率最高的 Hero31 必须换入。
    await tester.tap(
      find.ancestor(of: find.text('Win'), matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    expect(hasHero('Hero31'), isTrue);
  });
}

Map<String, Object?> _trendFixtureRow(int id, List<num> trend) {
  return {
    'hero': {
      'id': id,
      'heroId': '$id',
      'name': 'Hero $id',
      'position': '${id % 5}',
    },
    'wr': trend.last,
    'pick_rate': 10 + id,
    'avg_kills': id,
    'trend_smoothed': trend,
  };
}
