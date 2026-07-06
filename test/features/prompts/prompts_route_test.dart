import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/prompts/data/prompts_repository.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';
import 'package:hok_helper_mobile/src/features/profile/presentation/public_profile_screen.dart';

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

  testWidgets('prompt authors open public profile routes', (tester) async {
    final router = createAppRouter();
    router.go('/tools/prompts');

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
                content: 'Create a neon HOK skin.',
                tags: ['skin'],
                imageUrl: '',
                authorId: 77,
                authorName: 'artist',
                likeCount: 12,
                favoriteCount: 5,
                isPublic: true,
              ),
            ];
          }),
          publicUserProfileProvider(77).overrideWith((ref) async {
            return const UserProfile(
              id: 77,
              username: 'artist',
              displayName: 'Artist',
              email: 'artist@example.test',
              avatar: '',
              level: 5,
              points: 500,
              xpTotal: 500,
              xpCurrentLevel: 100,
              xpToNextLevel: 400,
              levelProgress: 20,
              levelCap: false,
              bio: 'Prompt artist',
              socialLinks: {},
              stats: ProfileStats(
                posts: 1,
                following: 2,
                followers: 3,
                likes: 4,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('artist'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/profile/77');
    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Prompt artist'), findsOneWidget);
  });

  testWidgets('prompt author avatars open public profile routes', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/prompts');

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
                content: 'Create a neon HOK skin.',
                tags: ['skin'],
                imageUrl: '',
                authorId: 77,
                authorName: 'artist',
                likeCount: 12,
                favoriteCount: 5,
                isPublic: true,
              ),
            ];
          }),
          publicUserProfileProvider(77).overrideWith((ref) async {
            return const UserProfile(
              id: 77,
              username: 'artist',
              displayName: 'Artist',
              email: 'artist@example.test',
              avatar: '',
              level: 5,
              points: 500,
              xpTotal: 500,
              xpCurrentLevel: 100,
              xpToNextLevel: 400,
              levelProgress: 20,
              levelCap: false,
              bio: 'Prompt artist',
              socialLinks: {},
              stats: ProfileStats(
                posts: 1,
                following: 2,
                followers: 3,
                likes: 4,
              ),
              isFollowing: false,
              isLiked: false,
              isSelf: false,
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.image_not_supported_outlined).last);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/profile/77');
    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('Prompt artist'), findsOneWidget);
  });
}
