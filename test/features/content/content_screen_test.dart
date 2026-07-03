import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';

void main() {
  testWidgets('renders skin count from top-level total response', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async {
            return {
              'success': true,
              'total': 7,
              'rows': [
                {'id': 1},
                {'id': 2},
              ],
            };
          }),
          cgsProvider.overrideWith((ref) async {
            return {
              'success': true,
              'total': 3,
              'rows': [
                {'id': 11},
              ],
            };
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: ContentScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('7 skin records loaded'), findsOneWidget);
    expect(find.text('3 CG records loaded'), findsOneWidget);
  });
}
