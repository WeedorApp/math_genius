import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'user_preferences_service.dart';
import '../../features/game/models/game_model.dart';

/// State notifier for reactive user game preferences
class UserGamePreferencesNotifier
    extends StateNotifier<AsyncValue<UserGamePreferences>> {
  final UserPreferencesService _preferencesService;
  Timer? _debounceTimer;

  UserGamePreferencesNotifier(this._preferencesService)
    : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  /// Load initial preferences
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferencesService.getGamePreferences();
      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update preferences with debouncing to prevent excessive saves
  Future<void> updatePreferences(UserGamePreferences preferences) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Immediately update UI state for real-time sync
    state = AsyncValue.data(preferences);
    
    if (kDebugMode) {
      debugPrint('🔄 Real-time preference update broadcasted');
    }

    // Debounce the actual save operation
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _preferencesService.saveGamePreferences(preferences);
        if (kDebugMode) {
          debugPrint('✅ Preferences saved and synced app-wide');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error saving preferences: $e');
        }
        // Reload preferences from storage on error
        await _loadPreferences();
      }
    });
  }

  /// Update specific preference fields
  Future<void> updateDifficulty(GameDifficulty difficulty) async {
    state.whenData((prefs) async {
      await updatePreferences(
        prefs.copyWith(
          preferredDifficulty: difficulty,
          lastPlayed: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updateCategory(GameCategory category) async {
    state.whenData((prefs) async {
      await updatePreferences(
        prefs.copyWith(preferredCategory: category, lastPlayed: DateTime.now()),
      );
    });
  }

  Future<void> updateTimeLimit(int timeLimit) async {
    state.whenData((prefs) async {
      await updatePreferences(
        prefs.copyWith(
          preferredTimeLimit: timeLimit,
          lastPlayed: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updateQuestionCount(int questionCount) async {
    state.whenData((prefs) async {
      await updatePreferences(
        prefs.copyWith(
          preferredQuestionCount: questionCount,
          lastPlayed: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    state.whenData((prefs) async {
      await updatePreferences(prefs.copyWith(soundEnabled: enabled));
    });
  }

  Future<void> updateHapticFeedbackEnabled(bool enabled) async {
    state.whenData((prefs) async {
      await updatePreferences(prefs.copyWith(hapticFeedbackEnabled: enabled));
    });
  }

  Future<void> updateAutoStartNextGame(bool enabled) async {
    state.whenData((prefs) async {
      await updatePreferences(prefs.copyWith(autoStartNextGame: enabled));
    });
  }

  Future<void> updateLastGameMode(String gameMode) async {
    state.whenData((prefs) async {
      await updatePreferences(
        prefs.copyWith(lastGameMode: gameMode, lastPlayed: DateTime.now()),
      );
    });
  }

  /// Update preferences from completed game session
  Future<void> updateFromGameSession({
    required GameDifficulty difficulty,
    required GameCategory category,
    required int timeLimit,
    required int questionCount,
    required String gameMode,
    required int score,
    required int totalQuestions,
  }) async {
    state.whenData((prefs) async {
      // Update preferences based on successful game completion
      final updatedPrefs = prefs.copyWith(
        preferredDifficulty: difficulty,
        preferredCategory: category,
        preferredTimeLimit: timeLimit,
        preferredQuestionCount: questionCount,
        lastGameMode: gameMode,
        lastPlayed: DateTime.now(),
      );

      await updatePreferences(updatedPrefs);

      // Also add to recent games
      await _preferencesService.addRecentGame(
        gameMode: gameMode,
        difficulty: difficulty,
        category: category,
        score: score,
        totalQuestions: totalQuestions,
      );
    });
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults() async {
    final defaultPrefs = UserGamePreferences(lastPlayed: DateTime.now());
    await updatePreferences(defaultPrefs);
  }

  /// Refresh preferences from storage
  Future<void> refresh() async {
    await _loadPreferences();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for user game preferences notifier
final userGamePreferencesNotifierProvider =
    StateNotifierProvider<
      UserGamePreferencesNotifier,
      AsyncValue<UserGamePreferences>
    >((ref) {
      final preferencesService = ref.read(userPreferencesServiceProvider);
      return UserGamePreferencesNotifier(preferencesService);
    });

/// Convenience provider for current preferences data
final currentUserGamePreferencesProvider = Provider<UserGamePreferences?>((
  ref,
) {
  final asyncPrefs = ref.watch(userGamePreferencesNotifierProvider);
  return asyncPrefs.asData?.value;
});

/// Provider for specific preference values
final preferredDifficultyProvider = Provider<GameDifficulty>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.preferredDifficulty ?? GameDifficulty.normal;
});

final preferredCategoryProvider = Provider<GameCategory>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.preferredCategory ?? GameCategory.addition;
});

final preferredTimeLimitProvider = Provider<int>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.preferredTimeLimit ?? 30;
});

final preferredQuestionCountProvider = Provider<int>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.preferredQuestionCount ?? 10;
});

final soundEnabledProvider = Provider<bool>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.soundEnabled ?? true;
});

final hapticFeedbackEnabledProvider = Provider<bool>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.hapticFeedbackEnabled ?? true;
});

final autoStartNextGameProvider = Provider<bool>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.autoStartNextGame ?? false;
});

final lastGameModeProvider = Provider<String>((ref) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  return prefs?.lastGameMode ?? 'classic';
});
