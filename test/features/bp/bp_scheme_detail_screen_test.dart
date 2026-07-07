import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/bp/data/bp_repository.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_dashboard_screen.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_scheme_detail_screen.dart';

class _FakeBpRepository extends BpRepository {
  _FakeBpRepository() : super(apiClient: _NoopApiClient());

  String? updatedSchemeId;
  String? updatedName;
  int? updatedBoMode;
  String? updatedTeamAName;
  String? updatedTeamBName;
  String? updatedSideSelectionRule;
  String? draftSchemeId;
  int? draftGameNumber;
  int? draftCurrentStepIndex;
  int? draftBlueBanCount;
  int? draftRedBanCount;
  int? draftBluePickCount;
  int? draftRedPickCount;

  @override
  Future<BpSchemeSummary> updateScheme(
    String schemeId, {
    required String name,
    required int boMode,
    required String teamAName,
    required String teamBName,
    required String sideSelectionRule,
  }) async {
    updatedSchemeId = schemeId;
    updatedName = name;
    updatedBoMode = boMode;
    updatedTeamAName = teamAName;
    updatedTeamBName = teamBName;
    updatedSideSelectionRule = sideSelectionRule;
    return BpSchemeSummary(
      id: schemeId,
      name: name,
      createdAt: '2026-07-07T11:00:00Z',
      boMode: boMode,
      teamAName: teamAName,
      teamBName: teamBName,
      sideSelectionRule: sideSelectionRule,
      gameNumber: 3,
      historyCount: 2,
      currentStepIndex: 4,
      blueBanCount: 1,
      redBanCount: 1,
      bluePickCount: 1,
      redPickCount: 1,
    );
  }

  @override
  Future<BpSchemeSummary> updateDraftState(
    String schemeId, {
    required int gameNumber,
    required int currentStepIndex,
    required int blueBanCount,
    required int redBanCount,
    required int bluePickCount,
    required int redPickCount,
  }) async {
    draftSchemeId = schemeId;
    draftGameNumber = gameNumber;
    draftCurrentStepIndex = currentStepIndex;
    draftBlueBanCount = blueBanCount;
    draftRedBanCount = redBanCount;
    draftBluePickCount = bluePickCount;
    draftRedPickCount = redPickCount;
    return BpSchemeSummary(
      id: schemeId,
      name: 'KPL Finals Draft',
      createdAt: '2026-07-07T11:30:00Z',
      boMode: 7,
      teamAName: 'Wolves',
      teamBName: 'AG',
      sideSelectionRule: 'loser_selects',
      gameNumber: gameNumber,
      historyCount: 2,
      currentStepIndex: currentStepIndex,
      blueBanCount: blueBanCount,
      redBanCount: redBanCount,
      bluePickCount: bluePickCount,
      redPickCount: redPickCount,
    );
  }
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

void main() {
  testWidgets('edits BP scheme metadata from the mobile detail screen', (
    tester,
  ) async {
    final repository = _FakeBpRepository();

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
              gameNumber: 3,
              historyCount: 2,
              currentStepIndex: 4,
              blueBanCount: 1,
              redBanCount: 1,
              bluePickCount: 1,
              redPickCount: 1,
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BpSchemeDetailScreen(schemeId: '12')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Scheme name'),
      'Updated Draft',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Blue side'),
      'Team Alpha',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Red side'),
      'Team Beta',
    );
    await tester.tap(find.text('BO5'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.updatedSchemeId, '12');
    expect(repository.updatedName, 'Updated Draft');
    expect(repository.updatedBoMode, 5);
    expect(repository.updatedTeamAName, 'Team Alpha');
    expect(repository.updatedTeamBName, 'Team Beta');
    expect(repository.updatedSideSelectionRule, 'loser_selects');
    expect(find.text('Updated Draft'), findsOneWidget);
    expect(find.text('Team Alpha vs Team Beta'), findsOneWidget);
    expect(find.text('BO5'), findsOneWidget);
    expect(find.text('BP scheme updated'), findsOneWidget);
  });

  testWidgets('updates BP draft progress from the mobile detail screen', (
    tester,
  ) async {
    final repository = _FakeBpRepository();

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
              gameNumber: 3,
              historyCount: 2,
              currentStepIndex: 4,
              blueBanCount: 1,
              redBanCount: 1,
              bluePickCount: 1,
              redPickCount: 1,
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BpSchemeDetailScreen(schemeId: '12')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Draft Progress'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bp-progress-game-plus')));
    await tester.tap(find.byKey(const Key('bp-progress-step-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bp-progress-step-plus')));
    await tester.tap(find.byKey(const Key('bp-progress-blue-bans-plus')));
    await tester.tap(find.byKey(const Key('bp-progress-red-picks-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save Progress'));
    await tester.pumpAndSettle();

    expect(repository.draftSchemeId, '12');
    expect(repository.draftGameNumber, 4);
    expect(repository.draftCurrentStepIndex, 6);
    expect(repository.draftBlueBanCount, 2);
    expect(repository.draftRedBanCount, 1);
    expect(repository.draftBluePickCount, 1);
    expect(repository.draftRedPickCount, 2);
    expect(find.text('Game 4 · Step 6'), findsOneWidget);
    expect(find.text('3 bans · 3 picks'), findsOneWidget);
    expect(find.text('BP draft progress saved'), findsOneWidget);
  });

  testWidgets('renders BP current hero slots on the mobile detail screen', (
    tester,
  ) async {
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
              gameNumber: 3,
              historyCount: 2,
              currentStepIndex: 4,
              blueBanCount: 1,
              redBanCount: 1,
              bluePickCount: 1,
              redPickCount: 1,
              blueBanHeroIds: [199],
              redBanHeroIds: [133],
              bluePickHeroIds: [111],
              redPickHeroIds: [222],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BpSchemeDetailScreen(schemeId: '12')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current BP Board'), findsOneWidget);
    expect(find.text('Blue bans'), findsOneWidget);
    expect(find.text('Hero #199'), findsOneWidget);
    expect(find.text('Red bans'), findsOneWidget);
    expect(find.text('Hero #133'), findsOneWidget);
    expect(find.text('Blue picks'), findsOneWidget);
    expect(find.text('Hero #111'), findsOneWidget);
    expect(find.text('Red picks'), findsOneWidget);
    expect(find.text('Hero #222'), findsOneWidget);
  });
}
