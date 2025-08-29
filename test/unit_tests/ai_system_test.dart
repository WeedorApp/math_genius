import 'package:flutter_test/flutter_test.dart';
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('AI System Basic Tests', () {
    test('should have game difficulty levels', () {
      expect(GameDifficulty.values.length, equals(4));
      expect(GameDifficulty.values, contains(GameDifficulty.easy));
      expect(GameDifficulty.values, contains(GameDifficulty.normal));
      expect(GameDifficulty.values, contains(GameDifficulty.genius));
      expect(GameDifficulty.values, contains(GameDifficulty.quantum));
    });

    test('should have game categories', () {
      expect(GameCategory.values.length, greaterThan(0));
      expect(GameCategory.values, contains(GameCategory.addition));
      expect(GameCategory.values, contains(GameCategory.subtraction));
      expect(GameCategory.values, contains(GameCategory.multiplication));
    });

    test('should create game session correctly', () {
      final session = GameSession(
        id: 'test_session',
        name: 'Test Session',
        category: GameCategory.addition,
        difficulty: GameDifficulty.easy,
        totalQuestions: 10,
        questions: [],
        players: [],
        createdAt: DateTime.now(),
        status: GameStatus.waiting,
      );

      expect(session.id, equals('test_session'));
      expect(session.name, equals('Test Session'));
      expect(session.category, equals(GameCategory.addition));
      expect(session.difficulty, equals(GameDifficulty.easy));
      expect(session.totalQuestions, equals(10));
    });

    test('should create AI question correctly', () {
      final question = AIQuestion(
        id: 'q_1',
        question: 'What is 2 + 2?',
        options: ['3', '4', '5', '6'],
        correctAnswer: 1, // Index of correct answer
        category: GameCategory.addition,
        difficulty: GameDifficulty.easy,
        gradeLevel: GradeLevel.grade1,
        explanation: 'Two plus two equals four.',
        hint: 'Think about counting',
      );

      expect(question.id, equals('q_1'));
      expect(question.question, equals('What is 2 + 2?'));
      expect(question.correctAnswer, equals(1));
      expect(question.options.length, equals(4));
      expect(question.hint, equals('Think about counting'));
    });
  });
}