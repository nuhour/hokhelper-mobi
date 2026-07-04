import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/rank_fortune/data/rank_fortune_repository.dart';
import 'package:hok_helper_mobile/src/features/rank_fortune/domain/rank_fortune.dart';
import 'package:hok_helper_mobile/src/features/rank_fortune/presentation/rank_fortune_screen.dart';

class _FakeRepository extends RankFortuneRepository {
  _FakeRepository()
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  @override
  Future<RankFortuneDraw> drawToday() async {
    return const RankFortuneDraw(
      record: RankFortuneRecord(
        id: 8,
        date: '2026-07-05',
        typeId: 'legendary',
        score: 99,
      ),
      alreadyDrawn: false,
      canDraw: false,
      catalog: [RankFortuneCatalogEntry(typeId: 'legendary', score: 99)],
    );
  }
}

void main() {
  testWidgets('renders today fortune and history summary', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankFortuneHistoryProvider.overrideWith((ref) async {
            return const RankFortuneHistory(
              rows: [
                RankFortuneRecord(
                  id: 3,
                  date: '2026-07-04',
                  typeId: 'great',
                  score: 92,
                ),
              ],
              today: RankFortuneRecord(
                id: 3,
                date: '2026-07-04',
                typeId: 'great',
                score: 92,
              ),
              canDraw: false,
              days: 30,
              catalog: [RankFortuneCatalogEntry(typeId: 'great', score: 92)],
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: RankFortuneScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rank Fortune'), findsOneWidget);
    expect(
      find.text("Draw your fortune for today's ranked matches."),
      findsOneWidget,
    );
    expect(find.text('Great Luck'), findsWidgets);
    expect(find.text('Fortune Value'), findsOneWidget);
    expect(find.text('92'), findsWidgets);
    expect(find.text('30-day History'), findsOneWidget);
  });

  testWidgets('draw button updates today fortune', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankFortuneRepositoryProvider.overrideWithValue(_FakeRepository()),
          rankFortuneHistoryProvider.overrideWith((ref) async {
            return const RankFortuneHistory(
              rows: [],
              today: null,
              canDraw: true,
              days: 30,
              catalog: [],
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: RankFortuneScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fortune Jar'), findsOneWidget);
    await tester.tap(find.text("Draw Today's Fortune"));
    await tester.pumpAndSettle();

    expect(find.text('Legendary Luck'), findsWidgets);
    expect(find.text('99'), findsWidgets);
    expect(find.text('Already drawn today'), findsOneWidget);
  });
}
