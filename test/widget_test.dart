import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('shows app shell with tab destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith(
            (ref) async => const HomeStats(
              success: true,
              message: 'Ready',
              result: {'heroes': 128},
            ),
          ),
        ],
        child: HokHelperApp(router: createAppRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
