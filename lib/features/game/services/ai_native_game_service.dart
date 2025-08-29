import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

// Models
import '../models/game_model.dart';
import '../models/ai_difficulty_model.dart';

// ChatGPT Service
import '../../../core/ai/chatgpt_service.dart';

/// Advanced AI-Native Game Service for Math Genius
/// The most sophisticated AI-powered learning system in the market
class AINativeGameService {
  static const String _userProgressKey = 'ai_user_progress';
  static const String _aiQuestionsKey = 'ai_questions_cache';
  static const String _learningAnalyticsKey = 'ai_learning_analytics';

  final SharedPreferences _prefs;
  final ChatGPTService _chatGPTService;

  AINativeGameService(this._prefs, this._chatGPTService);

  /// Generate AI-native questions with advanced difficulty levels
  Future<List<AIQuestion>> generateAINativeQuestions({
    required AIDifficulty difficultyLevel,
    required GameCategory category,
    required int count,
    String? userId,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'Generating $count AI-native questions for $difficultyLevel difficulty',
        );
      }

      // Check for cached questions first
      final cachedQuestions = await _getCachedAIQuestions(
        difficultyLevel,
        category,
      );
      if (cachedQuestions.isNotEmpty && cachedQuestions.length >= count) {
        if (kDebugMode) {
          print('Using ${cachedQuestions.length} cached questions');
        }
        return cachedQuestions.take(count).toList();
      }

      // Try ChatGPT first for real AI generation
      final chatGPTQuestions = await _chatGPTService.generateAIQuestions(
        difficultyLevel: difficultyLevel,
        category: category,
        count: count,
        userId: userId,
        userContext: userContext,
      );

      if (chatGPTQuestions.isNotEmpty) {
        if (kDebugMode) {
          print('ChatGPT generated ${chatGPTQuestions.length} questions');
        }

        // Cache AI questions for performance
        await _cacheAIQuestions(difficultyLevel, category, chatGPTQuestions);

        return chatGPTQuestions;
      }

      // Fallback to local generation if ChatGPT fails
      if (kDebugMode) {
        print('ChatGPT failed, using local generation');
      }

      final questions = <AIQuestion>[];
      final random = Random();

      for (int i = 0; i < count; i++) {
        final question = await _generateSingleAINativeQuestion(
          difficultyLevel,
          category,
          random,
          userId,
          userContext,
        );
        questions.add(question);
      }

      // Cache AI questions for performance
      await _cacheAIQuestions(difficultyLevel, category, questions);

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating AI-native questions: $e');
      }
      return [];
    }
  }

  /// Generate a single AI-native question with advanced features
  Future<AIQuestion> _generateSingleAINativeQuestion(
    AIDifficulty difficultyLevel,
    GameCategory category,
    Random random,
    String? userId,
    Map<String, dynamic>? userContext,
  ) async {
    // Get difficulty model for adaptive properties
    final difficultyModel = AIDifficultyModel.fromEnum(difficultyLevel);

    // Generate question based on category and difficulty
    final question = await _generateQuestionByCategory(
      category,
      difficultyModel,
      random,
      userId,
      userContext,
    );

    return question;
  }

  /// Generate question based on category and difficulty
  Future<AIQuestion> _generateQuestionByCategory(
    GameCategory category,
    AIDifficultyModel difficultyModel,
    Random random,
    String? userId,
    Map<String, dynamic>? userContext,
  ) async {
    switch (category) {
      case GameCategory.addition:
        return _generateAdditionQuestion(difficultyModel, random);
      case GameCategory.subtraction:
        return _generateSubtractionQuestion(difficultyModel, random);
      case GameCategory.multiplication:
        return _generateMultiplicationQuestion(difficultyModel, random);
      case GameCategory.division:
        return _generateDivisionQuestion(difficultyModel, random);
      default:
        return _generateMixedQuestion(difficultyModel, random);
    }
  }

  /// Generate addition question with adaptive difficulty
  AIQuestion _generateAdditionQuestion(
    AIDifficultyModel difficulty,
    Random random,
  ) {
    final complexity = difficulty.complexityMultiplier;
    final maxNumber = ((100 * complexity).round()).clamp(1, 1000); // Ensure minimum 1

    final a = random.nextInt(maxNumber) + 1;
    final b = random.nextInt(maxNumber) + 1;
    final answer = a + b;

    // Generate wrong answers
    final wrongAnswers = _generateWrongAnswers(answer, 3, random);

    return AIQuestion(
      id: 'add_${DateTime.now().millisecondsSinceEpoch}',
      question: 'What is $a + $b?',
      correctAnswer: 0, // Index of correct answer in options
      options: [answer.toString(), ...wrongAnswers],
      category: GameCategory.addition,
      difficulty: _convertToGameDifficulty(difficulty.difficulty),
      gradeLevel: _getGradeLevel(difficulty.difficulty),
      explanation:
          'To add $a and $b, we combine the numbers: $a + $b = $answer',
      timeLimit: _getTimeLimit(difficulty.difficulty),
    );
  }

  /// Generate subtraction question with adaptive difficulty
  AIQuestion _generateSubtractionQuestion(
    AIDifficultyModel difficulty,
    Random random,
  ) {
    final complexity = difficulty.complexityMultiplier;
    final maxNumber = ((100 * complexity).round()).clamp(2, 1000); // Ensure minimum 2

    final a = random.nextInt(maxNumber) + 1;
    final b = random.nextInt(a.clamp(1, maxNumber)) + 1; // Ensure positive result
    final answer = a - b;

    // Generate wrong answers
    final wrongAnswers = _generateWrongAnswers(answer, 3, random);

    return AIQuestion(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      question: 'What is $a - $b?',
      correctAnswer: 0, // Index of correct answer in options
      options: [answer.toString(), ...wrongAnswers],
      category: GameCategory.subtraction,
      difficulty: _convertToGameDifficulty(difficulty.difficulty),
      gradeLevel: _getGradeLevel(difficulty.difficulty),
      explanation:
          'To subtract $b from $a, we find the difference: $a - $b = $answer',
      timeLimit: _getTimeLimit(difficulty.difficulty),
    );
  }

  /// Generate multiplication question with adaptive difficulty
  AIQuestion _generateMultiplicationQuestion(
    AIDifficultyModel difficulty,
    Random random,
  ) {
    final complexity = difficulty.complexityMultiplier;
    final maxNumber = ((20 * complexity).round()).clamp(1, 50); // Ensure minimum 1

    final a = random.nextInt(maxNumber) + 1;
    final b = random.nextInt(maxNumber) + 1;
    final answer = a * b;

    // Generate wrong answers
    final wrongAnswers = _generateWrongAnswers(answer, 3, random);

    return AIQuestion(
      id: 'mul_${DateTime.now().millisecondsSinceEpoch}',
      question: 'What is $a × $b?',
      correctAnswer: 0, // Index of correct answer in options
      options: [answer.toString(), ...wrongAnswers],
      category: GameCategory.multiplication,
      difficulty: _convertToGameDifficulty(difficulty.difficulty),
      gradeLevel: _getGradeLevel(difficulty.difficulty),
      explanation:
          'To multiply $a and $b, we multiply the numbers: $a × $b = $answer',
      timeLimit: _getTimeLimit(difficulty.difficulty),
    );
  }

  /// Generate division question with adaptive difficulty
  AIQuestion _generateDivisionQuestion(
    AIDifficultyModel difficulty,
    Random random,
  ) {
    final complexity = difficulty.complexityMultiplier;
    final maxNumber = ((50 * complexity).round()).clamp(1, 100); // Ensure minimum 1

    final b = random.nextInt(maxNumber) + 1;
    final answer = random.nextInt(maxNumber) + 1;
    final a = b * answer; // Ensure clean division

    // Generate wrong answers
    final wrongAnswers = _generateWrongAnswers(answer, 3, random);

    return AIQuestion(
      id: 'div_${DateTime.now().millisecondsSinceEpoch}',
      question: 'What is $a ÷ $b?',
      correctAnswer: 0, // Index of correct answer in options
      options: [answer.toString(), ...wrongAnswers],
      category: GameCategory.division,
      difficulty: _convertToGameDifficulty(difficulty.difficulty),
      gradeLevel: _getGradeLevel(difficulty.difficulty),
      explanation:
          'To divide $a by $b, we find how many times $b fits into $a: $a ÷ $b = $answer',
      timeLimit: _getTimeLimit(difficulty.difficulty),
    );
  }

  /// Generate mixed question with adaptive difficulty
  AIQuestion _generateMixedQuestion(
    AIDifficultyModel difficulty,
    Random random,
  ) {
    final categories = [
      GameCategory.addition,
      GameCategory.subtraction,
      GameCategory.multiplication,
      GameCategory.division,
    ];

    final category = categories[random.nextInt(categories.length)];

    switch (category) {
      case GameCategory.addition:
        return _generateAdditionQuestion(difficulty, random);
      case GameCategory.subtraction:
        return _generateSubtractionQuestion(difficulty, random);
      case GameCategory.multiplication:
        return _generateMultiplicationQuestion(difficulty, random);
      case GameCategory.division:
        return _generateDivisionQuestion(difficulty, random);
      default:
        return _generateAdditionQuestion(difficulty, random);
    }
  }

  /// Generate wrong answers for multiple choice
  List<String> _generateWrongAnswers(
    int correctAnswer,
    int count,
    Random random,
  ) {
    final wrongAnswers = <String>[];
    final usedAnswers = <int>{correctAnswer};
    int attempts = 0;
    const maxAttempts = 100; // Prevent infinite loops

    while (wrongAnswers.length < count && attempts < maxAttempts) {
      attempts++;
      final wrongAnswer = correctAnswer + random.nextInt(20) - 10;
      if (wrongAnswer != correctAnswer &&
          !usedAnswers.contains(wrongAnswer) &&
          wrongAnswer > 0) {
        wrongAnswers.add(wrongAnswer.toString());
        usedAnswers.add(wrongAnswer);
      }
    }

    // If we still don't have enough answers, generate simple fallbacks
    while (wrongAnswers.length < count) {
      final fallbackAnswer = correctAnswer + wrongAnswers.length + 1;
      if (!usedAnswers.contains(fallbackAnswer)) {
        wrongAnswers.add(fallbackAnswer.toString());
        usedAnswers.add(fallbackAnswer);
      }
    }

    return wrongAnswers;
  }

  /// Convert AIDifficulty to GameDifficulty
  GameDifficulty _convertToGameDifficulty(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return GameDifficulty.easy;
      case AIDifficulty.intermediate:
        return GameDifficulty.normal;
      case AIDifficulty.advanced:
        return GameDifficulty.genius;
      case AIDifficulty.expert:
        return GameDifficulty.quantum;
    }
  }

  /// Get grade level based on difficulty
  GradeLevel _getGradeLevel(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return GradeLevel.grade1;
      case AIDifficulty.intermediate:
        return GradeLevel.grade3;
      case AIDifficulty.advanced:
        return GradeLevel.grade6;
      case AIDifficulty.expert:
        return GradeLevel.grade9;
    }
  }

  /// Get time limit based on difficulty
  int _getTimeLimit(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 60;
      case AIDifficulty.intermediate:
        return 45;
      case AIDifficulty.advanced:
        return 30;
      case AIDifficulty.expert:
        return 20;
    }
  }

  /// Cache AI questions for performance
  Future<void> _cacheAIQuestions(
    AIDifficulty difficultyLevel,
    GameCategory category,
    List<AIQuestion> questions,
  ) async {
    try {
      final allQuestions = await _loadAllCachedQuestions();
      final key = '${difficultyLevel.name}_${category.name}';
      allQuestions[key] = questions.map((q) => q.toJson()).toList();
      await _prefs.setString(_aiQuestionsKey, jsonEncode(allQuestions));
    } catch (e) {
      if (kDebugMode) {
        print('Error caching AI questions: $e');
      }
    }
  }

  /// Get cached AI questions
  Future<List<AIQuestion>> _getCachedAIQuestions(
    AIDifficulty difficultyLevel,
    GameCategory category,
  ) async {
    try {
      final allQuestions = await _loadAllCachedQuestions();
      final key = '${difficultyLevel.name}_${category.name}';
      final questionsList = allQuestions[key];

      if (questionsList != null) {
        return questionsList.map((q) => AIQuestion.fromJson(q)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached AI questions: $e');
      }
    }

    return [];
  }

  /// Load all cached questions
  Future<Map<String, dynamic>> _loadAllCachedQuestions() async {
    try {
      final questionsJson = _prefs.getString(_aiQuestionsKey);
      if (questionsJson == null) return {};
      return Map<String, dynamic>.from(jsonDecode(questionsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached questions: $e');
      }
      return {};
    }
  }

  /// Save user progress
  Future<void> saveUserProgress({
    required String userId,
    required Map<String, dynamic> progress,
  }) async {
    try {
      final key = '$_userProgressKey$userId';
      await _prefs.setString(key, jsonEncode(progress));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user progress: $e');
      }
    }
  }

  /// Get user progress
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    try {
      final key = '$_userProgressKey$userId';
      final progressJson = _prefs.getString(key);

      if (progressJson != null) {
        return Map<String, dynamic>.from(jsonDecode(progressJson));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user progress: $e');
      }
    }

    return {};
  }

  /// Save learning analytics
  Future<void> saveLearningAnalytics({
    required String userId,
    required Map<String, dynamic> analytics,
  }) async {
    try {
      final key = '$_learningAnalyticsKey$userId';
      await _prefs.setString(key, jsonEncode(analytics));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving learning analytics: $e');
      }
    }
  }

  /// Get learning analytics
  Future<Map<String, dynamic>> getLearningAnalytics(String userId) async {
    try {
      final key = '$_learningAnalyticsKey$userId';
      final analyticsJson = _prefs.getString(key);

      if (analyticsJson != null) {
        return Map<String, dynamic>.from(jsonDecode(analyticsJson));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting learning analytics: $e');
      }
    }

    return {};
  }
}

/// Riverpod provider for AI Native Game Service
final aiNativeGameServiceProvider = Provider<AINativeGameService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final chatGPTService = ref.watch(chatGPTServiceProvider);
  return AINativeGameService(prefs, chatGPTService);
});

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences should be initialized in main.dart',
  );
});
