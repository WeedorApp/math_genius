import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Game models
import '../../features/game/models/game_model.dart';

/// User preferences for game settings and UX optimization
class UserGamePreferences {
  final GameDifficulty preferredDifficulty;
  final GameCategory preferredCategory;
  final int preferredTimeLimit;
  final int preferredQuestionCount;
  final bool soundEnabled;
  final bool hapticFeedbackEnabled;
  final bool autoStartNextGame;
  final String lastGameMode;
  final DateTime lastPlayed;

  const UserGamePreferences({
    this.preferredDifficulty = GameDifficulty.normal,
    this.preferredCategory = GameCategory.addition,
    this.preferredTimeLimit = 30,
    this.preferredQuestionCount = 10,
    this.soundEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.autoStartNextGame = false,
    this.lastGameMode = 'classic',
    required this.lastPlayed,
  });

  UserGamePreferences copyWith({
    GameDifficulty? preferredDifficulty,
    GameCategory? preferredCategory,
    int? preferredTimeLimit,
    int? preferredQuestionCount,
    bool? soundEnabled,
    bool? hapticFeedbackEnabled,
    bool? autoStartNextGame,
    String? lastGameMode,
    DateTime? lastPlayed,
  }) {
    return UserGamePreferences(
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      preferredCategory: preferredCategory ?? this.preferredCategory,
      preferredTimeLimit: preferredTimeLimit ?? this.preferredTimeLimit,
      preferredQuestionCount: preferredQuestionCount ?? this.preferredQuestionCount,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      autoStartNextGame: autoStartNextGame ?? this.autoStartNextGame,
      lastGameMode: lastGameMode ?? this.lastGameMode,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredDifficulty': preferredDifficulty.name,
      'preferredCategory': preferredCategory.name,
      'preferredTimeLimit': preferredTimeLimit,
      'preferredQuestionCount': preferredQuestionCount,
      'soundEnabled': soundEnabled,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'autoStartNextGame': autoStartNextGame,
      'lastGameMode': lastGameMode,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  factory UserGamePreferences.fromJson(Map<String, dynamic> json) {
    return UserGamePreferences(
      preferredDifficulty: GameDifficulty.values.byName(
        json['preferredDifficulty'] ?? 'normal',
      ),
      preferredCategory: GameCategory.values.byName(
        json['preferredCategory'] ?? 'addition',
      ),
      preferredTimeLimit: json['preferredTimeLimit'] ?? 30,
      preferredQuestionCount: json['preferredQuestionCount'] ?? 10,
      soundEnabled: json['soundEnabled'] ?? true,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
      autoStartNextGame: json['autoStartNextGame'] ?? false,
      lastGameMode: json['lastGameMode'] ?? 'classic',
      lastPlayed: DateTime.parse(json['lastPlayed']),
    );
  }
}

/// Service for managing user preferences and game settings
class UserPreferencesService {
  static const String _preferencesKey = 'user_game_preferences';
  static const String _quickStartKey = 'quick_start_enabled';
  static const String _recentGamesKey = 'recent_games';

  final SharedPreferences _prefs;

  UserPreferencesService(this._prefs);

  /// Get user game preferences
  Future<UserGamePreferences> getGamePreferences() async {
    try {
      final prefsString = _prefs.getString(_preferencesKey);
      if (prefsString == null) {
        return UserGamePreferences(lastPlayed: DateTime.now());
      }
      return UserGamePreferences.fromJson(jsonDecode(prefsString));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting game preferences: $e');
      }
      return UserGamePreferences(lastPlayed: DateTime.now());
    }
  }

  /// Save user game preferences
  Future<void> saveGamePreferences(UserGamePreferences preferences) async {
    try {
      await _prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game preferences: $e');
      }
    }
  }

  /// Update preferences based on game session
  Future<void> updatePreferencesFromGame({
    required GameDifficulty difficulty,
    required GameCategory category,
    required int timeLimit,
    required int questionCount,
    required String gameMode,
  }) async {
    try {
      final currentPrefs = await getGamePreferences();
      final updatedPrefs = currentPrefs.copyWith(
        preferredDifficulty: difficulty,
        preferredCategory: category,
        preferredTimeLimit: timeLimit,
        preferredQuestionCount: questionCount,
        lastGameMode: gameMode,
        lastPlayed: DateTime.now(),
      );
      await saveGamePreferences(updatedPrefs);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating preferences from game: $e');
      }
    }
  }

  /// Check if quick start is enabled
  Future<bool> isQuickStartEnabled() async {
    return _prefs.getBool(_quickStartKey) ?? true; // Default to enabled
  }

  /// Set quick start preference
  Future<void> setQuickStartEnabled(bool enabled) async {
    await _prefs.setBool(_quickStartKey, enabled);
  }

  /// Get recent games for quick access
  Future<List<Map<String, dynamic>>> getRecentGames() async {
    try {
      final recentString = _prefs.getString(_recentGamesKey);
      if (recentString == null) return [];
      
      final recentList = jsonDecode(recentString) as List;
      return recentList.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recent games: $e');
      }
      return [];
    }
  }

  /// Add game to recent games list
  Future<void> addRecentGame({
    required String gameMode,
    required GameDifficulty difficulty,
    required GameCategory category,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final recentGames = await getRecentGames();
      
      final newGame = {
        'gameMode': gameMode,
        'difficulty': difficulty.name,
        'category': category.name,
        'score': score,
        'totalQuestions': totalQuestions,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Add to front of list and limit to 5 recent games
      recentGames.insert(0, newGame);
      if (recentGames.length > 5) {
        recentGames.removeRange(5, recentGames.length);
      }
      
      await _prefs.setString(_recentGamesKey, jsonEncode(recentGames));
    } catch (e) {
      if (kDebugMode) {
        print('Error adding recent game: $e');
      }
    }
  }

  /// Get quick start configuration for instant game launch
  Future<Map<String, dynamic>> getQuickStartConfig() async {
    try {
      final preferences = await getGamePreferences();
      final isQuickStartEnabled = await this.isQuickStartEnabled();
      
      return {
        'enabled': isQuickStartEnabled,
        'difficulty': preferences.preferredDifficulty,
        'category': preferences.preferredCategory,
        'timeLimit': preferences.preferredTimeLimit,
        'questionCount': preferences.preferredQuestionCount,
        'gameMode': preferences.lastGameMode,
        'soundEnabled': preferences.soundEnabled,
        'hapticEnabled': preferences.hapticFeedbackEnabled,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting quick start config: $e');
      }
      return {
        'enabled': true,
        'difficulty': GameDifficulty.normal,
        'category': GameCategory.addition,
        'timeLimit': 30,
        'questionCount': 10,
        'gameMode': 'classic',
        'soundEnabled': true,
        'hapticEnabled': true,
      };
    }
  }
}

/// Provider for user preferences service
final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  throw UnimplementedError('UserPreferencesService must be initialized');
});

/// Provider for current user game preferences
final userGamePreferencesProvider = FutureProvider<UserGamePreferences>((ref) async {
  final service = ref.read(userPreferencesServiceProvider);
  return service.getGamePreferences();
});

/// Provider for quick start configuration
final quickStartConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(userPreferencesServiceProvider);
  return service.getQuickStartConfig();
});

/// Provider for recent games
final recentGamesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(userPreferencesServiceProvider);
  return service.getRecentGames();
});
