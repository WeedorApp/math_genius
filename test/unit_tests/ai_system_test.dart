import 'package:flutter_test/flutter_test.dart';
import 'package:math_genius/core/ai/barrel.dart';
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Adaptive Learning Engine Tests', () {
    late AdaptiveLearningEngine learningEngine;

    setUp(() {
      learningEngine = AdaptiveLearningEngine();
    });

    test('should generate learning profile correctly', () async {
      final mockSessions = [
        GameSession(
          id: 'session_1',
          playerId: 'player_1',
          category: GameCategory.addition,
          difficulty: GameDifficulty.easy,
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          endTime: DateTime.now().subtract(const Duration(minutes: 5)),
          score: 80,
          totalQuestions: 10,
          correctAnswers: 8,
          results: [],
        ),
        GameSession(
          id: 'session_2',
          playerId: 'player_1',
          category: GameCategory.subtraction,
          difficulty: GameDifficulty.normal,
          startTime: DateTime.now().subtract(const Duration(minutes: 20)),
          endTime: DateTime.now().subtract(const Duration(minutes: 15)),
          score: 90,
          totalQuestions: 10,
          correctAnswers: 9,
          results: [],
        ),
      ];

      final profile = await learningEngine.generateLearningProfile(
        'student_1',
        mockSessions,
      );

      expect(profile.studentId, equals('student_1'));
      expect(profile.learningStyle, isA<LearningStyle>());
      expect(profile.strengths, isNotEmpty);
      expect(profile.weaknesses, isNotEmpty);
      expect(profile.motivationFactors, isNotEmpty);
    });

    test('should predict optimal difficulty correctly', () async {
      final profile = LearningProfile(
        studentId: 'student_1',
        learningStyle: LearningStyle.visual,
        strengths: StrengthsWeaknesses(
          strong: [LearningObjective.addition],
          weak: [LearningObjective.multiplication],
        ),
        motivationFactors: [MotivationFactor.achievement],
        cognitiveLoad: CognitiveLoad.medium,
        performanceData: PerformanceData(
          overallAccuracy: 0.85,
          averageSpeed: const Duration(seconds: 30),
          consistency: 0.8,
          categoryPerformance: {},
        ),
        preferences: const {},
        lastUpdated: DateTime.now(),
      );

      final difficulty = await learningEngine.predictOptimalDifficulty(
        profile,
        GameCategory.addition,
      );

      expect(difficulty, isA<GameDifficulty>());
      expect([GameDifficulty.easy, GameDifficulty.normal, GameDifficulty.genius, GameDifficulty.quantum]
          .contains(difficulty), isTrue);
    });

    test('should generate contextual hints', () async {
      final profile = LearningProfile(
        studentId: 'student_1',
        learningStyle: LearningStyle.visual,
        strengths: StrengthsWeaknesses(
          strong: [LearningObjective.addition],
          weak: [LearningObjective.multiplication],
        ),
        motivationFactors: [MotivationFactor.curiosity],
        cognitiveLoad: CognitiveLoad.low,
        performanceData: PerformanceData(
          overallAccuracy: 0.75,
          averageSpeed: const Duration(seconds: 45),
          consistency: 0.7,
          categoryPerformance: {},
        ),
        preferences: const {},
        lastUpdated: DateTime.now(),
      );

      final hint = await learningEngine.generateContextualHint(
        profile,
        'What is 7 + 5?',
        GameCategory.addition,
        2, // attempt number
      );

      expect(hint.content, isNotEmpty);
      expect(hint.level, isA<HintLevel>());
      expect(hint.visualAids, isA<List<VisualAid>>());
    });
  });

  group('Enhanced AI Tutor Service Tests', () {
    late EnhancedAITutorService tutorService;

    setUp(() {
      tutorService = EnhancedAITutorService();
    });

    test('should create enhanced tutor session', () async {
      final session = await tutorService.createEnhancedSession(
        'student_1',
        GameCategory.algebra,
        GameDifficulty.normal,
      );

      expect(session.studentId, equals('student_1'));
      expect(session.subject, equals(GameCategory.algebra));
      expect(session.difficulty, equals(GameDifficulty.normal));
      expect(session.tutorPersonality, isA<TutorPersonality>());
      expect(session.sessionContext, isA<SessionContext>());
    });

    test('should generate enhanced hints with personality', () async {
      final session = EnhancedTutorSession(
        id: 'session_1',
        studentId: 'student_1',
        subject: GameCategory.multiplication,
        difficulty: GameDifficulty.easy,
        tutorPersonality: TutorPersonality(
          name: 'Alex',
          style: ExplanationStyle.encouraging,
          tone: EmotionalTone.friendly,
          adaptability: 0.8,
          patience: 0.9,
        ),
        sessionContext: SessionContext(
          currentTopic: 'Basic Multiplication',
          sessionDuration: const Duration(minutes: 15),
          questionsAnswered: 3,
          correctAnswers: 2,
          strugglingAreas: ['Times tables'],
          recentMistakes: ['7 x 8 = 54'],
        ),
        adaptiveParameters: AdaptiveParameters(
          hintFrequency: 0.3,
          encouragementLevel: 0.7,
          difficultyAdjustment: 0.0,
        ),
        engagementMetrics: EngagementMetrics(
          attentionLevel: 0.8,
          frustrationLevel: 0.2,
          confidenceLevel: 0.7,
          motivationLevel: 0.8,
        ),
        startTime: DateTime.now(),
      );

      final hint = await tutorService.generateEnhancedHint(
        session,
        'What is 7 × 8?',
        ['56', '54', '64', '72'],
        2, // attempt number
      );

      expect(hint.content, isNotEmpty);
      expect(hint.personalizedMessage, isNotEmpty);
      expect(hint.level, isA<HintLevel>());
    });
  });

  group('Adaptive Game Integration Tests', () {
    late AdaptiveGameIntegration gameIntegration;

    setUp(() {
      gameIntegration = AdaptiveGameIntegration();
    });

    test('should create adaptive game session', () async {
      final session = await gameIntegration.createAdaptiveGameSession(
        'student_1',
        GameCategory.fractions,
        GameDifficulty.normal,
        10, // question count
      );

      expect(session.studentId, equals('student_1'));
      expect(session.gameCategory, equals(GameCategory.fractions));
      expect(session.targetDifficulty, equals(GameDifficulty.normal));
      expect(session.questionCount, equals(10));
      expect(session.behaviorTracking, isA<StudentBehaviorTracking>());
    });

    test('should process student answers and adapt', () async {
      final session = AdaptiveGameSession(
        id: 'session_1',
        studentId: 'student_1',
        gameCategory: GameCategory.addition,
        targetDifficulty: GameDifficulty.easy,
        questionCount: 5,
        currentQuestionIndex: 0,
        adaptationHistory: [],
        performanceMetrics: AdaptivePerformanceMetrics(
          accuracy: 0.8,
          averageResponseTime: const Duration(seconds: 15),
          difficultyProgression: [],
          engagementScore: 0.7,
          adaptationEffectiveness: 0.6,
        ),
        behaviorTracking: StudentBehaviorTracking(
          responsePatterns: [],
          engagementLevel: 0.8,
          frustrationIndicators: [],
          confidenceLevel: 0.7,
          attentionSpan: const Duration(minutes: 10),
        ),
        startTime: DateTime.now(),
      );

      final result = await gameIntegration.processStudentAnswer(
        session,
        'What is 5 + 3?',
        '8',
        true, // is correct
        const Duration(seconds: 12),
      );

      expect(result.isCorrect, isTrue);
      expect(result.responseTime, equals(const Duration(seconds: 12)));
      expect(result.adaptationTriggered, isA<bool>());
    });
  });

  group('Learning Models Tests', () {
    test('should create and serialize learning profile', () {
      final profile = LearningProfile(
        studentId: 'student_123',
        learningStyle: LearningStyle.kinesthetic,
        strengths: StrengthsWeaknesses(
          strong: [LearningObjective.geometry, LearningObjective.addition],
          weak: [LearningObjective.algebra],
        ),
        motivationFactors: [MotivationFactor.competition, MotivationFactor.achievement],
        cognitiveLoad: CognitiveLoad.high,
        performanceData: PerformanceData(
          overallAccuracy: 0.88,
          averageSpeed: const Duration(seconds: 25),
          consistency: 0.85,
          categoryPerformance: {
            'addition': CategoryPerformance(
              accuracy: 0.95,
              averageTime: const Duration(seconds: 15),
              trend: Trend.improving,
            ),
          },
        ),
        preferences: {'visual_aids': true, 'audio_support': false},
        lastUpdated: DateTime.now(),
      );

      final json = profile.toJson();
      final deserialized = LearningProfile.fromJson(json);

      expect(deserialized.studentId, equals(profile.studentId));
      expect(deserialized.learningStyle, equals(profile.learningStyle));
      expect(deserialized.strengths.strong.length, equals(profile.strengths.strong.length));
      expect(deserialized.motivationFactors.length, equals(profile.motivationFactors.length));
    });

    test('should create learning path with objectives', () {
      final path = LearningPath(
        id: 'path_1',
        studentId: 'student_1',
        objectives: [
          LearningObjective(
            id: 'obj_1',
            title: 'Master Basic Addition',
            description: 'Learn single-digit addition',
            targetAccuracy: 0.9,
            estimatedDuration: const Duration(hours: 2),
            prerequisites: [],
            milestones: [],
            priority: Priority.high,
          ),
        ],
        estimatedDuration: const Duration(hours: 5),
        difficultyProgression: [GameDifficulty.easy, GameDifficulty.normal],
        adaptiveAdjustments: [],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      expect(path.objectives.length, equals(1));
      expect(path.objectives.first.title, equals('Master Basic Addition'));
      expect(path.difficultyProgression.length, equals(2));
    });
  });
}
