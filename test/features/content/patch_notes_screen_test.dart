import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';
import 'package:hok_helper_mobile/src/features/content/domain/patch_note_summary.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/patch_notes_screen.dart';

class _PagedPatchRepository extends ContentRepository {
  _PagedPatchRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  final requestedPages = <int>[];
  int? requestedDetailId;

  @override
  Future<List<PatchNoteSummary>> loadPatchNotes(
    int regionId, {
    int page = 1,
    int pageSize = 120,
  }) async {
    requestedPages.add(page);
    final startId = (page - 1) * pageSize + 1;
    final count = page == 1 ? pageSize : 1;
    return List.generate(count, (index) {
      final id = startId + index;
      return PatchNoteSummary(
        id: id,
        version: '1.2.$id',
        title: 'Version 1.2.$id Patch Notes',
        date: '2026-07-${(id % 28) + 1}',
        preview: 'Balance preview $id.',
        content: 'Full patch note body $id.',
        changeCount: 1,
        tags: const ['Patch Notes'],
        heroChanges: [
          PatchHeroChange(
            heroId: id,
            heroName: 'Hero $id',
            avatarUrl: '',
            changeType: 'adjust',
          ),
        ],
      );
    }, growable: false);
  }

  @override
  Future<PatchNoteSummary> loadPatchNoteDetail(
    int noteId, {
    required int regionId,
  }) async {
    requestedDetailId = noteId;
    return PatchNoteSummary(
      id: noteId,
      version: '1.2.$noteId',
      title: 'Version 1.2.$noteId Patch Notes',
      date: '2026-07-01',
      preview: 'List preview only.',
      content: 'Complete patch detail body loaded after opening the note.',
      changeCount: 1,
      tags: const ['Patch Notes'],
      heroChanges: [
        PatchHeroChange(
          heroId: noteId,
          heroName: 'Hero $noteId',
          avatarUrl: '',
          changeType: 'buff',
        ),
      ],
    );
  }
}

class _StaticPatchRepository extends ContentRepository {
  _StaticPatchRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  @override
  Future<PatchNoteSummary> loadPatchNoteDetail(
    int noteId, {
    required int regionId,
  }) async {
    return PatchNoteSummary(
      id: noteId,
      version: '1.2.4',
      title: 'Version 1.2.4 Patch Notes',
      date: '2026-07-02',
      preview: 'Arthur adjusted.',
      content: 'Arthur changes only.',
      changeCount: 1,
      tags: const ['Patch Notes'],
      heroChanges: const [
        PatchHeroChange(
          heroId: 10,
          heroName: 'Arthur',
          avatarUrl: '',
          changeType: 'adjust',
        ),
      ],
    );
  }
}

class _PatchLinkRepository extends ContentRepository {
  _PatchLinkRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  @override
  Future<PatchNoteSummary> loadPatchNoteDetail(
    int noteId, {
    required int regionId,
  }) async {
    return PatchNoteSummary(
      id: noteId,
      version: '1.2.5',
      title: 'Version 1.2.5 Patch Notes',
      date: '2026-07-03',
      preview: 'Official notes linked.',
      content:
          'Read the [official notes](https://updates.example/hok/125) before playing.',
      changeCount: 0,
      tags: const ['Patch Notes'],
    );
  }
}

void main() {
  testWidgets('renders patch timeline, filters heroes, and opens detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 31,
                version: '1.2.3',
                title: 'Version 1.2.3 Patch Notes',
                date: '2026-07-01',
                preview: 'Lam and Angela adjusted.',
                content: 'Full patch note body with balance details.',
                changeCount: 2,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                  PatchHeroChange(
                    heroId: 21,
                    heroName: 'Angela',
                    avatarUrl: '',
                    changeType: 'nerf',
                  ),
                ],
              ),
              PatchNoteSummary(
                id: 32,
                version: '1.2.4',
                title: 'Version 1.2.4 Patch Notes',
                date: '2026-07-02',
                preview: 'Arthur adjusted.',
                content: 'Arthur changes only.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 10,
                    heroName: 'Arthur',
                    avatarUrl: '',
                    changeType: 'adjust',
                  ),
                ],
              ),
            ];
          }),
          contentRepositoryProvider.overrideWithValue(_StaticPatchRepository()),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: PatchNotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patch Notes'), findsWidgets);
    expect(find.text('Version 1.2.3 Patch Notes'), findsOneWidget);
    expect(find.text('Version 1.2.4 Patch Notes'), findsOneWidget);
    expect(find.byTooltip('Lam (buff)'), findsOneWidget);
    expect(find.byTooltip('Angela (nerf)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Arthur');
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3 Patch Notes'), findsNothing);
    expect(find.text('Version 1.2.4 Patch Notes'), findsOneWidget);

    await tester.tap(find.text('Version 1.2.4 Patch Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Hero Adjustments'), findsOneWidget);
    expect(find.text('Arthur changes only.'), findsOneWidget);
    expect(find.text('adjust'), findsOneWidget);
  });

  testWidgets('loads more patch notes after the first timeline page', (
    tester,
  ) async {
    final repository = _PagedPatchRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: PatchNotesScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Version 1.2.1 Patch Notes'), findsOneWidget);
    expect(find.text('Version 1.2.121 Patch Notes'), findsNothing);

    final loadMoreButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Load more'),
    );
    await tester.runAsync(() async {
      loadMoreButton.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(repository.requestedPages, [1, 2]);
    expect(find.text('Version 1.2.121 Patch Notes'), findsOneWidget);
  });

  testWidgets('loads full patch note body when opening detail', (tester) async {
    final repository = _PagedPatchRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: PatchNotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Version 1.2.1 Patch Notes'));
    await tester.pumpAndSettle();

    expect(repository.requestedDetailId, 1);
    expect(
      find.text('Complete patch detail body loaded after opening the note.'),
      findsOneWidget,
    );
  });

  testWidgets('patch timeline hero chips open hero history routes', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/content/patch-notes',
          builder: (context, state) => const PatchNotesScreen(),
        ),
        GoRoute(
          path: '/heroes/:heroId',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
      initialLocation: '/content/patch-notes',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 32,
                version: '1.2.4',
                title: 'Version 1.2.4 Patch Notes',
                date: '2026-07-02',
                preview: 'Arthur adjusted.',
                content: 'Arthur changes only.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 10,
                    heroName: 'Arthur',
                    avatarUrl: '',
                    changeType: 'adjust',
                  ),
                ],
              ),
            ];
          }),
          contentRepositoryProvider.overrideWithValue(_StaticPatchRepository()),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Arthur (adjust)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/heroes/10');
    expect(uri.queryParameters['tab'], 'history');
  });

  testWidgets('patch detail hero adjustments open hero history routes', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/content/patch-notes',
          builder: (context, state) => const PatchNotesScreen(),
        ),
        GoRoute(
          path: '/heroes/:heroId',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
      initialLocation: '/content/patch-notes',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 32,
                version: '1.2.4',
                title: 'Version 1.2.4 Patch Notes',
                date: '2026-07-02',
                preview: 'Arthur adjusted.',
                content: 'Arthur changes only.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 10,
                    heroName: 'Arthur',
                    avatarUrl: '',
                    changeType: 'adjust',
                  ),
                ],
              ),
            ];
          }),
          contentRepositoryProvider.overrideWithValue(_StaticPatchRepository()),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Version 1.2.4 Patch Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arthur').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/heroes/10');
    expect(uri.queryParameters['tab'], 'history');
  });

  testWidgets('patch detail markdown links open through the mobile link route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/content/patch-notes',
          builder: (context, state) => const PatchNotesScreen(),
        ),
        GoRoute(
          path: '/external-link',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
      initialLocation: '/content/patch-notes',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 33,
                version: '1.2.5',
                title: 'Version 1.2.5 Patch Notes',
                date: '2026-07-03',
                preview: 'Official notes linked.',
                content:
                    'Read the [official notes](https://updates.example/hok/125) before playing.',
                changeCount: 0,
                tags: ['Patch Notes'],
              ),
            ];
          }),
          contentRepositoryProvider.overrideWithValue(_PatchLinkRepository()),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Version 1.2.5 Patch Notes'));
    await tester.pumpAndSettle();
    final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    markdown.onTapLink!(
      'official notes',
      'https://updates.example/hok/125',
      '',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/external-link');
    expect(uri.queryParameters['url'], 'https://updates.example/hok/125');
  });
}
