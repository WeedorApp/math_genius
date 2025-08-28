import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';

// Models
import '../models/game_model.dart';

/// AI-powered game service for Math Genius
class GameService {
  static const String _gameSessionsKey = 'game_sessions';
  static const String _gameResultsKey = 'game_results';
  static const String _cachedQuestionsKey = 'cached_questions';
  static const String _userProgressKey = 'user_progress';
  static const String _aiQuestionsKey = 'ai_questions';

  final SharedPreferences _prefs;
  final Box? _hiveBox;

  GameService(this._prefs, this._hiveBox);

  /// Generate AI-powered questions for a specific grade and category
  Future<List<AIQuestion>> generateAIQuestions({
    required GradeLevel gradeLevel,
    required GameCategory category,
    required GameDifficulty difficulty,
    required int count,
    String? userId,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Try to get cached AI questions first
      final cachedQuestions = await _getCachedAIQuestions(
        gradeLevel,
        category,
        difficulty,
      );

      // Only use cache if we have enough questions
      if (cachedQuestions.length >= count) {
        return cachedQuestions.take(count).toList();
      }

      // Generate new AI-powered questions
      final questions = await _generateAIQuestionsForGrade(
        gradeLevel,
        category,
        difficulty,
        count,
        userId,
        userContext,
      );

      // Cache the AI questions
      await _cacheAIQuestions(gradeLevel, category, difficulty, questions);

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating AI questions: $e');
      }
      return [];
    }
  }

  /// Create a new AI-powered game session
  Future<GameSession> createAIGameSession({
    required String name,
    required GradeLevel gradeLevel,
    required GameDifficulty difficulty,
    required GameCategory category,
    required List<GamePlayer> players,
    int? questionCount,
    int timeLimit = 600,
    String? userId,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Use the provided question count, or fallback to dynamic count
      final finalQuestionCount =
          questionCount ?? _getDynamicQuestionCount(gradeLevel, difficulty);

      final questions = await generateAIQuestions(
        gradeLevel: gradeLevel,
        category: category,
        difficulty: difficulty,
        count: finalQuestionCount,
        userId: userId,
        userContext: userContext,
      );

      // Ensure we have the correct number of questions
      if (kDebugMode) {
        print('Requested questions: $finalQuestionCount');
        print('Generated questions: ${questions.length}');
      }

      if (questions.length != finalQuestionCount) {
        if (kDebugMode) {
          print(
            'Warning: Generated ${questions.length} questions, expected $finalQuestionCount',
          );
        }
      }

      // Convert AI questions to game questions for compatibility
      final gameQuestions = questions
          .map(
            (aiQ) => GameQuestion(
              id: aiQ.id,
              question: aiQ.question,
              options: aiQ.options,
              correctAnswer: aiQ.correctAnswer,
              category: aiQ.category,
              difficulty: aiQ.difficulty,
              gradeLevel: aiQ.gradeLevel,
              explanation: aiQ.explanation,
              hint: aiQ.hint,
              timeLimit: aiQ.timeLimit,
              aiMetadata: aiQ.aiMetadata,
              confidence: aiQ.confidence,
              learningObjectives: aiQ.learningObjectives,
              visualAid: aiQ.visualAid,
            ),
          )
          .toList();

      final session = GameSession(
        id: _generateId(),
        name: name,
        difficulty: difficulty,
        category: category,
        questions: gameQuestions,
        players: players,
        createdAt: DateTime.now(),
        totalQuestions: finalQuestionCount, // Use the expected count
        timeLimit: timeLimit,
      );

      await _saveGameSession(session);
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating AI game session: $e');
      }
      rethrow;
    }
  }

  /// Get dynamic question count based on grade and difficulty
  int _getDynamicQuestionCount(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
  ) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return difficulty == GameDifficulty.easy ? 5 : 3;
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        return difficulty == GameDifficulty.easy ? 8 : 6;
      case GradeLevel.grade3:
      case GradeLevel.grade4:
        return difficulty == GameDifficulty.easy ? 10 : 8;
      case GradeLevel.grade5:
      case GradeLevel.grade6:
        return difficulty == GameDifficulty.easy ? 12 : 10;
      case GradeLevel.grade7:
      case GradeLevel.grade8:
        return difficulty == GameDifficulty.easy ? 15 : 12;
      case GradeLevel.grade9:
      case GradeLevel.grade10:
        return difficulty == GameDifficulty.easy ? 18 : 15;
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        return difficulty == GameDifficulty.easy ? 20 : 18;
    }
  }

  /// Join an existing game session
  Future<GameSession?> joinGameSession(
    String sessionId,
    GamePlayer player,
  ) async {
    try {
      final session = await getGameSession(sessionId);
      if (session == null) return null;

      final updatedPlayers = List<GamePlayer>.from(session.players);
      updatedPlayers.add(player);

      final updatedSession = session.copyWith(players: updatedPlayers);
      await _saveGameSession(updatedSession);

      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error joining game session: $e');
      }
      return null;
    }
  }

  /// Start a game session
  Future<GameSession?> startGameSession(String sessionId) async {
    try {
      final session = await getGameSession(sessionId);
      if (session == null) return null;

      final updatedSession = session.copyWith(
        status: GameStatus.active,
        startedAt: DateTime.now(),
      );

      await _saveGameSession(updatedSession);
      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting game session: $e');
      }
      return null;
    }
  }

  /// Submit an answer for a question
  Future<bool> submitAnswer(
    String sessionId,
    String playerId,
    String questionId,
    int answer,
    Duration timeSpent,
  ) async {
    try {
      final session = await getGameSession(sessionId);
      if (session == null) return false;

      final question = session.questions.firstWhere((q) => q.id == questionId);
      final isCorrect = answer == question.correctAnswer;

      // Update player score
      final updatedPlayers = session.players.map((player) {
        if (player.id == playerId) {
          return player.copyWith(
            score: player.score + (isCorrect ? 10 : 0),
            correctAnswers: player.correctAnswers + (isCorrect ? 1 : 0),
            totalQuestions: player.totalQuestions + 1,
            lastActive: DateTime.now(),
          );
        }
        return player;
      }).toList();

      final updatedSession = session.copyWith(players: updatedPlayers);
      await _saveGameSession(updatedSession);

      return isCorrect;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting answer: $e');
      }
      return false;
    }
  }

  /// End a game session
  Future<GameSession?> endGameSession(String sessionId) async {
    try {
      final session = await getGameSession(sessionId);
      if (session == null) return null;

      final updatedSession = session.copyWith(
        status: GameStatus.completed,
        endedAt: DateTime.now(),
      );

      await _saveGameSession(updatedSession);

      // Save game results
      await _saveGameResults(sessionId, updatedSession);

      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error ending game session: $e');
      }
      return null;
    }
  }

  /// Get game session by ID
  Future<GameSession?> getGameSession(String sessionId) async {
    try {
      final sessions = await getAllGameSessions();
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting game session: $e');
      }
      return null;
    }
  }

  /// Get all game sessions
  Future<List<GameSession>> getAllGameSessions() async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final sessionsData = _hiveBox.get(_gameSessionsKey);
        if (sessionsData != null) {
          final sessionsList = jsonDecode(sessionsData as String) as List;
          return sessionsList
              .map(
                (session) =>
                    GameSession.fromJson(session as Map<String, dynamic>),
              )
              .toList();
        }
      }

      // Fallback to SharedPreferences
      final sessionsString = _prefs.getString(_gameSessionsKey);
      if (sessionsString == null) return [];

      final sessionsList = jsonDecode(sessionsString) as List;
      return sessionsList
          .map(
            (session) => GameSession.fromJson(session as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all game sessions: $e');
      }
      return [];
    }
  }

  /// Get game results for a session
  Future<List<GameResult>> getGameResults(String sessionId) async {
    try {
      final resultsString = _prefs.getString('${_gameResultsKey}_$sessionId');
      if (resultsString == null) return [];

      final resultsList = jsonDecode(resultsString) as List;
      return resultsList
          .map((result) => GameResult.fromJson(result as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting game results: $e');
      }
      return [];
    }
  }

  /// Get leaderboard for a session
  Future<List<GamePlayer>> getLeaderboard(String sessionId) async {
    try {
      final session = await getGameSession(sessionId);
      if (session == null) return [];

      final sortedPlayers = List<GamePlayer>.from(session.players);
      sortedPlayers.sort((a, b) => b.score.compareTo(a.score));
      return sortedPlayers;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting leaderboard: $e');
      }
      return [];
    }
  }

  /// Generate AI questions for a specific grade
  Future<List<AIQuestion>> _generateAIQuestionsForGrade(
    GradeLevel gradeLevel,
    GameCategory category,
    GameDifficulty difficulty,
    int count,
    String? userId,
    Map<String, dynamic>? userContext,
  ) async {
    final questions = <AIQuestion>[];
    final random = Random();

    if (kDebugMode) {
      print(
        'Generating $count questions for grade: ${gradeLevel.name}, category: ${category.name}',
      );
    }

    for (int i = 0; i < count; i++) {
      final question = await _generateAISingleQuestion(
        gradeLevel,
        category,
        difficulty,
        random,
        userId,
        userContext,
      );
      questions.add(question);

      if (kDebugMode) {
        print('Generated question ${i + 1}/$count: ${question.question}');
      }
    }

    if (kDebugMode) {
      print('Successfully generated ${questions.length} questions');
    }

    return questions;
  }

  /// Generate a single AI-powered question with maximum unpredictability
  Future<AIQuestion> _generateAISingleQuestion(
    GradeLevel gradeLevel,
    GameCategory category,
    GameDifficulty difficulty,
    Random random,
    String? userId,
    Map<String, dynamic>? userContext,
  ) async {
    // Get user's learning progress for personalization
    final userProgress = await _getUserProgress(userId);

    // Update user progress with current session data
    if (userId != null && userProgress != null) {
      final updatedProgress = Map<String, dynamic>.from(userProgress);
      updatedProgress['lastQuestionGenerated'] = DateTime.now()
          .toIso8601String();
      updatedProgress['totalQuestionsGenerated'] =
          (updatedProgress['totalQuestionsGenerated'] ?? 0) + 1;
      await _updateUserProgress(userId, updatedProgress);
    }

    // Add randomization to question generation order
    final questionTypes = [
      GameCategory.addition,
      GameCategory.subtraction,
      GameCategory.multiplication,
      GameCategory.division,
      GameCategory.algebra,
      GameCategory.geometry,
      GameCategory.calculus,
    ];

    // Randomly select category if not specified, or use provided category
    final selectedCategory =
        category == GameCategory.addition && random.nextBool()
        ? questionTypes[random.nextInt(questionTypes.length)]
        : category;

    // Generate question based on category and grade
    switch (selectedCategory) {
      case GameCategory.addition:
        return await _generateGradeAppropriateAdditionQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.subtraction:
        return _generateGradeAppropriateSubtractionQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.multiplication:
        return _generateGradeAppropriateMultiplicationQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.division:
        return _generateGradeAppropriateDivisionQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.fractions:
        return _generateGradeAppropriateFractionsQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.decimals:
        return _generateGradeAppropriateDecimalsQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.percentages:
        return _generateGradeAppropriatePercentagesQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.algebra:
        return _generateGradeAppropriateAlgebraQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.geometry:
        return _generateGradeAppropriateGeometryQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.calculus:
        return _generateGradeAppropriateCalculusQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.wordProblems:
        return _generateGradeAppropriateWordProblemsQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.patterns:
        return _generateGradeAppropriatePatternsQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.measurement:
        return _generateGradeAppropriateMeasurementQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
      case GameCategory.dataAnalysis:
        return _generateGradeAppropriateDataAnalysisQuestion(
          gradeLevel,
          difficulty,
          random,
          userProgress,
        );
    }
  }

  /// Generate grade-appropriate addition question
  Future<AIQuestion> _generateGradeAppropriateAdditionQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) async {
    int a, b, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = random.nextInt(5) + 1;
        b = random.nextInt(5) + 1;
        question = '🍎 + 🍎 = ?\nHow many apples in total?';
        hint = 'Count the apples together: 1, 2, 3...';
        learningObjectives = ['Basic counting', 'Number recognition'];
        break;
      case GradeLevel.grade1:
        a = random.nextInt(10) + 1;
        b = random.nextInt(10) + 1;
        question = '🍬 + 🍬 = ?\nWhat is $a + $b?';
        hint = 'Use your fingers to count: $a + $b';
        learningObjectives = ['Single-digit addition', 'Counting strategies'];
        break;
      case GradeLevel.grade2:
        a = random.nextInt(20) + 10;
        b = random.nextInt(20) + 10;
        question = '🎈 + 🎈 = ?\nWhat is $a + $b?';
        hint = 'Break it down: $a = 10 + ${a - 10}';
        learningObjectives = ['Two-digit addition', 'Place value'];
        break;
      case GradeLevel.grade3:
        a = random.nextInt(100) + 50;
        b = random.nextInt(100) + 50;
        question = 'What is $a + $b?';
        hint = 'Add the ones first, then the tens';
        learningObjectives = ['Three-digit addition', 'Regrouping'];
        break;
      case GradeLevel.grade4:
        a = random.nextInt(1000) + 500;
        b = random.nextInt(1000) + 500;
        question = 'What is $a + $b?';
        hint = 'Line up the numbers by place value';
        learningObjectives = ['Multi-digit addition', 'Place value'];
        break;
      case GradeLevel.grade5:
        a = random.nextInt(10000) + 5000;
        b = random.nextInt(10000) + 5000;
        question = 'What is $a + $b?';
        hint = 'Use the standard algorithm';
        learningObjectives = ['Large number addition', 'Estimation'];
        break;
      default:
        a = random.nextInt(100000) + 50000;
        b = random.nextInt(100000) + 50000;
        question = 'What is $a + $b?';
        hint = 'Use mental math strategies';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = a + b;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    final aiQuestion = AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.addition,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: '$a + $b = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_addition',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );

    // Save AI question metadata
    await _saveAIQuestionsMetadata(aiQuestion.id, aiQuestion.aiMetadata);

    return aiQuestion;
  }

  /// Generate grade-appropriate subtraction question
  AIQuestion _generateGradeAppropriateSubtractionQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int a, b, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = random.nextInt(5) + 1;
        b = random.nextInt(a) + 1;
        question = '🍎 - 🍎 = ?\nHow many apples are left?';
        hint = 'Count the apples: $a - $b = ?';
        learningObjectives = ['Basic counting', 'Number recognition'];
        break;
      case GradeLevel.grade1:
        a = random.nextInt(10) + 1;
        b = random.nextInt(a) + 1;
        question = '🍪 - 🍪 = ?\nWhat is $a - $b?';
        hint = 'Use your fingers to count: $a - $b';
        learningObjectives = [
          'Single-digit subtraction',
          'Counting strategies',
        ];
        break;
      case GradeLevel.grade2:
        a = random.nextInt(20) + 10;
        b = random.nextInt(a) + 10;
        question = '🎈 - 🎈 = ?\nWhat is $a - $b?';
        hint = 'Break it down: $a = 10 + ${a - 10}';
        learningObjectives = ['Two-digit subtraction', 'Place value'];
        break;
      case GradeLevel.grade3:
        a = random.nextInt(100) + 50;
        b = random.nextInt(a) + 50;
        question = 'What is $a - $b?';
        hint = 'Subtract the ones first, then the tens';
        learningObjectives = ['Three-digit subtraction', 'Regrouping'];
        break;
      case GradeLevel.grade4:
        a = random.nextInt(1000) + 500;
        b = random.nextInt(a) + 500;
        question = 'What is $a - $b?';
        hint = 'Line up the numbers by place value';
        learningObjectives = ['Multi-digit subtraction', 'Place value'];
        break;
      case GradeLevel.grade5:
        a = random.nextInt(10000) + 5000;
        b = random.nextInt(a) + 5000;
        question = 'What is $a - $b?';
        hint = 'Use the standard algorithm';
        learningObjectives = ['Large number subtraction', 'Estimation'];
        break;
      default:
        a = random.nextInt(100000) + 50000;
        b = random.nextInt(a) + 50000;
        question = 'What is $a - $b?';
        hint = 'Use mental math strategies';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = a - b;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.subtraction,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: '$a - $b = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_subtraction',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate multiplication question
  AIQuestion _generateGradeAppropriateMultiplicationQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int a, b, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = random.nextInt(5) + 1;
        b = random.nextInt(5) + 1;
        question = '🍎 × 🍎 = ?\nHow many apples in groups?';
        hint = 'Count the apples in groups: $a groups of $b';
        learningObjectives = ['Basic counting', 'Number recognition'];
        break;
      case GradeLevel.grade1:
        a = random.nextInt(10) + 1;
        b = random.nextInt(10) + 1;
        question = '🍬 × 🍬 = ?\nWhat is $a × $b?';
        hint = 'Use your fingers to count: $a groups of $b';
        learningObjectives = [
          'Single-digit multiplication',
          'Counting strategies',
        ];
        break;
      case GradeLevel.grade2:
        a = random.nextInt(20) + 5;
        b = random.nextInt(20) + 5;
        question = '🎈 × 🎈 = ?\nWhat is $a × $b?';
        hint = 'Break it down: $a = 10 + ${a - 10}';
        learningObjectives = ['Two-digit multiplication', 'Place value'];
        break;
      case GradeLevel.grade3:
        a = random.nextInt(50) + 10;
        b = random.nextInt(50) + 10;
        question = 'What is $a × $b?';
        hint = 'Add the ones first, then the tens';
        learningObjectives = ['Three-digit multiplication', 'Regrouping'];
        break;
      case GradeLevel.grade4:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        question = 'What is $a × $b?';
        hint = 'Line up the numbers by place value';
        learningObjectives = ['Multi-digit multiplication', 'Place value'];
        break;
      case GradeLevel.grade5:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        question = 'What is $a × $b?';
        hint = 'Use the standard algorithm';
        learningObjectives = ['Large number multiplication', 'Estimation'];
        break;
      default:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        question = 'What is $a × $b?';
        hint = 'Use mental math strategies';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = a * b;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.multiplication,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: '$a × $b = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_multiplication',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate division question
  AIQuestion _generateGradeAppropriateDivisionQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int a, b, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        b = random.nextInt(5) + 2;
        a = b * (random.nextInt(5) + 1);
        question = '🍎 ÷ 🍎 = ?\nHow many apples in each group?';
        hint = 'Share the apples equally: $a apples ÷ $b groups';
        learningObjectives = ['Basic counting', 'Number recognition'];
        break;
      case GradeLevel.grade1:
        b = random.nextInt(10) + 2;
        a = b * (random.nextInt(10) + 1);
        question = '🍪 ÷ 🍪 = ?\nWhat is $a ÷ $b?';
        hint = 'Use your fingers to count: $a ÷ $b';
        learningObjectives = ['Single-digit division', 'Counting strategies'];
        break;
      case GradeLevel.grade2:
        b = random.nextInt(20) + 2;
        a = b * (random.nextInt(20) + 1);
        question = '🎈 ÷ 🎈 = ?\nWhat is $a ÷ $b?';
        hint = 'Break it down: $a = 10 + ${a - 10}';
        learningObjectives = ['Two-digit division', 'Place value'];
        break;
      case GradeLevel.grade3:
        b = random.nextInt(50) + 5;
        a = b * (random.nextInt(50) + 1);
        question = 'What is $a ÷ $b?';
        hint = 'Subtract the ones first, then the tens';
        learningObjectives = ['Three-digit division', 'Regrouping'];
        break;
      case GradeLevel.grade4:
        b = random.nextInt(100) + 5;
        a = b * (random.nextInt(100) + 1);
        question = 'What is $a ÷ $b?';
        hint = 'Line up the numbers by place value';
        learningObjectives = ['Multi-digit division', 'Place value'];
        break;
      case GradeLevel.grade5:
        b = random.nextInt(100) + 10;
        a = b * (random.nextInt(100) + 1);
        question = 'What is $a ÷ $b?';
        hint = 'Use the standard algorithm';
        learningObjectives = ['Large number division', 'Estimation'];
        break;
      default:
        b = random.nextInt(50) + 10;
        a = b * (random.nextInt(50) + 1);
        question = 'What is $a ÷ $b?';
        hint = 'Use mental math strategies';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = a ~/ b;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.division,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: '$a ÷ $b = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_division',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate algebra question
  AIQuestion _generateGradeAppropriateAlgebraQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    // Simple algebra questions
    int a, b, x, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = random.nextInt(5) + 1;
        b = random.nextInt(10) + 1;
        x = random.nextInt(5) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Basic algebra', 'Solving equations'];
        break;
      case GradeLevel.grade1:
        a = random.nextInt(10) + 2;
        b = random.nextInt(20) + 5;
        x = random.nextInt(10) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Single-digit algebra', 'Solving equations'];
        break;
      case GradeLevel.grade2:
        a = random.nextInt(20) + 5;
        b = random.nextInt(50) + 10;
        x = random.nextInt(20) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Two-digit algebra', 'Solving equations'];
        break;
      case GradeLevel.grade3:
        a = random.nextInt(50) + 10;
        b = random.nextInt(100) + 20;
        x = random.nextInt(50) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Three-digit algebra', 'Solving equations'];
        break;
      case GradeLevel.grade4:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        x = random.nextInt(100) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Multi-digit algebra', 'Solving equations'];
        break;
      case GradeLevel.grade5:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        x = random.nextInt(100) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Large number algebra', 'Solving equations'];
        break;
      default:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        x = random.nextInt(100) + 1;
        question = 'If $a × x + $b = ?';
        hint = 'Solve for x';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = a * x + b;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(x.toString()),
      category: GameCategory.algebra,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: 'x = ${correctAnswer - b} ÷ $a = $x',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_algebra',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate geometry question
  AIQuestion _generateGradeAppropriateGeometryQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    // Simple geometry questions
    int side, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        side = random.nextInt(10) + 1;
        question = 'How many apples? 🍎 × 🍎 = ?';
        hint = 'Count the apples together';
        learningObjectives = ['Basic counting', 'Number recognition'];
        break;
      case GradeLevel.grade1:
        side = random.nextInt(20) + 5;
        question = 'What is the area of the square? 🟦 = ?';
        hint = 'Measure the side';
        learningObjectives = ['Single-digit geometry', 'Area'];
        break;
      case GradeLevel.grade2:
        side = random.nextInt(50) + 10;
        question = 'What is the area of the rectangle? 🟨 = ?';
        hint = 'Measure the sides';
        learningObjectives = ['Two-digit geometry', 'Area'];
        break;
      case GradeLevel.grade3:
        side = random.nextInt(100) + 50;
        question = 'What is the area of the triangle? 🟪 = ?';
        hint = 'Measure the base and height';
        learningObjectives = ['Three-digit geometry', 'Area'];
        break;
      case GradeLevel.grade4:
        side = random.nextInt(1000) + 500;
        question = 'What is the area of the circle? 🟧 = ?';
        hint = 'Measure the radius';
        learningObjectives = ['Multi-digit geometry', 'Area'];
        break;
      case GradeLevel.grade5:
        side = random.nextInt(10000) + 5000;
        question = 'What is the area of the sphere? 🟦 = ?';
        hint = 'Measure the radius';
        learningObjectives = ['Large number geometry', 'Area'];
        break;
      default:
        side = random.nextInt(100000) + 50000;
        question = 'What is the area of the cube? 🟦 = ?';
        hint = 'Measure the side';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = side * side;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.geometry,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: 'Area = side² = $side² = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_geometry',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate calculus question
  AIQuestion _generateGradeAppropriateCalculusQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    // Simple calculus questions (derivatives)
    int a, b, x, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = random.nextInt(5) + 1;
        b = random.nextInt(10) + 1;
        x = random.nextInt(5) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Basic calculus', 'Derivatives'];
        break;
      case GradeLevel.grade1:
        a = random.nextInt(10) + 2;
        b = random.nextInt(20) + 5;
        x = random.nextInt(10) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Single-digit calculus', 'Derivatives'];
        break;
      case GradeLevel.grade2:
        a = random.nextInt(20) + 5;
        b = random.nextInt(50) + 10;
        x = random.nextInt(20) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Two-digit calculus', 'Derivatives'];
        break;
      case GradeLevel.grade3:
        a = random.nextInt(50) + 10;
        b = random.nextInt(100) + 20;
        x = random.nextInt(50) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Three-digit calculus', 'Derivatives'];
        break;
      case GradeLevel.grade4:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        x = random.nextInt(100) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Multi-digit calculus', 'Derivatives'];
        break;
      case GradeLevel.grade5:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        x = random.nextInt(100) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Large number calculus', 'Derivatives'];
        break;
      default:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        x = random.nextInt(100) + 1;
        question = 'What is the derivative of ${a}x² + ${b}x at x = ?';
        hint = 'Find the derivative';
        learningObjectives = ['Mental math', 'Number sense'];
    }

    correctAnswer = 2 * a * x + b;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.calculus,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: 'Derivative = 2${a}x + $b = 2×$a×$x + $b = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_calculus',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate options with unpredictable placement
  List<String> _generateGradeAppropriateOptions(
    int correctAnswer,
    Random random,
    GradeLevel gradeLevel,
  ) {
    final options = <String>[];
    final correctAnswerString = correctAnswer.toString();

    // Generate wrong options based on grade level with more variety
    final wrongOptions = <String>{};

    while (wrongOptions.length < 3) {
      int wrongAnswer = correctAnswer; // Initialize with default value

      // Use multiple strategies to generate wrong answers
      final strategy = random.nextInt(4);

      switch (strategy) {
        case 0:
          // Add/subtract small random numbers
          wrongAnswer = correctAnswer + random.nextInt(20) - 10;
          break;
        case 1:
          // Multiply/divide by small factors
          final factor = random.nextBool()
              ? random.nextInt(3) + 1
              : 1 / (random.nextInt(3) + 1);
          wrongAnswer = (correctAnswer * factor).round();
          break;
        case 2:
          // Use similar digits but different arrangement
          final digits = correctAnswer.toString().split('');
          digits.shuffle(random);
          wrongAnswer =
              int.tryParse(digits.join()) ?? correctAnswer + random.nextInt(10);
          break;
        case 3:
          // Completely random within reasonable range
          final range =
              gradeLevel == GradeLevel.preK ||
                  gradeLevel == GradeLevel.kindergarten
              ? 10
              : 50;
          wrongAnswer = correctAnswer + random.nextInt(range * 2) - range;
          break;
      }

      // Ensure wrong answer is different and positive
      if (wrongAnswer != correctAnswer &&
          wrongAnswer > 0 &&
          !wrongOptions.contains(wrongAnswer.toString()) &&
          wrongAnswer.toString() != correctAnswerString) {
        wrongOptions.add(wrongAnswer.toString());
      }
    }

    // Add all options to the list
    options.addAll(wrongOptions);
    options.add(correctAnswerString);

    // Shuffle multiple times for maximum unpredictability
    for (int i = 0; i < 3; i++) {
      options.shuffle(random);
    }

    // Additional randomization: sometimes swap adjacent options
    if (random.nextBool()) {
      for (int i = 0; i < options.length - 1; i++) {
        if (random.nextBool()) {
          final temp = options[i];
          options[i] = options[i + 1];
          options[i + 1] = temp;
        }
      }
    }

    return options;
  }

  /// Get grade-appropriate time limit
  int _getGradeAppropriateTimeLimit(GradeLevel gradeLevel) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return 45; // More time for young learners
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        return 40;
      case GradeLevel.grade3:
      case GradeLevel.grade4:
        return 35;
      case GradeLevel.grade5:
      case GradeLevel.grade6:
        return 30;
      default:
        return 25; // Less time for older students
    }
  }

  /// Get user progress for personalization
  Future<Map<String, dynamic>?> _getUserProgress(String? userId) async {
    if (userId == null) return null;

    try {
      final progressString = _prefs.getString('${_userProgressKey}_$userId');
      if (progressString == null) return null;

      return Map<String, dynamic>.from(jsonDecode(progressString));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user progress: $e');
      }
      return null;
    }
  }

  /// Update user progress after question generation
  Future<void> _updateUserProgress(
    String? userId,
    Map<String, dynamic> progress,
  ) async {
    if (userId == null) return;
    await _saveUserProgress(userId, progress);
  }

  /// Save user progress
  Future<void> _saveUserProgress(
    String userId,
    Map<String, dynamic> progress,
  ) async {
    try {
      await _prefs.setString(
        '${_userProgressKey}_$userId',
        jsonEncode(progress),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user progress: $e');
      }
    }
  }

  /// Get cached AI questions
  Future<List<AIQuestion>> _getCachedAIQuestions(
    GradeLevel gradeLevel,
    GameCategory category,
    GameDifficulty difficulty,
  ) async {
    try {
      final allQuestions = await _loadAllCachedQuestions();
      final key = '${gradeLevel.name}_${category.name}_${difficulty.name}';
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

  /// Cache AI questions
  Future<void> _cacheAIQuestions(
    GradeLevel gradeLevel,
    GameCategory category,
    GameDifficulty difficulty,
    List<AIQuestion> questions,
  ) async {
    try {
      final allQuestions = await _loadAllCachedQuestions();
      final key = '${gradeLevel.name}_${category.name}_${difficulty.name}';
      allQuestions[key] = questions.map((q) => q.toJson()).toList();
      await _prefs.setString(_cachedQuestionsKey, jsonEncode(allQuestions));
    } catch (e) {
      if (kDebugMode) {
        print('Error caching AI questions: $e');
      }
    }
  }

  /// Load all cached questions
  Future<Map<String, dynamic>> _loadAllCachedQuestions() async {
    try {
      final questionsJson = _prefs.getString(_cachedQuestionsKey);
      if (questionsJson == null) return {};
      return Map<String, dynamic>.from(jsonDecode(questionsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached questions: $e');
      }
      return {};
    }
  }

  /// Save AI questions metadata
  Future<void> _saveAIQuestionsMetadata(
    String questionId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final allMetadata = await _loadAllAIQuestionsMetadata();
      allMetadata[questionId] = metadata;
      await _prefs.setString(_aiQuestionsKey, jsonEncode(allMetadata));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving AI questions metadata: $e');
      }
    }
  }

  /// Load all AI questions metadata
  Future<Map<String, dynamic>> _loadAllAIQuestionsMetadata() async {
    try {
      final metadataJson = _prefs.getString(_aiQuestionsKey);
      if (metadataJson == null) return {};
      return Map<String, dynamic>.from(jsonDecode(metadataJson));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading AI questions metadata: $e');
      }
      return {};
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  /// Save game session
  Future<void> _saveGameSession(GameSession session) async {
    try {
      final sessions = await getAllGameSessions();
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);

      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      final sessionsJson = jsonEncode(sessions.map((s) => s.toJson()).toList());

      // Save to both Hive and SharedPreferences for redundancy
      if (_hiveBox != null) {
        await _hiveBox.put(_gameSessionsKey, sessionsJson);
      }
      await _prefs.setString(_gameSessionsKey, sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game session: $e');
      }
    }
  }

  /// Save game results
  Future<void> _saveGameResults(String sessionId, GameSession session) async {
    try {
      for (final player in session.players) {
        final result = GameResult(
          id: _generateId(),
          sessionId: sessionId,
          playerId: player.id,
          score: player.score,
          correctAnswers: player.correctAnswers,
          totalQuestions: player.totalQuestions,
          accuracy: player.totalQuestions > 0
              ? player.correctAnswers / player.totalQuestions
              : 0.0,
          timeSpent: session.startedAt != null && session.endedAt != null
              ? session.endedAt!.difference(session.startedAt!)
              : Duration.zero,
          completedAt: DateTime.now(),
          answers: [], // todo: Track individual answers
        );

        final results = await getGameResults(sessionId);
        results.add(result);

        await _prefs.setString(
          '${_gameResultsKey}_$sessionId',
          jsonEncode(results.map((r) => r.toJson()).toList()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game results: $e');
      }
    }
  }

  /// Generate grade-appropriate fractions question
  AIQuestion _generateGradeAppropriateFractionsQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int numerator, denominator, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        numerator = random.nextInt(3) + 1;
        denominator = random.nextInt(3) + 2;
        question = '🍕 $numerator/$denominator\nHow many pizza slices?';
        hint = 'Count the colored slices: $numerator out of $denominator';
        learningObjectives = ['Basic fractions', 'Part-whole relationships'];
        break;
      case GradeLevel.grade1:
        numerator = random.nextInt(5) + 1;
        denominator = random.nextInt(5) + 2;
        question =
            '🍰 $numerator/$denominator\nWhat is $numerator/$denominator?';
        hint = 'Count the parts of the whole cake';
        learningObjectives = ['Simple fractions', 'Visual representation'];
        break;
      case GradeLevel.grade2:
        numerator = random.nextInt(8) + 1;
        denominator = random.nextInt(8) + 2;
        question =
            '🍪 $numerator/$denominator\nWhat is $numerator/$denominator?';
        hint = 'Divide the numerator by denominator';
        learningObjectives = ['Fraction concepts', 'Division relationship'];
        break;
      case GradeLevel.grade3:
        numerator = random.nextInt(10) + 1;
        denominator = random.nextInt(10) + 2;
        question = 'What is $numerator/$denominator?';
        hint = 'Use division: $numerator ÷ $denominator';
        learningObjectives = ['Fraction operations', 'Decimal conversion'];
        break;
      case GradeLevel.grade4:
        numerator = random.nextInt(15) + 1;
        denominator = random.nextInt(15) + 2;
        question = 'What is $numerator/$denominator?';
        hint = 'Convert to decimal or percentage';
        learningObjectives = [
          'Fraction simplification',
          'Equivalent fractions',
        ];
        break;
      case GradeLevel.grade5:
        numerator = random.nextInt(20) + 1;
        denominator = random.nextInt(20) + 2;
        question = 'What is $numerator/$denominator?';
        hint = 'Simplify if possible, then convert';
        learningObjectives = ['Complex fractions', 'Fraction arithmetic'];
        break;
      default:
        numerator = random.nextInt(25) + 1;
        denominator = random.nextInt(25) + 2;
        question = 'What is $numerator/$denominator?';
        hint = 'Use advanced fraction techniques';
        learningObjectives = ['Advanced fractions', 'Algebraic fractions'];
    }

    correctAnswer = (numerator / denominator * 100).round();
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options.map((e) => '$e%').toList(),
      correctAnswer: options.indexOf('$correctAnswer%'),
      category: GameCategory.fractions,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation:
          '$numerator/$denominator = ${(numerator / denominator * 100).round()}%',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_fractions',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate decimals question
  AIQuestion _generateGradeAppropriateDecimalsQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    double a, b;
    int correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = (random.nextInt(5) + 1) / 10.0;
        b = (random.nextInt(5) + 1) / 10.0;
        question =
            '💰 \$${a.toStringAsFixed(1)} + \$${b.toStringAsFixed(1)}\nHow much money?';
        hint =
            'Add the cents together: ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)}';
        learningObjectives = ['Basic decimals', 'Money concepts'];
        break;
      case GradeLevel.grade1:
        a = (random.nextInt(10) + 1) / 10.0;
        b = (random.nextInt(10) + 1) / 10.0;
        question =
            '🪙 ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)}\nWhat is ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)}?';
        hint = 'Add the tenths place first';
        learningObjectives = ['Decimal addition', 'Place value'];
        break;
      case GradeLevel.grade2:
        a = (random.nextInt(20) + 10) / 10.0;
        b = (random.nextInt(20) + 10) / 10.0;
        question =
            '💵 ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)}\nWhat is ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)}?';
        hint = 'Line up the decimal points';
        learningObjectives = ['Decimal operations', 'Place value'];
        break;
      case GradeLevel.grade3:
        a = (random.nextInt(100) + 50) / 100.0;
        b = (random.nextInt(100) + 50) / 100.0;
        question = 'What is ${a.toStringAsFixed(2)} + ${b.toStringAsFixed(2)}?';
        hint = 'Add hundredths, then tenths';
        learningObjectives = ['Hundredths', 'Decimal precision'];
        break;
      case GradeLevel.grade4:
        a = (random.nextInt(1000) + 500) / 1000.0;
        b = (random.nextInt(1000) + 500) / 1000.0;
        question = 'What is ${a.toStringAsFixed(3)} + ${b.toStringAsFixed(3)}?';
        hint = 'Add thousandths, then hundredths';
        learningObjectives = ['Thousandths', 'Decimal precision'];
        break;
      case GradeLevel.grade5:
        a = (random.nextInt(10000) + 5000) / 10000.0;
        b = (random.nextInt(10000) + 5000) / 10000.0;
        question = 'What is ${a.toStringAsFixed(4)} + ${b.toStringAsFixed(4)}?';
        hint = 'Use standard decimal addition';
        learningObjectives = ['Ten-thousandths', 'Decimal arithmetic'];
        break;
      default:
        a = (random.nextInt(100000) + 50000) / 100000.0;
        b = (random.nextInt(100000) + 50000) / 100000.0;
        question = 'What is ${a.toStringAsFixed(5)} + ${b.toStringAsFixed(5)}?';
        hint = 'Use mental math strategies';
        learningObjectives = ['Advanced decimals', 'Precision'];
    }

    correctAnswer = ((a + b) * 100).round();
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options
          .map((e) => (int.parse(e) / 100.0).toStringAsFixed(2))
          .toList(),
      correctAnswer: options.indexOf(((a + b) * 100).round().toString()),
      category: GameCategory.decimals,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation:
          '${a.toStringAsFixed(2)} + ${b.toStringAsFixed(2)} = ${(a + b).toStringAsFixed(2)}',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_decimals',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate percentages question
  AIQuestion _generateGradeAppropriatePercentagesQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int part, whole, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        part = random.nextInt(5) + 1;
        whole = random.nextInt(5) + 5;
        question = '🎨 $part out of $whole\nHow many are colored?';
        hint = 'Count the colored items: $part colored out of $whole total';
        learningObjectives = ['Basic percentages', 'Part-whole relationships'];
        break;
      case GradeLevel.grade1:
        part = random.nextInt(10) + 1;
        whole = random.nextInt(10) + 10;
        question =
            '🌈 $part out of $whole\nWhat percent is $part out of $whole?';
        hint = 'Divide part by whole, then multiply by 100';
        learningObjectives = ['Simple percentages', 'Division'];
        break;
      case GradeLevel.grade2:
        part = random.nextInt(20) + 5;
        whole = random.nextInt(20) + 20;
        question =
            '🎯 $part out of $whole\nWhat percent is $part out of $whole?';
        hint = 'Use the formula: (part ÷ whole) × 100';
        learningObjectives = ['Percentage calculation', 'Fractions'];
        break;
      case GradeLevel.grade3:
        part = random.nextInt(50) + 10;
        whole = random.nextInt(50) + 50;
        question = 'What percent is $part out of $whole?';
        hint = 'Convert to decimal first';
        learningObjectives = ['Decimal percentages', 'Conversion'];
        break;
      case GradeLevel.grade4:
        part = random.nextInt(100) + 20;
        whole = random.nextInt(100) + 100;
        question = 'What percent is $part out of $whole?';
        hint = 'Simplify the fraction first';
        learningObjectives = ['Complex percentages', 'Simplification'];
        break;
      case GradeLevel.grade5:
        part = random.nextInt(200) + 50;
        whole = random.nextInt(200) + 200;
        question = 'What percent is $part out of $whole?';
        hint = 'Use mental math strategies';
        learningObjectives = ['Advanced percentages', 'Mental math'];
        break;
      default:
        part = random.nextInt(500) + 100;
        whole = random.nextInt(500) + 500;
        question = 'What percent is $part out of $whole?';
        hint = 'Use calculator or estimation';
        learningObjectives = ['Complex percentages', 'Estimation'];
    }

    correctAnswer = (part / whole * 100).round();
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options.map((e) => '$e%').toList(),
      correctAnswer: options.indexOf('$correctAnswer%'),
      category: GameCategory.percentages,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: '$part/$whole = ${(part / whole * 100).round()}%',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_percentages',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate word problems question
  AIQuestion _generateGradeAppropriateWordProblemsQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int a, b, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        a = random.nextInt(5) + 1;
        b = random.nextInt(5) + 1;
        question =
            '🍎 Tom has $a apples\n🍎 He gets $b more\n🍎 How many does he have now?';
        hint = 'Add the numbers together: $a + $b';
        learningObjectives = ['Basic word problems', 'Addition'];
        break;
      case GradeLevel.grade1:
        a = random.nextInt(10) + 1;
        b = random.nextInt(10) + 1;
        question =
            '🍬 Sarah has $a candies\n🍬 She eats $b\n🍬 How many are left?';
        hint = 'Subtract the eaten candies: $a - $b';
        learningObjectives = ['Simple word problems', 'Subtraction'];
        break;
      case GradeLevel.grade2:
        a = random.nextInt(20) + 10;
        b = random.nextInt(10) + 1;
        question =
            '👥 A class has $a students\n👥 They are in groups of $b\n👥 How many groups?';
        hint = 'Divide total by group size: $a ÷ $b';
        learningObjectives = ['Division word problems', 'Grouping'];
        break;
      case GradeLevel.grade3:
        a = random.nextInt(50) + 20;
        b = random.nextInt(10) + 2;
        question =
            'A store has $a items. Each costs \$$b. What is the total cost? 💰';
        hint = 'Multiply items by price';
        learningObjectives = ['Multiplication word problems', 'Money'];
        break;
      case GradeLevel.grade4:
        a = random.nextInt(100) + 50;
        b = random.nextInt(20) + 5;
        question = 'A train travels $a km in $b hours. What is the speed? 🚂';
        hint = 'Divide distance by time';
        learningObjectives = ['Rate problems', 'Speed calculation'];
        break;
      case GradeLevel.grade5:
        a = random.nextInt(200) + 100;
        b = random.nextInt(50) + 10;
        question =
            'A rectangle has length $a cm and width $b cm. What is the area? 📐';
        hint = 'Multiply length by width';
        learningObjectives = ['Area problems', 'Geometry'];
        break;
      default:
        a = random.nextInt(500) + 200;
        b = random.nextInt(100) + 20;
        question = 'A car travels $a km at $b km/h. How long does it take? 🚗';
        hint = 'Divide distance by speed';
        learningObjectives = ['Complex word problems', 'Time calculation'];
    }

    correctAnswer = a + b; // Default to addition, but varies by problem type
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.wordProblems,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: 'Word problem solution: $a + $b = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_word_problems',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate patterns question
  AIQuestion _generateGradeAppropriatePatternsQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int pattern, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        pattern = random.nextInt(5) + 1;
        question = '🔢 1, 2, 3, ?, 5\nWhat comes next?';
        hint = 'Count the numbers: 1, 2, 3, 4, 5';
        learningObjectives = ['Number patterns', 'Sequencing'];
        break;
      case GradeLevel.grade1:
        pattern = random.nextInt(10) + 1;
        question = '🔢 2, 4, 6, ?, 10\nWhat comes next?';
        hint = 'Add 2 each time: 2, 4, 6, 8, 10';
        learningObjectives = ['Skip counting', 'Addition patterns'];
        break;
      case GradeLevel.grade2:
        pattern = random.nextInt(20) + 10;
        question = '🔢 5, 10, 15, ?, 25\nWhat comes next?';
        hint = 'Add 5 each time: 5, 10, 15, 20, 25';
        learningObjectives = ['Multiples', 'Multiplication patterns'];
        break;
      case GradeLevel.grade3:
        pattern = random.nextInt(50) + 20;
        question = 'What comes next? 3, 6, 12, ?, 48 🔢';
        hint = 'Multiply by 2 each time';
        learningObjectives = ['Geometric sequences', 'Multiplication'];
        break;
      case GradeLevel.grade4:
        pattern = random.nextInt(100) + 50;
        question = 'What comes next? 1, 3, 6, ?, 15 🔢';
        hint = 'Add 1, then 2, then 3...';
        learningObjectives = ['Triangular numbers', 'Complex patterns'];
        break;
      case GradeLevel.grade5:
        pattern = random.nextInt(200) + 100;
        question = 'What comes next? 2, 6, 18, ?, 162 🔢';
        hint = 'Multiply by 3 each time';
        learningObjectives = ['Exponential patterns', 'Advanced sequences'];
        break;
      default:
        pattern = random.nextInt(500) + 200;
        question = 'What comes next? 1, 1, 2, 3, ?, 8 🔢';
        hint = 'Add the previous two numbers';
        learningObjectives = ['Fibonacci sequence', 'Complex patterns'];
    }

    correctAnswer = pattern;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.patterns,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: 'Pattern rule: $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_patterns',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate measurement question
  AIQuestion _generateGradeAppropriateMeasurementQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int length, width, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        length = random.nextInt(5) + 1;
        width = random.nextInt(5) + 1;
        question = '📏 $length units\nHow long is the pencil?';
        hint = 'Count the units: $length units long';
        learningObjectives = ['Basic measurement', 'Length'];
        break;
      case GradeLevel.grade1:
        length = random.nextInt(10) + 1;
        width = random.nextInt(10) + 1;
        question = '📏 $length cm + $width cm\nWhat is $length cm + $width cm?';
        hint = 'Add the centimeters: $length + $width';
        learningObjectives = ['Centimeter addition', 'Length measurement'];
        break;
      case GradeLevel.grade2:
        length = random.nextInt(20) + 10;
        width = random.nextInt(20) + 10;
        question = '📏 $length m + $width m\nWhat is $length m + $width m?';
        hint = 'Add the meters: $length + $width';
        learningObjectives = ['Meter measurement', 'Length addition'];
        break;
      case GradeLevel.grade3:
        length = random.nextInt(50) + 20;
        width = random.nextInt(50) + 20;
        question = 'What is $length cm × $width cm? 📏';
        hint = 'Multiply length by width';
        learningObjectives = ['Area calculation', 'Multiplication'];
        break;
      case GradeLevel.grade4:
        length = random.nextInt(100) + 50;
        width = random.nextInt(100) + 50;
        question = 'What is $length m × $width m? 📏';
        hint = 'Calculate area in square meters';
        learningObjectives = ['Area measurement', 'Square units'];
        break;
      case GradeLevel.grade5:
        length = random.nextInt(200) + 100;
        width = random.nextInt(200) + 100;
        question = 'What is $length km + $width km? 📏';
        hint = 'Add the kilometers';
        learningObjectives = ['Kilometer measurement', 'Distance'];
        break;
      default:
        length = random.nextInt(500) + 200;
        width = random.nextInt(500) + 200;
        question = 'What is $length mm + $width mm? 📏';
        hint = 'Convert to appropriate units';
        learningObjectives = ['Unit conversion', 'Precision measurement'];
    }

    correctAnswer = length + width;
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.measurement,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation: 'Measurement: $length + $width = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_measurement',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }

  /// Generate grade-appropriate data analysis question
  AIQuestion _generateGradeAppropriateDataAnalysisQuestion(
    GradeLevel gradeLevel,
    GameDifficulty difficulty,
    Random random,
    Map<String, dynamic>? userProgress,
  ) {
    int data1, data2, data3, correctAnswer;
    List<String> options;
    String question;
    String? hint;
    List<String> learningObjectives;

    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        data1 = random.nextInt(5) + 1;
        data2 = random.nextInt(5) + 1;
        data3 = random.nextInt(5) + 1;
        question = '🔴 $data1, $data2, $data3\nHow many red balls?';
        hint = 'Count the red ones: $data1 + $data2 + $data3';
        learningObjectives = ['Basic data', 'Counting'];
        break;
      case GradeLevel.grade1:
        data1 = random.nextInt(10) + 1;
        data2 = random.nextInt(10) + 1;
        data3 = random.nextInt(10) + 1;
        question = '📊 $data1, $data2, $data3\nWhat is the highest number?';
        hint = 'Find the biggest number: $data1, $data2, or $data3?';
        learningObjectives = ['Data comparison', 'Number ordering'];
        break;
      case GradeLevel.grade2:
        data1 = random.nextInt(20) + 10;
        data2 = random.nextInt(20) + 10;
        data3 = random.nextInt(20) + 10;
        question = '📈 $data1, $data2, $data3\nWhat is the average?';
        hint =
            'Add all numbers, then divide by 3: ($data1 + $data2 + $data3) ÷ 3';
        learningObjectives = ['Averages', 'Division'];
        break;
      case GradeLevel.grade3:
        data1 = random.nextInt(50) + 20;
        data2 = random.nextInt(50) + 20;
        data3 = random.nextInt(50) + 20;
        question = 'What is the range? $data1, $data2, $data3';
        hint = 'Subtract smallest from largest';
        learningObjectives = ['Range calculation', 'Data spread'];
        break;
      case GradeLevel.grade4:
        data1 = random.nextInt(100) + 50;
        data2 = random.nextInt(100) + 50;
        data3 = random.nextInt(100) + 50;
        question = 'What is the median? $data1, $data2, $data3';
        hint = 'Find the middle number';
        learningObjectives = ['Median', 'Data ordering'];
        break;
      case GradeLevel.grade5:
        data1 = random.nextInt(200) + 100;
        data2 = random.nextInt(200) + 100;
        data3 = random.nextInt(200) + 100;
        question = 'What is the mode? $data1, $data2, $data1';
        hint = 'Find the most common number';
        learningObjectives = ['Mode', 'Frequency'];
        break;
      default:
        data1 = random.nextInt(500) + 200;
        data2 = random.nextInt(500) + 200;
        data3 = random.nextInt(500) + 200;
        question = 'What is the standard deviation? $data1, $data2, $data3';
        hint = 'Use statistical formulas';
        learningObjectives = ['Advanced statistics', 'Data analysis'];
    }

    correctAnswer = (data1 + data2 + data3) ~/ 3; // Default to average
    options = _generateGradeAppropriateOptions(
      correctAnswer,
      random,
      gradeLevel,
    );

    return AIQuestion(
      id: _generateId(),
      question: question,
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.dataAnalysis,
      difficulty: difficulty,
      gradeLevel: gradeLevel,
      explanation:
          'Data analysis: Average = ($data1 + $data2 + $data3) ÷ 3 = $correctAnswer',
      hint: hint,
      timeLimit: _getGradeAppropriateTimeLimit(gradeLevel),
      aiMetadata: {
        'userProgress': userProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'algorithm': 'grade_appropriate_data_analysis',
      },
      confidence: 0.95,
      learningObjectives: learningObjectives,
    );
  }
}

/// Riverpod providers for game management
final gameServiceProvider = Provider<GameService>((ref) {
  throw UnimplementedError('GameService must be initialized');
});

final gameSessionsProvider = FutureProvider<List<GameSession>>((ref) async {
  final gameService = ref.read(gameServiceProvider);
  return gameService.getAllGameSessions();
});

final gameResultsProvider = FutureProvider.family<List<GameResult>, String>((
  ref,
  sessionId,
) async {
  final gameService = ref.read(gameServiceProvider);
  return gameService.getGameResults(sessionId);
});

final leaderboardProvider = FutureProvider.family<List<GamePlayer>, String>((
  ref,
  sessionId,
) async {
  final gameService = ref.read(gameServiceProvider);
  return gameService.getLeaderboard(sessionId);
});
