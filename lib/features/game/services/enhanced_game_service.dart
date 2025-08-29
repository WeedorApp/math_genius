import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math' as math;

// Models
import '../models/game_model.dart';
import '../models/enhanced_game_model.dart';

/// Enhanced game service with advanced features
/// Provides progression, achievements, power-ups, and adaptive difficulty
class EnhancedGameService {
  static const String _gameStatsKey = 'enhanced_game_stats';
  static const String _achievementsKey = 'user_achievements';
  static const String _powerUpsKey = 'user_powerups';
  static const String _progressionKey = 'game_progression';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final math.Random _random = math.Random();

  EnhancedGameService(this._prefs, this._hiveBox);

  /// Get user's game statistics
  Future<GameStats> getGameStats(String userId) async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final statsData = _hiveBox.get('${_gameStatsKey}_$userId');
        if (statsData != null) {
          return GameStats.fromJson(jsonDecode(statsData as String));
        }
      }

      // Fallback to SharedPreferences
      final statsString = _prefs.getString('${_gameStatsKey}_$userId');
      if (statsString == null) {
        return GameStats(lastPlayed: DateTime.now());
      }

      return GameStats.fromJson(jsonDecode(statsString));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting game stats: $e');
      }
      return GameStats(lastPlayed: DateTime.now());
    }
  }

  /// Update user's game statistics
  Future<void> updateGameStats(String userId, GameStats stats) async {
    try {
      final statsJson = jsonEncode(stats.toJson());

      // Save to Hive first
      if (_hiveBox != null) {
        await _hiveBox.put('${_gameStatsKey}_$userId', statsJson);
      }

      // Fallback to SharedPreferences
      await _prefs.setString('${_gameStatsKey}_$userId', statsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating game stats: $e');
      }
    }
  }

  /// Process game session completion and update stats
  Future<GameStats> processGameCompletion({
    required String userId,
    required EnhancedGameSession session,
  }) async {
    try {
      final currentStats = await getGameStats(userId);
      final sessionDuration =
          session.endedAt != null && session.startedAt != null
          ? session.endedAt!.difference(session.startedAt!).inSeconds
          : session.startedAt != null
          ? DateTime.now().difference(session.startedAt!).inSeconds
          : 0;

      // Calculate new statistics
      final newStats = currentStats.copyWith(
        totalGamesPlayed: currentStats.totalGamesPlayed + 1,
        totalQuestionsAnswered:
            currentStats.totalQuestionsAnswered + session.questions.length,
        correctAnswers: currentStats.correctAnswers + session.score,
        totalTimeSpent: currentStats.totalTimeSpent + sessionDuration,
        currentStreak: _calculateStreak(currentStats, session),
        totalPoints: currentStats.totalPoints + session.finalScore,
        lastPlayed: DateTime.now(),
      );

      // Update category mastery
      final updatedCategoryMastery = Map<GameCategory, int>.from(
        currentStats.categoryMastery,
      );
      updatedCategoryMastery[session.category] =
          (updatedCategoryMastery[session.category] ?? 0) + session.score;

      // Update difficulty progress
      final updatedDifficultyProgress = Map<GameDifficulty, int>.from(
        currentStats.difficultyProgress,
      );
      updatedDifficultyProgress[session.difficulty] =
          (updatedDifficultyProgress[session.difficulty] ?? 0) + session.score;

      final finalStats = newStats.copyWith(
        categoryMastery: updatedCategoryMastery,
        difficultyProgress: updatedDifficultyProgress,
        longestStreak: math.max(newStats.longestStreak, newStats.currentStreak),
        averageAccuracy: _calculateAverageAccuracy(newStats),
        currentLevel: _calculateProgression(newStats),
      );

      await updateGameStats(userId, finalStats);

      // Check for new achievements
      await _checkAndUnlockAchievements(userId, finalStats, session);

      return finalStats;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing game completion: $e');
      }
      return await getGameStats(userId);
    }
  }

  /// Calculate streak based on performance
  int _calculateStreak(GameStats currentStats, EnhancedGameSession session) {
    final accuracy = session.questions.isNotEmpty
        ? (session.score / session.questions.length) * 100
        : 0.0;

    // Continue streak if accuracy is above 70%
    if (accuracy >= 70.0) {
      return currentStats.currentStreak + 1;
    } else {
      return 0; // Reset streak
    }
  }

  /// Calculate average accuracy
  double _calculateAverageAccuracy(GameStats stats) {
    return stats.totalQuestionsAnswered > 0
        ? (stats.correctAnswers / stats.totalQuestionsAnswered) * 100
        : 0.0;
  }

  /// Calculate user's progression level
  GameProgression _calculateProgression(GameStats stats) {
    final totalPoints = stats.totalPoints;

    if (totalPoints >= 50000) return GameProgression.grandmaster;
    if (totalPoints >= 25000) return GameProgression.master;
    if (totalPoints >= 10000) return GameProgression.expert;
    if (totalPoints >= 5000) return GameProgression.skilled;
    if (totalPoints >= 1000) return GameProgression.apprentice;
    return GameProgression.novice;
  }

  /// Get available achievements
  Future<List<Achievement>> getAvailableAchievements(String userId) async {
    return [
      const Achievement(
        id: 'streak_master_10',
        title: 'Streak Master',
        description: 'Answer 10 questions correctly in a row',
        iconPath: 'assets/icons/streak_master.png',
        type: AchievementType.streakMaster,
        pointsReward: 500,
        maxProgress: 10,
      ),
      const Achievement(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Answer 5 questions in under 30 seconds',
        iconPath: 'assets/icons/speed_demon.png',
        type: AchievementType.speedDemon,
        pointsReward: 300,
        maxProgress: 5,
      ),
      const Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Complete a game with 100% accuracy',
        iconPath: 'assets/icons/perfectionist.png',
        type: AchievementType.perfectionist,
        pointsReward: 1000,
        maxProgress: 1,
      ),
      const Achievement(
        id: 'explorer',
        title: 'Explorer',
        description: 'Try all game categories',
        iconPath: 'assets/icons/explorer.png',
        type: AchievementType.explorer,
        pointsReward: 750,
        maxProgress: 14, // Number of GameCategory enum values
      ),
      const Achievement(
        id: 'math_wizard',
        title: 'Math Wizard',
        description: 'Reach Master level',
        iconPath: 'assets/icons/math_wizard.png',
        type: AchievementType.mathWizard,
        pointsReward: 2000,
        maxProgress: 1,
      ),
    ];
  }

  /// Check and unlock achievements
  Future<void> _checkAndUnlockAchievements(
    String userId,
    GameStats stats,
    EnhancedGameSession session,
  ) async {
    try {
      final availableAchievements = await getAvailableAchievements(userId);
      final newlyUnlocked = <String>[];

      for (final achievement in availableAchievements) {
        if (stats.unlockedAchievements.contains(achievement.id)) continue;

        bool shouldUnlock = false;

        switch (achievement.type) {
          case AchievementType.streakMaster:
            shouldUnlock = stats.currentStreak >= achievement.maxProgress;
            break;
          case AchievementType.speedDemon:
            // Check if last 5 questions were answered quickly
            shouldUnlock = _checkSpeedDemonRequirement(session);
            break;
          case AchievementType.perfectionist:
            final accuracy = session.questions.isNotEmpty
                ? (session.score / session.questions.length) * 100
                : 0.0;
            shouldUnlock = accuracy == 100.0;
            break;
          case AchievementType.explorer:
            shouldUnlock =
                stats.categoryMastery.length >= achievement.maxProgress;
            break;
          case AchievementType.mathWizard:
            shouldUnlock =
                stats.currentLevel.index >= GameProgression.master.index;
            break;
          default:
            break;
        }

        if (shouldUnlock) {
          newlyUnlocked.add(achievement.id);
        }
      }

      if (newlyUnlocked.isNotEmpty) {
        final updatedStats = stats.copyWith(
          unlockedAchievements: [
            ...stats.unlockedAchievements,
            ...newlyUnlocked,
          ],
          totalPoints:
              stats.totalPoints +
              (newlyUnlocked.length * 500), // Bonus points for achievements
        );
        await updateGameStats(userId, updatedStats);

        // Save achievements data
        await _saveAchievements(userId, newlyUnlocked);

        // Update progression
        await _saveProgression(userId, updatedStats);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking achievements: $e');
      }
    }
  }

  /// Check speed demon achievement requirement
  bool _checkSpeedDemonRequirement(EnhancedGameSession session) {
    // This would need actual timing data from the session
    // For now, return a simple check based on session duration
    if (session.endedAt == null || session.startedAt == null) return false;

    final duration = session.endedAt!.difference(session.startedAt!).inSeconds;
    return session.questions.length >= 5 && duration <= 30;
  }

  /// Get available power-ups for user
  Future<List<PowerUp>> getAvailablePowerUps(String userId) async {
    final powerUps = [
      const PowerUp(
        id: 'time_extension',
        name: 'Time Extension',
        description: 'Add 30 seconds to the timer',
        type: PowerUpType.timeExtension,
        duration: 0,
        cost: 100,
        iconPath: 'assets/icons/time_extension.png',
        effects: {'timeBonus': 30},
      ),
      const PowerUp(
        id: 'fifty_fifty',
        name: '50/50',
        description: 'Remove two wrong answers',
        type: PowerUpType.fiftyFifty,
        duration: 0,
        cost: 150,
        iconPath: 'assets/icons/fifty_fifty.png',
        effects: {'removeOptions': 2},
      ),
      const PowerUp(
        id: 'double_points',
        name: 'Double Points',
        description: 'Double points for next 3 questions',
        type: PowerUpType.doublePoints,
        duration: 0,
        cost: 200,
        iconPath: 'assets/icons/double_points.png',
        effects: {'multiplier': 2, 'questionCount': 3},
      ),
      const PowerUp(
        id: 'hint_reveal',
        name: 'Hint Reveal',
        description: 'Show a helpful hint',
        type: PowerUpType.hintReveal,
        duration: 0,
        cost: 75,
        iconPath: 'assets/icons/hint_reveal.png',
        effects: {'showHint': true},
      ),
    ];

    // Save power-ups for user
    await _savePowerUps(userId, powerUps);

    return powerUps;
  }

  /// Generate adaptive questions based on user performance
  Future<List<AIQuestion>> generateAdaptiveQuestions({
    required String userId,
    required int count,
    GameCategory? preferredCategory,
  }) async {
    try {
      final stats = await getGameStats(userId);

      // Determine optimal difficulty based on recent performance
      final adaptiveDifficulty = _calculateAdaptiveDifficulty(stats);

      // Select categories based on mastery levels
      final categories = _selectOptimalCategories(stats, preferredCategory);

      final questions = <AIQuestion>[];

      for (int i = 0; i < count; i++) {
        final category = categories[i % categories.length];
        final difficulty = _adjustDifficultyForCategory(
          adaptiveDifficulty,
          category,
          stats,
        );

        final question = await _generateAdaptiveQuestion(
          category: category,
          difficulty: difficulty,
          gradeLevel: _getGradeLevelFromProgression(stats.currentLevel),
          userStats: stats,
        );

        questions.add(question);
      }

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating adaptive questions: $e');
      }
      // Fallback to basic questions
      return _generateBasicQuestions(count);
    }
  }

  /// Calculate adaptive difficulty based on user performance
  GameDifficulty _calculateAdaptiveDifficulty(GameStats stats) {
    final accuracy = stats.accuracyPercentage;

    if (accuracy >= 90) {
      // User is performing very well, increase difficulty
      return GameDifficulty.genius;
    } else if (accuracy >= 75) {
      // Good performance, moderate difficulty
      return GameDifficulty.normal;
    } else if (accuracy >= 60) {
      // Struggling a bit, keep it manageable
      return GameDifficulty.easy;
    } else {
      // User needs more practice at easy level
      return GameDifficulty.easy;
    }
  }

  /// Select optimal categories for learning
  List<GameCategory> _selectOptimalCategories(
    GameStats stats,
    GameCategory? preferred,
  ) {
    if (preferred != null) {
      return [preferred];
    }

    // Find categories where user needs more practice
    final allCategories = GameCategory.values;
    final categoriesByMastery = allCategories.map((category) {
      final mastery = stats.categoryMastery[category] ?? 0;
      return MapEntry(category, mastery);
    }).toList();

    // Sort by mastery level (ascending) to focus on weaker areas
    categoriesByMastery.sort((a, b) => a.value.compareTo(b.value));

    // Return mix of weak and strong categories
    final result = <GameCategory>[];
    for (int i = 0; i < categoriesByMastery.length && result.length < 3; i++) {
      result.add(categoriesByMastery[i].key);
    }

    return result.isNotEmpty ? result : [GameCategory.addition];
  }

  /// Adjust difficulty for specific category based on mastery
  GameDifficulty _adjustDifficultyForCategory(
    GameDifficulty baseDifficulty,
    GameCategory category,
    GameStats stats,
  ) {
    final categoryMastery = stats.categoryMastery[category] ?? 0;

    // If user has high mastery in this category, increase difficulty
    if (categoryMastery > 100) {
      final difficultyIndex = math.min(
        baseDifficulty.index + 1,
        GameDifficulty.values.length - 1,
      );
      return GameDifficulty.values[difficultyIndex];
    }

    // If user has low mastery, decrease difficulty
    if (categoryMastery < 20) {
      final difficultyIndex = math.max(baseDifficulty.index - 1, 0);
      return GameDifficulty.values[difficultyIndex];
    }

    return baseDifficulty;
  }

  /// Get grade level from progression
  GradeLevel _getGradeLevelFromProgression(GameProgression progression) {
    switch (progression) {
      case GameProgression.novice:
        return GradeLevel.kindergarten;
      case GameProgression.apprentice:
        return GradeLevel.grade2;
      case GameProgression.skilled:
        return GradeLevel.grade4;
      case GameProgression.expert:
        return GradeLevel.grade6;
      case GameProgression.master:
        return GradeLevel.grade8;
      case GameProgression.grandmaster:
        return GradeLevel.grade10;
    }
  }

  /// Generate an adaptive question
  Future<AIQuestion> _generateAdaptiveQuestion({
    required GameCategory category,
    required GameDifficulty difficulty,
    required GradeLevel gradeLevel,
    required GameStats userStats,
  }) async {
    // This would integrate with AI service in a real implementation
    // For now, generate a sample question based on parameters

    final questionId = 'adaptive_${_random.nextInt(10000)}';
    String question;
    List<String> options;
    int correctAnswer;

    switch (category) {
      case GameCategory.addition:
        final (q, opts, correct) = _generateAdditionQuestion(difficulty);
        question = q;
        options = opts;
        correctAnswer = correct;
        break;
      case GameCategory.subtraction:
        final (q, opts, correct) = _generateSubtractionQuestion(difficulty);
        question = q;
        options = opts;
        correctAnswer = correct;
        break;
      case GameCategory.multiplication:
        final (q, opts, correct) = _generateMultiplicationQuestion(difficulty);
        question = q;
        options = opts;
        correctAnswer = correct;
        break;
      default:
        final (q, opts, correct) = _generateAdditionQuestion(difficulty);
        question = q;
        options = opts;
        correctAnswer = correct;
    }

    return AIQuestion(
      id: questionId,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
      category: category,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: _generateExplanation(question, options[correctAnswer]),
      hint: _generateHint(category, difficulty),
      timeLimit: _calculateTimeLimit(difficulty),
      confidence: 0.95,
      learningObjectives: _getLearningObjectives(category),
    );
  }

  /// Generate addition question
  (String, List<String>, int) _generateAdditionQuestion(
    GameDifficulty difficulty,
  ) {
    int a, b;
    switch (difficulty) {
      case GameDifficulty.easy:
        a = _random.nextInt(10) + 1;
        b = _random.nextInt(10) + 1;
        break;
      case GameDifficulty.normal:
        a = _random.nextInt(50) + 10;
        b = _random.nextInt(50) + 10;
        break;
      case GameDifficulty.genius:
        a = _random.nextInt(100) + 50;
        b = _random.nextInt(100) + 50;
        break;
      case GameDifficulty.quantum:
        a = _random.nextInt(500) + 100;
        b = _random.nextInt(500) + 100;
        break;
    }

    final correct = a + b;
    final question = 'What is $a + $b?';

    final options = <String>[];
    options.add(correct.toString());

    // Generate wrong answers
    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final wrong = correct + (_random.nextInt(20) - 10);
      if (wrong != correct && wrong > 0) {
        wrongAnswers.add(wrong);
      }
    }

    options.addAll(wrongAnswers.map((w) => w.toString()));
    options.shuffle();

    final correctIndex = options.indexOf(correct.toString());

    return (question, options, correctIndex);
  }

  /// Generate subtraction question
  (String, List<String>, int) _generateSubtractionQuestion(
    GameDifficulty difficulty,
  ) {
    int a, b;
    switch (difficulty) {
      case GameDifficulty.easy:
        a = _random.nextInt(20) + 10;
        b = _random.nextInt(a);
        break;
      case GameDifficulty.normal:
        a = _random.nextInt(100) + 50;
        b = _random.nextInt(a);
        break;
      case GameDifficulty.genius:
        a = _random.nextInt(200) + 100;
        b = _random.nextInt(a);
        break;
      case GameDifficulty.quantum:
        a = _random.nextInt(1000) + 500;
        b = _random.nextInt(a);
        break;
    }

    final correct = a - b;
    final question = 'What is $a - $b?';

    final options = <String>[];
    options.add(correct.toString());

    // Generate wrong answers
    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final wrong = correct + (_random.nextInt(20) - 10);
      if (wrong != correct && wrong >= 0) {
        wrongAnswers.add(wrong);
      }
    }

    options.addAll(wrongAnswers.map((w) => w.toString()));
    options.shuffle();

    final correctIndex = options.indexOf(correct.toString());

    return (question, options, correctIndex);
  }

  /// Generate multiplication question
  (String, List<String>, int) _generateMultiplicationQuestion(
    GameDifficulty difficulty,
  ) {
    int a, b;
    switch (difficulty) {
      case GameDifficulty.easy:
        a = _random.nextInt(10) + 1;
        b = _random.nextInt(10) + 1;
        break;
      case GameDifficulty.normal:
        a = _random.nextInt(12) + 1;
        b = _random.nextInt(12) + 1;
        break;
      case GameDifficulty.genius:
        a = _random.nextInt(20) + 1;
        b = _random.nextInt(15) + 1;
        break;
      case GameDifficulty.quantum:
        a = _random.nextInt(50) + 1;
        b = _random.nextInt(25) + 1;
        break;
    }

    final correct = a * b;
    final question = 'What is $a × $b?';

    final options = <String>[];
    options.add(correct.toString());

    // Generate wrong answers
    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final wrong = correct + (_random.nextInt(correct ~/ 2) - (correct ~/ 4));
      if (wrong != correct && wrong > 0) {
        wrongAnswers.add(wrong);
      }
    }

    options.addAll(wrongAnswers.map((w) => w.toString()));
    options.shuffle();

    final correctIndex = options.indexOf(correct.toString());

    return (question, options, correctIndex);
  }

  /// Generate explanation for answer
  String _generateExplanation(String question, String answer) {
    return 'The correct answer is $answer. Great job!';
  }

  /// Generate hint for category and difficulty
  String _generateHint(GameCategory category, GameDifficulty difficulty) {
    switch (category) {
      case GameCategory.addition:
        return 'Try breaking down the numbers into smaller parts to add them easier.';
      case GameCategory.subtraction:
        return 'Count backwards from the larger number.';
      case GameCategory.multiplication:
        return 'Think of multiplication as repeated addition.';
      default:
        return 'Take your time and think through the problem step by step.';
    }
  }

  /// Calculate time limit based on difficulty
  int _calculateTimeLimit(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 45;
      case GameDifficulty.normal:
        return 30;
      case GameDifficulty.genius:
        return 20;
      case GameDifficulty.quantum:
        return 15;
    }
  }

  /// Get learning objectives for category
  List<String> _getLearningObjectives(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return ['Master basic addition', 'Understand number relationships'];
      case GameCategory.subtraction:
        return ['Master basic subtraction', 'Understand inverse operations'];
      case GameCategory.multiplication:
        return ['Master multiplication tables', 'Understand repeated addition'];
      default:
        return ['Improve mathematical thinking'];
    }
  }

  /// Generate basic fallback questions
  Future<List<AIQuestion>> _generateBasicQuestions(int count) async {
    final questions = <AIQuestion>[];

    for (int i = 0; i < count; i++) {
      final category =
          GameCategory.values[_random.nextInt(GameCategory.values.length)];
      final difficulty = GameDifficulty.easy;

      final (question, options, correctAnswer) = _generateAdditionQuestion(
        difficulty,
      );

      questions.add(
        AIQuestion(
          id: 'basic_$i',
          question: question,
          options: options,
          correctAnswer: correctAnswer,
          category: category,
          difficulty: difficulty,
          gradeLevel: GradeLevel.grade1,
        ),
      );
    }

    return questions;
  }

  /// Save achievements data
  Future<void> _saveAchievements(
    String userId,
    List<String> achievements,
  ) async {
    try {
      final achievementsData = {
        'userId': userId,
        'achievements': achievements,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_hiveBox != null) {
        await _hiveBox.put(
          '${_achievementsKey}_$userId',
          jsonEncode(achievementsData),
        );
      }
      await _prefs.setString(
        '${_achievementsKey}_$userId',
        jsonEncode(achievementsData),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving achievements: $e');
      }
    }
  }

  /// Save power-ups data
  Future<void> _savePowerUps(String userId, List<PowerUp> powerUps) async {
    try {
      final powerUpsData = {
        'userId': userId,
        'powerUps': powerUps.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_hiveBox != null) {
        await _hiveBox.put('${_powerUpsKey}_$userId', jsonEncode(powerUpsData));
      }
      await _prefs.setString(
        '${_powerUpsKey}_$userId',
        jsonEncode(powerUpsData),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving power-ups: $e');
      }
    }
  }

  /// Save progression data
  Future<void> _saveProgression(String userId, GameStats stats) async {
    try {
      final progressionData = {
        'userId': userId,
        'currentLevel': stats.currentLevel.name,
        'totalPoints': stats.totalPoints,
        'categoryMastery': stats.categoryMastery.map(
          (k, v) => MapEntry(k.name, v),
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_hiveBox != null) {
        await _hiveBox.put(
          '${_progressionKey}_$userId',
          jsonEncode(progressionData),
        );
      }
      await _prefs.setString(
        '${_progressionKey}_$userId',
        jsonEncode(progressionData),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving progression: $e');
      }
    }
  }
}

/// Provider for enhanced game service
final enhancedGameServiceProvider = Provider<EnhancedGameService>((ref) {
  // This would be properly injected in a real app
  throw UnimplementedError(
    'EnhancedGameService provider needs to be configured',
  );
});
