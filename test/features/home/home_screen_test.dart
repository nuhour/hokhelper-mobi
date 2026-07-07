import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

Widget _buildHomeScreen(HomeStats stats) {
  return ProviderScope(
    overrides: [homeStatsProvider.overrideWith((ref) async => stats)],
    child: const MaterialApp(home: Scaffold(body: HomeScreen())),
  );
}

void main() {
  testWidgets('home screen exposes hokx portal tool and topic entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHomeScreen(
        const HomeStats(
          success: true,
          message: 'Backend connected',
          result: {'heroes': 128},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Core Stats'), findsOneWidget);
    expect(find.text('Enter Tier List'), findsOneWidget);
    expect(find.text('BP Simulator'), findsOneWidget);
    expect(find.text('Tier Editor'), findsOneWidget);
    expect(find.text('AI Prompts'), findsOneWidget);
    expect(find.text('Team Builder'), findsOneWidget);
    expect(find.text('Build Sim'), findsOneWidget);
    expect(find.text('Rank Fortune'), findsOneWidget);
    expect(find.text('Event Assistance'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('HOK World'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('HOK World'), findsOneWidget);
    expect(find.text('Enter HOK World Topic'), findsOneWidget);
  });

  testWidgets('compact viewport handles many backend stats without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildHomeScreen(
        HomeStats(
          success: true,
          message: 'Ready with a dense payload from the backend.',
          result: {
            for (var index = 0; index < 18; index++)
              'statistic_$index': 'value_$index',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('statistic_17'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('statistic_17'), findsOneWidget);
  });
}
