import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/storage/preferences_store.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows app shell destinations in English by default', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

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
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('shows app shell destinations in selected Chinese locale', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.selectedLanguageCodeKey: 'zh',
    });

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

    expect(find.text('首页'), findsAtLeastNWidgets(1));
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('社区'), findsOneWidget);
    expect(find.text('工具'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
