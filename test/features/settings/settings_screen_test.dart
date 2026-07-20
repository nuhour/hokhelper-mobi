import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/constants/regions.dart';
import 'package:hok_helper_mobile/src/core/i18n/app_localizations.dart';
import 'package:hok_helper_mobile/src/core/storage/preferences_store.dart';
import 'package:hok_helper_mobile/src/core/theme/app_theme.dart';
import 'package:hok_helper_mobile/src/features/settings/presentation/settings_controller.dart';
import 'package:hok_helper_mobile/src/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings screen persists language-derived region and theme', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.selectedLanguageCodeKey: 'en',
    });

    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedSettingsHost()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Region'), findsNothing);
    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();
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
      AppThemeMode.classic.storageValue,
    );
  });

  testWidgets('settings screen exposes common app actions', (tester) async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.selectedLanguageCodeKey: 'en',
    });

    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedSettingsHost()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clear Cache'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-profile-tile')), findsOneWidget);
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
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
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
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
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

  testWidgets('settings screen action panels follow hokx classic palette', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.selectedLanguageCodeKey: 'en',
      PreferencesStore.selectedThemeKey: AppThemeMode.classic.storageValue,
    });

    await tester.pumpWidget(
      ProviderScope(child: _LocalizedSettingsHost(theme: AppTheme.light())),
    );
    await tester.pumpAndSettle();

    final materialFinder = find.ancestor(
      of: find.byKey(const ValueKey('settings-clear-cache-tile')),
      matching: find.byType(Material),
    );
    final panel = tester.widget<Material>(materialFinder.first);

    expect(panel.color, AppTheme.lightPanel);
  });
}

class _LocalizedSettingsHost extends StatelessWidget {
  const _LocalizedSettingsHost({this.theme});

  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );
  }
}
