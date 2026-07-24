import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/content/domain/patch_note_summary.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/content_screen.dart';
import 'package:hok_helper_mobile/src/features/content/presentation/patch_notes_screen.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';

class _PatchDetailRepository extends ContentRepository {
  _PatchDetailRepository()
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
      version: '1.2.3',
      title: 'Version 1.2.3 Patch Notes',
      date: '2026-07-01',
      preview: 'Lam and Angela adjusted.',
      content: 'Full patch note body loaded from the focused route.',
      changeCount: 1,
      tags: const ['Patch Notes'],
      heroChanges: const [
        PatchHeroChange(
          heroId: 42,
          heroName: 'Lam',
          avatarUrl: '',
          changeType: 'buff',
        ),
      ],
    );
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) => const ContentScreen(),
        routes: [
          GoRoute(
            path: 'patch-notes',
            builder: (context, state) => PatchNotesScreen(
              initialNoteId: int.tryParse(
                state.uri.queryParameters['note_id'] ??
                    state.uri.queryParameters['post_id'] ??
                    '',
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('content screen opens patch notes route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 31,
                version: '1.2.3',
                title: 'Version 1.2.3 Patch Notes',
                date: '2026-07-01',
                preview: 'Lam and Angela adjusted.',
                content: 'Full patch note body.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                ],
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patch Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3 Patch Notes'), findsOneWidget);
    expect(find.byTooltip('Lam (buff)'), findsOneWidget);
  });

  testWidgets('content patch note preview opens a focused patch detail route', (
    tester,
  ) async {
    final router = _buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinsProvider.overrideWith((ref) async => const []),
          cgsProvider.overrideWith((ref) async => const []),
          patchNotesProvider.overrideWith((ref) async {
            return const [
              PatchNoteSummary(
                id: 31,
                version: '1.2.3',
                title: 'Version 1.2.3 Patch Notes',
                date: '2026-07-01',
                preview: 'Lam and Angela adjusted.',
                content: 'List patch note body.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                ],
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final mainScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Version 1.2.3 Patch Notes'),
      300,
      scrollable: mainScroll,
    );
    await tester.tap(find.text('Version 1.2.3 Patch Notes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/content/patch-notes');
    expect(uri.queryParameters['note_id'], '31');
  });

  testWidgets('patch notes note_id route opens the focused detail sheet', (
    tester,
  ) async {
    final router = _buildRouter();
    router.go('/content/patch-notes?note_id=31');

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
                content: 'List patch note body.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                ],
              ),
            ];
          }),
          contentRepositoryProvider.overrideWithValue(_PatchDetailRepository()),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Full patch note body loaded from the focused route.'),
      findsOneWidget,
    );
  });

  testWidgets('patch notes post_id route opens the focused detail sheet', (
    tester,
  ) async {
    final router = _buildRouter();
    router.go('/content/patch-notes?post_id=31');

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
                content: 'List patch note body.',
                changeCount: 1,
                tags: ['Patch Notes'],
                heroChanges: [
                  PatchHeroChange(
                    heroId: 42,
                    heroName: 'Lam',
                    avatarUrl: '',
                    changeType: 'buff',
                  ),
                ],
              ),
            ];
          }),
          contentRepositoryProvider.overrideWithValue(_PatchDetailRepository()),
          patchNotesRegionProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Full patch note body loaded from the focused route.'),
      findsOneWidget,
    );
  });
}
