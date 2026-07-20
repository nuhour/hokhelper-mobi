import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_detail.dart';
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

    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Fly'), findsWidgets);
    expect(find.text('Clash Lane'), findsWidgets);
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

    expect(find.text('Teams'), findsOneWidget);
    expect(find.text('Chongqing Wolves'), findsOneWidget);
    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('12W / 3L'), findsWidgets);
    expect(find.text('4 - 3'), findsNothing);
  });

  testWidgets('localized tools esports team route keeps the deep path', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/en/tools/esports/teams/1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/teams/1',
    );
    expect(find.text('Chongqing Wolves'), findsOneWidget);
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
    expect(find.text('Fly'), findsWidgets);
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

    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Team'), findsWidgets);
    expect(find.text('Wolves'), findsWidgets);
    expect(find.text('Win Rate'), findsOneWidget);
    expect(find.text('66.2%'), findsOneWidget);
    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('4 - 3'), findsNothing);
  });

  testWidgets('tools esports stats route opens the stats tab', (tester) async {
    final router = createAppRouter();
    router.go('/tools/esports/stats');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/stats',
    );
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Wolves'), findsWidgets);
    expect(find.text('4 - 3'), findsNothing);
  });

  testWidgets('tools esports team and player deep links open focused tabs', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/esports/teams/1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/teams/1',
    );
    expect(find.text('Chongqing Wolves'), findsOneWidget);
    expect(find.text('4 - 3'), findsNothing);

    router.go('/tools/esports/players/8');
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/players/8',
    );
    expect(find.text('Fly'), findsWidgets);
  });

  testWidgets('legacy tools esports player query opens focused player route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/esports?player_id=8&league=kpl');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/tools/esports/players/8');
    expect(uri.queryParameters['league'], 'kpl');
    expect(find.text('Fly'), findsWidgets);
    expect(find.text('KPL Spring'), findsNothing);
  });

  testWidgets('tools esports tab changes preserve the tools route namespace', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/esports');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/teams',
    );

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/players',
    );

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/stats',
    );

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/esports/schedule',
    );
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

  testWidgets('esports team cards open focused team routes', (tester) async {
    final router = createAppRouter();
    router.go('/esports/teams');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chongqing Wolves'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/esports/teams/1');
    expect(find.text('12W / 3L'), findsWidgets);
  });

  testWidgets('esports player cards open focused player routes', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/esports/players');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _esportsOverrides(),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fly'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/esports/players/8',
    );
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
    esportsTeamDetailProvider.overrideWith((ref, teamId) async {
      return EsportsTeamDetail.fromJson(const {
        'id': 1,
        'name': 'Wolves',
        'short_name': 'WOL',
        'league_name': 'KPL Spring',
        'club': 'Chongqing Wolves',
        'wins': 12,
        'losses': 3,
        'win_rate': 0.8,
        'battle_count': 15,
        'team_profile': {
          'team_nation': 'China',
          'team_desc': 'A championship team with a storied history.',
          'honor_list': [
            {'name': 'KPL Spring', 'title_name': 'Champion'},
          ],
        },
        'event_stats': {
          'team_rank_stat': {'avgKda': 6.8, 'avgKill': 12.4},
        },
        'members': [
          {
            'source_id': 8,
            'name': 'Fly',
            'role_key': 'clash',
            'avatar_url': '',
          },
        ],
        'recent_matches': [],
      });
    }),
    esportsPlayerDetailProvider.overrideWith((ref, playerId) async {
      return EsportsPlayerDetail.fromJson(const {
        'id': 8,
        'name': 'Fly',
        'role': 'Clash Lane',
        'team_name': 'Wolves',
        'avatar_url': '',
        'team_logo_url': '',
        'stats_json': {
          'kda': 6.8,
          'participation_rate': 0.72,
          'gold_per_min': 680,
          'damage_per_min': 4200,
          'taken_per_min': 3900,
        },
        'event_stats': [
          {
            'dimension': 'avgKill',
            'dimension_desc': 'Avg Kills',
            'display_value': '5.40',
          },
        ],
        'common_heroes': [
          {
            'hero': {'id': 105, 'hero_name': 'Mulan', 'hero_icon': ''},
            'battle_count': 10,
            'win_rate': 0.7,
            'avg_kda': 5.8,
            'avg_participation_rate': 0.65,
          },
        ],
        'recent_matches': [],
      });
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
          teamId: '1',
          teamName: 'Wolves',
          teamLogoUrl: '',
          metrics: [
            EsportsStatMetric(label: 'Win Rate', value: '66.2%'),
            EsportsStatMetric(label: 'KDA', value: '5.4'),
          ],
        ),
      ];
    }),
  ];
}
