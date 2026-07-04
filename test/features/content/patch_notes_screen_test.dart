import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/content/domain/patch_note_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/patch_notes_screen.dart';

void main() {
  testWidgets('renders patch timeline, filters heroes, and opens detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 31,
                version: '1.2.3',
                title: 'Version 1.2.3 Patch Notes',
                date: '2026-07-01',
                preview: 'Lam and Angela adjusted.',
                content: 'Full patch note body with balance details.',
                changeCount: 2,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                  PatchHeroChange(
                    heroId: 21,
                    heroName: 'Angela',
                    avatarUrl: '',
                    changeType: 'nerf',
                  ),
                ],
              ),
              PatchNoteSummary(
                id: 32,
                version: '1.2.4',
                title: 'Version 1.2.4 Patch Notes',
                date: '2026-07-02',
                preview: 'Arthur adjusted.',
                content: 'Arthur changes only.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 10,
                    heroName: 'Arthur',
                    avatarUrl: '',
                    changeType: 'adjust',
                  ),
                ],
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: PatchNotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patch Notes'), findsWidgets);
    expect(find.text('Version 1.2.3 Patch Notes'), findsOneWidget);
    expect(find.text('Version 1.2.4 Patch Notes'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('Angela'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Arthur');
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3 Patch Notes'), findsNothing);
    expect(find.text('Version 1.2.4 Patch Notes'), findsOneWidget);

    await tester.tap(find.text('Version 1.2.4 Patch Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Hero Adjustments'), findsOneWidget);
    expect(find.text('Arthur changes only.'), findsOneWidget);
    expect(find.text('adjust'), findsOneWidget);
  });
}
