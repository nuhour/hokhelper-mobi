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
}
