import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
import 'package:hok_helper_mobile/src/features/content/domain/patch_note_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

void main() {
  testWidgets('renders skin and cg media cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 11,
                kind: ContentKind.skin,
                title: 'Starlit Blade',
                heroName: 'Lam',
                imageUrl: '',
                subtitle: 'Galaxy',
                rating: 4.5,
                ratingCount: 18,
                viewCount: 0,
              ),
            ];
          }),
          cgsProvider.overrideWith((ref) async {
            return const [
              ContentItemSummary(
                id: 21,
                kind: ContentKind.cg,
                title: 'Origin Story',
                heroName: 'Angela',
                imageUrl: '',
                subtitle: 'Playable video',
                rating: 4,
                ratingCount: 9,
                viewCount: 300,
              ),
            ];
          }),
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 31,
                version: '1.2.3',
                title: 'Version 1.2.3 Patch Notes',
                date: '2026-07-01',
                preview: 'Lam and Angela adjusted.',
                changeCount: 2,
                tags: ['Patch Notes'],
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: ContentScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final mainScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Skins'),
      300,
      scrollable: mainScroll,
    );
    expect(find.text('Skins'), findsOneWidget);
    expect(find.text('Starlit Blade'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('4.5 · 18 ratings'), findsOneWidget);
    await tester.drag(mainScroll, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('CGs'), findsOneWidget);
    expect(find.text('Origin Story'), findsOneWidget);
    expect(find.text('Angela'), findsOneWidget);
    expect(find.text('300 views'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Version 1.2.3 Patch Notes'),
      300,
      scrollable: mainScroll,
    );
    expect(find.text('Patch Notes'), findsWidgets);
    expect(find.text('Version 1.2.3 Patch Notes'), findsOneWidget);
    expect(find.text('V1.2.3 · 2026-07-01'), findsOneWidget);
    expect(find.text('2 hero changes'), findsOneWidget);
  });
}
