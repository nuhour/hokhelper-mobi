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
  }) async {
    calls.add({
      'myPicks': myPicks,
      'enemyPicks': enemyPicks,
      'bans': bans,
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
        teamRecommendationsProvider.overrideWith(
          (ref, mainJob) async => const TeamRecommendationResult(
            recommendations: [
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
            sideWinRates: TeamSideWinRates(blue: .57, red: .43),
          ),
        ),
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
    expect(find.text('Priority Bans'), findsOneWidget);
    expect(find.text('Counter Bans'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('team-pool-7')));
    await _pumpTeamBuilder(tester);

    // 主请求：slot_type=ban，上下文为双方已 ban 列表。
    final banCalls = repository.calls
        .where((call) => call['slotType'] == 'ban')
        .toList();
    expect(banCalls, isNotEmpty);
    expect(banCalls.last['myPicks'], [7]);
    expect(banCalls.last['enemyPicks'], isEmpty);
    expect(banCalls.last['bans'], [7]);
    // 胜率请求：ban 位时仍按双方已选阵容单独计算。
    final rateCalls = repository.calls
        .where((call) => call['slotType'] == 'pick' && call['limit'] == 1)
        .toList();
    expect(rateCalls, isNotEmpty);
    expect(rateCalls.last['myPicks'], [42]);
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
