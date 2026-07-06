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
    expect(find.text('4 - 3'), findsOneWidget);

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
    expect(find.text('4 - 3'), findsWidgets);
    expect(find.text('Finished'), findsWidgets);
    expect(find.text('2026-06-28T11:00:00Z'), findsWidgets);
  });
}
