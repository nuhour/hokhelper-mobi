import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/domain/tierlist_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_tool_screen.dart';

void main() {
  testWidgets('renders tier list scheme cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolSchemesProvider.overrideWith((ref) async {
            return const [
              TierListSchemeSummary(
                id: '9',
                name: 'Solo Queue Meta',
                createdAt: '2026-07-01T08:00:00Z',
                updatedAt: '2026-07-03T12:00:00Z',
                rows: [
                  TierListSchemeRowSummary(
                    id: 'r1',
                    label: 'T0',
                    color: 'bg-red-600',
                    heroCount: 2,
                  ),
                  TierListSchemeRowSummary(
                    id: 'r2',
                    label: 'T1',
                    color: 'bg-orange-500',
                    heroCount: 1,
                  ),
                ],
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: TierListToolScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tier List Tool'), findsOneWidget);
    expect(find.text('Solo Queue Meta'), findsOneWidget);
    expect(find.text('3 heroes'), findsOneWidget);
    expect(find.text('Updated 2026-07-03'), findsOneWidget);
    expect(find.text('T0 · 2'), findsOneWidget);
    expect(find.text('T1 · 1'), findsOneWidget);
  });
}
