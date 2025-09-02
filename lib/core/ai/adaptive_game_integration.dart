import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';

// Core imports
import '../barrel.dart';

// Feature imports
import '../../features/game/models/game_model.dart';
import '../../features/ai_tutor_agent/services/enhanced_ai_tutor_service.dart';

/// Integration service that connects adaptive learning with the game system
class AdaptiveGameIntegration {
  static const String _adaptiveSessionsKey = 'adaptive_game_sessions';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final AdaptiveLearningEngine _adaptiveLearningEngine;
  final EnhancedAITutorService _enhancedTutorService;

  AdaptiveGameIntegration(
    this._prefs,
    this._hiveBox,
    this._adaptiveLearningEngine,
    this._enhancedTutorService,
  );

  /// Create an adaptive game session with personalized parameters
  Future<AdaptiveGameSession> createAdaptiveGameSession({
    required String studentId,
    required GradeLevel gradeLevel,
    required GameCategory category,
    String? parentSessionId,
  }) async {
    try {
      // Get student's learning profile
      final learningProfile = await _adaptiveLearningEngine.getLearningProfile(
        studentId,
      );

      // Predict optimal difficulty
      final recentResults = await _getRecentGameResults(studentId, category);
      final optimalDifficulty = await _adaptiveLearningEngine
          .predictOptimalDifficulty(studentId, category, recentResults);

      // Generate personalized learning path
      final masteredObjectives = await _getMasteredObjectives(
        studentId,
        gradeLevel,
      );
      final learningPath = await _adaptiveLearningEngine.generateLearningPath(
        studentId,
        gradeLevel,
        masteredObjectives,
      );

      // Create enhanced tutor session
      final tutorSession = await _enhancedTutorService.createTutorSession(
        studentId: studentId,
        subject: category.toString(),
      );

      // Create adaptive game session
      final adaptiveSession = AdaptiveGameSession(
        id: _generateId(),
        studentId: studentId,
        gradeLevel: gradeLevel,
        category: category,
        optimalDifficulty: optimalDifficulty,
        learningProfile: learningProfile,
        learningPath: learningPath,
        tutorSessionId: tutorSession.id,
        behaviorTracking: StudentBehaviorTracking.initial(),
        adaptationEvents: [],
        performanceMetrics: AdaptivePerformanceMetrics.initial(),
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isActive: true,
      );

      await _saveAdaptiveSession(adaptiveSession);
      return adaptiveSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating adaptive game session: $e');
      }
      rethrow;
    }
  }

  /// Generate adaptive questions based on student's current state
  Future<List<AIQuestion>> generateAdaptiveQuestions({
    required String sessionId,
    required int questionCount,
    required StudentBehavior currentBehavior,
  }) async {
    try {
      final session = await getAdaptiveSession(sessionId);
      if (session == null) {
        throw Exception('Adaptive session not found: $sessionId');
      }

      // Analyze current behavior and adjust difficulty if needed
      final adjustedDifficulty = await _adjustDifficultyBasedOnBehavior(
        session.optimalDifficulty,
        currentBehavior,
        session.performanceMetrics,
      );

      // Generate questions using a placeholder method (would integrate with actual AI service)
      final questions = await _generateQuestionsPlaceholder(
        gradeLevel: session.gradeLevel,
        category: session.category,
        difficulty: adjustedDifficulty,
        count: questionCount,
        userId: session.studentId,
        userContext: await _buildUserContext(session, currentBehavior),
      );

      // Enhance questions with adaptive features
      final enhancedQuestions = await _enhanceQuestionsWithAdaptiveFeatures(
        questions,
        session,
        currentBehavior,
      );

      // Update session with new questions
      await _updateSessionWithQuestions(sessionId, enhancedQuestions);

      return enhancedQuestions;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating adaptive questions: $e');
      }
      rethrow;
    }
  }

  /// Provide adaptive hint based on student's current state and question context
  Future<EnhancedHint> provideAdaptiveHint({
    required String sessionId,
    required AIQuestion question,
    required List<String> previousAttempts,
    required Duration timeSpent,
    required StudentBehavior currentBehavior,
  }) async {
    try {
      final session = await getAdaptiveSession(sessionId);
      if (session == null) {
        throw Exception('Adaptive session not found: $sessionId');
      }

      // Generate enhanced hint - simplified approach
      final enhancedHint = EnhancedHint(
        id: _generateId(),
        encouragement: 'You can do this!',
        deliveryStyle: DeliveryStyle.gentle,
        emotionalTone: EmotionalTone.encouraging,
        visualEnhancements: [],
        audioEnhancements: [],
        interactiveEnhancements: [],
        baseHint: AdaptiveHint(
          id: _generateId(),
          questionId: question.id,
          studentId: session.studentId,
          hintLevel: HintLevel.gentle,
          content: question.hint ?? 'Think about the problem step by step',
          visualAids: [],
          audioSupport: AudioSupport(
            questionReading: false,
            hintReading: false,
            encouragement: false,
          ),
          interactiveElements: [],
          learningStyle: LearningStyle.visual,
          estimatedHelpfulness: 0.8,
          createdAt: DateTime.now(),
        ),
        personalizedContent: 'Here\'s a hint: ${question.hint ?? 'Break this down into smaller steps'}',
        createdAt: DateTime.now(),
      );

      // Track hint usage for adaptation
      await _trackHintUsage(sessionId, enhancedHint, currentBehavior);

      return enhancedHint;
    } catch (e) {
      if (kDebugMode) {
        print('Error providing adaptive hint: $e');
      }
      rethrow;
    }
  }

  /// Process student's answer and provide adaptive feedback
  Future<AdaptiveFeedback> processStudentAnswer({
    required String sessionId,
    required AIQuestion question,
    required String studentAnswer,
    required bool isCorrect,
    required Duration responseTime,
    required StudentBehavior currentBehavior,
  }) async {
    try {
      final session = await getAdaptiveSession(sessionId);
      if (session == null) {
        throw Exception('Adaptive session not found: $sessionId');
      }

      // Update performance metrics
      final updatedMetrics = await _updatePerformanceMetrics(
        session.performanceMetrics,
        isCorrect,
        responseTime,
        question.difficulty,
      );

      // Generate adaptive feedback
      final feedback = await _generateAdaptiveFeedback(
        question,
        studentAnswer,
        isCorrect,
        session,
        currentBehavior,
      );

      // Check if adaptation is needed
      final adaptationNeeded = await _checkIfAdaptationNeeded(
        session,
        currentBehavior,
        updatedMetrics,
      );

      if (adaptationNeeded) {
        await _performAdaptation(sessionId, currentBehavior, updatedMetrics);
      }

      // Update session
      await _updateSessionMetrics(sessionId, updatedMetrics);

      return feedback;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing student answer: $e');
      }
      rethrow;
    }
  }

  /// Track student behavior for real-time adaptation
  Future<void> trackStudentBehavior({
    required String sessionId,
    required StudentBehavior behavior,
  }) async {
    try {
      final session = await getAdaptiveSession(sessionId);
      if (session == null) return;

      // Update behavior tracking
      final updatedTracking = session.behaviorTracking.addBehaviorPoint(
        behavior,
      );

      // Analyze behavior patterns
      final behaviorAnalysis = await _analyzeBehaviorPatterns(updatedTracking);

      // Generate engagement strategy if needed
      if (behaviorAnalysis.needsIntervention) {
        final engagementStrategy = await _adaptiveLearningEngine
            .optimizeEngagement(sessionId, behavior);

        await _applyEngagementStrategy(sessionId, engagementStrategy);
      }

      // Update session
      await _updateSessionBehaviorTracking(sessionId, updatedTracking);
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking student behavior: $e');
      }
    }
  }

  /// Generate learning insights for the session
  Future<List<LearningInsight>> generateSessionInsights({
    required String sessionId,
  }) async {
    try {
      final session = await getAdaptiveSession(sessionId);
      if (session == null) return [];

      final insights = <LearningInsight>[];

      // Generate insights from tutor service
      final sessionDuration = DateTime.now().difference(session.createdAt);
      final tutorInsight = LearningInsight(
        type: InsightType.recommendation,
        title: 'Tutor Session Analysis',
        description: 'Session lasted ${sessionDuration.inMinutes} minutes',
        recommendation: 'Continue with current approach',
        confidence: 0.7,
        priority: Priority.medium,
        createdAt: DateTime.now(),
      );
      insights.add(tutorInsight);

      // Generate performance insights
      final performanceInsights = await _generatePerformanceInsights(session);
      insights.addAll(performanceInsights);

      // Generate adaptation insights
      final adaptationInsights = await _generateAdaptationInsights(session);
      insights.addAll(adaptationInsights);

      return insights;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating session insights: $e');
      }
      return [];
    }
  }

  /// Get adaptive session by ID
  Future<AdaptiveGameSession?> getAdaptiveSession(String sessionId) async {
    try {
      final sessionsString = _prefs.getString(_adaptiveSessionsKey);
      if (sessionsString == null) return null;

      final sessionsMap = jsonDecode(sessionsString) as Map<String, dynamic>;
      final sessionData = sessionsMap[sessionId];
      if (sessionData == null) return null;

      return AdaptiveGameSession.fromJson(sessionData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting adaptive session: $e');
      }
      return null;
    }
  }

  /// Get all adaptive sessions for a student
  Future<List<AdaptiveGameSession>> getStudentAdaptiveSessions(
    String studentId,
  ) async {
    try {
      final sessionsString = _prefs.getString(_adaptiveSessionsKey);
      if (sessionsString == null) return [];

      final sessionsMap = jsonDecode(sessionsString) as Map<String, dynamic>;
      final studentSessions = <AdaptiveGameSession>[];

      for (final sessionData in sessionsMap.values) {
        final session = AdaptiveGameSession.fromJson(
          sessionData as Map<String, dynamic>,
        );
        if (session.studentId == studentId) {
          studentSessions.add(session);
        }
      }

      // Sort by most recent first
      studentSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return studentSessions;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student adaptive sessions: $e');
      }
      return [];
    }
  }

  // Private helper methods

  Future<List<AIQuestion>> _generateQuestionsPlaceholder({
    required GradeLevel gradeLevel,
    required GameCategory category,
    required GameDifficulty difficulty,
    required int count,
    required String userId,
    required Map<String, dynamic> userContext,
  }) async {
    // Placeholder implementation - would integrate with actual AI service
    final questions = <AIQuestion>[];

    for (int i = 0; i < count; i++) {
      questions.add(
        AIQuestion(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$i',
          question: 'Sample question ${i + 1} for $category',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswer: 0,
          category: category,
          difficulty: difficulty,
          gradeLevel: gradeLevel,
          explanation: 'Sample explanation',
          hint: 'Sample hint',
          timeLimit: 30,
          aiMetadata: userContext,
          confidence: 0.8,
          learningObjectives: ['Sample objective'],
        ),
      );
    }

    return questions;
  }

  Future<List<GameResult>> _getRecentGameResults(
    String studentId,
    GameCategory category,
  ) async {
    // Get recent game results for the student in this category
    // This would typically query the game service or database
    return []; // Placeholder
  }

  Future<List<LearningObjective>> _getMasteredObjectives(
    String studentId,
    GradeLevel gradeLevel,
  ) async {
    // Get objectives the student has already mastered
    // This would typically query the learning progress service
    return []; // Placeholder
  }

  Future<GameDifficulty> _adjustDifficultyBasedOnBehavior(
    GameDifficulty currentDifficulty,
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) async {
    // Adjust difficulty based on current behavior and performance
    if (behavior.frustrationLevel > 0.8 || metrics.recentAccuracy < 0.4) {
      // Decrease difficulty if student is frustrated or struggling
      switch (currentDifficulty) {
        case GameDifficulty.quantum:
          return GameDifficulty.genius;
        case GameDifficulty.genius:
          return GameDifficulty.normal;
        case GameDifficulty.normal:
          return GameDifficulty.easy;
        case GameDifficulty.easy:
          return GameDifficulty.easy;
      }
    } else if (behavior.boredomLevel > 0.7 && metrics.recentAccuracy > 0.85) {
      // Increase difficulty if student is bored and performing well
      switch (currentDifficulty) {
        case GameDifficulty.easy:
          return GameDifficulty.normal;
        case GameDifficulty.normal:
          return GameDifficulty.genius;
        case GameDifficulty.genius:
          return GameDifficulty.quantum;
        case GameDifficulty.quantum:
          return GameDifficulty.quantum;
      }
    }

    return currentDifficulty;
  }

  Future<Map<String, dynamic>> _buildUserContext(
    AdaptiveGameSession session,
    StudentBehavior behavior,
  ) async {
    return {
      'learningProfile': session.learningProfile?.toJson(),
      'currentBehavior': behavior.toJson(),
      'performanceMetrics': session.performanceMetrics.toJson(),
      'sessionDuration': DateTime.now().difference(session.createdAt).inMinutes,
    };
  }

  Future<List<AIQuestion>> _enhanceQuestionsWithAdaptiveFeatures(
    List<AIQuestion> questions,
    AdaptiveGameSession session,
    StudentBehavior behavior,
  ) async {
    final enhancedQuestions = <AIQuestion>[];

    for (final question in questions) {
      // Add adaptive features based on learning profile
      var enhancedQuestion = question;

      if (session.learningProfile?.learningStyle == LearningStyle.visual) {
        // Add visual aids for visual learners (would be implemented in actual AI service)
        // enhancedQuestion = enhancedQuestion.copyWith(visualAid: 'diagram');
      }

      if (session.learningProfile?.learningStyle == LearningStyle.auditory) {
        // Add audio support for auditory learners (would be implemented in actual AI service)
        // enhancedQuestion = enhancedQuestion.copyWith(audioSupport: true);
      }

      // Adjust time limit based on cognitive load
      if (session.learningProfile?.cognitiveLoad == CognitiveLoad.high) {
        enhancedQuestion = enhancedQuestion.copyWith(
          timeLimit: (question.timeLimit * 1.5).round(),
        );
      }

      enhancedQuestions.add(enhancedQuestion);
    }

    return enhancedQuestions;
  }

  Future<void> _trackHintUsage(
    String sessionId,
    EnhancedHint hint,
    StudentBehavior behavior,
  ) async {
    // Track hint usage for learning analytics
    final hintUsage = HintUsageEvent(
      sessionId: sessionId,
      hintId: hint.id,
      hintLevel: hint.baseHint.hintLevel,
      studentBehavior: behavior,
      timestamp: DateTime.now(),
    );

    await _saveHintUsageEvent(hintUsage);
  }

  Future<AdaptivePerformanceMetrics> _updatePerformanceMetrics(
    AdaptivePerformanceMetrics currentMetrics,
    bool isCorrect,
    Duration responseTime,
    GameDifficulty difficulty,
  ) async {
    final newTotalQuestions = currentMetrics.totalQuestions + 1;
    final newCorrectAnswers =
        currentMetrics.correctAnswers + (isCorrect ? 1 : 0);
    final newAccuracy = newCorrectAnswers / newTotalQuestions;

    // Update recent accuracy (last 10 questions)
    final recentResults = List<bool>.from(currentMetrics.recentResults);
    recentResults.add(isCorrect);
    if (recentResults.length > 10) {
      recentResults.removeAt(0);
    }
    final recentAccuracy =
        recentResults.where((r) => r).length / recentResults.length;

    // Update average response time
    final totalResponseTime =
        currentMetrics.averageResponseTime.inMilliseconds *
        currentMetrics.totalQuestions;
    final newTotalResponseTime =
        totalResponseTime + responseTime.inMilliseconds;
    final newAverageResponseTime = Duration(
      milliseconds: newTotalResponseTime ~/ newTotalQuestions,
    );

    return currentMetrics.copyWith(
      totalQuestions: newTotalQuestions,
      correctAnswers: newCorrectAnswers,
      accuracy: newAccuracy,
      recentAccuracy: recentAccuracy,
      recentResults: recentResults,
      averageResponseTime: newAverageResponseTime,
      lastUpdated: DateTime.now(),
    );
  }

  Future<AdaptiveFeedback> _generateAdaptiveFeedback(
    AIQuestion question,
    String studentAnswer,
    bool isCorrect,
    AdaptiveGameSession session,
    StudentBehavior behavior,
  ) async {
    String message;
    FeedbackType type;
    List<String> suggestions = [];

    if (isCorrect) {
      type = FeedbackType.positive;
      if (behavior.engagementLevel > 0.8) {
        message = "Excellent work! You're really getting the hang of this!";
      } else {
        message = "Great job! That's the correct answer.";
      }

      // Suggest next steps for correct answers
      if (session.performanceMetrics.recentAccuracy > 0.85) {
        suggestions.add("Ready for a more challenging problem?");
      }
    } else {
      if (behavior.frustrationLevel > 0.7) {
        type = FeedbackType.supportive;
        message =
            "Don't worry, this is a tricky one! Let's work through it together.";
        suggestions.addAll([
          "Would you like a hint?",
          "Let's try breaking this down into smaller steps",
        ]);
      } else {
        type = FeedbackType.corrective;
        message = "Not quite right, but you're on the right track!";
        suggestions.addAll([
          "Think about ${question.hint ?? 'the key concept here'}",
          "Would you like to try again?",
        ]);
      }
    }

    return AdaptiveFeedback(
      id: _generateId(),
      questionId: question.id,
      studentAnswer: studentAnswer,
      isCorrect: isCorrect,
      type: type,
      message: message,
      suggestions: suggestions,
      personalizedElements: await _addPersonalizedFeedbackElements(
        session,
        behavior,
      ),
      createdAt: DateTime.now(),
    );
  }

  Future<bool> _checkIfAdaptationNeeded(
    AdaptiveGameSession session,
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) async {
    // Check various conditions that might trigger adaptation

    // High frustration level
    if (behavior.frustrationLevel > 0.8) {
      return true;
    }

    // Low engagement for extended period
    if (behavior.engagementLevel < 0.3 &&
        behavior.sessionDuration.inMinutes > 5) {
      return true;
    }

    // Performance significantly below expected level
    if (metrics.recentAccuracy < 0.4 && metrics.totalQuestions > 3) {
      return true;
    }

    // Performance significantly above expected level (boredom risk)
    if (metrics.recentAccuracy > 0.9 && behavior.boredomLevel > 0.6) {
      return true;
    }

    return false;
  }

  Future<void> _performAdaptation(
    String sessionId,
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) async {
    final session = await getAdaptiveSession(sessionId);
    if (session == null) return;

    final adaptationEvent = AdaptationEvent(
      id: _generateId(),
      sessionId: sessionId,
      trigger: _identifyAdaptationTrigger(behavior, metrics),
      adaptationType: _determineAdaptationType(behavior, metrics),
      parameters: await _calculateAdaptationParameters(behavior, metrics),
      timestamp: DateTime.now(),
    );

    // Apply the adaptation
    await _applyAdaptation(sessionId, adaptationEvent);

    // Record the adaptation event
    await _recordAdaptationEvent(sessionId, adaptationEvent);
  }

  Future<BehaviorAnalysis> _analyzeBehaviorPatterns(
    StudentBehaviorTracking tracking,
  ) async {
    final recentBehaviors = tracking.behaviorHistory.take(5).toList();

    // Analyze trends
    final frustrationTrend = _calculateTrend(
      recentBehaviors.map((b) => b.frustrationLevel).toList(),
    );
    final engagementTrend = _calculateTrend(
      recentBehaviors.map((b) => b.engagementLevel).toList(),
    );

    // Determine if intervention is needed
    final needsIntervention =
        frustrationTrend > 0.2 ||
        engagementTrend < -0.2 ||
        recentBehaviors.any((b) => b.frustrationLevel > 0.8);

    return BehaviorAnalysis(
      frustrationTrend: frustrationTrend,
      engagementTrend: engagementTrend,
      needsIntervention: needsIntervention,
      recommendedActions: _generateRecommendedActions(
        frustrationTrend,
        engagementTrend,
      ),
    );
  }

  Future<void> _applyEngagementStrategy(
    String sessionId,
    EngagementStrategy strategy,
  ) async {
    // Apply the engagement strategy to the session
    // This might involve adjusting difficulty, providing encouragement, etc.

    final strategyApplication = EngagementStrategyApplication(
      sessionId: sessionId,
      strategy: strategy,
      appliedAt: DateTime.now(),
    );

    await _saveEngagementStrategyApplication(strategyApplication);
  }

  Future<List<LearningInsight>> _generatePerformanceInsights(
    AdaptiveGameSession session,
  ) async {
    final insights = <LearningInsight>[];

    // Analyze performance trends
    if (session.performanceMetrics.recentAccuracy < 0.5) {
      insights.add(
        LearningInsight(
          type: InsightType.performance,
          title: 'Performance Challenge',
          description: 'Student is struggling with recent questions',
          recommendation:
              'Consider reducing difficulty or providing additional support',
          confidence: 0.8,
          priority: Priority.high,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Analyze response time patterns
    if (session.performanceMetrics.averageResponseTime.inSeconds > 45) {
      insights.add(
        LearningInsight(
          type: InsightType.performance,
          title: 'Response Time',
          description: 'Student is taking longer than average to respond',
          recommendation:
              'Check if questions are too complex or if student needs more time',
          confidence: 0.7,
          priority: Priority.medium,
          createdAt: DateTime.now(),
        ),
      );
    }

    return insights;
  }

  Future<List<LearningInsight>> _generateAdaptationInsights(
    AdaptiveGameSession session,
  ) async {
    final insights = <LearningInsight>[];

    // Analyze adaptation effectiveness
    if (session.adaptationEvents.isNotEmpty) {
      final recentAdaptations = session.adaptationEvents
          .where((e) => DateTime.now().difference(e.timestamp).inMinutes < 10)
          .toList();

      if (recentAdaptations.isNotEmpty) {
        insights.add(
          LearningInsight(
            type: InsightType.recommendation,
            title: 'Recent Adaptations',
            description:
                'System has made ${recentAdaptations.length} recent adaptations',
            recommendation: 'Monitor effectiveness of recent changes',
            confidence: 0.6,
            priority: Priority.low,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return insights;
  }

  // Storage methods

  Future<void> _saveAdaptiveSession(AdaptiveGameSession session) async {
    try {
      final sessionsString = _prefs.getString(_adaptiveSessionsKey);
      final sessionsMap = sessionsString != null
          ? Map<String, dynamic>.from(jsonDecode(sessionsString))
          : <String, dynamic>{};

      sessionsMap[session.id] = session.toJson();

      await _prefs.setString(_adaptiveSessionsKey, jsonEncode(sessionsMap));

      // Also save to Hive for better performance
      if (_hiveBox != null) {
        await _hiveBox.put(
          '${_adaptiveSessionsKey}_${session.id}',
          session.toJson(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving adaptive session: $e');
      }
    }
  }

  Future<void> _updateSessionWithQuestions(
    String sessionId,
    List<AIQuestion> questions,
  ) async {
    final session = await getAdaptiveSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(lastUpdated: DateTime.now());
      await _saveAdaptiveSession(updatedSession);
    }
  }

  Future<void> _updateSessionMetrics(
    String sessionId,
    AdaptivePerformanceMetrics metrics,
  ) async {
    final session = await getAdaptiveSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        performanceMetrics: metrics,
        lastUpdated: DateTime.now(),
      );
      await _saveAdaptiveSession(updatedSession);
    }
  }

  Future<void> _updateSessionBehaviorTracking(
    String sessionId,
    StudentBehaviorTracking tracking,
  ) async {
    final session = await getAdaptiveSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        behaviorTracking: tracking,
        lastUpdated: DateTime.now(),
      );
      await _saveAdaptiveSession(updatedSession);
    }
  }

  Future<void> _saveHintUsageEvent(HintUsageEvent event) async {
    try {
      final eventsString = _prefs.getString('hint_usage_events');
      final eventsList = eventsString != null
          ? List<Map<String, dynamic>>.from(jsonDecode(eventsString))
          : <Map<String, dynamic>>[];

      eventsList.add(event.toJson());

      // Keep only last 100 events to manage storage
      if (eventsList.length > 100) {
        eventsList.removeRange(0, eventsList.length - 100);
      }

      await _prefs.setString('hint_usage_events', jsonEncode(eventsList));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving hint usage event: $e');
      }
    }
  }

  Future<void> _recordAdaptationEvent(
    String sessionId,
    AdaptationEvent event,
  ) async {
    final session = await getAdaptiveSession(sessionId);
    if (session != null) {
      final updatedEvents = List<AdaptationEvent>.from(session.adaptationEvents)
        ..add(event);
      final updatedSession = session.copyWith(
        adaptationEvents: updatedEvents,
        lastUpdated: DateTime.now(),
      );
      await _saveAdaptiveSession(updatedSession);
    }
  }

  Future<void> _saveEngagementStrategyApplication(
    EngagementStrategyApplication application,
  ) async {
    try {
      final applicationsString = _prefs.getString(
        'engagement_strategy_applications',
      );
      final applicationsList = applicationsString != null
          ? List<Map<String, dynamic>>.from(jsonDecode(applicationsString))
          : <Map<String, dynamic>>[];

      applicationsList.add(application.toJson());

      // Keep only last 50 applications to manage storage
      if (applicationsList.length > 50) {
        applicationsList.removeRange(0, applicationsList.length - 50);
      }

      await _prefs.setString(
        'engagement_strategy_applications',
        jsonEncode(applicationsList),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving engagement strategy application: $e');
      }
    }
  }

  // Utility methods

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<List<String>> _addPersonalizedFeedbackElements(
    AdaptiveGameSession session,
    StudentBehavior behavior,
  ) async {
    final elements = <String>[];

    if (session.learningProfile?.motivationFactors.contains(
          MotivationFactor.achievement,
        ) ??
        false) {
      elements.add("Achievement progress updated!");
    }

    if (behavior.frustrationLevel > 0.6) {
      elements.add("Remember, every expert was once a beginner!");
    }

    return elements;
  }

  AdaptationTrigger _identifyAdaptationTrigger(
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) {
    if (behavior.frustrationLevel > 0.8) {
      return AdaptationTrigger.highFrustration;
    } else if (behavior.engagementLevel < 0.3) {
      return AdaptationTrigger.lowEngagement;
    } else if (metrics.recentAccuracy < 0.4) {
      return AdaptationTrigger.poorPerformance;
    } else if (metrics.recentAccuracy > 0.9 && behavior.boredomLevel > 0.6) {
      return AdaptationTrigger.boredom;
    } else {
      return AdaptationTrigger.other;
    }
  }

  AdaptationType _determineAdaptationType(
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) {
    if (behavior.frustrationLevel > 0.8 || metrics.recentAccuracy < 0.4) {
      return AdaptationType.difficultyReduction;
    } else if (behavior.boredomLevel > 0.6 && metrics.recentAccuracy > 0.9) {
      return AdaptationType.difficultyIncrease;
    } else if (behavior.engagementLevel < 0.3) {
      return AdaptationType.engagementBoost;
    } else {
      return AdaptationType.other;
    }
  }

  Future<Map<String, dynamic>> _calculateAdaptationParameters(
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) async {
    return {
      'frustrationLevel': behavior.frustrationLevel,
      'engagementLevel': behavior.engagementLevel,
      'recentAccuracy': metrics.recentAccuracy,
      'adaptationStrength': _calculateAdaptationStrength(behavior, metrics),
    };
  }

  double _calculateAdaptationStrength(
    StudentBehavior behavior,
    AdaptivePerformanceMetrics metrics,
  ) {
    // Calculate how strong the adaptation should be
    if (behavior.frustrationLevel > 0.9 || metrics.recentAccuracy < 0.2) {
      return 1.0; // Strong adaptation needed
    } else if (behavior.frustrationLevel > 0.7 ||
        metrics.recentAccuracy < 0.4) {
      return 0.7; // Moderate adaptation
    } else {
      return 0.3; // Gentle adaptation
    }
  }

  Future<void> _applyAdaptation(String sessionId, AdaptationEvent event) async {
    // Apply the specific adaptation based on the event type
    switch (event.adaptationType) {
      case AdaptationType.difficultyReduction:
        await _reduceDifficulty(sessionId, event.parameters);
        break;
      case AdaptationType.difficultyIncrease:
        await _increaseDifficulty(sessionId, event.parameters);
        break;
      case AdaptationType.engagementBoost:
        await _boostEngagement(sessionId, event.parameters);
        break;
      case AdaptationType.hintFrequencyAdjustment:
        await _adjustHintFrequency(sessionId, event.parameters);
        break;
      case AdaptationType.encouragementIncrease:
        await _increaseEncouragement(sessionId, event.parameters);
        break;
      case AdaptationType.breakSuggestion:
        await _suggestBreak(sessionId, event.parameters);
        break;
      case AdaptationType.other:
        // Handle other adaptation types
        break;
    }
  }

  Future<void> _reduceDifficulty(
    String sessionId,
    Map<String, dynamic> parameters,
  ) async {
    // Implementation for reducing difficulty
    // This might involve changing question types, providing more hints, etc.
  }

  Future<void> _increaseDifficulty(
    String sessionId,
    Map<String, dynamic> parameters,
  ) async {
    // Implementation for increasing difficulty
    // This might involve more complex questions, less hints, etc.
  }

  Future<void> _boostEngagement(
    String sessionId,
    Map<String, dynamic> parameters,
  ) async {
    // Implementation for boosting engagement
    // This might involve gamification elements, animations, etc.
  }

  Future<void> _adjustHintFrequency(
    String sessionId,
    Map<String, dynamic> parameters,
  ) async {
    // Implementation for adjusting hint frequency
    // This might involve changing how often hints are offered
  }

  Future<void> _increaseEncouragement(
    String sessionId,
    Map<String, dynamic> parameters,
  ) async {
    // Implementation for increasing encouragement
    // This might involve more frequent positive feedback
  }

  Future<void> _suggestBreak(
    String sessionId,
    Map<String, dynamic> parameters,
  ) async {
    // Implementation for suggesting breaks
    // This might involve showing break reminders or activities
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    // Simple linear trend calculation
    final firstValue = values.first;
    final lastValue = values.last;
    return (lastValue - firstValue) / (values.length - 1);
  }

  List<String> _generateRecommendedActions(
    double frustrationTrend,
    double engagementTrend,
  ) {
    final actions = <String>[];

    if (frustrationTrend > 0.2) {
      actions.add("Provide additional support");
      actions.add("Consider reducing difficulty");
    }

    if (engagementTrend < -0.2) {
      actions.add("Introduce engaging elements");
      actions.add("Take a short break");
    }

    return actions;
  }
}

/// Riverpod providers for adaptive game integration
final adaptiveGameIntegrationProvider = Provider<AdaptiveGameIntegration>((
  ref,
) {
  throw UnimplementedError('AdaptiveGameIntegration must be initialized');
});

final adaptiveGameSessionProvider =
    FutureProvider.family<AdaptiveGameSession?, String>((ref, sessionId) async {
      final integration = ref.read(adaptiveGameIntegrationProvider);
      return integration.getAdaptiveSession(sessionId);
    });

final studentAdaptiveSessionsProvider =
    FutureProvider.family<List<AdaptiveGameSession>, String>((
      ref,
      studentId,
    ) async {
      final integration = ref.read(adaptiveGameIntegrationProvider);
      return integration.getStudentAdaptiveSessions(studentId);
    });

final adaptiveQuestionsProvider =
    FutureProvider.family<List<AIQuestion>, AdaptiveQuestionsParams>((
      ref,
      params,
    ) async {
      final integration = ref.read(adaptiveGameIntegrationProvider);
      return integration.generateAdaptiveQuestions(
        sessionId: params.sessionId,
        questionCount: params.questionCount,
        currentBehavior: params.currentBehavior,
      );
    });

final gameAdaptiveHintProvider =
    FutureProvider.family<EnhancedHint, GameAdaptiveHintParams>((
      ref,
      params,
    ) async {
      final integration = ref.read(adaptiveGameIntegrationProvider);
      return integration.provideAdaptiveHint(
        sessionId: params.sessionId,
        question: params.question,
        previousAttempts: params.previousAttempts,
        timeSpent: params.timeSpent,
        currentBehavior: params.currentBehavior,
      );
    });

final adaptiveFeedbackProvider =
    FutureProvider.family<AdaptiveFeedback, AdaptiveFeedbackParams>((
      ref,
      params,
    ) async {
      final integration = ref.read(adaptiveGameIntegrationProvider);
      return integration.processStudentAnswer(
        sessionId: params.sessionId,
        question: params.question,
        studentAnswer: params.studentAnswer,
        isCorrect: params.isCorrect,
        responseTime: params.responseTime,
        currentBehavior: params.currentBehavior,
      );
    });

final sessionInsightsProvider =
    FutureProvider.family<List<LearningInsight>, String>((
      ref,
      sessionId,
    ) async {
      final integration = ref.read(adaptiveGameIntegrationProvider);
      return integration.generateSessionInsights(sessionId: sessionId);
    });

// Parameter classes for providers
class AdaptiveQuestionsParams {
  final String sessionId;
  final int questionCount;
  final StudentBehavior currentBehavior;

  AdaptiveQuestionsParams({
    required this.sessionId,
    required this.questionCount,
    required this.currentBehavior,
  });
}

class GameAdaptiveHintParams {
  final String sessionId;
  final AIQuestion question;
  final List<String> previousAttempts;
  final Duration timeSpent;
  final StudentBehavior currentBehavior;

  GameAdaptiveHintParams({
    required this.sessionId,
    required this.question,
    required this.previousAttempts,
    required this.timeSpent,
    required this.currentBehavior,
  });
}

class AdaptiveFeedbackParams {
  final String sessionId;
  final AIQuestion question;
  final String studentAnswer;
  final bool isCorrect;
  final Duration responseTime;
  final StudentBehavior currentBehavior;

  AdaptiveFeedbackParams({
    required this.sessionId,
    required this.question,
    required this.studentAnswer,
    required this.isCorrect,
    required this.responseTime,
    required this.currentBehavior,
  });
}
