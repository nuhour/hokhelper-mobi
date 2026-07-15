import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

@immutable
class HokThemeColors extends ThemeExtension<HokThemeColors> {
  const HokThemeColors({
    required this.backgroundDeep,
    required this.surfaceSlate,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.onSurfaceStrong,
    required this.onSurfaceMuted,
    required this.outlineSoft,
    required this.accentRed,
    required this.success,
  });

  final Color backgroundDeep;
  final Color surfaceSlate;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color onSurfaceStrong;
  final Color onSurfaceMuted;
  final Color outlineSoft;
  final Color accentRed;
  final Color success;

  @override
  HokThemeColors copyWith({
    Color? backgroundDeep,
    Color? surfaceSlate,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? onSurfaceStrong,
    Color? onSurfaceMuted,
    Color? outlineSoft,
    Color? accentRed,
    Color? success,
  }) {
    return HokThemeColors(
      backgroundDeep: backgroundDeep ?? this.backgroundDeep,
      surfaceSlate: surfaceSlate ?? this.surfaceSlate,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      onSurfaceStrong: onSurfaceStrong ?? this.onSurfaceStrong,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      outlineSoft: outlineSoft ?? this.outlineSoft,
      accentRed: accentRed ?? this.accentRed,
      success: success ?? this.success,
    );
  }

  @override
  HokThemeColors lerp(ThemeExtension<HokThemeColors>? other, double t) {
    if (other is! HokThemeColors) {
      return this;
    }
    return HokThemeColors(
      backgroundDeep: Color.lerp(backgroundDeep, other.backgroundDeep, t)!,
      surfaceSlate: Color.lerp(surfaceSlate, other.surfaceSlate, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      onSurfaceStrong: Color.lerp(onSurfaceStrong, other.onSurfaceStrong, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      outlineSoft: Color.lerp(outlineSoft, other.outlineSoft, t)!,
      accentRed: Color.lerp(accentRed, other.accentRed, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

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
  static const success = Color(0xFF22C55E);
  static const outline = Color(0xFF1E293B);
  static const lightBg = Color(0xFFF6F8FC);
  static const lightPanel = Colors.white;
  static const lightPanelAlt = Color(0xFFEAF0F8);
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF5F6F86);
  static const lightOutline = Color(0xFFD7E0EC);

  static const _darkTokens = HokThemeColors(
    backgroundDeep: bg,
    surfaceSlate: panel,
    surfaceRaised: panelAlt,
    surfaceMuted: Color(0xFF111C2D),
    onSurfaceStrong: text,
    onSurfaceMuted: muted,
    outlineSoft: outline,
    accentRed: error,
    success: success,
  );

  static const _lightTokens = HokThemeColors(
    backgroundDeep: lightBg,
    surfaceSlate: lightPanel,
    surfaceRaised: lightPanelAlt,
    surfaceMuted: Color(0xFFF1F5FB),
    onSurfaceStrong: lightText,
    onSurfaceMuted: lightMuted,
    outlineSoft: lightOutline,
    accentRed: error,
    success: Color(0xFF168A45),
  );

  static ThemeData dark({Color primary = gold, Color secondary = cyan}) {
    final base = FlexThemeData.dark(
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: success,
        surface: panel,
        surfaceContainerLowest: bg,
        surfaceContainerLow: panel,
        surfaceContainer: panel,
        surfaceContainerHigh: panelAlt,
        surfaceContainerHighest: const Color(0xFF253445),
        outline: outline,
        outlineVariant: outline,
        error: error,
        onPrimary: text,
        onSecondary: bg,
        onTertiary: bg,
        onSurface: text,
      ),
      subThemesData: _subThemesData,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
    final textTheme = base.textTheme.apply(bodyColor: text, displayColor: text);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      dividerColor: outline,
      cardColor: panel,
      extensions: const [_darkTokens],
      cardTheme: _cardTheme(panel, outline),
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
      filledButtonTheme: _filledButtonTheme(primary, text),
      outlinedButtonTheme: _outlinedButtonTheme(primary, outline),
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
    final base = FlexThemeData.light(
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: const Color(0xFF168A45),
        surface: lightPanel,
        surfaceContainerLowest: lightBg,
        surfaceContainerLow: lightPanel,
        surfaceContainer: lightPanel,
        surfaceContainerHigh: lightPanelAlt,
        surfaceContainerHighest: const Color(0xFFDDE7F3),
        outline: lightOutline,
        outlineVariant: lightOutline,
        error: error,
        onPrimary: text,
        onSecondary: lightText,
        onTertiary: text,
        onSurface: lightText,
      ),
      subThemesData: _subThemesData,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
    final textTheme = base.textTheme.apply(
      bodyColor: lightText,
      displayColor: lightText,
    );

    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      dividerColor: lightOutline,
      cardColor: lightPanel,
      extensions: const [_lightTokens],
      cardTheme: _cardTheme(lightPanel, lightOutline),
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
      filledButtonTheme: _filledButtonTheme(primary, text),
      outlinedButtonTheme: _outlinedButtonTheme(primary, lightOutline),
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

  static const _subThemesData = FlexSubThemesData(
    defaultRadius: 10,
    adaptiveRemoveElevationTint: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    blendOnLevel: 8,
    blendOnColors: false,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    navigationBarMutedUnselectedIcon: true,
    navigationBarMutedUnselectedLabel: true,
  );

  static CardThemeData _cardTheme(Color color, Color borderColor) {
    return CardThemeData(
      color: color,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor.withValues(alpha: 0.72)),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(
    Color primary,
    Color foreground,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: foreground,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(
    Color primary,
    Color outlineColor,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(44, 44),
        side: BorderSide(color: outlineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
