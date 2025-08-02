import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';

// Models
import '../models/game_model.dart';

/// Game service for Math Genius
class GameService {
  static const String _gameSessionsKey = 'game_sessions';
  static const String _gameResultsKey = 'game_results';
  static const String _cachedQuestionsKey = 'cached_questions';

  final SharedPreferences _prefs;
  final Box? _hiveBox;

  GameService(this._prefs, this._hiveBox);

  /// Generate questions for a specific category and difficulty
  Future<List<GameQuestion>> generateQuestions(
    GameCategory category,
    GameDifficulty difficulty,
    int count,
  ) async {
    try {
      // Try to get cached questions first
      final cachedQuestions = await _getCachedQuestions(category, difficulty);
      if (cachedQuestions.isNotEmpty) {
        return cachedQuestions.take(count).toList();
      }

      // Generate new questions
      final questions = await _generateQuestionsForCategory(
        category,
        difficulty,
        count,
      );

      // Cache the questions
      await _cacheQuestions(category, difficulty, questions);

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating questions: $e');
      }
      return [];
    }
  }

  /// Create a new game session
  Future<GameSession> createGameSession({
    required String name,
    required GameDifficulty difficulty,
    required GameCategory category,
    required List<GamePlayer> players,
    int questionCount = 10,
    int timeLimit = 600,
  }) async {
    try {
      final questions = await generateQuestions(
        category,
        difficulty,
        questionCount,
      );

      final session = GameSession(
        id: _generateId(),
        name: name,
        difficulty: difficulty,
        category: category,
        questions: questions,
        players: players,
        createdAt: DateTime.now(),
        totalQuestions: questions.length,
        timeLimit: timeLimit,
      );

      await _saveGameSession(session);
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating game session: $e');
      }
      rethrow;
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

  /// Generate questions for a specific category
  Future<List<GameQuestion>> _generateQuestionsForCategory(
    GameCategory category,
    GameDifficulty difficulty,
    int count,
  ) async {
    final questions = <GameQuestion>[];
    final random = Random();

    for (int i = 0; i < count; i++) {
      final question = await _generateSingleQuestion(
        category,
        difficulty,
        random,
      );
      questions.add(question);
    }

    return questions;
  }

  /// Generate a single question
  Future<GameQuestion> _generateSingleQuestion(
    GameCategory category,
    GameDifficulty difficulty,
    Random random,
  ) async {
    switch (category) {
      case GameCategory.addition:
        return _generateAdditionQuestion(difficulty, random);
      case GameCategory.subtraction:
        return _generateSubtractionQuestion(difficulty, random);
      case GameCategory.multiplication:
        return _generateMultiplicationQuestion(difficulty, random);
      case GameCategory.division:
        return _generateDivisionQuestion(difficulty, random);
      case GameCategory.algebra:
        return _generateAlgebraQuestion(difficulty, random);
      case GameCategory.geometry:
        return _generateGeometryQuestion(difficulty, random);
      case GameCategory.calculus:
        return _generateCalculusQuestion(difficulty, random);
    }
  }

  /// Generate addition question
  GameQuestion _generateAdditionQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    int a, b, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        a = random.nextInt(10) + 1;
        b = random.nextInt(10) + 1;
        break;
      case GameDifficulty.normal:
        a = random.nextInt(50) + 10;
        b = random.nextInt(50) + 10;
        break;
      case GameDifficulty.genius:
        a = random.nextInt(200) + 50;
        b = random.nextInt(200) + 50;
        break;
      case GameDifficulty.quantum:
        a = random.nextInt(1000) + 200;
        b = random.nextInt(1000) + 200;
        break;
    }

    correctAnswer = a + b;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'What is $a + $b?',
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.addition,
      difficulty: difficulty,
      explanation: '$a + $b = $correctAnswer',
    );
  }

  /// Generate subtraction question
  GameQuestion _generateSubtractionQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    int a, b, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        a = random.nextInt(10) + 5;
        b = random.nextInt(a) + 1;
        break;
      case GameDifficulty.normal:
        a = random.nextInt(100) + 20;
        b = random.nextInt(a) + 10;
        break;
      case GameDifficulty.genius:
        a = random.nextInt(500) + 100;
        b = random.nextInt(a) + 50;
        break;
      case GameDifficulty.quantum:
        a = random.nextInt(2000) + 500;
        b = random.nextInt(a) + 200;
        break;
    }

    correctAnswer = a - b;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'What is $a - $b?',
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.subtraction,
      difficulty: difficulty,
      explanation: '$a - $b = $correctAnswer',
    );
  }

  /// Generate multiplication question
  GameQuestion _generateMultiplicationQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    int a, b, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        a = random.nextInt(10) + 1;
        b = random.nextInt(10) + 1;
        break;
      case GameDifficulty.normal:
        a = random.nextInt(20) + 5;
        b = random.nextInt(20) + 5;
        break;
      case GameDifficulty.genius:
        a = random.nextInt(50) + 10;
        b = random.nextInt(50) + 10;
        break;
      case GameDifficulty.quantum:
        a = random.nextInt(100) + 20;
        b = random.nextInt(100) + 20;
        break;
    }

    correctAnswer = a * b;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'What is $a × $b?',
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.multiplication,
      difficulty: difficulty,
      explanation: '$a × $b = $correctAnswer',
    );
  }

  /// Generate division question
  GameQuestion _generateDivisionQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    int a, b, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        b = random.nextInt(5) + 2;
        a = b * (random.nextInt(5) + 1);
        break;
      case GameDifficulty.normal:
        b = random.nextInt(10) + 2;
        a = b * (random.nextInt(10) + 1);
        break;
      case GameDifficulty.genius:
        b = random.nextInt(20) + 5;
        a = b * (random.nextInt(20) + 1);
        break;
      case GameDifficulty.quantum:
        b = random.nextInt(50) + 10;
        a = b * (random.nextInt(50) + 1);
        break;
    }

    correctAnswer = a ~/ b;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'What is $a ÷ $b?',
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.division,
      difficulty: difficulty,
      explanation: '$a ÷ $b = $correctAnswer',
    );
  }

  /// Generate algebra question
  GameQuestion _generateAlgebraQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    // Simple algebra questions
    int a, b, x, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        a = random.nextInt(5) + 1;
        b = random.nextInt(10) + 1;
        x = random.nextInt(5) + 1;
        break;
      case GameDifficulty.normal:
        a = random.nextInt(10) + 2;
        b = random.nextInt(20) + 5;
        x = random.nextInt(10) + 1;
        break;
      case GameDifficulty.genius:
        a = random.nextInt(20) + 5;
        b = random.nextInt(50) + 10;
        x = random.nextInt(20) + 1;
        break;
      case GameDifficulty.quantum:
        a = random.nextInt(50) + 10;
        b = random.nextInt(100) + 20;
        x = random.nextInt(50) + 1;
        break;
    }

    correctAnswer = a * x + b;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'If $a × x + $b = $correctAnswer, what is x?',
      options: options,
      correctAnswer: options.indexOf(x.toString()),
      category: GameCategory.algebra,
      difficulty: difficulty,
      explanation: 'x = ${correctAnswer - b} ÷ $a = $x',
    );
  }

  /// Generate geometry question
  GameQuestion _generateGeometryQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    // Simple geometry questions
    int side, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        side = random.nextInt(10) + 1;
        break;
      case GameDifficulty.normal:
        side = random.nextInt(20) + 5;
        break;
      case GameDifficulty.genius:
        side = random.nextInt(50) + 10;
        break;
      case GameDifficulty.quantum:
        side = random.nextInt(100) + 20;
        break;
    }

    correctAnswer = side * side;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'What is the area of a square with side length $side?',
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.geometry,
      difficulty: difficulty,
      explanation: 'Area = side² = $side² = $correctAnswer',
    );
  }

  /// Generate calculus question
  GameQuestion _generateCalculusQuestion(
    GameDifficulty difficulty,
    Random random,
  ) {
    // Simple calculus questions (derivatives)
    int a, b, x, correctAnswer;
    List<String> options;

    switch (difficulty) {
      case GameDifficulty.easy:
        a = random.nextInt(5) + 1;
        b = random.nextInt(10) + 1;
        x = random.nextInt(5) + 1;
        break;
      case GameDifficulty.normal:
        a = random.nextInt(10) + 2;
        b = random.nextInt(20) + 5;
        x = random.nextInt(10) + 1;
        break;
      case GameDifficulty.genius:
        a = random.nextInt(20) + 5;
        b = random.nextInt(50) + 10;
        x = random.nextInt(20) + 1;
        break;
      case GameDifficulty.quantum:
        a = random.nextInt(50) + 10;
        b = random.nextInt(100) + 20;
        x = random.nextInt(50) + 1;
        break;
    }

    correctAnswer = 2 * a * x + b;
    options = _generateOptions(correctAnswer, random);

    return GameQuestion(
      id: _generateId(),
      question: 'What is the derivative of ${a}x² + ${b}x at x = $x?',
      options: options,
      correctAnswer: options.indexOf(correctAnswer.toString()),
      category: GameCategory.calculus,
      difficulty: difficulty,
      explanation: 'Derivative = 2${a}x + $b = 2×$a×$x + $b = $correctAnswer',
    );
  }

  /// Generate answer options
  List<String> _generateOptions(int correctAnswer, Random random) {
    final options = <String>[correctAnswer.toString()];

    // Generate 3 wrong options
    while (options.length < 4) {
      final wrongAnswer = correctAnswer + random.nextInt(20) - 10;
      if (wrongAnswer != correctAnswer &&
          !options.contains(wrongAnswer.toString())) {
        options.add(wrongAnswer.toString());
      }
    }

    options.shuffle(random);
    return options;
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

  /// Get cached questions
  Future<List<GameQuestion>> _getCachedQuestions(
    GameCategory category,
    GameDifficulty difficulty,
  ) async {
    try {
      final key = '${_cachedQuestionsKey}_${category.name}_${difficulty.name}';
      final questionsString = _prefs.getString(key);
      if (questionsString == null) return [];

      final questionsList = jsonDecode(questionsString) as List;
      return questionsList
          .map((q) => GameQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached questions: $e');
      }
      return [];
    }
  }

  /// Cache questions
  Future<void> _cacheQuestions(
    GameCategory category,
    GameDifficulty difficulty,
    List<GameQuestion> questions,
  ) async {
    try {
      final key = '${_cachedQuestionsKey}_${category.name}_${difficulty.name}';
      await _prefs.setString(
        key,
        jsonEncode(questions.map((q) => q.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error caching questions: $e');
      }
    }
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
