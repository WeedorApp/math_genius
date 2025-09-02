import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/barrel.dart';

/// Unified Preference Synchronization Mixin
/// Provides comprehensive real-time preference synchronization for all game types
mixin UnifiedPreferenceSyncMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  // Flag to prevent infinite loops during sync
  bool _isSyncing = false;

  /// Initialize preference synchronization
  void initializeUnifiedPreferenceSync() {
    // This will be called by games to set up sync
  }

  /// Apply synchronized preferences with comprehensive coverage
  void applySynchronizedPreferences(UserGamePreferences prefs) {
    if (!mounted || _isSyncing) return;

    _isSyncing = true;

    try {
      // Apply core game preferences
      applyGamePreferences(prefs);

      // Apply advanced learning preferences
      applyLearningPreferences(prefs);

      // Apply AI preferences
      applyAIPreferences(prefs);

      // Apply accessibility preferences
      applyAccessibilityPreferences(prefs);

      // Apply UI preferences
      applyUIPreferences(prefs);

      // Show sync feedback
      showSyncFeedback(prefs);
    } finally {
      _isSyncing = false;
    }
  }

  // Abstract methods that implementing classes must override
  void applyGamePreferences(UserGamePreferences prefs);
  void applyLearningPreferences(UserGamePreferences prefs);
  void applyAIPreferences(UserGamePreferences prefs);
  void applyAccessibilityPreferences(UserGamePreferences prefs);
  void applyUIPreferences(UserGamePreferences prefs);

  /// Default implementation for sync feedback
  void showSyncFeedback(UserGamePreferences prefs) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚙️ Game settings updated!'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Helper method to check if core game parameters changed
  bool hasGameParametersChanged(
    UserGamePreferences current,
    UserGamePreferences previous,
  ) {
    return current.preferredDifficulty != previous.preferredDifficulty ||
        current.preferredCategory != previous.preferredCategory ||
        current.preferredQuestionCount != previous.preferredQuestionCount ||
        current.preferredTimeLimit != previous.preferredTimeLimit;
  }

  /// Helper method to check if UI preferences changed
  bool hasUIPreferencesChanged(
    UserGamePreferences current,
    UserGamePreferences previous,
  ) {
    return current.fontSize != previous.fontSize ||
        current.highContrastMode != previous.highContrastMode ||
        current.reducedMotion != previous.reducedMotion ||
        current.visualTheme != previous.visualTheme;
  }

  /// Helper method to check if accessibility preferences changed
  bool hasAccessibilityPreferencesChanged(
    UserGamePreferences current,
    UserGamePreferences previous,
  ) {
    return current.dyslexiaFriendlyMode != previous.dyslexiaFriendlyMode ||
        current.screenReaderOptimized != previous.screenReaderOptimized ||
        current.highContrastMode != previous.highContrastMode ||
        current.fontSize != previous.fontSize;
  }
}
