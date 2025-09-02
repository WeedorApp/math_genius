import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_genius/features/game/services/game_service.dart';
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Percentage Category Specific Tests', () {
    late GameService gameService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      gameService = GameService(prefs, null);
    });

    test('Percentage questions should be generated correctly', () async {
      final questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade6,
        category: GameCategory.percentages,
        difficulty: GameDifficulty.normal,
        count: 5,
        forceRefresh: true,
      );

      expect(questions.length, 5);
      
      for (final question in questions) {
        expect(question.category, GameCategory.percentages);
        expect(question.gradeLevel, GradeLevel.grade6);
        // Percentage questions should contain % or percent
        expect(
          question.question.toLowerCase(), 
          anyOf(contains('%'), contains('percent'), contains('out of'))
        );
      }
    });

    test('Different grade levels should get appropriate percentage questions', () async {
      // Test PreK percentages
      final prekQuestions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.preK,
        category: GameCategory.percentages,
        difficulty: GameDifficulty.normal,
        count: 2,
        forceRefresh: true,
      );

      // Test Grade 8 percentages  
      final grade8Questions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade8,
        category: GameCategory.percentages,
        difficulty: GameDifficulty.normal,
        count: 2,
        forceRefresh: true,
      );

      expect(prekQuestions.length, 2);
      expect(grade8Questions.length, 2);

      // PreK should have simpler, visual questions
      for (final question in prekQuestions) {
        expect(question.category, GameCategory.percentages);
        expect(question.gradeLevel, GradeLevel.preK);
        expect(question.question, contains('🎨')); // Should have emojis for PreK
      }

      // Grade 8 should have more complex questions
      for (final question in grade8Questions) {
        expect(question.category, GameCategory.percentages);
        expect(question.gradeLevel, GradeLevel.grade8);
      }
    });

    test('Force refresh should bypass cache', () async {
      // Generate questions normally (will be cached)
      final cachedQuestions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade5,
        category: GameCategory.percentages,
        difficulty: GameDifficulty.normal,
        count: 3,
        forceRefresh: false,
      );

      // Generate questions with force refresh (should bypass cache)
      final freshQuestions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade5,
        category: GameCategory.percentages,
        difficulty: GameDifficulty.normal,
        count: 3,
        forceRefresh: true,
      );

      expect(cachedQuestions.length, 3);
      expect(freshQuestions.length, 3);
      
      // Both should be percentage questions
      for (final question in [...cachedQuestions, ...freshQuestions]) {
        expect(question.category, GameCategory.percentages);
      }
    });
  });
}
