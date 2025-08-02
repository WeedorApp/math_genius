import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tflite_flutter/tflite_flutter.dart'; // Not supported on web
import 'dart:math';

/// AI Service for Math Genius
/// Handles math problem solving and AI tutoring (web-compatible)
class AIService {
  static AIService? _instance;
  bool _isInitialized = false;

  AIService._();

  static AIService get instance {
    _instance ??= AIService._();
    return _instance!;
  }

  /// Initialize AI service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Web-compatible initialization
      _isInitialized = true;

      if (kDebugMode) {
        print('AI Service initialized successfully (web mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AI Service: $e');
      }
      rethrow;
    }
  }

  /// Solve math problem
  Future<MathSolution> solveMathProblem(String problem) async {
    try {
      // Web-compatible rule-based solving
      return await _solveWithRules(problem);
    } catch (e) {
      if (kDebugMode) {
        print('Error solving math problem: $e');
      }
      rethrow;
    }
  }

  /// Solve using rule-based approach
  Future<MathSolution> _solveWithRules(String problem) async {
    try {
      // Simple math evaluation for basic operations
      final expression = problem.replaceAll('×', '*').replaceAll('÷', '/');
      final result = _evaluateSimpleExpression(expression);

      return MathSolution(
        problem: problem,
        answer: result.toString(),
        steps: ['Parsed expression: $expression', 'Evaluated result: $result'],
        confidence: 0.95,
        method: 'Rule-based',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error with rule-based solving: $e');
      }
      rethrow;
    }
  }

  /// Generate math problem
  Future<MathProblem> generateMathProblem({
    required MathDifficulty difficulty,
    required MathCategory category,
    int? gradeLevel,
  }) async {
    try {
      switch (category) {
        case MathCategory.addition:
          return _generateAdditionProblem(difficulty, gradeLevel);
        case MathCategory.subtraction:
          return _generateSubtractionProblem(difficulty, gradeLevel);
        case MathCategory.multiplication:
          return _generateMultiplicationProblem(difficulty, gradeLevel);
        case MathCategory.division:
          return _generateDivisionProblem(difficulty, gradeLevel);
        case MathCategory.algebra:
          return _generateAlgebraProblem(difficulty, gradeLevel);
        case MathCategory.geometry:
          return _generateGeometryProblem(difficulty, gradeLevel);
        default:
          return _generateMixedProblem(difficulty, gradeLevel);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating math problem: $e');
      }
      rethrow;
    }
  }

  /// Generate addition problem
  MathProblem _generateAdditionProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final random = Random();
    int maxNumber;

    switch (difficulty) {
      case MathDifficulty.easy:
        maxNumber = gradeLevel == null ? 50 : (gradeLevel * 10);
        break;
      case MathDifficulty.medium:
        maxNumber = gradeLevel == null ? 200 : (gradeLevel * 25);
        break;
      case MathDifficulty.hard:
        maxNumber = gradeLevel == null ? 1000 : (gradeLevel * 50);
        break;
      case MathDifficulty.expert:
        maxNumber = gradeLevel == null ? 10000 : (gradeLevel * 100);
        break;
    }

    final a = random.nextInt(maxNumber) + 1;
    final b = random.nextInt(maxNumber) + 1;
    final answer = a + b;

    return MathProblem(
      question: '$a + $b = ?',
      answer: answer.toString(),
      category: MathCategory.addition,
      difficulty: difficulty,
      gradeLevel: gradeLevel ?? 1,
    );
  }

  /// Generate subtraction problem
  MathProblem _generateSubtractionProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final random = Random();
    int maxNumber;

    switch (difficulty) {
      case MathDifficulty.easy:
        maxNumber = gradeLevel == null ? 50 : (gradeLevel * 10);
        break;
      case MathDifficulty.medium:
        maxNumber = gradeLevel == null ? 200 : (gradeLevel * 25);
        break;
      case MathDifficulty.hard:
        maxNumber = gradeLevel == null ? 1000 : (gradeLevel * 50);
        break;
      case MathDifficulty.expert:
        maxNumber = gradeLevel == null ? 10000 : (gradeLevel * 100);
        break;
    }

    final a = random.nextInt(maxNumber) + maxNumber;
    final b = random.nextInt(maxNumber) + 1;
    final answer = a - b;

    return MathProblem(
      question: '$a - $b = ?',
      answer: answer.toString(),
      category: MathCategory.subtraction,
      difficulty: difficulty,
      gradeLevel: gradeLevel ?? 1,
    );
  }

  /// Generate multiplication problem
  MathProblem _generateMultiplicationProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final random = Random();
    int maxNumber;

    switch (difficulty) {
      case MathDifficulty.easy:
        maxNumber = gradeLevel == null ? 12 : (gradeLevel * 2);
        break;
      case MathDifficulty.medium:
        maxNumber = gradeLevel == null ? 25 : (gradeLevel * 5);
        break;
      case MathDifficulty.hard:
        maxNumber = gradeLevel == null ? 50 : (gradeLevel * 10);
        break;
      case MathDifficulty.expert:
        maxNumber = gradeLevel == null ? 100 : (gradeLevel * 20);
        break;
    }

    final a = random.nextInt(maxNumber) + 1;
    final b = random.nextInt(maxNumber) + 1;
    final answer = a * b;

    return MathProblem(
      question: '$a × $b = ?',
      answer: answer.toString(),
      category: MathCategory.multiplication,
      difficulty: difficulty,
      gradeLevel: gradeLevel ?? 1,
    );
  }

  /// Generate division problem
  MathProblem _generateDivisionProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final random = Random();
    int maxNumber;

    switch (difficulty) {
      case MathDifficulty.easy:
        maxNumber = gradeLevel == null ? 12 : (gradeLevel * 2);
        break;
      case MathDifficulty.medium:
        maxNumber = gradeLevel == null ? 25 : (gradeLevel * 5);
        break;
      case MathDifficulty.hard:
        maxNumber = gradeLevel == null ? 50 : (gradeLevel * 10);
        break;
      case MathDifficulty.expert:
        maxNumber = gradeLevel == null ? 100 : (gradeLevel * 20);
        break;
    }

    final b = random.nextInt(maxNumber) + 1;
    final answer = random.nextInt(maxNumber) + 1;
    final a = b * answer;

    return MathProblem(
      question: '$a ÷ $b = ?',
      answer: answer.toString(),
      category: MathCategory.division,
      difficulty: difficulty,
      gradeLevel: gradeLevel ?? 1,
    );
  }

  /// Generate algebra problem
  MathProblem _generateAlgebraProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final random = Random();
    int maxNumber;

    switch (difficulty) {
      case MathDifficulty.easy:
        maxNumber = 10;
        break;
      case MathDifficulty.medium:
        maxNumber = 20;
        break;
      case MathDifficulty.hard:
        maxNumber = 50;
        break;
      case MathDifficulty.expert:
        maxNumber = 100;
        break;
    }

    final a = random.nextInt(maxNumber) + 1;
    final b = random.nextInt(maxNumber) + 1;
    final x = random.nextInt(maxNumber) + 1;
    final answer = a * x + b;

    return MathProblem(
      question: 'If $a × x + $b = $answer, what is x?',
      answer: x.toString(),
      category: MathCategory.algebra,
      difficulty: difficulty,
      gradeLevel: gradeLevel ?? 6,
    );
  }

  /// Generate geometry problem
  MathProblem _generateGeometryProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final random = Random();
    int maxNumber;

    switch (difficulty) {
      case MathDifficulty.easy:
        maxNumber = 10;
        break;
      case MathDifficulty.medium:
        maxNumber = 20;
        break;
      case MathDifficulty.hard:
        maxNumber = 50;
        break;
      case MathDifficulty.expert:
        maxNumber = 100;
        break;
    }

    final length = random.nextInt(maxNumber) + 1;
    final width = random.nextInt(maxNumber) + 1;
    final area = length * width;

    return MathProblem(
      question:
          'A rectangle has length $length and width $width. What is its area?',
      answer: area.toString(),
      category: MathCategory.geometry,
      difficulty: difficulty,
      gradeLevel: gradeLevel ?? 4,
    );
  }

  /// Generate mixed problem
  MathProblem _generateMixedProblem(
    MathDifficulty difficulty,
    int? gradeLevel,
  ) {
    final categories = MathCategory.values
        .where((c) => c != MathCategory.mixed)
        .toList();
    final randomCategory = categories[Random().nextInt(categories.length)];

    switch (randomCategory) {
      case MathCategory.addition:
        return _generateAdditionProblem(difficulty, gradeLevel);
      case MathCategory.subtraction:
        return _generateSubtractionProblem(difficulty, gradeLevel);
      case MathCategory.multiplication:
        return _generateMultiplicationProblem(difficulty, gradeLevel);
      case MathCategory.division:
        return _generateDivisionProblem(difficulty, gradeLevel);
      case MathCategory.algebra:
        return _generateAlgebraProblem(difficulty, gradeLevel);
      case MathCategory.geometry:
        return _generateGeometryProblem(difficulty, gradeLevel);
      default:
        return _generateAdditionProblem(difficulty, gradeLevel);
    }
  }

  /// Provide tutoring hints
  Future<List<String>> provideHints(String problem, String userAnswer) async {
    try {
      final solution = await solveMathProblem(problem);
      final hints = <String>[];

      if (userAnswer != solution.answer) {
        hints.add('Try breaking down the problem into smaller steps.');
        hints.add('Check your arithmetic carefully.');
        hints.add('Make sure you\'re using the correct operation.');

        // Add specific hints based on problem type
        if (problem.contains('+')) {
          hints.add('For addition, line up the numbers carefully.');
        } else if (problem.contains('-')) {
          hints.add('For subtraction, remember to borrow when needed.');
        } else if (problem.contains('×')) {
          hints.add('For multiplication, use the distributive property.');
        } else if (problem.contains('÷')) {
          hints.add('For division, check if your answer makes sense.');
        }
      }

      return hints;
    } catch (e) {
      if (kDebugMode) {
        print('Error providing hints: $e');
      }
      return ['Try your best!'];
    }
  }

  /// Simple expression evaluator for basic math operations
  double _evaluateSimpleExpression(String expression) {
    try {
      // Remove spaces and normalize operators
      final cleanExpression = expression.replaceAll(' ', '');

      // Handle basic arithmetic operations
      if (cleanExpression.contains('+')) {
        final parts = cleanExpression.split('+');
        return double.parse(parts[0]) + double.parse(parts[1]);
      } else if (cleanExpression.contains('-')) {
        final parts = cleanExpression.split('-');
        return double.parse(parts[0]) - double.parse(parts[1]);
      } else if (cleanExpression.contains('*')) {
        final parts = cleanExpression.split('*');
        return double.parse(parts[0]) * double.parse(parts[1]);
      } else if (cleanExpression.contains('/')) {
        final parts = cleanExpression.split('/');
        return double.parse(parts[0]) / double.parse(parts[1]);
      } else {
        return double.parse(cleanExpression);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error evaluating expression: $e');
      }
      return 0.0;
    }
  }

  /// Dispose resources
  void dispose() {
    // Web-compatible disposal
    _isInitialized = false;
  }
}

/// Math problem model
class MathProblem {
  final String question;
  final String answer;
  final MathCategory category;
  final MathDifficulty difficulty;
  final int gradeLevel;

  const MathProblem({
    required this.question,
    required this.answer,
    required this.category,
    required this.difficulty,
    required this.gradeLevel,
  });
}

/// Math solution model
class MathSolution {
  final String problem;
  final String answer;
  final List<String> steps;
  final double confidence;
  final String method;

  const MathSolution({
    required this.problem,
    required this.answer,
    required this.steps,
    required this.confidence,
    required this.method,
  });
}

/// Model result
class ModelResult {
  final String answer;
  final List<String> steps;
  final double confidence;

  const ModelResult({
    required this.answer,
    required this.steps,
    required this.confidence,
  });
}

/// Math categories
enum MathCategory {
  addition,
  subtraction,
  multiplication,
  division,
  algebra,
  geometry,
  mixed,
}

/// Math difficulties
enum MathDifficulty { easy, medium, hard, expert }

/// AI Service Provider
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService.instance;
});
