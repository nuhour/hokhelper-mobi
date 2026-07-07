import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/builds/data/builds_repository.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_explorer_screen.dart';

class _FakeBuildsRepository extends BuildsRepository {
  _FakeBuildsRepository() : super(apiClient: _NoopApiClient());

  int? likedSchemeId;
  int? favoritedSchemeId;
  int? clonedSchemeId;
  int? clonedSlotIndex;
  BuildSchemeSort? loadedSort;
  int? loadedHeroId;

  @override
  Future<List<BuildSchemeSummary>> loadPublicSchemes(
    int regionId, {
    BuildSchemeSort sort = BuildSchemeSort.popular,
    int? heroId,
  }) async {
    loadedSort = sort;
    loadedHeroId = heroId;
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
  }

  @override
  Future<void> likeBuildScheme(int schemeId) async {
    likedSchemeId = schemeId;
  }

  @override
  Future<void> favoriteBuildScheme(int schemeId) async {
    favoritedSchemeId = schemeId;
  }

  @override
  Future<void> cloneBuildScheme({
    required int schemeId,
    required int slotIndex,
    String? name,
  }) async {
    clonedSchemeId = schemeId;
    clonedSlotIndex = slotIndex;
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

  testWidgets('likes public build schemes from explorer cards', (tester) async {
    final repository = _FakeBuildsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildsRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Like'));
    await tester.pumpAndSettle();

    expect(repository.likedSchemeId, 7);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('Build liked'), findsOneWidget);
  });

  testWidgets('favorites public build schemes from explorer cards', (
    tester,
  ) async {
    final repository = _FakeBuildsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildsRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Favorite'));
    await tester.pumpAndSettle();

    expect(repository.favoritedSchemeId, 7);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Build favorited'), findsOneWidget);
  });

  testWidgets('clones public build schemes into selected slots', (
    tester,
  ) async {
    final repository = _FakeBuildsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildsRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Clone'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Slot 2'));
    await tester.pumpAndSettle();

    expect(repository.clonedSchemeId, 7);
    expect(repository.clonedSlotIndex, 2);
    expect(find.text('Build cloned to Slot 2'), findsOneWidget);
  });

  testWidgets('copies public build share links from explorer cards', (
    tester,
  ) async {
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(clipboardCall, isNotNull);
    expect(clipboardCall!.arguments, {'text': '/tools/build-sim?scheme=7'});
    expect(find.text('Build link copied'), findsOneWidget);
  });

  testWidgets('switches public build explorer sorting like hokx', (
    tester,
  ) async {
    final repository = _FakeBuildsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildsRepositoryProvider.overrideWithValue(repository),
          publicBuildSchemesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: BuildExplorerScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadedSort, BuildSchemeSort.popular);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);

    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();

    expect(repository.loadedSort, BuildSchemeSort.latest);
  });
}
