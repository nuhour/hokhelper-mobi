import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';
import 'package:hok_helper_mobile/src/features/bp/data/bp_repository.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_dashboard_screen.dart';

class _FakeBpRepository extends BpRepository {
  _FakeBpRepository() : super(apiClient: _NoopApiClient());

  String? createdName;
  int? createdBoMode;
  String? createdTeamAName;
  String? createdTeamBName;
  String? createdSideSelectionRule;
  String? deletedSchemeId;
  Object? createError;

  @override
  Future<BpSchemeSummary> createScheme({
    required String name,
    required int boMode,
    required String teamAName,
    required String teamBName,
    required String sideSelectionRule,
  }) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdName = name;
    createdBoMode = boMode;
    createdTeamAName = teamAName;
    createdTeamBName = teamBName;
    createdSideSelectionRule = sideSelectionRule;
    return BpSchemeSummary(
      id: '99',
      name: name,
      createdAt: '2026-07-07T10:00:00Z',
      boMode: boMode,
      teamAName: teamAName,
      teamBName: teamBName,
      sideSelectionRule: sideSelectionRule,
      gameNumber: 1,
      historyCount: 0,
      currentStepIndex: 0,
      blueBanCount: 0,
      redBanCount: 0,
      bluePickCount: 0,
      redPickCount: 0,
    );
  }

  @override
  Future<void> deleteScheme(String schemeId) async {
    deletedSchemeId = schemeId;
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
  testWidgets('renders BP scheme cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemesProvider.overrideWith((ref) async {
            return const [
              BpSchemeSummary(
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
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BpDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BP Simulator'), findsOneWidget);
    expect(find.text('KPL Finals Draft'), findsOneWidget);
    expect(find.text('BO7'), findsOneWidget);
    expect(find.text('Loser selects side'), findsOneWidget);
    expect(find.text('Current (Game 3)'), findsOneWidget);
    expect(find.text('WOLVES'), findsOneWidget);
    expect(find.text('AG'), findsOneWidget);
    expect(find.text('Wolves: 0'), findsOneWidget);
    expect(find.text('AG: 0'), findsOneWidget);
  });

  testWidgets('scheme cards switch completed BP game previews', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemesProvider.overrideWith((ref) async {
            return const [
              BpSchemeSummary(
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
                history: [
                  BpHistoryGame(
                    gameNumber: 1,
                    blueTeamId: 'team_a',
                    redTeamId: 'team_b',
                    blueBans: [101, null, null, null, null],
                    redBans: [201, null, null, null, null],
                    bluePicks: [102, 103, 104, 105, 106],
                    redPicks: [202, 203, 204, 205, 206],
                    winner: 'blue',
                  ),
                  BpHistoryGame(
                    gameNumber: 2,
                    blueTeamId: 'team_b',
                    redTeamId: 'team_a',
                    blueBans: [301, null, null, null, null],
                    redBans: [401, null, null, null, null],
                    bluePicks: [302, 303, 304, 305, 306],
                    redPicks: [402, 403, 404, 405, 406],
                    winner: 'red',
                  ),
                ],
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BpDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Game 1'), findsOneWidget);
    expect(find.text('Game 2'), findsOneWidget);
    expect(find.bySemanticsLabel('BP hero 102'), findsOneWidget);

    await tester.tap(find.text('Game 2'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('BP hero 302'), findsOneWidget);
  });

  testWidgets('creates BP schemes from the mobile dashboard form', (
    tester,
  ) async {
    final repository = _FakeBpRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpRepositoryProvider.overrideWithValue(repository),
          bpSchemesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: BpDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create BP'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Scheme name'),
      'Mobile Draft',
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
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(repository.createdName, 'Mobile Draft');
    expect(repository.createdBoMode, 5);
    expect(repository.createdTeamAName, 'Team Alpha');
    expect(repository.createdTeamBName, 'Team Beta');
    expect(repository.createdSideSelectionRule, 'loser_selects');
    expect(find.text('Mobile Draft'), findsOneWidget);
    expect(find.text('BO5'), findsOneWidget);
    expect(find.text('Current (Game 1)'), findsOneWidget);
    expect(find.text('TEAM ALPHA'), findsOneWidget);
    expect(find.text('TEAM BETA'), findsOneWidget);
    expect(find.text('BP scheme created'), findsOneWidget);
  });

  testWidgets('asks guests to sign in before saving BP schemes', (
    tester,
  ) async {
    final repository = _FakeBpRepository()
      ..createError = const ApiError(
        kind: ApiErrorKind.authExpired,
        message: 'Authentication credentials were not provided.',
        statusCode: 401,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpRepositoryProvider.overrideWithValue(repository),
          bpSchemesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: BpDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create BP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Scheme name'),
      'Guest Draft',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to save BP schemes'), findsOneWidget);
  });

  testWidgets('deletes BP schemes after confirmation', (tester) async {
    final repository = _FakeBpRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpRepositoryProvider.overrideWithValue(repository),
          bpSchemesProvider.overrideWith((ref) async {
            return const [
              BpSchemeSummary(
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
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BpDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete BP scheme'));
    await tester.pumpAndSettle();

    expect(find.text('Delete BP scheme?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedSchemeId, '12');
    expect(find.text('KPL Finals Draft'), findsNothing);
    expect(find.text('BP scheme deleted'), findsOneWidget);
  });
}
