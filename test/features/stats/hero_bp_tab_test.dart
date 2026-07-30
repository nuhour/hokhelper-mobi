import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_trends.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';

import 'stats_trends_fixture.dart';

void main() {
  testWidgets('BP tab renders blue and red side cards from real payload', (
    tester,
  ) async {
    final detail = StatsTrendDetail.fromJson({
      'hero': const {'id': 2624, 'heroId': '2624', 'name': 'Haya'},
      'hero_bp_stats': const {
        'sample_size': 1200,
        'blue_pick_share': 56.08,
        'blue_win_rate': 52.4,
        'red_pick_share': 43.92,
        'red_win_rate': 47.6,
        'blue_slot1_share': 30.1,
        'blue_slot1_win_rate': 51.0,
        'blue_slot2_share': 20.2,
        'blue_slot2_win_rate': 52.0,
        'blue_slot3_share': 18.3,
        'blue_slot3_win_rate': 53.0,
        'blue_slot4_share': 16.4,
        'blue_slot4_win_rate': 54.0,
        'blue_slot5_share': 15.0,
        'blue_slot5_win_rate': 55.0,
        'red_slot1_share': 28.0,
        'red_slot1_win_rate': 47.0,
        'red_slot2_share': 22.0,
        'red_slot2_win_rate': 48.0,
        'red_slot3_share': 20.0,
        'red_slot3_win_rate': 46.0,
        'red_slot4_share': 17.0,
        'red_slot4_win_rate': 49.0,
        'red_slot5_share': 13.0,
        'red_slot5_win_rate': 45.0,
      },
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith((ref, request) async => detail),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-avatar-hero-199')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('hero-preparation-tabs')),
      const Offset(-500, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('hero-preparation-tabs')),
        matching: find.text('BP'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BP · Position'), findsOneWidget);
    expect(find.text('Blue side'), findsOneWidget);
    expect(find.text('56.08%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
