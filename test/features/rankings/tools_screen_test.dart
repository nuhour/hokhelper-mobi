import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_explorer_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/tools_screen.dart';

void main() {
  testWidgets('build explorer tile opens the build explorer route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/tools',
      routes: [
        GoRoute(
          path: '/tools',
          builder: (context, state) => const ToolsScreen(),
          routes: [
            GoRoute(
              path: 'builds',
              builder: (context, state) => const BuildExplorerScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicBuildSchemesProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build Explorer'));
    await tester.pumpAndSettle();

    expect(find.text('Build Explorer'), findsOneWidget);
    expect(find.text('No public builds'), findsOneWidget);
  });
}
