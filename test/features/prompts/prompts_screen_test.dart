import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/prompts/data/prompts_repository.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';

void main() {
  testWidgets('renders prompt explorer cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptListProvider(PromptListAction.explore).overrideWith((
            ref,
          ) async {
            return const [
              PromptSummary(
                id: '7',
                title: 'Cyber skin concept',
                content: 'Create a neon Honor of Kings skin splash art.',
                tags: ['skin', 'cyber'],
                imageUrl: '',
                authorName: 'artist',
                likeCount: 12,
                favoriteCount: 5,
                isPublic: true,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: PromptsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prompts'), findsOneWidget);
    expect(find.text('Cyber skin concept'), findsOneWidget);
    expect(
      find.text('Create a neon Honor of Kings skin splash art.'),
      findsOneWidget,
    );
    expect(find.text('artist'), findsOneWidget);
    expect(find.text('skin'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('opens favorites tab from the initial action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptListProvider(PromptListAction.favorites).overrideWith((
            ref,
          ) async {
            return const [
              PromptSummary(
                id: '9',
                title: 'Favorite prompt',
                content: 'Saved prompt content.',
                tags: ['saved'],
                imageUrl: '',
                authorName: 'collector',
                likeCount: 3,
                favoriteCount: 8,
                isPublic: true,
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PromptsScreen(initialAction: PromptListAction.favorites),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Favorite prompt'), findsOneWidget);
    expect(find.text('Cyber skin concept'), findsNothing);
  });
}
