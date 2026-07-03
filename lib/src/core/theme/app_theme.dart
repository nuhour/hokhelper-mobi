import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const bg = Color(0xFF070A12);
  static const panel = Color(0xFF101624);
  static const panelAlt = Color(0xFF151D2E);
  static const gold = Color(0xFFF5D06F);
  static const cyan = Color(0xFF45D5FF);
  static const text = Color(0xFFF4F7FB);
  static const muted = Color(0xFF94A3B8);
  static const error = Color(0xFFFF6B6B);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(bodyColor: text, displayColor: text);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: cyan,
        surface: panel,
        error: error,
      ),
      textTheme: textTheme.copyWith(
        bodySmall: textTheme.bodySmall?.copyWith(color: muted),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: text),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: text),
        displaySmall: textTheme.displaySmall?.copyWith(color: text),
        displayMedium: textTheme.displayMedium?.copyWith(color: text),
        displayLarge: textTheme.displayLarge?.copyWith(color: text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: gold.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? gold : muted;
          return TextStyle(color: color, fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? gold : muted;
          return IconThemeData(color: color);
        }),
      ),
    );
  }
}
