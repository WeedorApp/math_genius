import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/barrel.dart';
import '../models/game_model.dart';

/// Mixin for handling game preferences synchronization across all game screens
mixin GamePreferencesMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  // Note: No StreamSubscription needed - individual screens handle ref.listen in build method

  // Flag to prevent infinite loops during real-time sync
  bool _isApplyingRealTimeUpdate = false;

  // Abstract properties that implementing classes must define
  GameDifficulty? get selectedDifficulty;
  GameCategory? get selectedCategory;
  int? get selectedQuestionCount;
  int get selectedTimeLimit;
  bool get soundEnabled;
  bool get hapticFeedbackEnabled;
  String get gameMode;

  // Abstract methods that implementing classes must implement
  void onDifficultyChanged(GameDifficulty difficulty);
  void onCategoryChanged(GameCategory category);
  void onQuestionCountChanged(int count);
  void onTimeLimitChanged(int timeLimit);
  void onSoundEnabledChanged(bool enabled);
  void onHapticFeedbackChanged(bool enabled);
  void onPreferencesLoaded(UserGamePreferences preferences);

  /// Initialize preferences listening
  void initializePreferencesSync() {
    // Load initial preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPreferences();
    });

    // NOTE: Real-time sync must be set up in build method
    // Call setupRealTimeSyncInBuild() from your widget's build method
  }

  /// Handle real-time preference updates
  /// This method should be called from the build method when preferences change
  void handleRealTimePreferenceUpdate(UserGamePreferences newPrefs) {
    if (!mounted || _isApplyingRealTimeUpdate) return;

    try {
      _isApplyingRealTimeUpdate = true;

      // Apply new preferences to current game (read-only, no preference updates)
      onDifficultyChanged(newPrefs.preferredDifficulty);
      onCategoryChanged(newPrefs.preferredCategory);
      onQuestionCountChanged(newPrefs.preferredQuestionCount);
      onTimeLimitChanged(newPrefs.preferredTimeLimit);
      onSoundEnabledChanged(newPrefs.soundEnabled);
      onHapticFeedbackChanged(newPrefs.hapticFeedbackEnabled);

      if (kDebugMode) {
        debugPrint('✅ Real-time preferences applied to $gameMode');
      }
    } catch (e) {
      debugPrint('Error applying real-time preferences: $e');
    } finally {
      _isApplyingRealTimeUpdate = false;
    }
  }

  /// Load initial preferences and configure game
  Future<void> _loadInitialPreferences() async {
    try {
      final asyncPrefs = ref.read(userGamePreferencesNotifierProvider);
      asyncPrefs.whenData((preferences) {
        onPreferencesLoaded(preferences);
      });
    } catch (e) {
      debugPrint('Error loading initial preferences: $e');
    }
  }

  /// Update preferences when game settings change
  Future<void> updateGamePreferences({
    GameDifficulty? difficulty,
    GameCategory? category,
    int? questionCount,
    int? timeLimit,
    bool? soundEnabled,
    bool? hapticEnabled,
  }) async {
    try {
      // Check if widget is still mounted before using ref
      if (!mounted) {
        debugPrint('⚠️ Widget disposed, skipping preference update');
        return;
      }

      // Prevent infinite loops during real-time sync
      if (_isApplyingRealTimeUpdate) {
        debugPrint(
          '⚠️ Skipping preference update during real-time sync to prevent loop',
        );
        return;
      }

      final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
      final currentPrefs = ref.read(currentUserGamePreferencesProvider);

      if (currentPrefs != null) {
        final updatedPrefs = currentPrefs.copyWith(
          preferredDifficulty: difficulty ?? currentPrefs.preferredDifficulty,
          preferredCategory: category ?? currentPrefs.preferredCategory,
          preferredQuestionCount:
              questionCount ?? currentPrefs.preferredQuestionCount,
          preferredTimeLimit: timeLimit ?? currentPrefs.preferredTimeLimit,
          soundEnabled: soundEnabled ?? currentPrefs.soundEnabled,
          hapticFeedbackEnabled:
              hapticEnabled ?? currentPrefs.hapticFeedbackEnabled,
          lastGameMode: gameMode,
          lastPlayed: DateTime.now(),
        );

        await notifier.updatePreferences(updatedPrefs);
        debugPrint('✅ Game preferences updated: $gameMode');
      }
    } catch (e) {
      debugPrint('❌ Error updating game preferences: $e');
    }
  }

  /// Update preferences when game session completes
  Future<void> updatePreferencesFromGameCompletion({
    required int score,
    required int totalQuestions,
  }) async {
    try {
      // Check if widget is still mounted before using ref
      if (!mounted) {
        debugPrint('⚠️ Widget disposed, skipping game completion update');
        return;
      }

      final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);

      if (selectedDifficulty != null &&
          selectedCategory != null &&
          selectedQuestionCount != null) {
        await notifier.updateFromGameSession(
          difficulty: selectedDifficulty!,
          category: selectedCategory!,
          timeLimit: selectedTimeLimit,
          questionCount: selectedQuestionCount!,
          gameMode: gameMode,
          score: score,
          totalQuestions: totalQuestions,
        );

        debugPrint('✅ Preferences updated from completed game: $gameMode');
      }
    } catch (e) {
      debugPrint('❌ Error updating preferences from game completion: $e');
    }
  }

  /// Quick update methods for individual preferences
  Future<void> updateDifficulty(GameDifficulty difficulty) async {
    if (!mounted || _isApplyingRealTimeUpdate) return;
    final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
    await notifier.updateDifficulty(difficulty);
  }

  Future<void> updateCategory(GameCategory category) async {
    if (!mounted || _isApplyingRealTimeUpdate) return;
    final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
    await notifier.updateCategory(category);
  }

  Future<void> updateQuestionCount(int count) async {
    if (!mounted || _isApplyingRealTimeUpdate) return;
    final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
    await notifier.updateQuestionCount(count);
  }

  Future<void> updateTimeLimit(int timeLimit) async {
    if (!mounted || _isApplyingRealTimeUpdate) return;
    final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
    await notifier.updateTimeLimit(timeLimit);
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    if (!mounted || _isApplyingRealTimeUpdate) return;
    final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
    await notifier.updateSoundEnabled(enabled);
  }

  Future<void> updateHapticFeedback(bool enabled) async {
    if (!mounted || _isApplyingRealTimeUpdate) return;
    final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
    await notifier.updateHapticFeedbackEnabled(enabled);
  }

  /// Check if current game settings match stored preferences
  bool get isInSyncWithPreferences {
    if (!mounted) return false;
    final currentPrefs = ref.read(currentUserGamePreferencesProvider);
    if (currentPrefs == null) return false;

    return selectedDifficulty == currentPrefs.preferredDifficulty &&
        selectedCategory == currentPrefs.preferredCategory &&
        selectedQuestionCount == currentPrefs.preferredQuestionCount &&
        selectedTimeLimit == currentPrefs.preferredTimeLimit &&
        soundEnabled == currentPrefs.soundEnabled &&
        hapticFeedbackEnabled == currentPrefs.hapticFeedbackEnabled;
  }

  /// Sync current game settings to preferences
  Future<void> syncCurrentSettingsToPreferences() async {
    if (!mounted) return;
    if (!isInSyncWithPreferences) {
      await updateGamePreferences(
        difficulty: selectedDifficulty,
        category: selectedCategory,
        questionCount: selectedQuestionCount,
        timeLimit: selectedTimeLimit,
        soundEnabled: soundEnabled,
        hapticEnabled: hapticFeedbackEnabled,
      );
    }
  }

  /// Dispose preferences sync (no longer needed - handled by individual screens)
  void disposePreferencesSync() {
    // No-op: Individual screens handle their own ref.listen disposal
  }

  @override
  void dispose() {
    disposePreferencesSync();
    super.dispose();
  }
}
