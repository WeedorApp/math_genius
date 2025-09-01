import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_notifier.dart';
import '../preferences/user_preferences_service.dart';

/// Comprehensive accessibility service for app-wide implementation
class AccessibilityService {
  /// Apply font size scaling app-wide
  static TextScaler getTextScaler(double fontSize) {
    return TextScaler.linear(fontSize);
  }

  /// Get high contrast color scheme
  static ColorScheme getHighContrastColorScheme(
    ColorScheme base,
    bool highContrast,
  ) {
    if (!highContrast) return base;

    return base.copyWith(
      // High contrast adjustments
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red[900]!,
      onError: Colors.white,
    );
  }

  /// Get dyslexia-friendly text theme
  static TextTheme getDyslexiaFriendlyTextTheme(
    TextTheme base,
    bool dyslexiaMode,
  ) {
    if (!dyslexiaMode) return base;

    // Use OpenDyslexic-style properties
    return base.copyWith(
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'Roboto', // More readable font
        letterSpacing: 1.2, // Increased letter spacing
        height: 1.6, // Increased line height
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'Roboto',
        letterSpacing: 1.1,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'Roboto',
        letterSpacing: 1.0,
        height: 1.4,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'Roboto',
        letterSpacing: 1.3,
        height: 1.7,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'Roboto',
        letterSpacing: 1.2,
        height: 1.6,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: 'Roboto',
        letterSpacing: 1.1,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Get reduced motion duration
  static Duration getAnimationDuration(Duration original, bool reducedMotion) {
    if (!reducedMotion) return original;

    // Reduce animation duration by 80% or minimum 50ms
    final reducedMs = (original.inMilliseconds * 0.2).round();
    return Duration(milliseconds: reducedMs < 50 ? 50 : reducedMs);
  }

  /// Get screen reader optimized semantics
  static Widget addScreenReaderSemantics({
    required Widget child,
    required bool screenReaderOptimized,
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? header,
  }) {
    if (!screenReaderOptimized) return child;

    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button ?? false,
      header: header ?? false,
      excludeSemantics: false,
      child: child,
    );
  }

  /// Apply accessibility settings to widget
  static Widget applyAccessibilitySettings({
    required Widget child,
    required UserGamePreferences preferences,
  }) {
    Widget accessibleChild = child;

    // Apply font scaling
    if (preferences.fontSize != 1.0) {
      accessibleChild = MediaQuery(
        data: MediaQuery.of(
          child as BuildContext,
        ).copyWith(textScaler: getTextScaler(preferences.fontSize)),
        child: accessibleChild,
      );
    }

    return accessibleChild;
  }
}

/// Provider for accessibility service
final accessibilityServiceProvider = Provider<AccessibilityService>((ref) {
  return AccessibilityService();
});

/// Provider for current accessibility settings
final accessibilitySettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  if (prefs == null) return {};

  return {
    'fontSize': prefs.fontSize,
    'highContrastMode': prefs.highContrastMode,
    'screenReaderOptimized': prefs.screenReaderOptimized,
    'dyslexiaFriendlyMode': prefs.dyslexiaFriendlyMode,
    'visualTheme': prefs.visualTheme,
    'reducedMotion': prefs.reducedMotion,
  };
});

/// Provider for text scaler based on font size preference
final textScalerProvider = Provider<TextScaler>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  final fontSize = prefs?.fontSize ?? 1.0;
  return AccessibilityService.getTextScaler(fontSize);
});

/// Provider for high contrast color scheme
final accessibleColorSchemeProvider = Provider.family<ColorScheme, ColorScheme>(
  (ref, baseScheme) {
    final prefs = ref.watch(currentUserGamePreferencesProvider);
    final highContrast = prefs?.highContrastMode ?? false;
    return AccessibilityService.getHighContrastColorScheme(
      baseScheme,
      highContrast,
    );
  },
);

/// Provider for dyslexia-friendly text theme
final accessibleTextThemeProvider = Provider.family<TextTheme, TextTheme>((
  ref,
  baseTheme,
) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  final dyslexiaMode = prefs?.dyslexiaFriendlyMode ?? false;
  return AccessibilityService.getDyslexiaFriendlyTextTheme(
    baseTheme,
    dyslexiaMode,
  );
});

/// Provider for animation duration based on reduced motion preference
final animationDurationProvider = Provider.family<Duration, Duration>((
  ref,
  originalDuration,
) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  final reducedMotion = prefs?.reducedMotion ?? false;
  return AccessibilityService.getAnimationDuration(
    originalDuration,
    reducedMotion,
  );
});
