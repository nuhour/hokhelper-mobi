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
  await tester.tap(find.byKey(const ValueKey('tier-list-save-changes-top')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tier list edit mode asks portrait users to rotate landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    expect(
      find.byKey(const ValueKey('tier-editor-landscape-prompt')),
      findsOneWidget,
    );
    expect(find.text('Rotate to landscape'), findsOneWidget);
    expect(find.byKey(const ValueKey('tier-editor-toolbar')), findsNothing);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tier-editor-landscape-prompt')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('tier-editor-toolbar')), findsOneWidget);
  });

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
    expect(
      find.byKey(const ValueKey('tier-editor-fullscreen')),
      findsOneWidget,
    );
    expect(find.text('Legacy Shared Tier List'), findsOneWidget);
  });

  testWidgets('tier list edit mode is a fullscreen compact landscape editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    expect(
      find.byKey(const ValueKey('tier-editor-fullscreen')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('standalone-back-button')), findsNothing);
    expect(find.text('Tier List Detail'), findsNothing);
    expect(find.byKey(const ValueKey('tier-list-name-field')), findsNothing);
    expect(
      find.byKey(const ValueKey('tier-row-color-r1-bg-blue-500')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tier-row-color-strip-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tier-row-color-strip-r2')),
      findsOneWidget,
    );
  });

  testWidgets('tier list edit mode filters hero pool by lane icons only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = createAppRouter();
    router.go('/tools/tier-list/42?mode=edit');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '301',
                heroId: '301',
                name: 'Jungle Hero',
                avatar: 'https://example.test/jungle.png',
                title: 'Jungle',
                position: 3,
              ),
              HeroSummary(
                id: '401',
                heroId: '401',
                name: 'Support Hero',
                avatar: 'https://example.test/support.png',
                title: 'Support',
                position: 4,
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
                  heroCount: 0,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-pool-search')), findsNothing);
    expect(find.byKey(const ValueKey('lane-filter-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('lane-filter-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('lane-filter-4')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hero-pool-draggable-301')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-pool-draggable-401')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('lane-filter-4')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-pool-draggable-301')), findsNothing);
    expect(
      find.byKey(const ValueKey('hero-pool-draggable-401')),
      findsOneWidget,
    );
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
