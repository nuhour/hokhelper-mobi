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
    required this.accentBlue,
    required this.accentViolet,
    required this.accentRed,
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color backgroundDeep;
  final Color surfaceSlate;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color onSurfaceStrong;
  final Color onSurfaceMuted;
  final Color outlineSoft;
  final Color accentBlue;
  final Color accentViolet;
  final Color accentRed;
  final Color success;
  final Color warning;
  final Color info;

  @override
  HokThemeColors copyWith({
    Color? backgroundDeep,
    Color? surfaceSlate,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? onSurfaceStrong,
    Color? onSurfaceMuted,
    Color? outlineSoft,
    Color? accentBlue,
    Color? accentViolet,
    Color? accentRed,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return HokThemeColors(
      backgroundDeep: backgroundDeep ?? this.backgroundDeep,
      surfaceSlate: surfaceSlate ?? this.surfaceSlate,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      onSurfaceStrong: onSurfaceStrong ?? this.onSurfaceStrong,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      outlineSoft: outlineSoft ?? this.outlineSoft,
      accentBlue: accentBlue ?? this.accentBlue,
      accentViolet: accentViolet ?? this.accentViolet,
      accentRed: accentRed ?? this.accentRed,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
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
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      accentRed: Color.lerp(accentRed, other.accentRed, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension HokThemeBuildContext on BuildContext {
  HokThemeColors get hokTheme {
    return Theme.of(this).extension<HokThemeColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppTheme.darkTokens
            : AppTheme.lightTokens);
  }
}

class AppTheme {
  const AppTheme._();

  static const bg = Color(0xFF030817);
  static const panel = Color(0xFF0F172A);
  static const panelAlt = Color(0xFF1B2940);
  static const gold = Color(0xFF2563EB);
  static const cyan = Color(0xFF38BDF8);
  static const violet = Color(0xFF8B7CF6);
  static const text = Color(0xFFF4F7FB);
  static const muted = Color(0xFFA5B4C7);
  static const error = Color(0xFFC83E4D);
  static const success = Color(0xFF20A965);
  static const warning = Color(0xFFD98B24);
  static const outline = Color(0xFF293A54);
  static const lightBg = Color(0xFFF3F6FB);
  static const lightPanel = Colors.white;
  static const lightPanelAlt = Color(0xFFE9EFF7);
  static const lightText = Color(0xFF172033);
  static const lightMuted = Color(0xFF586A82);
  static const lightOutline = Color(0xFFCDD8E7);

  static const _darkTokens = HokThemeColors(
    backgroundDeep: bg,
    surfaceSlate: panel,
    surfaceRaised: panelAlt,
    surfaceMuted: Color(0xFF121E32),
    onSurfaceStrong: text,
    onSurfaceMuted: muted,
    outlineSoft: outline,
    accentBlue: Color(0xFF5B8FF9),
    accentViolet: Color(0xFFA89AF8),
    accentRed: Color(0xFFF06A78),
    success: success,
    warning: Color(0xFFF2B55E),
    info: Color(0xFF56C7F2),
  );

  static const _lightTokens = HokThemeColors(
    backgroundDeep: lightBg,
    surfaceSlate: lightPanel,
    surfaceRaised: lightPanelAlt,
    surfaceMuted: Color(0xFFF7F9FC),
    onSurfaceStrong: lightText,
    onSurfaceMuted: lightMuted,
    outlineSoft: lightOutline,
    accentBlue: gold,
    accentViolet: Color(0xFF715CC7),
    accentRed: error,
    success: Color(0xFF147A45),
    warning: Color(0xFFAD6500),
    info: Color(0xFF087CA7),
  );

  static const darkTokens = _darkTokens;
  static const lightTokens = _lightTokens;

  static ThemeData dark({Color primary = gold, Color secondary = cyan}) {
    const darkPrimary = Color(0xFF6B9BFF);
    final effectivePrimary = primary == gold ? darkPrimary : primary;
    final base = FlexThemeData.dark(
      colorScheme: ColorScheme.dark(
        primary: effectivePrimary,
        onPrimary: const Color(0xFF07142C),
        primaryContainer: const Color(0xFF17396F),
        onPrimaryContainer: const Color(0xFFDCE8FF),
        secondary: secondary,
        onSecondary: const Color(0xFF041B26),
        secondaryContainer: const Color(0xFF12384A),
        onSecondaryContainer: const Color(0xFFD7F3FF),
        tertiary: success,
        tertiaryContainer: const Color(0xFF123C2A),
        onTertiaryContainer: const Color(0xFFD5F7E5),
        surface: panel,
        surfaceContainerLowest: bg,
        surfaceContainerLow: panel,
        surfaceContainer: const Color(0xFF131D31),
        surfaceContainerHigh: panelAlt,
        surfaceContainerHighest: const Color(0xFF243651),
        outline: outline,
        outlineVariant: const Color(0xFF203049),
        error: const Color(0xFFF06A78),
        errorContainer: const Color(0xFF5B1F2A),
        onErrorContainer: const Color(0xFFFFD9DE),
        onTertiary: bg,
        onSurface: text,
        onSurfaceVariant: muted,
        inverseSurface: const Color(0xFFE8EEF7),
        onInverseSurface: const Color(0xFF182237),
        inversePrimary: gold,
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
      cardTheme: _cardTheme(
        panel,
        outline,
        shadowColor: Colors.black.withValues(alpha: 0.30),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkTokens.surfaceMuted,
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
          borderSide: BorderSide(color: effectivePrimary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF06A78)),
        ),
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
      ),
      filledButtonTheme: _filledButtonTheme(
        effectivePrimary,
        const Color(0xFF07142C),
      ),
      outlinedButtonTheme: _outlinedButtonTheme(effectivePrimary, outline),
      textButtonTheme: _textButtonTheme(effectivePrimary),
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: effectivePrimary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? effectivePrimary
              : muted;
          return TextStyle(color: color, fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? effectivePrimary
              : muted;
          return IconThemeData(color: color);
        }),
      ),
      chipTheme: _chipTheme(
        background: _darkTokens.surfaceMuted,
        selected: const Color(0xFF17396F),
        foreground: muted,
        selectedForeground: const Color(0xFFDCE8FF),
        outlineColor: outline,
      ),
      dialogTheme: _dialogTheme(panel, outline),
      bottomSheetTheme: _bottomSheetTheme(panel),
      snackBarTheme: _snackBarTheme(
        background: const Color(0xFFE8EEF7),
        foreground: const Color(0xFF182237),
      ),
      popupMenuTheme: _popupMenuTheme(panel, outline, text),
      tabBarTheme: _tabBarTheme(effectivePrimary, muted),
      switchTheme: _switchTheme(effectivePrimary, panelAlt),
      checkboxTheme: _checkboxTheme(effectivePrimary, outline),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: effectivePrimary,
        linearTrackColor: panelAlt,
        circularTrackColor: panelAlt,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: effectivePrimary,
        selectionColor: effectivePrimary.withValues(alpha: 0.28),
        selectionHandleColor: effectivePrimary,
      ),
    );
  }

  static ThemeData light({Color primary = gold, Color secondary = cyan}) {
    final base = FlexThemeData.light(
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFDCE8FF),
        onPrimaryContainer: const Color(0xFF12356B),
        secondary: const Color(0xFF715CC7),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE9E3FF),
        onSecondaryContainer: const Color(0xFF38266E),
        tertiary: const Color(0xFF147A45),
        tertiaryContainer: const Color(0xFFD7F5E5),
        onTertiaryContainer: const Color(0xFF0E4A2D),
        surface: lightPanel,
        surfaceContainerLowest: lightBg,
        surfaceContainerLow: lightPanel,
        surfaceContainer: const Color(0xFFF7F9FC),
        surfaceContainerHigh: lightPanelAlt,
        surfaceContainerHighest: const Color(0xFFDCE5F1),
        outline: lightOutline,
        outlineVariant: const Color(0xFFDCE4EF),
        error: error,
        errorContainer: const Color(0xFFFFDDE1),
        onErrorContainer: const Color(0xFF6D1723),
        onTertiary: text,
        onSurface: lightText,
        onSurfaceVariant: lightMuted,
        inverseSurface: const Color(0xFF202B40),
        onInverseSurface: const Color(0xFFF2F6FC),
        inversePrimary: const Color(0xFF91B6FF),
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
      cardTheme: _cardTheme(
        lightPanel,
        lightOutline,
        shadowColor: const Color(0x1A36557A),
        elevation: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightTokens.surfaceMuted,
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
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: lightMuted),
        labelStyle: const TextStyle(color: lightMuted),
      ),
      filledButtonTheme: _filledButtonTheme(primary, Colors.white),
      outlinedButtonTheme: _outlinedButtonTheme(primary, lightOutline),
      textButtonTheme: _textButtonTheme(primary),
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFFDCE8FF),
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
      chipTheme: _chipTheme(
        background: _lightTokens.surfaceMuted,
        selected: const Color(0xFFDCE8FF),
        foreground: lightMuted,
        selectedForeground: const Color(0xFF12356B),
        outlineColor: lightOutline,
      ),
      dialogTheme: _dialogTheme(lightPanel, lightOutline),
      bottomSheetTheme: _bottomSheetTheme(lightPanel),
      snackBarTheme: _snackBarTheme(
        background: const Color(0xFF202B40),
        foreground: const Color(0xFFF2F6FC),
      ),
      popupMenuTheme: _popupMenuTheme(lightPanel, lightOutline, lightText),
      tabBarTheme: _tabBarTheme(primary, lightMuted),
      switchTheme: _switchTheme(primary, const Color(0xFFC7D2E2)),
      checkboxTheme: _checkboxTheme(primary, lightOutline),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: lightPanelAlt,
        circularTrackColor: lightPanelAlt,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.18),
        selectionHandleColor: primary,
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

  static CardThemeData _cardTheme(
    Color color,
    Color borderColor, {
    Color? shadowColor,
    double elevation = 0,
  }) {
    return CardThemeData(
      color: color,
      surfaceTintColor: Colors.transparent,
      shadowColor: shadowColor,
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor.withValues(alpha: 0.82)),
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
        disabledBackgroundColor: primary.withValues(alpha: 0.34),
        disabledForegroundColor: foreground.withValues(alpha: 0.68),
        minimumSize: const Size(44, 44),
        elevation: 0,
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
        side: BorderSide(color: outlineColor.withValues(alpha: 0.94)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(Color primary) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static ChipThemeData _chipTheme({
    required Color background,
    required Color selected,
    required Color foreground,
    required Color selectedForeground,
    required Color outlineColor,
  }) {
    return ChipThemeData(
      backgroundColor: background,
      selectedColor: selected,
      disabledColor: background.withValues(alpha: 0.54),
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      secondaryLabelStyle: TextStyle(
        color: selectedForeground,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: outlineColor.withValues(alpha: 0.86)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      showCheckmark: false,
    );
  }

  static DialogThemeData _dialogTheme(Color background, Color outlineColor) {
    return DialogThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: outlineColor.withValues(alpha: 0.86)),
      ),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(Color background) {
    return BottomSheetThemeData(
      backgroundColor: background,
      modalBackgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      modalElevation: 16,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme({
    required Color background,
    required Color foreground,
  }) {
    return SnackBarThemeData(
      backgroundColor: background,
      contentTextStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: cyan,
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static PopupMenuThemeData _popupMenuTheme(
    Color background,
    Color outlineColor,
    Color foreground,
  ) {
    return PopupMenuThemeData(
      color: background,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      textStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outlineColor.withValues(alpha: 0.86)),
      ),
    );
  }

  static TabBarThemeData _tabBarTheme(Color primary, Color mutedColor) {
    return TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: mutedColor,
      indicatorColor: primary,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.08)),
    );
  }

  static SwitchThemeData _switchTheme(Color primary, Color inactiveTrack) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? Colors.white : null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? primary : inactiveTrack;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  static CheckboxThemeData _checkboxTheme(Color primary, Color outlineColor) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? primary : null;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: BorderSide(color: outlineColor, width: 1.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}
