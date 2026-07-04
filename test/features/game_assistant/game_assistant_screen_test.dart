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
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
