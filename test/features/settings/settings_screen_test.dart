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
