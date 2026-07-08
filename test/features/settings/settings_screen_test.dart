import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/constants/regions.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/core/storage/preferences_store.dart';
import 'package:hok_helper_mobile/src/features/settings/presentation/settings_controller.dart';
import 'package:hok_helper_mobile/src/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings screen persists region language and theme choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedSettingsHost()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.text('China'));
    await tester.tap(find.text('中文'));
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt(PreferencesStore.selectedRegionIdKey),
      HokRegion.cn.id,
    );
    expect(
      preferences.getString(PreferencesStore.selectedLanguageCodeKey),
      'zh',
    );
    expect(
      preferences.getString(PreferencesStore.selectedThemeKey),
      AppThemeMode.versus.storageValue,
    );
  });

  testWidgets('settings screen exposes common app actions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedSettingsHost()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clear Cache'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settings-clear-cache-tile')));
    await tester.pump();
    expect(find.text('Cache cleared'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(SettingsScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-check-updates-tile')),
      500,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-check-updates-tile')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check for Updates'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, 'Check for Updates').hitTestable(),
    );
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('You are using the latest version'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(SettingsScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-about-tile')),
      500,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-about-tile')),
    );
    await tester.pumpAndSettle();
    expect(find.text('About'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('settings-about-tile')));
    await tester.pumpAndSettle();
    expect(find.text('HOK Helper Mobile'), findsOneWidget);
  });
}

class _LocalizedSettingsHost extends StatelessWidget {
  const _LocalizedSettingsHost();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(),
    );
  }
}
