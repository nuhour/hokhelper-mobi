import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/theme/app_theme.dart';

double _relativeLuminance(Color color) {
  double channel(double value) {
    final normalized = value / 255;
    return normalized <= 0.03928
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  return channel(color.r * 255) * 0.2126 +
      channel(color.g * 255) * 0.7152 +
      channel(color.b * 255) * 0.0722;
}

double _contrastRatio(Color first, Color second) {
  final a = _relativeLuminance(first);
  final b = _relativeLuminance(second);
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('dark theme uses the hokx portal dark palette', () {
    final theme = AppTheme.dark();
    final tokens = theme.extension<HokThemeColors>();

    expect(AppTheme.bg, const Color(0xFF030817));
    expect(AppTheme.panel, const Color(0xFF0F172A));
    expect(AppTheme.panelAlt, const Color(0xFF1B2940));
    expect(AppTheme.gold, const Color(0xFF2563EB));
    expect(AppTheme.text, const Color(0xFFF4F7FB));
    expect(AppTheme.muted, const Color(0xFFA5B4C7));
    expect(AppTheme.error, const Color(0xFFC83E4D));
    expect(theme.scaffoldBackgroundColor, AppTheme.bg);
    expect(theme.colorScheme.primary, const Color(0xFF6B9BFF));
    expect(theme.navigationBarTheme.backgroundColor, AppTheme.panel);
    expect(tokens?.backgroundDeep, AppTheme.bg);
    expect(tokens?.surfaceSlate, AppTheme.panel);
    expect(tokens?.surfaceRaised, AppTheme.panelAlt);
    expect(tokens?.onSurfaceMuted, AppTheme.muted);
    expect(
      theme.filledButtonTheme.style?.shape?.resolve({}),
      isA<OutlinedBorder>(),
    );
    expect(theme.cardTheme.color, AppTheme.panel);
  });

  test('light theme uses the hokx portal light palette', () {
    final theme = AppTheme.light();
    final tokens = theme.extension<HokThemeColors>();

    expect(AppTheme.lightBg, const Color(0xFFF3F6FB));
    expect(AppTheme.lightPanel, Colors.white);
    expect(AppTheme.lightPanelAlt, const Color(0xFFE9EFF7));
    expect(AppTheme.lightText, const Color(0xFF172033));
    expect(AppTheme.lightMuted, const Color(0xFF586A82));
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

  test('theme text and semantic colors keep accessible contrast', () {
    final dark = AppTheme.dark().colorScheme;
    final light = AppTheme.light().colorScheme;

    expect(_contrastRatio(AppTheme.text, AppTheme.bg), greaterThan(7));
    expect(_contrastRatio(AppTheme.muted, AppTheme.bg), greaterThan(4.5));
    expect(
      _contrastRatio(AppTheme.lightText, AppTheme.lightBg),
      greaterThan(7),
    );
    expect(
      _contrastRatio(AppTheme.lightMuted, AppTheme.lightPanel),
      greaterThan(4.5),
    );
    expect(_contrastRatio(dark.primary, dark.onPrimary), greaterThan(4.5));
    expect(_contrastRatio(light.primary, light.onPrimary), greaterThan(4.5));
  });

  test('light and dark themes provide harmonized component surfaces', () {
    final dark = AppTheme.dark();
    final light = AppTheme.light();

    expect(dark.dialogTheme.surfaceTintColor, Colors.transparent);
    expect(light.dialogTheme.surfaceTintColor, Colors.transparent);
    expect(
      dark.inputDecorationTheme.fillColor,
      AppTheme.darkTokens.surfaceMuted,
    );
    expect(
      light.inputDecorationTheme.fillColor,
      AppTheme.lightTokens.surfaceMuted,
    );
    expect(light.chipTheme.selectedColor, const Color(0xFFDCE8FF));
    expect(dark.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(light.snackBarTheme.behavior, SnackBarBehavior.floating);
  });
}
