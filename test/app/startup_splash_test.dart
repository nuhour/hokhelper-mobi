import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/startup_splash.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('preloads home data before revealing the app', (tester) async {
    final homeStats = Completer<HomeStats>();
    var loadCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) {
            loadCount++;
            return homeStats.future;
          }),
        ],
        child: const MaterialApp(
          home: StartupSplash(
            minimumGatherDelay: Duration(milliseconds: 120),
            child: Scaffold(body: Center(child: Text('Home ready'))),
          ),
        ),
      ),
    );

    expect(loadCount, 1);
    expect(find.text('HOK HELPER'), findsOneWidget);
    expect(find.text('Home ready'), findsOneWidget);
    for (var index = 1; index <= 6; index++) {
      expect(find.bySemanticsLabel('Tool icon $index'), findsOneWidget);
    }

    homeStats.complete(
      const HomeStats(success: true, message: 'Ready', result: {}),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('HOK HELPER'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('HOK HELPER'), findsNothing);
    expect(find.text('Home ready'), findsOneWidget);
  });

  testWidgets('does not block startup indefinitely when preload is slow', (
    tester,
  ) async {
    final homeStats = Completer<HomeStats>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeStatsProvider.overrideWith((ref) => homeStats.future)],
        child: const MaterialApp(
          home: StartupSplash(
            minimumGatherDelay: Duration(milliseconds: 120),
            child: Scaffold(body: Text('App shell')),
          ),
        ),
      ),
    );

    for (var second = 0; second < 6; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    expect(find.text('HOK HELPER'), findsNothing);
    expect(find.text('App shell'), findsOneWidget);
  });
}
