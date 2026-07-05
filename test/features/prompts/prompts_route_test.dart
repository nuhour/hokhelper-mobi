import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/prompts/data/prompts_repository.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';

void main() {
  testWidgets('web prompts tab query opens the matching mobile tab', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/prompts?tab=favorites');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptListProvider(
            PromptListAction.explore,
          ).overrideWith((ref) async => const []),
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/tools/prompts');
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Favorite prompt'), findsOneWidget);
    expect(find.text('No prompts found'), findsNothing);
  });

  testWidgets('web prompt share query pins the shared mobile prompt', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/prompts?promptId=42');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptListProvider(PromptListAction.explore).overrideWith((
            ref,
          ) async {
            return const [
              PromptSummary(
                id: '1',
                title: 'Prompt 1',
                content: 'First prompt.',
                tags: [],
                imageUrl: '',
                authorName: 'artist',
                likeCount: 1,
                favoriteCount: 1,
                isPublic: true,
              ),
              PromptSummary(
                id: '42',
                title: 'Shared route prompt',
                content: 'Prompt opened from a hokx share link.',
                tags: ['share'],
                imageUrl: '',
                authorName: 'sharer',
                likeCount: 12,
                favoriteCount: 7,
                isPublic: true,
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/tools/prompts');
    expect(find.text('Shared prompt'), findsOneWidget);
    expect(find.text('Shared route prompt'), findsOneWidget);
    expect(find.text('Prompt opened from a hokx share link.'), findsOneWidget);
  });
}
