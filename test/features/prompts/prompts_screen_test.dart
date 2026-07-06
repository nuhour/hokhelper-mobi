import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/prompts/data/prompts_repository.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';

class _FakePromptsRepository extends PromptsRepository {
  _FakePromptsRepository() : super(apiClient: _NoopApiClient());

  String? likedPromptId;
  String? favoritedPromptId;
  PromptDraft? createdDraft;
  String? updatedPromptId;
  PromptDraft? updatedDraft;
  String? deletedPromptId;
  String? generatedPromptId;
  int? generatedCount;
  String? generatedContent;

  @override
  Future<PromptLikeResult> toggleLike(String promptId) async {
    likedPromptId = promptId;
    return const PromptLikeResult(isLiked: true, likeCount: 13);
  }

  @override
  Future<PromptFavoriteResult> toggleFavorite(String promptId) async {
    favoritedPromptId = promptId;
    return const PromptFavoriteResult(isFavorited: true, favoriteCount: 6);
  }

  @override
  Future<PromptSummary> createPrompt(PromptDraft draft) async {
    createdDraft = draft;
    return PromptSummary(
      id: '10',
      title: draft.title,
      content: draft.content,
      tags: draft.tags,
      imageUrl: '',
      authorName: 'me',
      likeCount: 0,
      favoriteCount: 0,
      isPublic: draft.isPublic,
    );
  }

  @override
  Future<PromptSummary> updatePrompt(String promptId, PromptDraft draft) async {
    updatedPromptId = promptId;
    updatedDraft = draft;
    return PromptSummary(
      id: promptId,
      title: draft.title,
      content: draft.content,
      tags: draft.tags,
      imageUrl: '',
      authorName: 'me',
      likeCount: 12,
      favoriteCount: 5,
      isPublic: draft.isPublic,
    );
  }

  @override
  Future<void> deletePrompt(String promptId) async {
    deletedPromptId = promptId;
  }

  @override
  Future<PromptGenerationQuota> loadGenerationQuota() async {
    return const PromptGenerationQuota(used: 1, total: 5);
  }

  @override
  Future<PromptGenerateResult> generateImages({
    required String promptId,
    int count = 1,
    String? customContent,
  }) async {
    generatedPromptId = promptId;
    generatedCount = count;
    generatedContent = customContent;
    return const PromptGenerateResult(
      images: ['https://example.test/generated-1.png'],
      quota: PromptGenerationQuota(used: 2, total: 5),
    );
  }
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

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

  testWidgets('pins shared prompt from initial prompt id', (tester) async {
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
                id: '2',
                title: 'Prompt 2',
                content: 'Second prompt.',
                tags: [],
                imageUrl: '',
                authorName: 'artist',
                likeCount: 2,
                favoriteCount: 2,
                isPublic: true,
              ),
              PromptSummary(
                id: '42',
                title: 'Shared prompt target',
                content: 'Prompt shared from the hokx portal.',
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
        child: const MaterialApp(
          home: Scaffold(body: PromptsScreen(initialPromptId: '42')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared prompt'), findsOneWidget);
    expect(find.text('Shared prompt target'), findsOneWidget);
    expect(find.text('Prompt shared from the hokx portal.'), findsOneWidget);
    expect(find.text('sharer'), findsOneWidget);
  });

  testWidgets('copies prompt content to clipboard', (tester) async {
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCall = call;
          }
          return null;
        });

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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Copy'));
    await tester.pumpAndSettle();

    expect(clipboardCall?.arguments, {
      'text': 'Create a neon Honor of Kings skin splash art.',
    });
    expect(find.text('Prompt copied'), findsOneWidget);
  });

  testWidgets('favorites prompt cards through the backend', (tester) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptsRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Favorite'));
    await tester.pumpAndSettle();

    expect(repository.favoritedPromptId, '7');
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Prompt favorited'), findsOneWidget);
  });

  testWidgets('likes prompt cards through the backend', (tester) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptsRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Like'));
    await tester.pumpAndSettle();

    expect(repository.likedPromptId, '7');
    expect(find.text('13'), findsOneWidget);
    expect(find.text('Prompt liked'), findsOneWidget);
  });

  testWidgets('creates a prompt from the mobile prompt form', (tester) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptsRepositoryProvider.overrideWithValue(repository),
          promptListProvider(PromptListAction.explore).overrideWith((
            ref,
          ) async {
            return const [];
          }),
          promptListProvider(PromptListAction.myPrompts).overrideWith((
            ref,
          ) async {
            return const [];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: PromptsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Mobile prompt',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prompt content'),
      'Generate a clean HOK hero portrait.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tags'),
      'portrait, mobile',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save prompt'));
    await tester.pumpAndSettle();

    expect(repository.createdDraft?.title, 'Mobile prompt');
    expect(
      repository.createdDraft?.content,
      'Generate a clean HOK hero portrait.',
    );
    expect(repository.createdDraft?.tags, ['portrait', 'mobile']);
    expect(find.text('Mobile prompt'), findsOneWidget);
    expect(find.text('Prompt created'), findsOneWidget);
  });

  testWidgets('edits my prompts from the mobile prompt form', (tester) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptsRepositoryProvider.overrideWithValue(repository),
          promptListProvider(PromptListAction.myPrompts).overrideWith((
            ref,
          ) async {
            return const [
              PromptSummary(
                id: '7',
                title: 'Cyber skin concept',
                content: 'Create a neon Honor of Kings skin splash art.',
                tags: ['skin', 'cyber'],
                imageUrl: '',
                authorName: 'me',
                likeCount: 12,
                favoriteCount: 5,
                isPublic: true,
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PromptsScreen(initialAction: PromptListAction.myPrompts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit prompt'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Updated prompt',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prompt content'),
      'Updated HOK prompt content.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tags'),
      'updated',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save prompt'));
    await tester.pumpAndSettle();

    expect(repository.updatedPromptId, '7');
    expect(repository.updatedDraft?.title, 'Updated prompt');
    expect(repository.updatedDraft?.tags, ['updated']);
    expect(find.text('Updated prompt'), findsOneWidget);
    expect(find.text('Prompt updated'), findsOneWidget);
  });

  testWidgets('deletes my prompts after confirmation', (tester) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptsRepositoryProvider.overrideWithValue(repository),
          promptListProvider(PromptListAction.myPrompts).overrideWith((
            ref,
          ) async {
            return const [
              PromptSummary(
                id: '7',
                title: 'Cyber skin concept',
                content: 'Create a neon Honor of Kings skin splash art.',
                tags: ['skin', 'cyber'],
                imageUrl: '',
                authorName: 'me',
                likeCount: 12,
                favoriteCount: 5,
                isPublic: true,
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PromptsScreen(initialAction: PromptListAction.myPrompts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete prompt?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedPromptId, '7');
    expect(find.text('Cyber skin concept'), findsNothing);
    expect(find.text('Prompt deleted'), findsOneWidget);
  });

  testWidgets('generates prompt images from a prompt card', (tester) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptsRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Generate'));
    await tester.pumpAndSettle();

    expect(find.text('Image generation'), findsOneWidget);
    expect(find.text('4 / 5 left'), findsOneWidget);
    expect(
      find.text('Create a neon Honor of Kings skin splash art.'),
      findsWidgets,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Generate image'));
    await tester.pumpAndSettle();

    expect(repository.generatedPromptId, '7');
    expect(repository.generatedCount, 1);
    expect(
      repository.generatedContent,
      'Create a neon Honor of Kings skin splash art.',
    );
    expect(find.text('3 / 5 left'), findsOneWidget);
    expect(find.bySemanticsLabel('Generated image 1'), findsOneWidget);
  });
}
