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
    expect(find.text('statistic_17'), findsOneWidget);
  });
}
