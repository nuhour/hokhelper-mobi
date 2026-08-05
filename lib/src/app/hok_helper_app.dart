import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_controller.dart';
import 'global_edge_back_gesture.dart';
import 'router.dart';
import 'startup_splash.dart';

class HokHelperApp extends ConsumerWidget {
  HokHelperApp({super.key, GoRouter? router})
    : _router = router ?? createAppRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 在 MaterialApp 和启动动画完成前就启动首页聚合接口，尽量让首屏直接命中
    // Riverpod 缓存，避免用户看到首页骨架。StartupSplash 仍负责等待并兜底超时。
    unawaited(
      ref
          .read(homeStatsProvider.future)
          .then<void>((_) {})
          .catchError((Object _) {}),
    );
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull;
    final themeMode = settings?.theme == AppThemeMode.classic
        ? ThemeMode.light
        : ThemeMode.dark;

    return StartupSplash(
      child: MaterialApp.router(
        title: 'HOK Helper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: settings == null ? null : Locale(settings.languageCode),
        routerConfig: _router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final textScale = MediaQuery.textScalerOf(
            context,
          ).scale(1).clamp(0.9, 1.0).toDouble();
          return GlobalEdgeBackGesture(
            router: _router,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
