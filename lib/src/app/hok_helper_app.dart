import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/presentation/settings_controller.dart';
import 'router.dart';

class HokHelperApp extends ConsumerWidget {
  HokHelperApp({super.key, GoRouter? router})
    : _router = router ?? createAppRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull;
    final theme = settings?.theme == AppThemeMode.versus
        ? AppTheme.light()
        : AppTheme.dark();

    return MaterialApp.router(
      title: 'HOK Helper',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: settings == null ? null : Locale(settings.languageCode),
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
