import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_match_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_player_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_stat_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_team_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/presentation/esports_screen.dart';

void main() {
  testWidgets('esports player deep link opens the players tab', (tester) async {
    final router = createAppRouter();
    router.go('/esports/players/8');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esports'), findsOneWidget);
    expect(find.text('Fly'), findsOneWidget);
    expect(find.text('Focused Player'), findsOneWidget);
    expect(find.text('Clash Lane'), findsWidgets);
    expect(find.text('76.0%'), findsOneWidget);
    expect(find.text('KPL Spring'), findsNothing);
  });

  testWidgets('esports team deep link opens the teams tab', (tester) async {
    final router = createAppRouter();
    router.go('/esports/teams/1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esports'), findsOneWidget);
    expect(find.text('Chongqing Wolves'), findsOneWidget);
    expect(find.text('Focused Team'), findsOneWidget);
    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('12W / 3L'), findsWidgets);
    expect(find.text('4 - 3'), findsNothing);
  });

  testWidgets('legacy esports team query opens the team route', (tester) async {
    final router = createAppRouter();
    router.go('/esports?team_id=1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/esports/teams/1');
    expect(find.text('Focused Team'), findsOneWidget);
    expect(find.text('Chongqing Wolves'), findsOneWidget);
    expect(find.text('4 - 3'), findsNothing);
  });

  testWidgets('legacy esports player query opens the player route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/esports?player_id=8');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/esports/players/8',
    );
    expect(find.text('Focused Player'), findsOneWidget);
    expect(find.text('Fly'), findsOneWidget);
    expect(find.text('KPL Spring'), findsNothing);
  });

  testWidgets('esports stats route opens the stats tab', (tester) async {
    final router = createAppRouter();
    router.go('/esports/stats');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esports'), findsOneWidget);
    expect(find.text('Esports Stats'), findsOneWidget);
    expect(find.text('Hero rankings and player performance'), findsOneWidget);
    expect(find.text('Luban No.7'), findsOneWidget);
    expect(find.text('Wolves · Fly'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    expect(find.text('66.2%'), findsOneWidget);
    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('4 - 3'), findsNothing);
  });

  testWidgets('esports tab changes synchronize the web route', (tester) async {
    final router = createAppRouter();
    router.go('/esports?season=2026');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/esports/teams');
    expect(router.routeInformationProvider.value.uri.query, isEmpty);

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/esports/players');

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/esports/stats');

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/esports/schedule');
  });
}

List<Override> _esportsOverrides() {
  return [
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
    esportsStatsProvider.overrideWith((ref) async {
      return const [
        EsportsStatSummary(
          id: 'stat-1',
          rank: 1,
          objectName: 'Luban No.7',
          subtitle: 'Wolves · Fly',
          imageUrl: '',
          leagueName: 'KPL Spring',
          metrics: [
            EsportsStatMetric(label: 'Win Rate', value: '66.2%'),
            EsportsStatMetric(label: 'KDA', value: '5.4'),
          ],
        ),
      ];
    }),
  ];
}
