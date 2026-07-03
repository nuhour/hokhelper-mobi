import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/content/domain/content_item_summary.dart';
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
        ],
        child: const MaterialApp(home: Scaffold(body: ContentScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Skins'), findsOneWidget);
    expect(find.text('Starlit Blade'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('4.5 · 18 ratings'), findsOneWidget);
    expect(find.text('CGs'), findsOneWidget);
    expect(find.text('Origin Story'), findsOneWidget);
    expect(find.text('Angela'), findsOneWidget);
    expect(find.text('300 views'), findsOneWidget);
  });
}
