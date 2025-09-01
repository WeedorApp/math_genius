import 'package:flutter/material.dart';

import '../preferences/user_preferences_service.dart';

/// Wrapper widget that applies accessibility settings to the entire app
class AccessibilityWrapper extends StatelessWidget {
  final UserGamePreferences? preferences;
  final Widget child;

  const AccessibilityWrapper({
    super.key,
    required this.preferences,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (preferences == null) return child;

    Widget accessibleChild = child;

    // Apply reduced motion by wrapping with custom animations
    if (preferences!.reducedMotion) {
      accessibleChild = ReducedMotionWrapper(child: accessibleChild);
    }

    // Apply screen reader optimizations
    if (preferences!.screenReaderOptimized) {
      accessibleChild = ScreenReaderWrapper(child: accessibleChild);
    }

    // Apply visual theme modifications
    if (preferences!.visualTheme != 'default') {
      accessibleChild = VisualThemeWrapper(
        theme: preferences!.visualTheme,
        child: accessibleChild,
      );
    }

    return accessibleChild;
  }
}

/// Wrapper for reduced motion functionality
class ReducedMotionWrapper extends StatelessWidget {
  final Widget child;

  const ReducedMotionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50), // Minimal animation
      child: child,
    );
  }
}

/// Wrapper for screen reader optimizations
class ScreenReaderWrapper extends StatelessWidget {
  final Widget child;

  const ScreenReaderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(explicitChildNodes: true, child: child);
  }
}

/// Wrapper for visual theme modifications
class VisualThemeWrapper extends StatelessWidget {
  final String theme;
  final Widget child;

  const VisualThemeWrapper({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Apply theme-specific modifications
    switch (theme) {
      case 'dark':
        return Theme(
          data: Theme.of(context).copyWith(brightness: Brightness.dark),
          child: child,
        );
      case 'colorful':
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple,
              brightness: Brightness.light,
            ),
          ),
          child: child,
        );
      case 'minimal':
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.light,
            ),
          ),
          child: child,
        );
      default:
        return child;
    }
  }
}
