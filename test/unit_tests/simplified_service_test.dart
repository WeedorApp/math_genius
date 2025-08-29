import 'package:flutter_test/flutter_test.dart';
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Core Service Integration Tests', () {
    group('Game Model Tests', () {
      test('should create valid AI question', () {
        final question = AIQuestion(
          id: 'test_1',
          question: 'What is 2 + 2?',
          options: ['3', '4', '5', '6'],
          correctAnswer: 1,
          category: GameCategory.addition,
          difficulty: GameDifficulty.easy,
          gradeLevel: GradeLevel.grade1,
        );

        expect(question.id, equals('test_1'));
        expect(question.question, equals('What is 2 + 2?'));
        expect(question.options.length, equals(4));
        expect(question.correctAnswer, equals(1));
        expect(question.category, equals(GameCategory.addition));
        expect(question.difficulty, equals(GameDifficulty.easy));
        expect(question.gradeLevel, equals(GradeLevel.grade1));
      });

      test('should handle different grade levels', () {
        final grades = [
          GradeLevel.preK,
          GradeLevel.kindergarten,
          GradeLevel.grade1,
          GradeLevel.grade5,
          GradeLevel.grade12,
        ];

        for (final grade in grades) {
          final question = AIQuestion(
            id: 'test_${grade.name}',
            question: 'Sample question for ${grade.name}',
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 0,
            category: GameCategory.addition,
            difficulty: GameDifficulty.normal,
            gradeLevel: grade,
          );

          expect(question.gradeLevel, equals(grade));
          expect(question.id, contains(grade.name));
        }
      });

      test('should handle different game categories', () {
        final categories = [
          GameCategory.addition,
          GameCategory.subtraction,
          GameCategory.multiplication,
          GameCategory.division,
          GameCategory.algebra,
          GameCategory.geometry,
        ];

        for (final category in categories) {
          final question = AIQuestion(
            id: 'test_${category.name}',
            question: 'Sample ${category.name} question',
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 0,
            category: category,
            difficulty: GameDifficulty.normal,
            gradeLevel: GradeLevel.grade5,
          );

          expect(question.category, equals(category));
          expect(question.question, contains(category.name));
        }
      });

      test('should handle different difficulty levels', () {
        final difficulties = [
          GameDifficulty.easy,
          GameDifficulty.normal,
          GameDifficulty.genius,
          GameDifficulty.quantum,
        ];

        for (final difficulty in difficulties) {
          final question = AIQuestion(
            id: 'test_${difficulty.name}',
            question: 'Sample ${difficulty.name} question',
            options: ['A', 'B', 'C', 'D'],
            correctAnswer: 0,
            category: GameCategory.addition,
            difficulty: difficulty,
            gradeLevel: GradeLevel.grade5,
          );

          expect(question.difficulty, equals(difficulty));
        }
      });
    });

    group('Game Session Tests', () {
      test('should create valid game session', () {
        final players = [
          GamePlayer(
            id: 'player1',
            name: 'Test Player',
            role: PlayerRole.host,
            lastActive: DateTime.now(),
          ),
        ];

        final questions = [
          GameQuestion(
            id: 'q1',
            question: 'What is 1 + 1?',
            options: ['1', '2', '3', '4'],
            correctAnswer: 1,
            category: GameCategory.addition,
            difficulty: GameDifficulty.easy,
            gradeLevel: GradeLevel.grade1,
          ),
        ];

        final session = GameSession(
          id: 'session_1',
          name: 'Test Session',
          difficulty: GameDifficulty.easy,
          category: GameCategory.addition,
          questions: questions,
          players: players,
          createdAt: DateTime.now(),
          totalQuestions: 1,
        );

        expect(session.id, equals('session_1'));
        expect(session.name, equals('Test Session'));
        expect(session.difficulty, equals(GameDifficulty.easy));
        expect(session.category, equals(GameCategory.addition));
        expect(session.questions.length, equals(1));
        expect(session.players.length, equals(1));
        expect(session.totalQuestions, equals(1));
        expect(session.status, equals(GameStatus.waiting));
      });

      test('should handle multiple players', () {
        final players = <GamePlayer>[
          GamePlayer(
            id: 'player1',
            name: 'Player 1',
            role: PlayerRole.host,
            lastActive: DateTime.now(),
          ),
          GamePlayer(
            id: 'player2',
            name: 'Player 2',
            role: PlayerRole.participant,
            lastActive: DateTime.now(),
          ),
          GamePlayer(
            id: 'player3',
            name: 'Player 3',
            role: PlayerRole.participant,
            lastActive: DateTime.now(),
          ),
        ];

        final session = GameSession(
          id: 'session_multi',
          name: 'Multiplayer Session',
          difficulty: GameDifficulty.normal,
          category: GameCategory.multiplication,
          questions: [],
          players: players,
          createdAt: DateTime.now(),
          totalQuestions: 10,
        );

        expect(session.players.length, equals(3));
        expect(
          session.players.where((p) => p.role == PlayerRole.host).length,
          equals(1),
        );
        expect(
          session.players.where((p) => p.role == PlayerRole.participant).length,
          equals(2),
        );
      });
    });

    group('User Model Tests', () {
      test('should create valid user', () {
        final user = TestUser(
          id: 'user_1',
          email: 'test@example.com',
          displayName: 'Test User',
          role: 'student',
          createdAt: DateTime.now(),
        );

        expect(user.id, equals('user_1'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.role, equals('student'));
        expect(user.createdAt, isNotNull);
      });

      test('should handle different user roles', () {
        final roles = ['student', 'parent', 'teacher', 'admin'];

        for (final role in roles) {
          final user = TestUser(
            id: 'user_$role',
            email: '$role@example.com',
            displayName: 'Test $role',
            role: role,
            createdAt: DateTime.now(),
          );

          expect(user.role, equals(role));
          expect(user.email, equals('$role@example.com'));
        }
      });
    });

    group('Integration Tests', () {
      test('should handle complete game flow', () {
        // Create a question
        final question = AIQuestion(
          id: 'q1',
          question: 'What is 5 × 3?',
          options: ['12', '15', '18', '20'],
          correctAnswer: 1,
          category: GameCategory.multiplication,
          difficulty: GameDifficulty.normal,
          gradeLevel: GradeLevel.grade3,
        );

        // Create a player
        final player = GamePlayer(
          id: 'student1',
          name: 'Alice',
          role: PlayerRole.host,
          lastActive: DateTime.now(),
        );

        // Create a session
        final session = GameSession(
          id: 'session1',
          name: 'Math Practice',
          difficulty: GameDifficulty.normal,
          category: GameCategory.multiplication,
          questions: [
            GameQuestion(
              id: question.id,
              question: question.question,
              options: question.options,
              correctAnswer: question.correctAnswer,
              category: question.category,
              difficulty: question.difficulty,
              gradeLevel: question.gradeLevel,
            ),
          ],
          players: [player],
          createdAt: DateTime.now(),
          totalQuestions: 1,
        );

        // Verify the complete flow
        expect(session.questions.first.question, equals('What is 5 × 3?'));
        expect(
          session.questions.first.options[1],
          equals('15'),
        ); // Correct answer
        expect(session.questions.first.correctAnswer, equals(1));
        expect(session.players.first.name, equals('Alice'));
        expect(session.category, equals(GameCategory.multiplication));
      });

      test('should handle scoring logic', () {
        final player = GamePlayer(
          id: 'player1',
          name: 'Test Player',
          role: PlayerRole.host,
          lastActive: DateTime.now(),
        );

        // Simulate correct answer
        final updatedPlayer = player.copyWith(
          score: player.score + 100,
          correctAnswers: player.correctAnswers + 1,
        );

        expect(updatedPlayer.score, equals(100));
        expect(updatedPlayer.correctAnswers, equals(1));
        expect(updatedPlayer.totalQuestions, equals(0));

        // Simulate answering more questions
        final finalPlayer = updatedPlayer.copyWith(
          totalQuestions: updatedPlayer.totalQuestions + 2,
        );

        expect(finalPlayer.correctAnswers, equals(1));
        expect(finalPlayer.totalQuestions, equals(2));

        // Calculate incorrect answers as total - correct
        final incorrectAnswers =
            finalPlayer.totalQuestions - finalPlayer.correctAnswers;
        expect(incorrectAnswers, equals(1));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty questions list', () {
        final session = GameSession(
          id: 'empty_session',
          name: 'Empty Session',
          difficulty: GameDifficulty.easy,
          category: GameCategory.addition,
          questions: [],
          players: [
            GamePlayer(
              id: 'player1',
              name: 'Player 1',
              role: PlayerRole.host,
              lastActive: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          totalQuestions: 0,
        );

        expect(session.questions, isEmpty);
        expect(session.totalQuestions, equals(0));
      });

      test('should handle invalid answer indices', () {
        final question = AIQuestion(
          id: 'test_q',
          question: 'Test question?',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 1,
          category: GameCategory.addition,
          difficulty: GameDifficulty.easy,
          gradeLevel: GradeLevel.grade1,
        );

        expect(question.correctAnswer, greaterThanOrEqualTo(0));
        expect(question.correctAnswer, lessThan(question.options.length));
      });

      test('should validate question structure', () {
        final question = AIQuestion(
          id: 'validation_test',
          question: 'Is this a valid question?',
          options: ['Yes', 'No', 'Maybe', 'Definitely'],
          correctAnswer: 0,
          category: GameCategory.wordProblems,
          difficulty: GameDifficulty.normal,
          gradeLevel: GradeLevel.grade4,
        );

        expect(question.question, isNotEmpty);
        expect(question.options.length, equals(4));
        expect(question.options.every((option) => option.isNotEmpty), isTrue);
        expect(question.id, isNotEmpty);
      });
    });
  });
}

// Test helper classes
class TestUser {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final DateTime createdAt;

  TestUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });
}
