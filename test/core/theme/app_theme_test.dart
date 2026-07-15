import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/theme/app_theme.dart';

void main() {
  test('dark theme uses the hokx portal dark palette', () {
    final theme = AppTheme.dark();
    final tokens = theme.extension<HokThemeColors>();

    expect(AppTheme.bg, const Color(0xFF020617));
    expect(AppTheme.panel, const Color(0xFF0F172A));
    expect(AppTheme.panelAlt, const Color(0xFF1E293B));
    expect(AppTheme.gold, const Color(0xFF2563EB));
    expect(AppTheme.text, const Color(0xFFF8FAFC));
    expect(AppTheme.muted, const Color(0xFF94A3B8));
    expect(AppTheme.error, const Color(0xFFDC2626));
    expect(theme.scaffoldBackgroundColor, AppTheme.bg);
    expect(theme.colorScheme.primary, AppTheme.gold);
    expect(theme.navigationBarTheme.backgroundColor, AppTheme.panel);
    expect(tokens?.backgroundDeep, AppTheme.bg);
    expect(tokens?.surfaceSlate, AppTheme.panel);
    expect(tokens?.surfaceRaised, AppTheme.panelAlt);
    expect(tokens?.onSurfaceMuted, AppTheme.muted);
    expect(theme.filledButtonTheme.style?.shape?.resolve({}), isA<OutlinedBorder>());
    expect(theme.cardTheme.color, AppTheme.panel);
  });

  test('light theme uses the hokx portal light palette', () {
    final theme = AppTheme.light();
    final tokens = theme.extension<HokThemeColors>();

    expect(AppTheme.lightBg, const Color(0xFFF6F8FC));
    expect(AppTheme.lightPanel, Colors.white);
    expect(AppTheme.lightPanelAlt, const Color(0xFFEAF0F8));
    expect(AppTheme.lightText, const Color(0xFF0F172A));
    expect(AppTheme.lightMuted, const Color(0xFF5F6F86));
    expect(theme.scaffoldBackgroundColor, AppTheme.lightBg);
    expect(theme.colorScheme.primary, AppTheme.gold);
    expect(theme.navigationBarTheme.backgroundColor, AppTheme.lightPanel);
    expect(tokens?.backgroundDeep, AppTheme.lightBg);
    expect(tokens?.surfaceSlate, AppTheme.lightPanel);
    expect(tokens?.surfaceRaised, AppTheme.lightPanelAlt);
    expect(tokens?.onSurfaceMuted, AppTheme.lightMuted);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.cardTheme.color, AppTheme.lightPanel);
  });
}
