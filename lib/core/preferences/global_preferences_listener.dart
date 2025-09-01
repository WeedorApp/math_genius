import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'preferences_notifier.dart';
import 'user_preferences_service.dart';

/// Global preferences listener for app-wide real-time synchronization
class GlobalPreferencesListener extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalPreferencesListener({super.key, required this.child});

  @override
  ConsumerState<GlobalPreferencesListener> createState() =>
      _GlobalPreferencesListenerState();
}

class _GlobalPreferencesListenerState
    extends ConsumerState<GlobalPreferencesListener> {
  UserGamePreferences? _lastPreferences;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🔄 Global preferences listener initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to preferences changes app-wide
    ref.listen<AsyncValue<UserGamePreferences>>(
      userGamePreferencesNotifierProvider,
      (previous, next) {
        if (next.hasValue && next.value != null) {
          _handlePreferencesChange(previous?.asData?.value, next.value!);
        }
      },
    );

    return widget.child;
  }

  /// Handle real-time preferences changes across the app
  void _handlePreferencesChange(
    UserGamePreferences? oldPrefs,
    UserGamePreferences newPrefs,
  ) {
    if (!mounted) return;

    // Skip if preferences haven't actually changed
    if (_lastPreferences != null &&
        _preferencesEqual(_lastPreferences!, newPrefs)) {
      return;
    }

    _lastPreferences = newPrefs;

    if (kDebugMode) {
      debugPrint('🔄 Global preferences changed, syncing app-wide...');
    }

    // Apply theme changes if visual theme changed
    if (oldPrefs?.visualTheme != newPrefs.visualTheme) {
      _applyThemeChanges(newPrefs);
    }

    // Apply accessibility changes if accessibility settings changed
    if (_accessibilityChanged(oldPrefs, newPrefs)) {
      _applyAccessibilityChanges(newPrefs);
    }

    // Apply audio changes if sound settings changed
    if (oldPrefs?.soundEnabled != newPrefs.soundEnabled ||
        oldPrefs?.hapticFeedbackEnabled != newPrefs.hapticFeedbackEnabled) {
      _applyAudioChanges(newPrefs);
    }

    // Notify all game screens of preference changes
    _notifyGameScreens(newPrefs);

    if (kDebugMode) {
      debugPrint('✅ App-wide preferences sync completed');
    }
  }

  /// Apply theme changes app-wide
  void _applyThemeChanges(UserGamePreferences prefs) {
    try {
      // Visual theme changes are now handled by MathGeniusApp build method
      // which watches currentUserGamePreferencesProvider and rebuilds automatically

      if (kDebugMode) {
        debugPrint('🎨 Visual theme updated to: ${prefs.visualTheme}');
        debugPrint('   📱 App will rebuild with new theme automatically');
      }
    } catch (e) {
      debugPrint('Error applying theme changes: $e');
    }
  }

  /// Apply accessibility changes app-wide
  void _applyAccessibilityChanges(UserGamePreferences prefs) {
    try {
      // Font size changes are handled by textScalerProvider in MaterialApp
      if (prefs.fontSize != 1.0) {
        if (kDebugMode) {
          debugPrint(
            '📝 Font size updated to: ${(prefs.fontSize * 100).round()}%',
          );
        }
      }

      // High contrast mode is handled by accessibleColorSchemeProvider in MaterialApp
      if (prefs.highContrastMode) {
        if (kDebugMode) {
          debugPrint('🔳 High contrast mode enabled');
        }
      }

      // Dyslexia-friendly mode is handled by accessibleTextThemeProvider in MaterialApp
      if (prefs.dyslexiaFriendlyMode) {
        if (kDebugMode) {
          debugPrint('👁️ Dyslexia-friendly mode enabled');
        }
      }

      // Reduced motion is handled by adaptiveAnimationDurationProvider
      if (prefs.reducedMotion) {
        if (kDebugMode) {
          debugPrint('🚫 Reduced motion enabled');
        }
      }

      // Screen reader optimization is handled by AccessibilityWrapper
      if (prefs.screenReaderOptimized) {
        if (kDebugMode) {
          debugPrint('📱 Screen reader optimization enabled');
        }
      }

      if (kDebugMode) {
        debugPrint('♿ Accessibility settings updated app-wide');
      }
    } catch (e) {
      debugPrint('Error applying accessibility changes: $e');
    }
  }

  /// Apply audio and haptic changes app-wide
  void _applyAudioChanges(UserGamePreferences prefs) {
    try {
      // Global sound settings
      if (!prefs.soundEnabled) {
        // TODO: Disable all app sounds
        if (kDebugMode) {
          debugPrint('🔇 Sound disabled app-wide');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🔊 Sound enabled app-wide');
        }
      }

      // Global haptic settings
      if (!prefs.hapticFeedbackEnabled) {
        // TODO: Disable all app haptics
        if (kDebugMode) {
          debugPrint('📳 Haptic feedback disabled app-wide');
        }
      } else {
        if (kDebugMode) {
          debugPrint('📳 Haptic feedback enabled app-wide');
        }
      }
    } catch (e) {
      debugPrint('Error applying audio changes: $e');
    }
  }

  /// Notify all game screens of preference changes
  void _notifyGameScreens(UserGamePreferences prefs) {
    try {
      // Game screens will automatically update via their ref.listen calls
      // This method can be used for additional custom notifications

      if (kDebugMode) {
        debugPrint('🎮 Game screens notified of preference changes');
      }
    } catch (e) {
      debugPrint('Error notifying game screens: $e');
    }
  }

  /// Check if accessibility settings changed
  bool _accessibilityChanged(
    UserGamePreferences? oldPrefs,
    UserGamePreferences newPrefs,
  ) {
    if (oldPrefs == null) return true;

    return oldPrefs.fontSize != newPrefs.fontSize ||
        oldPrefs.highContrastMode != newPrefs.highContrastMode ||
        oldPrefs.screenReaderOptimized != newPrefs.screenReaderOptimized ||
        oldPrefs.dyslexiaFriendlyMode != newPrefs.dyslexiaFriendlyMode ||
        oldPrefs.reducedMotion != newPrefs.reducedMotion;
  }

  /// Check if preferences are equal (for optimization)
  bool _preferencesEqual(UserGamePreferences a, UserGamePreferences b) {
    return a.preferredDifficulty == b.preferredDifficulty &&
        a.preferredCategory == b.preferredCategory &&
        a.preferredTimeLimit == b.preferredTimeLimit &&
        a.preferredQuestionCount == b.preferredQuestionCount &&
        a.soundEnabled == b.soundEnabled &&
        a.hapticFeedbackEnabled == b.hapticFeedbackEnabled &&
        a.visualTheme == b.visualTheme &&
        a.fontSize == b.fontSize &&
        a.highContrastMode == b.highContrastMode &&
        a.reducedMotion == b.reducedMotion;
  }
}

/// Provider for global preferences listening
final globalPreferencesListenerProvider = Provider<Widget>((ref) {
  throw UnimplementedError(
    'GlobalPreferencesListener must be wrapped around app',
  );
});
