import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme modes supported by Math Genius
enum ThemeMode { light, dark, childFriendly, girlMode, proMode }

/// Color scheme for Math Genius themes
class MathGeniusColorScheme {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color background;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onTertiary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  final Color surfaceTint;
  final Color surfaceVariant;
  final Color onSurfaceVariant;

  const MathGeniusColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onTertiary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.surfaceTint,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
  });

  /// Convert to Material 3 ColorScheme
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: _getBrightness(),
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: 0.1),
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondary.withValues(alpha: 0.1),
      onSecondaryContainer: secondary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiary.withValues(alpha: 0.1),
      onTertiaryContainer: tertiary,
      error: error,
      onError: onError,
      errorContainer: error.withValues(alpha: 0.1),
      onErrorContainer: error,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: inversePrimary,
      surfaceTint: surfaceTint,
    );
  }

  Brightness _getBrightness() {
    // Determine brightness based on background color
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }
}

/// Typography for Math Genius themes
class MathGeniusTypography {
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  const MathGeniusTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  /// Convert to Material 3 TextTheme
  TextTheme toTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}

/// Component theme data for Math Genius
class MathGeniusComponentTheme {
  final ButtonThemeData buttonTheme;
  final CardThemeData cardTheme;
  final AppBarTheme appBarTheme;
  final BottomNavigationBarThemeData bottomNavigationBarTheme;
  final FloatingActionButtonThemeData floatingActionButtonTheme;
  final InputDecorationTheme inputDecorationTheme;
  final DialogThemeData dialogTheme;
  final SnackBarThemeData snackBarTheme;

  const MathGeniusComponentTheme({
    required this.buttonTheme,
    required this.cardTheme,
    required this.appBarTheme,
    required this.bottomNavigationBarTheme,
    required this.floatingActionButtonTheme,
    required this.inputDecorationTheme,
    required this.dialogTheme,
    required this.snackBarTheme,
  });
}

/// Complete theme data for Math Genius
class MathGeniusThemeData {
  final MathGeniusColorScheme colorScheme;
  final MathGeniusTypography typography;
  final MathGeniusComponentTheme componentTheme;
  final ThemeMode mode;

  const MathGeniusThemeData({
    required this.colorScheme,
    required this.typography,
    required this.componentTheme,
    required this.mode,
  });

  /// Convert to Material 3 ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.toColorScheme(),
      textTheme: typography.toTextTheme(),
      buttonTheme: componentTheme.buttonTheme,
      cardTheme: componentTheme.cardTheme,
      appBarTheme: componentTheme.appBarTheme,
      bottomNavigationBarTheme: componentTheme.bottomNavigationBarTheme,
      floatingActionButtonTheme: componentTheme.floatingActionButtonTheme,
      inputDecorationTheme: componentTheme.inputDecorationTheme,
      dialogTheme: componentTheme.dialogTheme,
      snackBarTheme: componentTheme.snackBarTheme,
    );
  }
}

/// Theme service for Math Genius
class ThemeService {
  static const String _themeModeKey = 'theme_mode';
  static const String _isSystemThemeKey = 'is_system_theme';

  final SharedPreferences _prefs;

  ThemeService(this._prefs);

  /// Get the current theme mode
  Future<ThemeMode> getThemeMode() async {
    final modeString = _prefs.getString(_themeModeKey);
    if (modeString == null) return ThemeMode.light;

    return ThemeMode.values.firstWhere(
      (mode) => mode.name == modeString,
      orElse: () => ThemeMode.light,
    );
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  /// Check if system theme is enabled
  Future<bool> isSystemTheme() async {
    return _prefs.getBool(_isSystemThemeKey) ?? false;
  }

  /// Set system theme preference
  Future<void> setSystemTheme(bool enabled) async {
    await _prefs.setBool(_isSystemThemeKey, enabled);
  }

  /// Get theme data for the specified mode
  MathGeniusThemeData getThemeData(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _getLightTheme();
      case ThemeMode.dark:
        return _getDarkTheme();
      case ThemeMode.childFriendly:
        return _getChildFriendlyTheme();
      case ThemeMode.girlMode:
        return _getGirlModeTheme();
      case ThemeMode.proMode:
        return _getProModeTheme();
    }
  }

  /// Light theme
  MathGeniusThemeData _getLightTheme() {
    const colorScheme = MathGeniusColorScheme(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF03DAC6),
      tertiary: Color(0xFFFF6B6B),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF5F5F5),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onTertiary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF121212),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF90CAF9),
      surfaceTint: Color(0xFF2196F3),
      surfaceVariant: Color(0xFFF0F0F0),
      onSurfaceVariant: Color(0xFF666666),
    );

    return MathGeniusThemeData(
      mode: ThemeMode.light,
      colorScheme: colorScheme,
      typography: _getDefaultTypography(),
      componentTheme: _getDefaultComponentTheme(colorScheme),
    );
  }

  /// Dark theme
  MathGeniusThemeData _getDarkTheme() {
    const colorScheme = MathGeniusColorScheme(
      primary: Color(0xFF90CAF9),
      secondary: Color(0xFF03DAC6),
      tertiary: Color(0xFFFF6B6B),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onTertiary: Color(0xFFFFFFFF),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
      outline: Color(0xFF424242),
      outlineVariant: Color(0xFF616161),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFFFFFFF),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF2196F3),
      surfaceTint: Color(0xFF90CAF9),
      surfaceVariant: Color(0xFF1E1E1E),
      onSurfaceVariant: Color(0xFFBDBDBD),
    );

    return MathGeniusThemeData(
      mode: ThemeMode.dark,
      colorScheme: colorScheme,
      typography: _getDefaultTypography(),
      componentTheme: _getDefaultComponentTheme(colorScheme),
    );
  }

  /// Child-friendly theme
  MathGeniusThemeData _getChildFriendlyTheme() {
    const colorScheme = MathGeniusColorScheme(
      primary: Color(0xFFFF6B9D),
      secondary: Color(0xFF4ECDC4),
      tertiary: Color(0xFFFFE66D),
      surface: Color(0xFFFFF8E1),
      background: Color(0xFFFFFDE7),
      error: Color(0xFFFF6B6B),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onTertiary: Color(0xFF000000),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFFFB74D),
      outlineVariant: Color(0xFFFFCC80),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF121212),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFFFF6B9D),
      surfaceTint: Color(0xFFFF6B9D),
      surfaceVariant: Color(0xFFFFF3E0),
      onSurfaceVariant: Color(0xFF666666),
    );

    return MathGeniusThemeData(
      mode: ThemeMode.childFriendly,
      colorScheme: colorScheme,
      typography: _getChildFriendlyTypography(),
      componentTheme: _getChildFriendlyComponentTheme(colorScheme),
    );
  }

  /// Girl mode theme
  MathGeniusThemeData _getGirlModeTheme() {
    const colorScheme = MathGeniusColorScheme(
      primary: Color(0xFFE91E63),
      secondary: Color(0xFF9C27B0),
      tertiary: Color(0xFFFFC0CB),
      surface: Color(0xFFFFF0F5),
      background: Color(0xFFFFF8FA),
      error: Color(0xFFFF6B6B),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onTertiary: Color(0xFF000000),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFFFB6C1),
      outlineVariant: Color(0xFFFFC0CB),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF121212),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFFE91E63),
      surfaceTint: Color(0xFFE91E63),
      surfaceVariant: Color(0xFFFFF0F5),
      onSurfaceVariant: Color(0xFF666666),
    );

    return MathGeniusThemeData(
      mode: ThemeMode.girlMode,
      colorScheme: colorScheme,
      typography: _getGirlModeTypography(),
      componentTheme: _getGirlModeComponentTheme(colorScheme),
    );
  }

  /// Pro mode theme
  MathGeniusThemeData _getProModeTheme() {
    const colorScheme = MathGeniusColorScheme(
      primary: Color(0xFF00BCD4),
      secondary: Color(0xFF607D8B),
      tertiary: Color(0xFF795548),
      surface: Color(0xFFFAFAFA),
      background: Color(0xFFF5F5F5),
      error: Color(0xFFD32F2F),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onTertiary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF121212),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF00BCD4),
      surfaceTint: Color(0xFF00BCD4),
      surfaceVariant: Color(0xFFF0F0F0),
      onSurfaceVariant: Color(0xFF666666),
    );

    return MathGeniusThemeData(
      mode: ThemeMode.proMode,
      colorScheme: colorScheme,
      typography: _getProModeTypography(),
      componentTheme: _getProModeComponentTheme(colorScheme),
    );
  }

  /// Default typography
  MathGeniusTypography _getDefaultTypography() {
    return const MathGeniusTypography(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Child-friendly typography
  MathGeniusTypography _getChildFriendlyTypography() {
    return const MathGeniusTypography(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Girl mode typography
  MathGeniusTypography _getGirlModeTypography() {
    return const MathGeniusTypography(
      displayLarge: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Pro mode typography
  MathGeniusTypography _getProModeTypography() {
    return const MathGeniusTypography(
      displayLarge: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Default component theme
  MathGeniusComponentTheme _getDefaultComponentTheme(
    MathGeniusColorScheme colorScheme,
  ) {
    return MathGeniusComponentTheme(
      buttonTheme: ButtonThemeData(
        buttonColor: colorScheme.primary,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Child-friendly component theme
  MathGeniusComponentTheme _getChildFriendlyComponentTheme(
    MathGeniusColorScheme colorScheme,
  ) {
    return MathGeniusComponentTheme(
      buttonTheme: ButtonThemeData(
        buttonColor: colorScheme.primary,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(color: colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Girl mode component theme
  MathGeniusComponentTheme _getGirlModeComponentTheme(
    MathGeniusColorScheme colorScheme,
  ) {
    return MathGeniusComponentTheme(
      buttonTheme: ButtonThemeData(
        buttonColor: colorScheme.primary,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(color: colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Pro mode component theme
  MathGeniusComponentTheme _getProModeComponentTheme(
    MathGeniusColorScheme colorScheme,
  ) {
    return MathGeniusComponentTheme(
      buttonTheme: ButtonThemeData(
        buttonColor: colorScheme.primary,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// Riverpod providers for theme management
final themeServiceProvider = Provider<ThemeService>((ref) {
  throw UnimplementedError('ThemeService must be initialized');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.read(themeServiceProvider));
});

final themeDataProvider = Provider<MathGeniusThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final themeService = ref.read(themeServiceProvider);
  return themeService.getThemeData(themeMode);
});

/// State notifier for theme mode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _service;

  ThemeModeNotifier(this._service) : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    state = await _service.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _service.setThemeMode(mode);
    state = mode;
  }
}
