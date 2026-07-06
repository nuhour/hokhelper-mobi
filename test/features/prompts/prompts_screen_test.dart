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

  String? favoritedPromptId;

  @override
  Future<PromptFavoriteResult> toggleFavorite(String promptId) async {
    favoritedPromptId = promptId;
    return const PromptFavoriteResult(isFavorited: true, favoriteCount: 6);
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
}
