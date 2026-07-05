import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/domain/tierlist_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_scheme_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_tool_screen.dart';

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
}
