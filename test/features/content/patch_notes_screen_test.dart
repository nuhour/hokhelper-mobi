import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
        ],
        child: const MaterialApp(home: Scaffold(body: PatchNotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patch Notes'), findsWidgets);
    expect(find.text('Version 1.2.3 Patch Notes'), findsOneWidget);
    expect(find.text('Version 1.2.4 Patch Notes'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('Angela'), findsOneWidget);

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
}
