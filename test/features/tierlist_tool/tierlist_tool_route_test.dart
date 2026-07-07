import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
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

      expect(find.text('Editor mode'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('tier-row-label-r1')),
        'S+',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

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

    await tester.enterText(
      find.byKey(const ValueKey('tier-list-name-field')),
      'Mobile Finals Meta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

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

    await tester.tap(
      find.byKey(const ValueKey('tier-row-color-r1-bg-blue-500')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tier-row-move-down-r1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Save changes'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(repository.savedScheme, isNotNull);
    expect(repository.savedScheme!.rows.map((row) => row.id), ['r2', 'r1']);
    expect(repository.savedScheme!.rows.last.color, 'bg-blue-500');
    expect(repository.savedScheme!.rows.last.heroIds, [111, 222, 333]);
    expect(find.text('Tier list saved'), findsOneWidget);
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
