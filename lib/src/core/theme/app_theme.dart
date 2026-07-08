import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const bg = Color(0xFF020617);
  static const panel = Color(0xFF0F172A);
  static const panelAlt = Color(0xFF1E293B);
  static const gold = Color(0xFF2563EB);
  static const cyan = Color(0xFF60A5FA);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const error = Color(0xFFDC2626);
  static const outline = Color(0xFF1E293B);
  static const lightBg = Color(0xFFF8FAFC);
  static const lightPanel = Colors.white;
  static const lightPanelAlt = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
  static const lightOutline = Color(0xFFCBD5E1);

  static ThemeData dark({Color primary = gold, Color secondary = cyan}) {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(bodyColor: text, displayColor: text);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      dividerColor: outline,
      cardColor: panel,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: panel,
        surfaceContainerLowest: bg,
        surfaceContainerLow: panel,
        surfaceContainer: panel,
        surfaceContainerHigh: panelAlt,
        outline: outline,
        outlineVariant: outline,
        error: error,
        onPrimary: text,
        onSecondary: bg,
        onSurface: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: panel,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary),
        ),
        hintStyle: const TextStyle(color: muted),
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
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? primary : muted;
          return TextStyle(color: color, fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? primary : muted;
          return IconThemeData(color: color);
        }),
      ),
    );
  }

  static ThemeData light({Color primary = gold, Color secondary = cyan}) {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: lightText,
      displayColor: lightText,
    );

    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      dividerColor: lightOutline,
      cardColor: lightPanel,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightPanel,
        surfaceContainerLowest: lightBg,
        surfaceContainerLow: lightPanel,
        surfaceContainer: lightPanel,
        surfaceContainerHigh: lightPanelAlt,
        outline: lightOutline,
        outlineVariant: lightOutline,
        error: error,
        onPrimary: text,
        onSecondary: lightText,
        onSurface: lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPanel,
        foregroundColor: lightText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary),
        ),
        hintStyle: const TextStyle(color: lightMuted),
      ),
      textTheme: textTheme.copyWith(
        bodySmall: textTheme.bodySmall?.copyWith(color: lightMuted),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: lightText),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: lightText),
        displaySmall: textTheme.displaySmall?.copyWith(color: lightText),
        displayMedium: textTheme.displayMedium?.copyWith(color: lightText),
        displayLarge: textTheme.displayLarge?.copyWith(color: lightText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightPanel,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? primary
              : lightMuted;
          return TextStyle(color: color, fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? primary
              : lightMuted;
          return IconThemeData(color: color);
        }),
      ),
    );
  }
}
