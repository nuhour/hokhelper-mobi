import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_image.dart';
import 'package:hok_helper_mobile/src/features/bp/data/bp_repository.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_dashboard_screen.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_scheme_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

class _FakeBpRepository extends BpRepository {
  _FakeBpRepository() : super(apiClient: _NoopApiClient());

  int? advancedGameNumber;
  List<BpHistoryGame>? advancedHistory;

  @override
  Future<BpSchemeSummary> advanceSeries(
    String schemeId, {
    required int nextGameNumber,
    required List<BpHistoryGame> history,
  }) async {
    advancedGameNumber = nextGameNumber;
    advancedHistory = history;
    return BpSchemeSummary(
      id: schemeId,
      name: 'KPL Finals Draft',
      createdAt: '2026-07-03T10:00:00Z',
      boMode: 7,
      teamAName: 'Wolves',
      teamBName: 'AG',
      sideSelectionRule: 'loser_selects',
      gameNumber: nextGameNumber,
      historyCount: history.length,
      currentStepIndex: 0,
      blueBanCount: 0,
      redBanCount: 0,
      bluePickCount: 0,
      redPickCount: 0,
      history: history,
    );
  }
}

const _wolvesHeroes = [
  HeroSummary(
    id: '101',
    name: 'Wolves hero 1',
    avatar: 'https://cdn.example/a101.png',
    title: '',
    position: 1,
  ),
  HeroSummary(
    id: '102',
    name: 'Wolves hero 2',
    avatar: 'https://cdn.example/a102.png',
    title: '',
    position: 2,
  ),
  HeroSummary(
    id: '103',
    name: 'Wolves hero 3',
    avatar: 'https://cdn.example/a103.png',
    title: '',
    position: 3,
  ),
  HeroSummary(
    id: '104',
    name: 'Wolves hero 4',
    avatar: 'https://cdn.example/a104.png',
    title: '',
    position: 4,
  ),
  HeroSummary(
    id: '105',
    name: 'Wolves hero 5',
    avatar: 'https://cdn.example/a105.png',
    title: '',
    position: 5,
  ),
];

const _agHeroes = [
  HeroSummary(
    id: '201',
    name: 'AG hero 1',
    avatar: 'https://cdn.example/a201.png',
    title: '',
    position: 1,
  ),
  HeroSummary(
    id: '202',
    name: 'AG hero 2',
    avatar: 'https://cdn.example/a202.png',
    title: '',
    position: 2,
  ),
  HeroSummary(
    id: '203',
    name: 'AG hero 3',
    avatar: 'https://cdn.example/a203.png',
    title: '',
    position: 3,
  ),
  HeroSummary(
    id: '204',
    name: 'AG hero 4',
    avatar: 'https://cdn.example/a204.png',
    title: '',
    position: 4,
  ),
  HeroSummary(
    id: '205',
    name: 'AG hero 5',
    avatar: 'https://cdn.example/a205.png',
    title: '',
    position: 5,
  ),
];

const _freshHero = HeroSummary(
  id: '301',
  name: 'Fresh hero',
  avatar: 'https://cdn.example/a301.png',
  title: '',
  position: 1,
);

const _gameOneHistory = BpHistoryGame(
  gameNumber: 1,
  blueTeamId: 'team_a',
  redTeamId: 'team_b',
  bluePicks: [101, 102, 103, 104, 105],
  redPicks: [201, 202, 203, 204, 205],
  winner: 'blue',
);

BpSchemeSummary _gameTwoScheme({required int currentStepIndex}) {
  return BpSchemeSummary(
    id: '12',
    name: 'KPL Finals Draft',
    createdAt: '2026-07-03T10:00:00Z',
    boMode: 7,
    teamAName: 'Wolves',
    teamBName: 'AG',
    sideSelectionRule: 'loser_selects',
    gameNumber: 2,
    historyCount: 1,
    currentStepIndex: currentStepIndex,
    blueBanCount: 0,
    redBanCount: 0,
    bluePickCount: 0,
    redPickCount: 0,
    draftState: BpDraftState(currentStepIndex: currentStepIndex),
    history: const [_gameOneHistory],
  );
}

Finder _slotImage(int heroId) => find.byWidgetPredicate(
  (widget) =>
      widget is AppImage &&
      widget.url == 'https://hokhelper.com/static/game/hero/$heroId.png',
);

FilledButton _lockButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Lock in'));

void main() {
  testWidgets('pick 阶段禁用本队之前小局已用英雄', (tester) async {
    final router = createAppRouter();
    router.go('/tools/bp-simulator/12');
    tester.view.physicalSize = const Size(2532, 1170);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemeDetailProvider('12').overrideWith((ref) async {
            // 第 5 步是蓝方 pick；第 2 局蓝方是 Team B（AG）。
            return _gameTwoScheme(currentStepIndex: 4);
          }),
          heroGalleryProvider.overrideWith((ref) async {
            return const [..._wolvesHeroes, ..._agHeroes, _freshHero];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start BP'));
    await tester.pump();

    // AG（蓝方）在第 1 局用过 201-205，全部标记"本方已用"。
    expect(find.byIcon(Icons.person_off_rounded), findsNWidgets(5));
    expect(_lockButton(tester).onPressed, isNull);

    // 点击本队已用英雄不应被选中。
    await tester.tap(find.bySemanticsLabel('AG hero 1'));
    await tester.pump();
    expect(_lockButton(tester).onPressed, isNull);

    // 对方用过的英雄可以正常选用。
    await tester.tap(find.bySemanticsLabel('Wolves hero 1'));
    await tester.pump();
    expect(_lockButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Lock in'));
    await tester.pump();

    expect(_slotImage(101), findsOneWidget);
  });

  testWidgets('ban 阶段标记敌方已用英雄且仍可禁用', (tester) async {
    final router = createAppRouter();
    router.go('/tools/bp-simulator/12');
    tester.view.physicalSize = const Size(2532, 1170);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemeDetailProvider('12').overrideWith((ref) async {
            // 第 1 步是蓝方 ban；蓝方 AG 的对手 Wolves 用过 101-105。
            return _gameTwoScheme(currentStepIndex: 0);
          }),
          heroGalleryProvider.overrideWith((ref) async {
            return const [..._wolvesHeroes, ..._agHeroes, _freshHero];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start BP'));
    await tester.pump();

    expect(find.byIcon(Icons.shield_outlined), findsNWidgets(5));
    expect(find.byIcon(Icons.person_off_rounded), findsNothing);

    // 敌方已用英雄仍可被禁用。
    await tester.tap(find.bySemanticsLabel('Wolves hero 1'));
    await tester.pump();
    expect(_lockButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Lock in'));
    await tester.pump();

    expect(_slotImage(101), findsOneWidget);
  });

  testWidgets('历史回放比分只统计到所查看的小局', (tester) async {
    const gameTwoHistory = BpHistoryGame(
      gameNumber: 2,
      blueTeamId: 'team_b',
      redTeamId: 'team_a',
      bluePicks: [301, 302, 303, 304, 305],
      redPicks: [401, 402, 403, 404, 405],
      winner: 'blue',
    );
    final router = createAppRouter();
    router.go('/tools/bp-simulator/12?gameIndex=0');
    tester.view.physicalSize = const Size(2532, 1170);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemeDetailProvider('12').overrideWith((ref) async {
            return BpSchemeSummary(
              id: '12',
              name: 'KPL Finals Draft',
              createdAt: '2026-07-03T10:00:00Z',
              boMode: 7,
              teamAName: 'Wolves',
              teamBName: 'AG',
              sideSelectionRule: 'loser_selects',
              gameNumber: 3,
              historyCount: 2,
              currentStepIndex: 0,
              blueBanCount: 0,
              redBanCount: 0,
              bluePickCount: 0,
              redPickCount: 0,
              history: const [_gameOneHistory, gameTwoHistory],
            );
          }),
          heroGalleryProvider.overrideWith((ref) async {
            return const [..._wolvesHeroes, ..._agHeroes, _freshHero];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    // 查看第 1 局时比分应为 1-0（第 2 局 AG 的胜场不计入）。
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('完成小局后败方选边默认红色方', (tester) async {
    final repository = _FakeBpRepository();
    final router = createAppRouter();
    router.go('/tools/bp-simulator/12');
    tester.view.physicalSize = const Size(2532, 1170);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpRepositoryProvider.overrideWithValue(repository),
          bpSchemeDetailProvider('12').overrideWith((ref) async {
            return const BpSchemeSummary(
              id: '12',
              name: 'KPL Finals Draft',
              createdAt: '2026-07-03T10:00:00Z',
              boMode: 7,
              teamAName: 'Wolves',
              teamBName: 'AG',
              sideSelectionRule: 'loser_selects',
              gameNumber: 1,
              historyCount: 0,
              currentStepIndex: 20,
              blueBanCount: 0,
              redBanCount: 0,
              bluePickCount: 5,
              redPickCount: 5,
              draftState: BpDraftState(
                currentStepIndex: 20,
                isStarted: true,
                bluePicks: [101, 102, 103, 104, 105],
                redPicks: [201, 202, 203, 204, 205],
              ),
            );
          }),
          heroGalleryProvider.overrideWith((ref) async {
            return const [..._wolvesHeroes, ..._agHeroes, _freshHero];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Wolves wins'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Complete BP'));
    await tester.pumpAndSettle();

    expect(repository.advancedGameNumber, 1);
    expect(repository.advancedHistory, hasLength(1));
    expect(repository.advancedHistory!.single.winner, 'blue');
    expect(find.text('AG · Loser selects'), findsOneWidget);

    // HOKX 默认败方选红色方。
    final circleIcons = tester
        .widgetList<Icon>(find.byIcon(Icons.circle))
        .toList();
    expect(circleIcons, hasLength(2));
    expect(
      circleIcons.map((icon) => icon.color),
      contains(const Color(0xFFE83B43)),
    );
    expect(
      circleIcons.map((icon) => icon.color),
      isNot(contains(const Color(0xFF246BFF))),
    );
  });

  testWidgets('BP 完成后保存前可点击槽位改选英雄', (tester) async {
    final router = createAppRouter();
    router.go('/tools/bp-simulator/12');
    tester.view.physicalSize = const Size(2532, 1170);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemeDetailProvider('12').overrideWith((ref) async {
            return const BpSchemeSummary(
              id: '12',
              name: 'KPL Finals Draft',
              createdAt: '2026-07-03T10:00:00Z',
              boMode: 7,
              teamAName: 'Wolves',
              teamBName: 'AG',
              sideSelectionRule: 'loser_selects',
              gameNumber: 1,
              historyCount: 0,
              currentStepIndex: 20,
              blueBanCount: 0,
              redBanCount: 0,
              bluePickCount: 5,
              redPickCount: 5,
              draftState: BpDraftState(
                currentStepIndex: 20,
                isStarted: true,
                bluePicks: [101, 102, 103, 104, 105],
                redPicks: [201, 202, 203, 204, 205],
              ),
            );
          }),
          heroGalleryProvider.overrideWith((ref) async {
            return const [..._wolvesHeroes, ..._agHeroes, _freshHero];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(_slotImage(101), findsOneWidget);
    await tester.tap(_slotImage(101));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Fresh hero'));
    await tester.pump();

    expect(_slotImage(101), findsNothing);
    expect(_slotImage(301), findsOneWidget);
  });
}
