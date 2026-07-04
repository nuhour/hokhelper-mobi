import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_dashboard_screen.dart';

void main() {
  testWidgets('renders BP scheme cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bpSchemesProvider.overrideWith((ref) async {
            return const [
              BpSchemeSummary(
                id: '12',
                name: 'KPL Finals Draft',
                createdAt: '2026-07-03T10:00:00Z',
                boMode: 7,
                teamAName: 'Wolves',
                teamBName: 'AG',
                sideSelectionRule: 'loser_selects',
                gameNumber: 3,
                historyCount: 2,
                currentStepIndex: 4,
                blueBanCount: 1,
                redBanCount: 1,
                bluePickCount: 1,
                redPickCount: 1,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BpDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BP Simulator'), findsOneWidget);
    expect(find.text('KPL Finals Draft'), findsOneWidget);
    expect(find.text('Wolves vs AG'), findsOneWidget);
    expect(find.text('BO7'), findsOneWidget);
    expect(find.text('Game 3 · Step 4'), findsOneWidget);
    expect(find.text('2 games'), findsOneWidget);
  });
}
