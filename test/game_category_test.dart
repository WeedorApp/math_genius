import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_genius/features/game/services/game_service.dart';
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Game Category Tests', () {
    late GameService gameService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      gameService = GameService(prefs, null);
    });

    test('Addition questions should be generated for addition category', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade3,
        category: GameCategory.addition,
        difficulty: GameDifficulty.normal,
        count: 5,
      );

      expect(questions.length, 5);
      // All questions should be addition
      for (final question in questions) {
        expect(question.category, GameCategory.addition);
        expect(question.question, contains('+'));
      }
    });

    test('Algebra questions should be generated for algebra category', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade7,
        category: GameCategory.algebra,
        difficulty: GameDifficulty.normal,
        count: 3,
      );

      expect(questions.length, 3);
      // All questions should be algebra
      for (final question in questions) {
        expect(question.category, GameCategory.algebra);
        expect(question.question, contains('x'));
      }
    });

    test('Geometry questions should be generated for geometry category', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade6,
        category: GameCategory.geometry,
        difficulty: GameDifficulty.normal,
        count: 3,
      );

      expect(questions.length, 3);
      // All questions should be geometry
      for (final question in questions) {
        expect(question.category, GameCategory.geometry);
      }
    });

    test('Fractions questions should be generated for fractions category', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade4,
        category: GameCategory.fractions,
        difficulty: GameDifficulty.normal,
        count: 3,
      );

      expect(questions.length, 3);
      // All questions should be fractions
      for (final question in questions) {
        expect(question.category, GameCategory.fractions);
        expect(question.question, anyOf(contains('/'), contains('fraction')));
      }
    });

    test('All categories should generate appropriate questions', () async {
      for (final category in GameCategory.values) {
        final questions = await gameService.generateAIQuestions(
          gradeLevel: GradeLevel.grade5,
          category: category,
          difficulty: GameDifficulty.normal,
          count: 1,
        );

        expect(questions.length, 1);
        expect(questions.first.category, category,
            reason: 'Category $category should generate questions with matching category');
      }
    });
  });
}
