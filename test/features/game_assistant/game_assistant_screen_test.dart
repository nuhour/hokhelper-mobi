import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/game_assistant/presentation/game_assistant_screen.dart';

void main() {
  testWidgets('renders game assistant preview and feature cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GameAssistantScreen())),
    );

    expect(find.text('Game Assistant'), findsOneWidget);
    expect(find.text('Mobile Companion App'), findsOneWidget);
    expect(find.text('Jungle timers'), findsOneWidget);
    expect(find.text('Gold analytics'), findsWidgets);
    expect(find.text('Enemy cooldowns'), findsWidgets);
    expect(find.text('AI tactical tips'), findsOneWidget);
    expect(find.text('Live Match Console'), findsOneWidget);
    expect(find.text('Ready on this device'), findsOneWidget);
    expect(find.text('Android APK'), findsOneWidget);
    expect(find.text('Web assistant'), findsOneWidget);
    expect(find.text('Installed companion'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('runs the live match timer controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GameAssistantScreen())),
    );

    await tester.scrollUntilVisible(
      find.text('Start match'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Blue Buff 15s'), findsOneWidget);

    await tester.tap(find.text('Start match'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('00:02'), findsOneWidget);
    expect(find.text('Blue Buff 13s'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('00:02'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Blue Buff 15s'), findsOneWidget);
  });
}
