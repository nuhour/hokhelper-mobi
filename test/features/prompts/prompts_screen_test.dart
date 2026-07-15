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
  _FakePromptsRepository({
    this.initialQuota = const PromptGenerationQuota(used: 1, total: 5),
    this.generationEnabled = true,
  }) : super(apiClient: _NoopApiClient());

  final PromptGenerationQuota initialQuota;
  final bool generationEnabled;

  String? likedPromptId;
  String? favoritedPromptId;
  PromptDraft? createdDraft;
  String? updatedPromptId;
  PromptDraft? updatedDraft;
  String? deletedPromptId;
  String? generatedPromptId;
  int? generatedCount;
  String? generatedContent;
  String? generatedSourceImageUrl;
  String? setCoverPromptId;
  String? setCoverImageData;
  String? rechargePlanId;
  String? rechargePaymentMethod;
  PromptListAction? loadedAction;
  String? loadedSearch;
  PromptListSort? loadedSort;

  @override
  Future<List<PromptSummary>> loadPrompts({
    required PromptListAction action,
    String search = '',
    PromptListSort sort = PromptListSort.hot,
  }) async {
    loadedAction = action;
    loadedSearch = search;
    loadedSort = sort;
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
  }

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
    return initialQuota;
  }

  @override
  Future<bool> loadGenerationEnabled() async {
    return generationEnabled;
  }

  @override
  Future<PromptGenerateResult> generateImages({
    required String promptId,
    int count = 1,
    String? customContent,
    String? sourceImageUrl,
  }) async {
    generatedPromptId = promptId;
    generatedCount = count;
    generatedContent = customContent;
    generatedSourceImageUrl = sourceImageUrl;
    return const PromptGenerateResult(
      images: ['https://example.test/generated-1.png'],
      quota: PromptGenerationQuota(used: 2, total: 5),
    );
  }

  @override
  Future<PromptSummary> setPromptImage({
    required String promptId,
    required String imageData,
  }) async {
    setCoverPromptId = promptId;
    setCoverImageData = imageData;
    return PromptSummary(
      id: promptId,
      title: 'Cyber skin concept',
      content: 'Create a neon Honor of Kings skin splash art.',
      tags: const ['skin', 'cyber'],
      imageUrl: imageData,
      authorName: 'artist',
      likeCount: 12,
      favoriteCount: 5,
      isPublic: true,
    );
  }

  @override
  Future<PromptRechargeResult> rechargeGenerationQuota({
    required String planId,
    String paymentMethod = 'card',
  }) async {
    rechargePlanId = planId;
    rechargePaymentMethod = paymentMethod;
    return const PromptRechargeResult(
      quota: PromptGenerationQuota(used: 5, total: 15),
      added: 10,
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

  testWidgets('opens a prompt viewer with its image comparison', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptListProvider(PromptListAction.explore).overrideWith((
            ref,
          ) async {
            return const [
              PromptSummary(
                id: '7',
                title: 'Rainy battlefield',
                content: 'Transform this battlefield into a rainy scene.',
                tags: ['rain'],
                imageUrl: 'https://example.test/result.png',
                sourceImageUrl: 'https://example.test/source.png',
                effectImageUrl: 'https://example.test/result.png',
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

    await tester.tap(find.byTooltip('View prompt'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Rainy battlefield'), findsWidgets);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Copy'), findsOneWidget);

    await tester.tap(find.byTooltip('View Original fullscreen'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('Close full screen image'), findsOneWidget);
  });

  testWidgets('searches and sorts prompt explorer like the hokx portal', (
    tester,
  ) async {
    final repository = _FakePromptsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [promptsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: PromptsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search prompts'),
      'skin',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();

    expect(repository.loadedAction, PromptListAction.explore);
    expect(repository.loadedSearch, 'skin');
    expect(repository.loadedSort, PromptListSort.latest);
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

    await tester.tap(find.byTooltip('Copy'));
    await tester.pumpAndSettle();

    expect(clipboardCall?.arguments, {
      'text': 'Create a neon Honor of Kings skin splash art.',
    });
    expect(find.text('Prompt copied'), findsOneWidget);
  });

  testWidgets('copies prompt share links to clipboard', (tester) async {
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

    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();

    expect(clipboardCall?.arguments, {'text': '/tools/prompts?promptId=7'});
    expect(find.text('Prompt link copied'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Favorite'));
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

    await tester.tap(find.byTooltip('Like'));
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
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Custom tag'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Custom tag'),
      'portrait',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.enterText(
      find.widgetWithText(TextField, 'Custom tag'),
      'mobile',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Save prompt'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save prompt'));
    await tester.pumpAndSettle();

    expect(repository.createdDraft?.title, 'Mobile prompt');
    expect(
      repository.createdDraft?.content,
      'Generate a clean HOK hero portrait.',
    );
    expect(repository.createdDraft?.tags, ['portrait', 'mobile']);
    expect(repository.createdDraft?.sourceImageUrl, isEmpty);
    expect(repository.createdDraft?.effectImageUrl, isEmpty);
    expect(find.text('Mobile prompt'), findsOneWidget);
    expect(find.text('Prompt created'), findsOneWidget);
  });

  testWidgets('creates prompts with the selected prompt language', (
    tester,
  ) async {
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
      'Indonesian prompt',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prompt content'),
      'Buat splash art hero Honor of Kings.',
    );
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Indonesian').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Save prompt'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save prompt'));
    await tester.pumpAndSettle();

    expect(repository.createdDraft?.language, 'id');
    expect(repository.createdDraft?.title, 'Indonesian prompt');
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
                imageUrl: 'https://example.test/effect-old.png',
                sourceImageUrl: 'https://example.test/source-old.png',
                effectImageUrl: 'https://example.test/effect-old.png',
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

    await tester.tap(find.byTooltip('Edit'));
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
    expect(find.text('skin'), findsWidgets);
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Custom tag'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Custom tag'),
      'updated',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Save prompt'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save prompt'));
    await tester.pumpAndSettle();

    expect(repository.updatedPromptId, '7');
    expect(repository.updatedDraft?.title, 'Updated prompt');
    expect(
      repository.updatedDraft?.tags,
      containsAll(['skin', 'cyber', 'updated']),
    );
    expect(
      repository.updatedDraft?.sourceImageUrl,
      'https://example.test/source-old.png',
    );
    expect(
      repository.updatedDraft?.effectImageUrl,
      'https://example.test/effect-old.png',
    );
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

    await tester.tap(find.byTooltip('Delete'));
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

    await tester.tap(find.byTooltip('Generate'));
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

  testWidgets('generates prompt images from a source image URL', (
    tester,
  ) async {
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

    await tester.tap(find.byTooltip('Generate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Image to image'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Source image URL'),
      'https://example.test/source.png',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Generate image'));
    await tester.pumpAndSettle();

    expect(repository.generatedPromptId, '7');
    expect(
      repository.generatedSourceImageUrl,
      'https://example.test/source.png',
    );
    expect(find.bySemanticsLabel('Generated image 1'), findsOneWidget);
  });

  testWidgets('blocks prompt generation when backend config disables it', (
    tester,
  ) async {
    final repository = _FakePromptsRepository(generationEnabled: false);

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

    await tester.tap(find.byTooltip('Generate'));
    await tester.pumpAndSettle();

    expect(find.text('Image generation'), findsNothing);
    expect(
      find.text('Prompt generation is temporarily unavailable'),
      findsOneWidget,
    );
  });

  testWidgets('sets a generated prompt image as cover', (tester) async {
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

    await tester.tap(find.byTooltip('Generate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Generate image'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Set cover'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Set cover'));
    await tester.pumpAndSettle();

    expect(repository.setCoverPromptId, '7');
    expect(
      repository.setCoverImageData,
      'https://example.test/generated-1.png',
    );
    expect(find.text('Prompt cover updated'), findsOneWidget);
  });

  testWidgets('recharges prompt generation quota from the sheet', (
    tester,
  ) async {
    final repository = _FakePromptsRepository(
      initialQuota: const PromptGenerationQuota(used: 5, total: 5),
    );

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

    await tester.tap(find.byTooltip('Generate'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 5 left'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Recharge'));
    await tester.pumpAndSettle();

    expect(find.text('Recharge quota'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
    await tester.pumpAndSettle();

    expect(repository.rechargePlanId, 'standard');
    expect(repository.rechargePaymentMethod, 'card');
    expect(find.text('10 / 15 left'), findsOneWidget);
    expect(find.text('Quota recharged +10'), findsOneWidget);
  });
}
