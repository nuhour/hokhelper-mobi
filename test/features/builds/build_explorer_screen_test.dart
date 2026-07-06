import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_explorer_screen.dart';

void main() {
  testWidgets('renders public build scheme summaries', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicBuildSchemesProvider.overrideWith((ref) async {
            return const [
              BuildSchemeSummary(
                id: 7,
                title: 'Burst jungle',
                heroName: 'Lam',
                authorName: 'coach',
                equipmentIcons: [],
                likeCount: 12,
                favoriteCount: 5,
                cloneCount: 3,
                isPublic: true,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: BuildExplorerScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Build Explorer'), findsOneWidget);
    expect(find.text('Burst jungle'), findsOneWidget);
    expect(find.text('Lam · '), findsOneWidget);
    expect(find.text('coach'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
