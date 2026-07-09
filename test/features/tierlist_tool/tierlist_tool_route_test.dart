import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/data/tierlist_tool_repository.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/domain/tierlist_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_scheme_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_tool_screen.dart';

class _FakeTierListToolRepository extends TierListToolRepository {
  _FakeTierListToolRepository() : super(apiClient: _NoopApiClient());

  TierListSchemeSummary? savedScheme;

  @override
  Future<TierListSchemeSummary> updateScheme(
    TierListSchemeSummary scheme,
  ) async {
    savedScheme = scheme;
    return scheme;
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

Future<void> _saveChanges(WidgetTester tester) async {
  final saveButton = tester.widget<FloatingActionButton>(
    find.byKey(
      const ValueKey('tier-list-save-changes-floating'),
      skipOffstage: false,
    ),
  );
  saveButton.onPressed!();
  await tester.pumpAndSettle();
}

Future<void> _scrollToEditorControl(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tier list card opens its mobile scheme detail', (tester) async {
    final router = createAppRouter();
    router.go('/tools/tier-list');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolSchemesProvider.overrideWith((ref) async {
            return const [
              TierListSchemeSummary(
                id: '42',
                name: 'KIC Knockout Meta',
                createdAt: '2026-07-02T08:00:00Z',
                updatedAt: '2026-07-04T12:00:00Z',
                rows: [
                  TierListSchemeRowSummary(
                    id: 'r1',
                    label: 'T0',
                    color: 'bg-red-600',
                    heroCount: 3,
                  ),
                ],
              ),
            ];
          }),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'KIC Knockout Meta Detail',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('KIC Knockout Meta'));
    await tester.pumpAndSettle();

    expect(find.text('Tier List Detail'), findsOneWidget);
    expect(find.text('KIC Knockout Meta Detail'), findsOneWidget);
  });

  testWidgets('tier list deep link opens a mobile scheme detail', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/tier-list/42');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'KIC Knockout Meta',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                ),
                TierListSchemeRowSummary(
                  id: 'r2',
                  label: 'T1',
                  color: 'bg-orange-500',
                  heroCount: 1,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tier List Detail'), findsOneWidget);
    expect(find.text('KIC Knockout Meta'), findsOneWidget);
    expect(find.text('4 heroes'), findsOneWidget);
    expect(find.text('Updated 2026-07-04'), findsOneWidget);
    expect(find.text('T0'), findsOneWidget);
    expect(find.text('3 heroes'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('1 hero'), findsOneWidget);
  });

  testWidgets('legacy tier list id query opens mobile scheme detail', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/tier-list?id=42&mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Legacy Shared Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/tools/tier-list/42');
    expect(uri.queryParameters['mode'], 'edit');
    expect(find.text('Tier List Detail'), findsOneWidget);
    expect(find.text('Legacy Shared Tier List'), findsOneWidget);
  });

  testWidgets(
    'tier list edit links open row editing controls and save changes',
    (tester) async {
      final repository = _FakeTierListToolRepository();
      final router = createAppRouter();
      router.go('/tools/tier-list?id=42&mode=edit');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tierListToolRepositoryProvider.overrideWithValue(repository),
            tierListSchemeDetailProvider('42').overrideWith((ref) async {
              return const TierListSchemeSummary(
                id: '42',
                name: 'Editable Tier List',
                createdAt: '2026-07-02T08:00:00Z',
                updatedAt: '2026-07-04T12:00:00Z',
                rows: [
                  TierListSchemeRowSummary(
                    id: 'r1',
                    label: 'T0',
                    color: 'bg-red-600',
                    heroCount: 3,
                    heroIds: [111, 222, 333],
                  ),
                  TierListSchemeRowSummary(
                    id: 'r2',
                    label: 'T1',
                    color: 'bg-orange-500',
                    heroCount: 1,
                    heroIds: [444],
                  ),
                ],
              );
            }),
          ],
          child: HokHelperApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tier-editor-toolbar')), findsOneWidget);
      await _scrollToEditorControl(
        tester,
        find.byKey(const ValueKey('tier-row-label-r1')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('tier-row-label-r1')),
        'S+',
      );
      await _saveChanges(tester);

      expect(repository.savedScheme, isNotNull);
      expect(repository.savedScheme!.rows.first.label, 'S+');
      expect(repository.savedScheme!.rows.first.heroIds, [111, 222, 333]);
      expect(find.text('Tier list saved'), findsOneWidget);
    },
  );

  testWidgets('tier list edit mode renames schemes before saving', (
    tester,
  ) async {
    final repository = _FakeTierListToolRepository();
    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolRepositoryProvider.overrideWithValue(repository),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Editable Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                  heroIds: [111, 222, 333],
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final nameFieldFinder = find.byKey(const ValueKey('tier-list-name-field'));
    await _scrollToEditorControl(tester, nameFieldFinder);
    await tester.enterText(nameFieldFinder, 'Mobile Finals Meta');
    await _saveChanges(tester);

    expect(repository.savedScheme, isNotNull);
    expect(repository.savedScheme!.name, 'Mobile Finals Meta');
    expect(repository.savedScheme!.rows.single.heroIds, [111, 222, 333]);
    expect(find.text('Tier list saved'), findsOneWidget);
  });

  testWidgets('tier list edit mode changes row colors and order', (
    tester,
  ) async {
    final repository = _FakeTierListToolRepository();
    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolRepositoryProvider.overrideWithValue(repository),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Editable Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                  heroIds: [111, 222, 333],
                ),
                TierListSchemeRowSummary(
                  id: 'r2',
                  label: 'T1',
                  color: 'bg-orange-500',
                  heroCount: 1,
                  heroIds: [444],
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final colorFinder = find.byKey(
      const ValueKey('tier-row-color-r1-bg-blue-500'),
    );
    await _scrollToEditorControl(tester, colorFinder);
    await tester.tap(colorFinder);
    await tester.pumpAndSettle();
    final moveDownButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('tier-row-move-down-r1'), skipOffstage: false),
    );
    moveDownButton.onPressed!();
    await tester.pumpAndSettle();
    await _saveChanges(tester);

    expect(repository.savedScheme, isNotNull);
    expect(repository.savedScheme!.rows.map((row) => row.id), ['r2', 'r1']);
    expect(repository.savedScheme!.rows.last.color, 'bg-blue-500');
    expect(repository.savedScheme!.rows.last.heroIds, [111, 222, 333]);
    expect(find.text('Tier list saved'), findsOneWidget);
  });

  testWidgets('tier list edit mode removes heroes from rows', (tester) async {
    final repository = _FakeTierListToolRepository();
    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolRepositoryProvider.overrideWithValue(repository),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Editable Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                  heroIds: [111, 222, 333],
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final heroChipFinder = find.byKey(
      const ValueKey('tier-row-remove-hero-r1-111'),
      skipOffstage: false,
    );
    await _scrollToEditorControl(tester, heroChipFinder);
    expect(find.text('Hero #111'), findsOneWidget);
    final heroChip = tester.widget<InputChip>(heroChipFinder);
    heroChip.onPressed!();
    await tester.pumpAndSettle();
    await _saveChanges(tester);

    expect(repository.savedScheme, isNotNull);
    expect(repository.savedScheme!.rows.single.heroIds, [222, 333]);
    expect(repository.savedScheme!.rows.single.heroCount, 2);
    expect(find.text('Tier list saved'), findsOneWidget);
  });

  testWidgets('tier list edit mode adds heroes to rows by id', (tester) async {
    final repository = _FakeTierListToolRepository();
    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolRepositoryProvider.overrideWithValue(repository),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Editable Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 1,
                  heroIds: [111],
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final addHeroFieldFinder = find.byKey(
      const ValueKey('tier-row-add-hero-r1'),
    );
    await _scrollToEditorControl(tester, addHeroFieldFinder);
    await tester.enterText(addHeroFieldFinder, '999');
    final addHeroButton = tester.widget<IconButton>(
      find.byKey(
        const ValueKey('tier-row-add-hero-button-r1'),
        skipOffstage: false,
      ),
    );
    addHeroButton.onPressed!();
    await tester.pumpAndSettle();
    await _saveChanges(tester);

    expect(repository.savedScheme, isNotNull);
    expect(repository.savedScheme!.rows.single.heroIds, [111, 999]);
    expect(repository.savedScheme!.rows.single.heroCount, 2);
    expect(find.text('Hero #999'), findsOneWidget);
  });

  testWidgets('tier list edit mode renders hokx style board and hero pool', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '999',
                heroId: '999',
                name: 'Dolia',
                avatar: 'https://example.test/dolia.png',
                title: 'Support',
              ),
            ];
          }),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Editable Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 1,
                  heroIds: [111],
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tier-editor-toolbar')), findsOneWidget);
    expect(find.byKey(const ValueKey('tier-editor-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('tier-row-drop-r1')), findsOneWidget);
    expect(find.text('Hero Pool'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hero-pool-draggable-999')),
      findsOneWidget,
    );
  });

  testWidgets('tier list edit mode drags heroes from pool into rows', (
    tester,
  ) async {
    final repository = _FakeTierListToolRepository();
    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolRepositoryProvider.overrideWithValue(repository),
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '999',
                heroId: '999',
                name: 'Dolia',
                avatar: 'https://example.test/dolia.png',
                title: 'Support',
              ),
            ];
          }),
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'Editable Tier List',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 1,
                  heroIds: [111],
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('hero-pool-draggable-999')),
      tester.getCenter(find.byKey(const ValueKey('tier-row-drop-r1'))) -
          tester.getCenter(
            find.byKey(const ValueKey('hero-pool-draggable-999')),
          ),
    );
    await tester.pumpAndSettle();
    await _saveChanges(tester);

    expect(repository.savedScheme, isNotNull);
    expect(repository.savedScheme!.rows.single.heroIds, [111, 999]);
    expect(repository.savedScheme!.rows.single.heroCount, 2);
  });

  testWidgets('copies tier list detail share links', (tester) async {
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCall = call;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final router = createAppRouter();
    router.go('/tools/tier-list/42');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListSchemeDetailProvider('42').overrideWith((ref) async {
            return const TierListSchemeSummary(
              id: '42',
              name: 'KIC Knockout Meta',
              createdAt: '2026-07-02T08:00:00Z',
              updatedAt: '2026-07-04T12:00:00Z',
              rows: [
                TierListSchemeRowSummary(
                  id: 'r1',
                  label: 'T0',
                  color: 'bg-red-600',
                  heroCount: 3,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(clipboardCall, isNotNull);
    expect(clipboardCall!.arguments, {'text': '/tools/tier-list/42'});
    expect(find.text('Tier list link copied'), findsOneWidget);
  });
}
