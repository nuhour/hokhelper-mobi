import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/teambuild/data/team_builder_repository.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_build_hero.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_recommendation.dart';
import 'package:hok_helper_mobile/src/features/teambuild/presentation/team_builder_screen.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

class _RecordingTeamBuilderRepository extends TeamBuilderRepository {
  _RecordingTeamBuilderRepository() : super(apiClient: _NoopApiClient());

  final calls = <Map<String, Object?>>[];

  @override
  Future<TeamRecommendationResult> loadRecommendations({
    required int regionId,
    List<int> myPicks = const [],
    List<int> enemyPicks = const [],
    List<int> bans = const [],
    TeamRecommendType recommendType = TeamRecommendType.balanced,
    String mySide = 'blue',
    String slotType = 'pick',
    int slotIndex = 0,
    int limit = 10,
    int? mainJob,
    List<int>? blueBans,
    List<int>? redBans,
    List<int>? bluePicks,
    List<int>? redPicks,
    String? activeSide,
    String? activeSlotType,
    int? activeSlotIndex,
  }) async {
    calls.add({
      'myPicks': myPicks,
      'enemyPicks': enemyPicks,
      'bans': bans,
      'blueBans': blueBans,
      'redBans': redBans,
      'bluePicks': bluePicks,
      'redPicks': redPicks,
      'activeSide': activeSide,
      'activeSlotType': activeSlotType,
      'activeSlotIndex': activeSlotIndex,
      'slotType': slotType,
      'limit': limit,
    });
    return const TeamRecommendationResult(
      recommendations: [],
      sideWinRates: TeamSideWinRates(blue: .5, red: .5),
    );
  }
}

const _heroes = [
  TeamBuildHero(
    id: 42,
    externalHeroId: '142',
    name: 'Lam',
    mainJob: 3,
    avatarUrl: '',
  ),
  TeamBuildHero(
    id: 7,
    externalHeroId: '107',
    name: 'Marco Polo',
    mainJob: 5,
    avatarUrl: '',
  ),
  TeamBuildHero(
    id: 99,
    externalHeroId: '199',
    name: 'Dolia',
    mainJob: 6,
    avatarUrl: '',
  ),
];

Widget _app({TeamBuilderScreen screen = const TeamBuilderScreen()}) =>
    ProviderScope(
      overrides: [
        teamBuilderHeroesProvider.overrideWith((ref) async => _heroes),
        teamRecommendationsProvider.overrideWith((ref, mainJob) async {
          final hasEnemyPick = ref
              .watch(teamBuilderDraftProvider)
              .enemyIds
              .isNotEmpty;
          return TeamRecommendationResult(
            recommendations: const [
              TeamRecommendation(
                heroId: 99,
                externalHeroId: '199',
                name: 'Dolia',
                mainJob: 6,
                score: .79,
                reason: 'Fits the lineup',
                pickRate: .1,
                banRate: .02,
                synergy: .5,
                counter: .4,
              ),
            ],
            fitRecommendations: const [
              TeamRecommendation(
                heroId: 99,
                externalHeroId: '199',
                name: 'Dolia',
                mainJob: 6,
                score: .79,
                reason: 'Fits the lineup',
                pickRate: .1,
                banRate: .02,
                synergy: .5,
                counter: .4,
                protect: .7,
                confidence: .8,
              ),
            ],
            counterRecommendations: hasEnemyPick
                ? const [
                    TeamRecommendation(
                      heroId: 7,
                      externalHeroId: '107',
                      name: 'Marco Polo',
                      mainJob: 5,
                      score: .73,
                      reason: 'Counters the enemy',
                      pickRate: .08,
                      banRate: .03,
                      synergy: .2,
                      counter: .8,
                      confidence: .75,
                    ),
                  ]
                : const [],
            sideWinRates: const TeamSideWinRates(blue: .57, red: .43),
          );
        }),
      ],
      child: MaterialApp(home: Scaffold(body: screen)),
    );

Future<void> _pumpTeamBuilder(WidgetTester tester) async {
  // 活跃槽位的旋转动画是持续的，固定时长 pump 可等待异步数据而不等待永动帧。
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  testWidgets('renders the HOKX-style mobile team builder workspace', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _pumpTeamBuilder(tester);
    expect(find.text('Smart Team Builder'), findsNothing);
    expect(find.text('Synergy Picks'), findsOneWidget);
    expect(find.text('Counter Picks'), findsOneWidget);
    expect(find.text('Dolia'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-recommendation-99')),
        matching: find.byType(AppImage),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Counter Picks'));
    await _pumpTeamBuilder(tester);
    expect(
      find.text('Pick an opponent hero to calculate counters'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('team-pick-enemy-0')));
    await tester.tap(find.byKey(const ValueKey('team-pool-42')));
    await _pumpTeamBuilder(tester);
    await tester.tap(find.byKey(const ValueKey('team-pick-ally-0')));
    await tester.tap(find.text('Counter Picks'));
    await _pumpTeamBuilder(tester);
    expect(find.text('Marco Polo'), findsOneWidget);
    for (var index = 0; index < 5; index++) {
      expect(find.byKey(ValueKey('team-pick-enemy-$index')), findsOneWidget);
    }
  });

  testWidgets('fills the active pick slot and locks the hero in the pool', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _pumpTeamBuilder(tester);
    await tester.tap(find.byKey(const ValueKey('team-pool-42')));
    await _pumpTeamBuilder(tester);
    expect(find.byKey(const ValueKey('team-pick-ally-0')), findsOneWidget);
  });

  testWidgets(
    'uses either ban strip side and sends its combined bans to recommendations',
    (tester) async {
      await tester.pumpWidget(_app());
      await _pumpTeamBuilder(tester);
      await tester.tap(find.byKey(const ValueKey('team-ban-ally-0')));
      await tester.tap(find.byKey(const ValueKey('team-pool-42')));
      await _pumpTeamBuilder(tester);
      expect(find.byKey(const ValueKey('team-ban-ally-0')), findsOneWidget);
    },
  );

  testWidgets(
    'switches recommendation lists locally without a second request',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = _RecordingTeamBuilderRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamBuilderHeroesProvider.overrideWith((ref) async => _heroes),
            teamBuilderRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: Scaffold(body: TeamBuilderScreen())),
        ),
      );
      await _pumpTeamBuilder(tester);
      final requestCount = repository.calls.length;

      await tester.tap(find.text('Counter Picks'));
      await _pumpTeamBuilder(tester);

      expect(repository.calls.length, requestCount);
    },
  );

  testWidgets('ban slot switches recommendation labels and uses ban context', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _RecordingTeamBuilderRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamBuilderHeroesProvider.overrideWith((ref) async => _heroes),
          teamBuilderRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: TeamBuilderScreen())),
      ),
    );
    await _pumpTeamBuilder(tester);

    expect(find.text('Synergy Picks'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('team-pool-42')));
    await _pumpTeamBuilder(tester);

    await tester.tap(find.byKey(const ValueKey('team-ban-ally-0')));
    await _pumpTeamBuilder(tester);
    expect(find.text('Protect lineup'), findsOneWidget);
    expect(find.text('Deny enemy'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('team-pool-7')));
    await _pumpTeamBuilder(tester);

    // Draft v2：slot_type=ban 仍使用双方实际已选阵容，双方 Ban 独立传递。
    final banCalls = repository.calls
        .where((call) => call['slotType'] == 'ban')
        .toList();
    expect(banCalls, isNotEmpty);
    expect(banCalls.last['myPicks'], isEmpty);
    expect(banCalls.last['enemyPicks'], isEmpty);
    expect(banCalls.last['bans'], [7]);
    expect(banCalls.last['blueBans'], [7]);
    expect(banCalls.last['redBans'], isEmpty);
    expect(banCalls.last['bluePicks'], [42]);
    expect(banCalls.last['redPicks'], isEmpty);
    expect(banCalls.last['activeSide'], 'blue');
    expect(banCalls.last['activeSlotType'], 'ban');
    expect(banCalls.last['activeSlotIndex'], 1);
    expect(
      repository.calls.where((call) => call['slotType'] == 'ban'),
      hasLength(2),
    );
  });

  testWidgets(
    'hydrates incoming HOKX draft query values into workspace slots',
    (tester) async {
      await tester.pumpWidget(
        _app(
          screen: const TeamBuilderScreen(
            initialAllyHeroIds: [42],
            initialEnemyHeroIds: [99],
            initialBanHeroIds: [7],
            initialSlotType: TeamBuilderSlotType.ban,
          ),
        ),
      );
      await _pumpTeamBuilder(tester);
      expect(find.byKey(const ValueKey('team-pick-ally-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('team-pick-enemy-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('team-ban-ally-0')), findsOneWidget);
    },
  );

  testWidgets('advances enemy bans in the displayed right-to-left order', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _pumpTeamBuilder(tester);

    await tester.tap(find.byKey(const ValueKey('team-ban-enemy-4')));
    await _pumpTeamBuilder(tester);
    await tester.tap(find.byKey(const ValueKey('team-pool-42')));
    await _pumpTeamBuilder(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-ban-enemy-3')),
        matching: find.byType(RotationTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-ban-enemy-4')),
        matching: find.byType(RotationTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('keeps the active slot ring rotating beyond five seconds', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _pumpTeamBuilder(tester);

    final rotation = tester.widget<RotationTransition>(
      find.descendant(
        of: find.byKey(const ValueKey('team-pick-ally-0')),
        matching: find.byType(RotationTransition),
      ),
    );
    final initialTurns = rotation.turns.value;
    await tester.pump(const Duration(seconds: 5));

    expect(rotation.turns.value, isNot(equals(initialTurns)));
  });
}
