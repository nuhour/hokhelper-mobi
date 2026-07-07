import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('home screen opens global search route', (tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async {
            return const HomeStats(
              success: true,
              message: 'Backend connected',
              result: {'heroes': 128},
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Global Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search the portal'), findsOneWidget);
  });

  testWidgets('home screen opens core stats and tier list portal routes', (
    tester,
  ) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async {
            return const HomeStats(
              success: true,
              message: 'Backend connected',
              result: {'heroes': 128},
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Core Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/tools/stats');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['entry'],
      'home_core',
    );

    router.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Enter Tier List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/tier-list');
  });
}
