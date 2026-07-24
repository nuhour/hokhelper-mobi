import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
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

  int? loadedDays;

  @override
  Future<RankFortuneHistory> loadHistory({int days = 30}) async {
    loadedDays = days;
    return RankFortuneHistory(
      rows: [
        RankFortuneRecord(
          id: 3,
          date: '2026-07-04',
          typeId: 'great',
          score: 92,
        ),
      ],
      today: const RankFortuneRecord(
        id: 3,
        date: '2026-07-04',
        typeId: 'great',
        score: 92,
      ),
      canDraw: false,
      days: days,
      catalog: const [RankFortuneCatalogEntry(typeId: 'great', score: 92)],
    );
  }

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

class _PendingRepository extends RankFortuneRepository {
  _PendingRepository(this.completer)
    : super(
        apiClient: ApiClient(
          config: const AppConfig(
            apiBaseUrl: 'https://example.test',
            apiPrefix: '',
          ),
        ),
      );

  final Completer<RankFortuneDraw> completer;

  @override
  Future<RankFortuneDraw> drawToday() {
    return completer.future;
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
    expect(find.text('A daily ritual before your ranked queue'), findsNothing);
    expect(find.text('Great Fortune'), findsOneWidget);
    expect(
      find.text('Perfect day for ranked, win streak incoming!'),
      findsOneWidget,
    );
    expect(find.text('92'), findsOneWidget);
    expect(find.text('Fortune Value'), findsOneWidget);
    expect(find.text('Already drawn today'), findsNothing);
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

    expect(find.text('Try My Luck'), findsOneWidget);
    expect(find.textContaining('Shake'), findsNothing);
    expect(find.text('Tap'), findsNothing);
    await tester.tap(find.text('Try My Luck'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Legendary Luck'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Legendary Luck'), findsOneWidget);
    expect(find.text('99'), findsOneWidget);
  });

  testWidgets('shows fortune drawing feedback while draw is pending', (
    tester,
  ) async {
    final completer = Completer<RankFortuneDraw>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankFortuneRepositoryProvider.overrideWithValue(
            _PendingRepository(completer),
          ),
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

    await tester.tap(find.text('Try My Luck'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const RankFortuneDraw(
        record: RankFortuneRecord(
          id: 8,
          date: '2026-07-05',
          typeId: 'legendary',
          score: 99,
        ),
        alreadyDrawn: false,
        canDraw: false,
        catalog: [RankFortuneCatalogEntry(typeId: 'legendary', score: 99)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legendary Luck'), findsOneWidget);
  });

  testWidgets('copies today fortune share links', (tester) async {
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

    await tester.tap(find.byTooltip('Share Fortune'));
    await tester.pumpAndSettle();

    expect(clipboardCall, isNotNull);
    expect(clipboardCall!.arguments, {
      'text':
          "I just drew 【Great Fortune】 on HOK Helper today! Perfect day for ranked, win streak incoming! Who's ready to rank up with me? #HonorOfKings #HOKHelper\n/tools/rank-fortune",
    });
    expect(find.text('Fortune link copied'), findsOneWidget);
  });

  testWidgets('summarizes the latest thirty fortune history rows', (
    tester,
  ) async {
    final rows = List<RankFortuneRecord>.generate(31, (index) {
      final day = index + 1;
      return RankFortuneRecord(
        id: day,
        date: '2026-07-${day.toString().padLeft(2, '0')}',
        typeId: day == 31 ? 'legendary' : 'steady',
        score: day,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankFortuneHistoryProvider.overrideWith((ref) async {
            return RankFortuneHistory(
              rows: rows,
              today: rows.last,
              canDraw: false,
              days: 30,
              catalog: const [
                RankFortuneCatalogEntry(typeId: 'steady', score: 45),
                RankFortuneCatalogEntry(typeId: 'legendary', score: 99),
              ],
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: RankFortuneScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('30d Average'), findsNothing);
    expect(find.text('Best'), findsNothing);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('Lowest'), findsNothing);
    expect(find.text('Streak'), findsNothing);
  });

  testWidgets('loads hokx rank fortune history days from route query', (
    tester,
  ) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankFortuneRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RankFortuneScreen(initialDays: 7)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadedDays, 7);
  });

  testWidgets('web rank fortune alias preserves history days in app router', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final router = createAppRouter()..go('/rank-fortune?days=7');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankFortuneRepositoryProvider.overrideWithValue(repository),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/rank-fortune',
    );
    expect(repository.loadedDays, 7);
  });
}
