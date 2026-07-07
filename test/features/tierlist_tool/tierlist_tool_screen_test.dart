import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/data/tierlist_tool_repository.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/domain/tierlist_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_tool_screen.dart';

class _FakeTierListToolRepository extends TierListToolRepository {
  _FakeTierListToolRepository() : super(apiClient: _NoopApiClient());

  String? createdName;

  @override
  Future<TierListSchemeSummary> createScheme({required String name}) async {
    createdName = name;
    return TierListSchemeSummary(
      id: '77',
      name: name,
      createdAt: '2026-07-07T10:00:00Z',
      updatedAt: '2026-07-07T10:00:00Z',
      rows: const [
        TierListSchemeRowSummary(
          id: 't0',
          label: 'T0',
          color: 'bg-red-600',
          heroCount: 0,
        ),
        TierListSchemeRowSummary(
          id: 't1',
          label: 'T1',
          color: 'bg-orange-500',
          heroCount: 0,
        ),
      ],
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
  testWidgets('renders tier list scheme cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolSchemesProvider.overrideWith((ref) async {
            return const [
              TierListSchemeSummary(
                id: '9',
                name: 'Solo Queue Meta',
                createdAt: '2026-07-01T08:00:00Z',
                updatedAt: '2026-07-03T12:00:00Z',
                rows: [
                  TierListSchemeRowSummary(
                    id: 'r1',
                    label: 'T0',
                    color: 'bg-red-600',
                    heroCount: 2,
                  ),
                  TierListSchemeRowSummary(
                    id: 'r2',
                    label: 'T1',
                    color: 'bg-orange-500',
                    heroCount: 1,
                  ),
                ],
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: TierListToolScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tier List Tool'), findsOneWidget);
    expect(find.text('Solo Queue Meta'), findsOneWidget);
    expect(find.text('3 heroes'), findsOneWidget);
    expect(find.text('Updated 2026-07-03'), findsOneWidget);
    expect(find.text('T0 · 2'), findsOneWidget);
    expect(find.text('T1 · 1'), findsOneWidget);
  });

  testWidgets('creates tier list schemes from the mobile tool screen', (
    tester,
  ) async {
    final repository = _FakeTierListToolRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tierListToolRepositoryProvider.overrideWithValue(repository),
          tierListToolSchemesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: TierListToolScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Tier List'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tier list name'),
      'Mobile Tier List',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(repository.createdName, 'Mobile Tier List');
    expect(find.text('Mobile Tier List'), findsOneWidget);
    expect(find.text('0 heroes'), findsOneWidget);
    expect(find.text('Tier list created'), findsOneWidget);
  });
}
