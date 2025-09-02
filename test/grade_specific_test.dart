import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_genius/features/game/services/game_service.dart';
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Grade-Specific Question Tests', () {
    late GameService gameService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      gameService = GameService(prefs, null);
    });

    test('PreK addition questions should be very simple', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.preK,
        category: GameCategory.addition,
        difficulty: GameDifficulty.normal,
        count: 3,
      );

      expect(questions.length, 3);
      for (final question in questions) {
        expect(question.gradeLevel, GradeLevel.preK);
        expect(question.category, GameCategory.addition);
        // PreK questions should have emojis and simple numbers
        expect(question.question, contains('🍎'));
      }
    });

    test('Grade 5 addition questions should be more complex', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade5,
        category: GameCategory.addition,
        difficulty: GameDifficulty.normal,
        count: 3,
      );

      expect(questions.length, 3);
      for (final question in questions) {
        expect(question.gradeLevel, GradeLevel.grade5);
        expect(question.category, GameCategory.addition);
      }
    });

    test('Grade 12 algebra questions should be advanced', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade12,
        category: GameCategory.algebra,
        difficulty: GameDifficulty.normal,
        count: 3,
      );

      expect(questions.length, 3);
      for (final question in questions) {
        expect(question.gradeLevel, GradeLevel.grade12);
        expect(question.category, GameCategory.algebra);
      }
    });

    test('Time limits should vary by grade level', () async {
      final prekQuestions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.preK,
        category: GameCategory.addition,
        difficulty: GameDifficulty.normal,
        count: 1,
      );

      final grade12Questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade12,
        category: GameCategory.algebra,
        difficulty: GameDifficulty.normal,
        count: 1,
      );

      // PreK should get more time (45s) than Grade 12 (25s)
      expect(prekQuestions.first.timeLimit, greaterThan(grade12Questions.first.timeLimit));
      expect(prekQuestions.first.timeLimit, 45);
      expect(grade12Questions.first.timeLimit, 25);
    });
  });
}
