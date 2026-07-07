import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_match_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_player_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_team_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/presentation/esports_screen.dart';

void main() {
  testWidgets('renders matches, teams, and players tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
            ];
          }),
          esportsTeamsProvider.overrideWith((ref) async {
            return const [
              EsportsTeamSummary(
                id: '1',
                name: 'Wolves',
                shortName: 'WOL',
                logoUrl: '',
                leagueName: 'KPL Spring',
                club: 'Chongqing Wolves',
                wins: 12,
                losses: 3,
                winRate: 0.8,
              ),
            ];
          }),
          esportsPlayersProvider.overrideWith((ref) async {
            return const [
              EsportsPlayerSummary(
                id: '8',
                name: 'Fly',
                avatarUrl: '',
                teamName: 'Wolves',
                teamLogoUrl: '',
                role: 'Clash Lane',
                grade: 91.5,
                kda: 6.8,
                winRate: 0.76,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esports'), findsOneWidget);
    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('Wolves'), findsWidgets);
    expect(find.text('AG'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text(' - '), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();

    expect(find.text('Chongqing Wolves'), findsOneWidget);
    expect(find.text('12W / 3L'), findsOneWidget);
    expect(find.text('80.0%'), findsOneWidget);

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    expect(find.text('Fly'), findsOneWidget);
    expect(find.text('Clash Lane'), findsOneWidget);
    expect(find.text('91.5'), findsOneWidget);
    expect(find.text('6.8 KDA'), findsOneWidget);
  });

  testWidgets('match cards open a mobile match detail sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('KPL Spring'));
    await tester.pumpAndSettle();

    expect(find.text('Match Detail'), findsOneWidget);
    expect(find.text('KPL Spring · Playoffs'), findsOneWidget);
    expect(find.text('Wolves'), findsWidgets);
    expect(find.text('AG'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text(' - '), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Finished'), findsWidgets);
    expect(find.text('2026-06-28T11:00:00Z'), findsWidgets);
  });

  testWidgets('formats esports match card time like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('6/28 11:00'), findsOneWidget);
    expect(find.textContaining('2026-06-28T11:00:00'), findsNothing);
  });

  testWidgets('shows esports match best-of text like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00',
                bestOf: 7,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('BO7'), findsOneWidget);
  });

  testWidgets('highlights esports match winner score like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00',
                winnerTeamId: '1',
                teamAId: '1',
                teamBId: '2',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final winnerText = tester.widget<Text>(find.text('Wolves'));
    final loserText = tester.widget<Text>(find.text('AG'));
    final winnerScore = tester.widget<Text>(find.text('4'));
    final loserScore = tester.widget<Text>(find.text('3'));

    expect(winnerText.style?.color, Colors.greenAccent);
    expect(loserText.style?.color, isNot(Colors.greenAccent));
    expect(winnerScore.style?.color, Colors.greenAccent);
    expect(loserScore.style?.color, isNot(Colors.greenAccent));
  });

  testWidgets('marks the latest finished match winner as champion like hokx', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: 'old-final',
                leagueName: 'KPL Spring',
                stageName: 'Finals',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-20T11:00:00Z',
              ),
              EsportsMatchSummary(
                id: 'champion-final',
                leagueName: 'KPL Summer',
                stageName: 'Finals',
                teamAName: 'DRG',
                teamALogoUrl: '',
                teamBName: 'TTG',
                teamBLogoUrl: '',
                scoreA: 2,
                scoreB: 4,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('shows champion winner mark in match detail like hokx', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: 'old-final',
                leagueName: 'KPL Spring',
                stageName: 'Finals',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-20T11:00:00Z',
              ),
              EsportsMatchSummary(
                id: 'champion-final',
                leagueName: 'KPL Summer',
                stageName: 'Finals',
                teamAName: 'DRG',
                teamALogoUrl: '',
                teamBName: 'TTG',
                teamBLogoUrl: '',
                scoreA: 2,
                scoreB: 4,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('KPL Summer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KPL Summer'));
    await tester.pumpAndSettle();

    expect(find.text('Match Detail'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsNWidgets(2));
  });

  testWidgets('filters esports matches by league like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
              EsportsMatchSummary(
                id: '11',
                leagueName: 'KIC',
                stageName: 'Group Stage',
                teamAName: 'Nova',
                teamALogoUrl: '',
                teamBName: 'DRG',
                teamBLogoUrl: '',
                scoreA: null,
                scoreB: null,
                statusKey: 'upcoming',
                startTime: '2026-07-12T12:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('KIC'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);

    await tester.tap(find.text('All Leagues'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KIC').last);
    await tester.pumpAndSettle();

    expect(find.text('KPL Spring'), findsNothing);
    expect(find.text('Nova'), findsOneWidget);
  });

  testWidgets('filters esports matches by status like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
              EsportsMatchSummary(
                id: '11',
                leagueName: 'KIC',
                stageName: 'Group Stage',
                teamAName: 'Nova',
                teamALogoUrl: '',
                teamBName: 'DRG',
                teamBLogoUrl: '',
                scoreA: null,
                scoreB: null,
                statusKey: 'upcoming',
                startTime: '2026-07-12T12:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wolves'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);

    await tester.tap(find.text('All Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upcoming').last);
    await tester.pumpAndSettle();

    expect(find.text('Wolves'), findsNothing);
    expect(find.text('Nova'), findsOneWidget);
  });

  testWidgets('filters esports matches by date like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
              EsportsMatchSummary(
                id: '11',
                leagueName: 'KIC',
                stageName: 'Group Stage',
                teamAName: 'Nova',
                teamALogoUrl: '',
                teamBName: 'DRG',
                teamBLogoUrl: '',
                scoreA: null,
                scoreB: null,
                statusKey: 'upcoming',
                startTime: '2026-07-12T12:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wolves'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Match Date'), '2026-07-12');
    await tester.pumpAndSettle();

    expect(find.text('Wolves'), findsNothing);
    expect(find.text('Nova'), findsOneWidget);
  });

  testWidgets('groups esports matches by status like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsMatchesProvider.overrideWith((ref) async {
            return const [
              EsportsMatchSummary(
                id: '9',
                leagueName: 'KPL Spring',
                stageName: 'Finals',
                teamAName: 'TTG',
                teamALogoUrl: '',
                teamBName: 'WB',
                teamBLogoUrl: '',
                scoreA: 1,
                scoreB: 1,
                statusKey: 'live',
                startTime: '2026-06-28T10:00:00Z',
              ),
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
              EsportsMatchSummary(
                id: '11',
                leagueName: 'KIC',
                stageName: 'Group Stage',
                teamAName: 'Nova',
                teamALogoUrl: '',
                teamBName: 'DRG',
                teamBLogoUrl: '',
                scoreA: null,
                scoreB: null,
                statusKey: 'upcoming',
                startTime: '2026-07-12T12:00:00Z',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: EsportsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('match-status-heading-live')),
      findsOneWidget,
    );
    expect(find.text('TTG'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('match-status-heading-upcoming')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('match-status-heading-upcoming')),
      findsOneWidget,
    );
    expect(find.text('Nova'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('match-status-heading-finished')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('match-status-heading-finished')),
      findsOneWidget,
    );
    expect(find.text('Wolves'), findsOneWidget);
  });

  testWidgets('filters esports players by team like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsPlayersProvider.overrideWith((ref) async {
            return const [
              EsportsPlayerSummary(
                id: '8',
                name: 'Fly',
                avatarUrl: '',
                teamName: 'Wolves',
                teamLogoUrl: '',
                role: 'Clash Lane',
                grade: 91.5,
                kda: 6.8,
                winRate: 0.76,
              ),
              EsportsPlayerSummary(
                id: '9',
                name: 'Cat',
                avatarUrl: '',
                teamName: 'AG',
                teamLogoUrl: '',
                role: 'Mid',
                grade: 88.2,
                kda: 5.4,
                winRate: 0.71,
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EsportsScreen(initialTab: EsportsInitialTab.players),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fly'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);

    await tester.tap(find.text('All Teams'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AG').last);
    await tester.pumpAndSettle();

    expect(find.text('Fly'), findsNothing);
    expect(find.text('Cat'), findsOneWidget);
  });

  testWidgets('filters esports players by role like the hokx portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esportsPlayersProvider.overrideWith((ref) async {
            return const [
              EsportsPlayerSummary(
                id: '8',
                name: 'Fly',
                avatarUrl: '',
                teamName: 'Wolves',
                teamLogoUrl: '',
                role: 'Clash Lane',
                grade: 91.5,
                kda: 6.8,
                winRate: 0.76,
              ),
              EsportsPlayerSummary(
                id: '9',
                name: 'Cat',
                avatarUrl: '',
                teamName: 'AG',
                teamLogoUrl: '',
                role: 'Mid',
                grade: 88.2,
                kda: 5.4,
                winRate: 0.71,
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EsportsScreen(initialTab: EsportsInitialTab.players),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fly'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);

    await tester.tap(find.text('All Roles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mid').last);
    await tester.pumpAndSettle();

    expect(find.text('Fly'), findsNothing);
    expect(find.text('Cat'), findsOneWidget);
  });
}
