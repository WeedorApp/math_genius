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

  // Advanced adaptive learning features
  final bool autoAdjustDifficulty;
  final bool smartTopicRotation;
  final bool spacedRepetition;
  final double learningIntensity;
  final List<GameCategory> focusTopics;
  final Map<String, dynamic> gameSpecificSettings;

  // AI Personality and Style
  final String aiPersonality;
  final String aiStyle;
  final String chatGPTModel;
  final String tutoringStyle;
  final double explanationDepth;
  final double questionComplexity;

  // Accessibility and Personalization
  final double fontSize;
  final bool highContrastMode;
  final bool screenReaderOptimized;
  final bool dyslexiaFriendlyMode;
  final String visualTheme;
  final bool reducedMotion;

  // Learning Path and Analytics
  final String currentLearningPath;
  final Map<String, double> skillLevels;
  final List<String> completedMilestones;
  final Map<String, DateTime> lastPracticed;

  // Data Management
  final DateTime? lastSyncTime;
  final String preferenceVersion;
  final Map<String, dynamic> cloudBackupSettings;

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
    // Advanced features with smart defaults
    this.autoAdjustDifficulty = false,
    this.smartTopicRotation = false,
    this.spacedRepetition = false,
    this.learningIntensity = 0.5,
    this.focusTopics = const [],
    this.gameSpecificSettings = const {},

    // AI Personality and Style defaults
    this.aiPersonality = 'Encouraging',
    this.aiStyle = 'Adaptive',
    this.chatGPTModel = 'GPT-4',
    this.tutoringStyle = 'Socratic',
    this.explanationDepth = 0.5,
    this.questionComplexity = 0.5,

    // Accessibility defaults
    this.fontSize = 1.0,
    this.highContrastMode = false,
    this.screenReaderOptimized = false,
    this.dyslexiaFriendlyMode = false,
    this.visualTheme = 'default',
    this.reducedMotion = false,

    // Learning path defaults
    this.currentLearningPath = 'adaptive',
    this.skillLevels = const {},
    this.completedMilestones = const [],
    this.lastPracticed = const {},

    // Data management defaults
    this.preferenceVersion = '1.0.0',
    this.cloudBackupSettings = const {},
    this.lastSyncTime,
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
    // Advanced features
    bool? autoAdjustDifficulty,
    bool? smartTopicRotation,
    bool? spacedRepetition,
    double? learningIntensity,
    List<GameCategory>? focusTopics,
    Map<String, dynamic>? gameSpecificSettings,

    // AI Personality and Style
    String? aiPersonality,
    String? aiStyle,
    String? chatGPTModel,
    String? tutoringStyle,
    double? explanationDepth,
    double? questionComplexity,

    // Accessibility and Personalization
    double? fontSize,
    bool? highContrastMode,
    bool? screenReaderOptimized,
    bool? dyslexiaFriendlyMode,
    String? visualTheme,
    bool? reducedMotion,

    // Learning Path and Analytics
    String? currentLearningPath,
    Map<String, double>? skillLevels,
    List<String>? completedMilestones,
    Map<String, DateTime>? lastPracticed,

    // Data Management
    DateTime? lastSyncTime,
    String? preferenceVersion,
    Map<String, dynamic>? cloudBackupSettings,
  }) {
    return UserGamePreferences(
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      preferredCategory: preferredCategory ?? this.preferredCategory,
      preferredTimeLimit: preferredTimeLimit ?? this.preferredTimeLimit,
      preferredQuestionCount:
          preferredQuestionCount ?? this.preferredQuestionCount,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      autoStartNextGame: autoStartNextGame ?? this.autoStartNextGame,
      lastGameMode: lastGameMode ?? this.lastGameMode,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      // Advanced features
      autoAdjustDifficulty: autoAdjustDifficulty ?? this.autoAdjustDifficulty,
      smartTopicRotation: smartTopicRotation ?? this.smartTopicRotation,
      spacedRepetition: spacedRepetition ?? this.spacedRepetition,
      learningIntensity: learningIntensity ?? this.learningIntensity,
      focusTopics: focusTopics ?? this.focusTopics,
      gameSpecificSettings: gameSpecificSettings ?? this.gameSpecificSettings,

      // AI Personality and Style
      aiPersonality: aiPersonality ?? this.aiPersonality,
      aiStyle: aiStyle ?? this.aiStyle,
      chatGPTModel: chatGPTModel ?? this.chatGPTModel,
      tutoringStyle: tutoringStyle ?? this.tutoringStyle,
      explanationDepth: explanationDepth ?? this.explanationDepth,
      questionComplexity: questionComplexity ?? this.questionComplexity,

      // Accessibility and Personalization
      fontSize: fontSize ?? this.fontSize,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      screenReaderOptimized:
          screenReaderOptimized ?? this.screenReaderOptimized,
      dyslexiaFriendlyMode: dyslexiaFriendlyMode ?? this.dyslexiaFriendlyMode,
      visualTheme: visualTheme ?? this.visualTheme,
      reducedMotion: reducedMotion ?? this.reducedMotion,

      // Learning Path and Analytics
      currentLearningPath: currentLearningPath ?? this.currentLearningPath,
      skillLevels: skillLevels ?? this.skillLevels,
      completedMilestones: completedMilestones ?? this.completedMilestones,
      lastPracticed: lastPracticed ?? this.lastPracticed,

      // Data Management
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      preferenceVersion: preferenceVersion ?? this.preferenceVersion,
      cloudBackupSettings: cloudBackupSettings ?? this.cloudBackupSettings,
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
      // Advanced features
      'autoAdjustDifficulty': autoAdjustDifficulty,
      'smartTopicRotation': smartTopicRotation,
      'spacedRepetition': spacedRepetition,
      'learningIntensity': learningIntensity,
      'focusTopics': focusTopics.map((topic) => topic.name).toList(),
      'gameSpecificSettings': gameSpecificSettings,

      // AI Personality and Style
      'aiPersonality': aiPersonality,
      'aiStyle': aiStyle,
      'chatGPTModel': chatGPTModel,
      'tutoringStyle': tutoringStyle,
      'explanationDepth': explanationDepth,
      'questionComplexity': questionComplexity,

      // Accessibility and Personalization
      'fontSize': fontSize,
      'highContrastMode': highContrastMode,
      'screenReaderOptimized': screenReaderOptimized,
      'dyslexiaFriendlyMode': dyslexiaFriendlyMode,
      'visualTheme': visualTheme,
      'reducedMotion': reducedMotion,

      // Learning Path and Analytics
      'currentLearningPath': currentLearningPath,
      'skillLevels': skillLevels,
      'completedMilestones': completedMilestones,
      'lastPracticed': lastPracticed.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),

      // Data Management
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'preferenceVersion': preferenceVersion,
      'cloudBackupSettings': cloudBackupSettings,
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
      // Advanced features
      autoAdjustDifficulty: json['autoAdjustDifficulty'] ?? false,
      smartTopicRotation: json['smartTopicRotation'] ?? false,
      spacedRepetition: json['spacedRepetition'] ?? false,
      learningIntensity: json['learningIntensity']?.toDouble() ?? 0.5,
      focusTopics:
          (json['focusTopics'] as List?)
              ?.map((name) => GameCategory.values.byName(name))
              .toList() ??
          [],
      gameSpecificSettings:
          json['gameSpecificSettings'] as Map<String, dynamic>? ?? {},

      // AI Personality and Style
      aiPersonality: json['aiPersonality'] ?? 'Encouraging',
      aiStyle: json['aiStyle'] ?? 'Adaptive',
      chatGPTModel: json['chatGPTModel'] ?? 'GPT-4',
      tutoringStyle: json['tutoringStyle'] ?? 'Socratic',
      explanationDepth: json['explanationDepth']?.toDouble() ?? 0.5,
      questionComplexity: json['questionComplexity']?.toDouble() ?? 0.5,

      // Accessibility and Personalization
      fontSize: json['fontSize']?.toDouble() ?? 1.0,
      highContrastMode: json['highContrastMode'] ?? false,
      screenReaderOptimized: json['screenReaderOptimized'] ?? false,
      dyslexiaFriendlyMode: json['dyslexiaFriendlyMode'] ?? false,
      visualTheme: json['visualTheme'] ?? 'default',
      reducedMotion: json['reducedMotion'] ?? false,

      // Learning Path and Analytics
      currentLearningPath: json['currentLearningPath'] ?? 'adaptive',
      skillLevels:
          (json['skillLevels'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      completedMilestones:
          (json['completedMilestones'] as List?)?.cast<String>() ?? [],
      lastPracticed:
          (json['lastPracticed'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, DateTime.parse(value)),
          ) ??
          {},

      // Data Management
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : DateTime.now(),
      preferenceVersion: json['preferenceVersion'] ?? '1.0.0',
      cloudBackupSettings:
          json['cloudBackupSettings'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Service for managing user preferences and game settings
class UserPreferencesService {
  static const String _preferencesKey = 'user_game_preferences';
  static const String _quickStartKey = 'quick_start_enabled';
  static const String _recentGamesKey = 'recent_games';

  final SharedPreferences _prefs;

  // Performance optimization: Cache preferences in memory
  UserGamePreferences? _cachedPreferences;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  UserPreferencesService(this._prefs);

  /// Get user game preferences with caching for performance
  Future<UserGamePreferences> getGamePreferences() async {
    try {
      // Check cache first for instant loading
      if (_cachedPreferences != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheValidDuration) {
          if (kDebugMode) {
            debugPrint(
              '✅ Using cached preferences (${cacheAge.inSeconds}s old)',
            );
          }
          return _cachedPreferences!;
        }
      }

      final prefsString = _prefs.getString(_preferencesKey);
      if (prefsString == null) {
        final defaultPrefs = UserGamePreferences(lastPlayed: DateTime.now());
        _updateCache(defaultPrefs);
        return defaultPrefs;
      }

      final preferences = UserGamePreferences.fromJson(jsonDecode(prefsString));
      _updateCache(preferences);

      if (kDebugMode) {
        debugPrint('✅ Loaded preferences from storage');
      }

      return preferences;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting game preferences: $e');
      }
      final fallbackPrefs = UserGamePreferences(lastPlayed: DateTime.now());
      _updateCache(fallbackPrefs);
      return fallbackPrefs;
    }
  }

  /// Update memory cache
  void _updateCache(UserGamePreferences preferences) {
    _cachedPreferences = preferences;
    _cacheTimestamp = DateTime.now();
  }

  /// Save user game preferences
  Future<void> saveGamePreferences(UserGamePreferences preferences) async {
    try {
      await _prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
      // Update cache immediately for faster subsequent loads
      _updateCache(preferences);

      if (kDebugMode) {
        debugPrint('✅ Preferences saved and cached');
      }
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

/// Provider for current user game preferences (deprecated - use preferences_notifier.dart)
@Deprecated(
  'Use userGamePreferencesNotifierProvider from preferences_notifier.dart instead',
)
final userGamePreferencesProvider = FutureProvider<UserGamePreferences>((
  ref,
) async {
  final service = ref.read(userPreferencesServiceProvider);
  return service.getGamePreferences();
});

/// Provider for quick start configuration
final quickStartConfigProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(userPreferencesServiceProvider);
  return service.getQuickStartConfig();
});

/// Provider for recent games
final recentGamesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.read(userPreferencesServiceProvider);
  return service.getRecentGames();
});
