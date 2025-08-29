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

/// Enhanced AI tutor service with adaptive learning capabilities
class EnhancedAITutorService {
  static const String _enhancedSessionsKey = 'enhanced_tutor_sessions';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final AdaptiveLearningEngine _adaptiveLearningEngine;

  EnhancedAITutorService(
    this._prefs,
    this._hiveBox,
    this._adaptiveLearningEngine,
  );

  /// Create an enhanced tutor session with adaptive capabilities
  Future<EnhancedTutorSession> createEnhancedSession({
    required String studentId,
    required String topic,
    required GradeLevel gradeLevel,
    required GameCategory category,
    String? parentSessionId,
  }) async {
    try {
      // Get student's learning profile for personalization
      final learningProfile = await _adaptiveLearningEngine.getLearningProfile(
        studentId,
      );

      // Generate personalized tutor personality
      final tutorPersonality = await _generateTutorPersonality(learningProfile);

      // Create adaptive session context
      final sessionContext = await _createSessionContext(
        studentId,
        topic,
        gradeLevel,
        category,
        learningProfile,
      );

      final session = EnhancedTutorSession(
        id: _generateId(),
        studentId: studentId,
        topic: topic,
        gradeLevel: gradeLevel,
        category: category,
        tutorPersonality: tutorPersonality,
        sessionContext: sessionContext,
        adaptiveHints: [],
        learningInsights: [],
        engagementMetrics: EngagementMetrics.initial(),
        startedAt: DateTime.now(),
        lastInteraction: DateTime.now(),
        isActive: true,
        parentSessionId: parentSessionId,
      );

      await _saveEnhancedSession(session);
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating enhanced tutor session: $e');
      }
      rethrow;
    }
  }

  /// Generate contextual hint with multi-modal support
  Future<EnhancedHint> generateEnhancedHint({
    required String sessionId,
    required AIQuestion question,
    required List<String> previousAttempts,
    required Duration timeSpent,
    required StudentBehavior currentBehavior,
  }) async {
    try {
      final session = await getEnhancedSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      // Generate adaptive hint using the learning engine
      final adaptiveHint = await _adaptiveLearningEngine.generateContextualHint(
        session.studentId,
        question,
        previousAttempts,
        timeSpent,
      );

      // Enhance with tutor personality and context
      final enhancedHint = await _enhanceHintWithPersonality(
        adaptiveHint,
        session.tutorPersonality,
        session.sessionContext,
        currentBehavior,
      );

      // Update session with new hint
      await _updateSessionWithHint(sessionId, enhancedHint);

      return enhancedHint;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating enhanced hint: $e');
      }
      rethrow;
    }
  }

  /// Provide real-time tutoring response with emotional intelligence
  Future<TutorResponse> provideTutoringResponse({
    required String sessionId,
    required String studentInput,
    required StudentBehavior currentBehavior,
    required QuestionContext questionContext,
  }) async {
    try {
      final session = await getEnhancedSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      // Analyze student's emotional state and learning needs
      final emotionalAnalysis = await _analyzeEmotionalState(
        studentInput,
        currentBehavior,
        session.engagementMetrics,
      );

      // Generate adaptive response based on tutor personality and student needs
      final response = await _generateAdaptiveResponse(
        studentInput,
        emotionalAnalysis,
        session.tutorPersonality,
        session.sessionContext,
        questionContext,
      );

      // Update engagement metrics
      final updatedMetrics = await _updateEngagementMetrics(
        session.engagementMetrics,
        currentBehavior,
        response,
      );

      // Update session
      await _updateSessionEngagement(sessionId, updatedMetrics);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error providing tutoring response: $e');
      }
      rethrow;
    }
  }

  /// Generate personalized learning insights
  Future<List<LearningInsight>> generateLearningInsights({
    required String sessionId,
    required Duration sessionDuration,
  }) async {
    try {
      final session = await getEnhancedSession(sessionId);
      if (session == null) return [];

      final insights = <LearningInsight>[];

      // Analyze session performance
      final performanceInsight = await _analyzeSessionPerformance(session);
      if (performanceInsight != null) {
        insights.add(performanceInsight);
      }

      // Analyze engagement patterns
      final engagementInsight = await _analyzeEngagementPatterns(session);
      if (engagementInsight != null) {
        insights.add(engagementInsight);
      }

      // Analyze learning style effectiveness
      final learningStyleInsight = await _analyzeLearningStyleEffectiveness(
        session,
      );
      if (learningStyleInsight != null) {
        insights.add(learningStyleInsight);
      }

      // Generate recommendations
      final recommendationInsight = await _generateRecommendations(session);
      if (recommendationInsight != null) {
        insights.add(recommendationInsight);
      }

      // Update session with insights
      await _updateSessionWithInsights(sessionId, insights);

      return insights;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating learning insights: $e');
      }
      return [];
    }
  }

  /// Adapt tutor personality based on student response
  Future<TutorPersonality> adaptTutorPersonality({
    required String sessionId,
    required StudentFeedback feedback,
    required EngagementMetrics currentMetrics,
  }) async {
    try {
      final session = await getEnhancedSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      final adaptedPersonality = await _adaptPersonalityBasedOnFeedback(
        session.tutorPersonality,
        feedback,
        currentMetrics,
      );

      // Update session with adapted personality
      await _updateSessionPersonality(sessionId, adaptedPersonality);

      return adaptedPersonality;
    } catch (e) {
      if (kDebugMode) {
        print('Error adapting tutor personality: $e');
      }
      rethrow;
    }
  }

  /// Provide motivational support based on student state
  Future<MotivationalSupport> provideMotivationalSupport({
    required String sessionId,
    required StudentBehavior currentBehavior,
    required List<GameResult> recentResults,
  }) async {
    try {
      final session = await getEnhancedSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      // Analyze what type of motivation is needed
      final motivationType = _determineBestMotivationType(
        currentBehavior,
        recentResults,
        session.tutorPersonality,
      );

      // Generate personalized motivational content
      final support = await _generateMotivationalContent(
        motivationType,
        session.tutorPersonality,
        session.sessionContext,
        recentResults,
      );

      return support;
    } catch (e) {
      if (kDebugMode) {
        print('Error providing motivational support: $e');
      }
      rethrow;
    }
  }

  /// Get enhanced session by ID
  Future<EnhancedTutorSession?> getEnhancedSession(String sessionId) async {
    try {
      final sessionsString = _prefs.getString(_enhancedSessionsKey);
      if (sessionsString == null) return null;

      final sessionsMap = jsonDecode(sessionsString) as Map<String, dynamic>;
      final sessionData = sessionsMap[sessionId];
      if (sessionData == null) return null;

      return EnhancedTutorSession.fromJson(sessionData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting enhanced session: $e');
      }
      return null;
    }
  }

  /// Get all enhanced sessions for a student
  Future<List<EnhancedTutorSession>> getStudentSessions(
    String studentId,
  ) async {
    try {
      final sessionsString = _prefs.getString(_enhancedSessionsKey);
      if (sessionsString == null) return [];

      final sessionsMap = jsonDecode(sessionsString) as Map<String, dynamic>;
      final studentSessions = <EnhancedTutorSession>[];

      for (final sessionData in sessionsMap.values) {
        final session = EnhancedTutorSession.fromJson(
          sessionData as Map<String, dynamic>,
        );
        if (session.studentId == studentId) {
          studentSessions.add(session);
        }
      }

      // Sort by most recent first
      studentSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return studentSessions;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student sessions: $e');
      }
      return [];
    }
  }

  // Private helper methods

  Future<TutorPersonality> _generateTutorPersonality(
    LearningProfile? profile,
  ) async {
    // Generate tutor personality based on student's learning profile
    final personality = TutorPersonality(
      name: _selectTutorName(profile),
      communicationStyle: _selectCommunicationStyle(profile),
      encouragementLevel: _selectEncouragementLevel(profile),
      patienceLevel: _selectPatienceLevel(profile),
      humorLevel: _selectHumorLevel(profile),
      formalityLevel: _selectFormalityLevel(profile),
      adaptabilityScore: 0.8, // High adaptability for personalization
      specialties: _selectSpecialties(profile),
      preferredExplanationStyle: _selectExplanationStyle(profile),
    );

    return personality;
  }

  Future<SessionContext> _createSessionContext(
    String studentId,
    String topic,
    GradeLevel gradeLevel,
    GameCategory category,
    LearningProfile? profile,
  ) async {
    return SessionContext(
      studentId: studentId,
      topic: topic,
      gradeLevel: gradeLevel,
      category: category,
      learningObjectives: await _getTopicObjectives(topic, gradeLevel),
      prerequisiteKnowledge: await _getPrerequisites(topic, gradeLevel),
      difficultyLevel: profile?.optimalDifficulty ?? GameDifficulty.normal,
      estimatedDuration:
          profile?.preferredSessionLength ?? const Duration(minutes: 15),
      adaptiveParameters: AdaptiveParameters(
        hintFrequency: _calculateOptimalHintFrequency(profile),
        encouragementFrequency: _calculateOptimalEncouragementFrequency(
          profile,
        ),
        difficultyAdjustmentSensitivity:
            _calculateDifficultyAdjustmentSensitivity(profile),
      ),
    );
  }

  Future<EnhancedHint> _enhanceHintWithPersonality(
    AdaptiveHint adaptiveHint,
    TutorPersonality personality,
    SessionContext context,
    StudentBehavior behavior,
  ) async {
    // Enhance the hint with tutor personality
    final personalizedContent = await _personalizeHintContent(
      adaptiveHint.content,
      personality,
      behavior,
    );

    final encouragement = await _generateContextualEncouragement(
      personality,
      behavior,
      context,
    );

    return EnhancedHint(
      id: adaptiveHint.id,
      baseHint: adaptiveHint,
      personalizedContent: personalizedContent,
      encouragement: encouragement,
      deliveryStyle: _selectDeliveryStyle(personality, behavior),
      emotionalTone: _selectEmotionalTone(personality, behavior),
      visualEnhancements: await _generateVisualEnhancements(
        adaptiveHint,
        personality,
      ),
      audioEnhancements: await _generateAudioEnhancements(
        adaptiveHint,
        personality,
      ),
      interactiveEnhancements: await _generateInteractiveEnhancements(
        adaptiveHint,
        personality,
      ),
      createdAt: DateTime.now(),
    );
  }

  Future<EmotionalAnalysis> _analyzeEmotionalState(
    String studentInput,
    StudentBehavior behavior,
    EngagementMetrics metrics,
  ) async {
    // Analyze emotional indicators in student input and behavior
    final frustrationIndicators = _detectFrustrationIndicators(
      studentInput,
      behavior,
    );
    final confidenceIndicators = _detectConfidenceIndicators(
      studentInput,
      behavior,
    );
    final engagementIndicators = _detectEngagementIndicators(
      studentInput,
      behavior,
      metrics,
    );

    return EmotionalAnalysis(
      frustrationLevel: frustrationIndicators,
      confidenceLevel: confidenceIndicators,
      engagementLevel: engagementIndicators,
      emotionalState: _determineOverallEmotionalState(
        frustrationIndicators,
        confidenceIndicators,
        engagementIndicators,
      ),
      recommendedResponse: _recommendResponseStrategy(
        frustrationIndicators,
        confidenceIndicators,
        engagementIndicators,
      ),
    );
  }

  Future<TutorResponse> _generateAdaptiveResponse(
    String studentInput,
    EmotionalAnalysis emotionalAnalysis,
    TutorPersonality personality,
    SessionContext context,
    QuestionContext questionContext,
  ) async {
    // Generate response based on emotional analysis and personality
    final responseContent = await _generateResponseContent(
      studentInput,
      emotionalAnalysis,
      personality,
      questionContext,
    );

    final responseType = _determineResponseType(
      emotionalAnalysis,
      questionContext,
    );
    final deliveryStyle = _adaptDeliveryStyle(personality, emotionalAnalysis);

    return TutorResponse(
      id: _generateId(),
      content: responseContent,
      responseType: responseType,
      deliveryStyle: deliveryStyle,
      emotionalTone: _selectResponseTone(personality, emotionalAnalysis),
      followUpQuestions: await _generateFollowUpQuestions(
        questionContext,
        emotionalAnalysis,
      ),
      additionalResources: await _suggestAdditionalResources(
        context,
        emotionalAnalysis,
      ),
      estimatedHelpfulness: _predictResponseHelpfulness(
        emotionalAnalysis,
        personality,
      ),
      createdAt: DateTime.now(),
    );
  }

  Future<EngagementMetrics> _updateEngagementMetrics(
    EngagementMetrics currentMetrics,
    StudentBehavior behavior,
    TutorResponse response,
  ) async {
    return currentMetrics.copyWith(
      totalInteractions: currentMetrics.totalInteractions + 1,
      averageResponseTime: _calculateUpdatedAverageResponseTime(
        currentMetrics.averageResponseTime,
        behavior.sessionDuration,
        currentMetrics.totalInteractions,
      ),
      engagementTrend: _calculateEngagementTrend(currentMetrics, behavior),
      frustrationEvents: behavior.frustrationLevel > 0.7
          ? currentMetrics.frustrationEvents + 1
          : currentMetrics.frustrationEvents,
      successfulHints: response.responseType == ResponseType.helpful
          ? currentMetrics.successfulHints + 1
          : currentMetrics.successfulHints,
      lastUpdated: DateTime.now(),
    );
  }

  // Analysis methods

  Future<LearningInsight?> _analyzeSessionPerformance(
    EnhancedTutorSession session,
  ) async {
    if (session.adaptiveHints.isEmpty) return null;

    final hintEffectiveness =
        session.adaptiveHints
            .map((h) => h.baseHint.estimatedHelpfulness)
            .reduce((a, b) => a + b) /
        session.adaptiveHints.length;

    if (hintEffectiveness < 0.6) {
      return LearningInsight(
        type: InsightType.performance,
        title: 'Hint Effectiveness',
        description:
            'Student may need different types of hints or explanations',
        recommendation: 'Try more visual aids or step-by-step breakdowns',
        confidence: 0.8,
        priority: Priority.medium,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  Future<LearningInsight?> _analyzeEngagementPatterns(
    EnhancedTutorSession session,
  ) async {
    final metrics = session.engagementMetrics;

    if (metrics.engagementTrend < -0.2) {
      return LearningInsight(
        type: InsightType.engagement,
        title: 'Declining Engagement',
        description: 'Student engagement is decreasing during the session',
        recommendation: 'Consider taking a break or changing the activity type',
        confidence: 0.9,
        priority: Priority.high,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  Future<LearningInsight?> _analyzeLearningStyleEffectiveness(
    EnhancedTutorSession session,
  ) async {
    // Analyze if the current approach matches the student's learning style
    final learningProfile = await _adaptiveLearningEngine.getLearningProfile(
      session.studentId,
    );
    if (learningProfile == null) return null;

    // Check if visual aids are being used for visual learners
    if (learningProfile.learningStyle == LearningStyle.visual) {
      final visualHints = session.adaptiveHints
          .where((h) => h.baseHint.visualAids.isNotEmpty)
          .length;

      if (visualHints < session.adaptiveHints.length * 0.5) {
        return LearningInsight(
          type: InsightType.learningStyle,
          title: 'Visual Learning Opportunity',
          description:
              'This visual learner could benefit from more diagrams and visual aids',
          recommendation: 'Increase use of visual explanations and diagrams',
          confidence: 0.7,
          priority: Priority.medium,
          createdAt: DateTime.now(),
        );
      }
    }

    return null;
  }

  Future<LearningInsight?> _generateRecommendations(
    EnhancedTutorSession session,
  ) async {
    final metrics = session.engagementMetrics;

    if (metrics.frustrationEvents > 2) {
      return LearningInsight(
        type: InsightType.recommendation,
        title: 'Frustration Management',
        description: 'Student experienced multiple frustration events',
        recommendation:
            'Consider reducing difficulty or providing more encouragement',
        confidence: 0.8,
        priority: Priority.high,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  // Personality adaptation methods

  String _selectTutorName(LearningProfile? profile) {
    final names = ['Alex', 'Sam', 'Jordan', 'Casey', 'Riley'];
    return names[Random().nextInt(names.length)];
  }

  CommunicationStyle _selectCommunicationStyle(LearningProfile? profile) {
    if (profile?.learningStyle == LearningStyle.auditory) {
      return CommunicationStyle.conversational;
    } else if (profile?.learningStyle == LearningStyle.visual) {
      return CommunicationStyle.descriptive;
    } else {
      return CommunicationStyle.interactive;
    }
  }

  double _selectEncouragementLevel(LearningProfile? profile) {
    if (profile?.confidenceScore != null && profile!.confidenceScore < 0.5) {
      return 0.9; // High encouragement for low confidence
    }
    return 0.7; // Moderate encouragement
  }

  double _selectPatienceLevel(LearningProfile? profile) {
    if (profile?.cognitiveLoad == CognitiveLoad.high) {
      return 0.95; // Very patient for high cognitive load
    }
    return 0.8; // Good patience level
  }

  double _selectHumorLevel(LearningProfile? profile) {
    // Adjust humor based on age and preferences
    return 0.6; // Moderate humor
  }

  double _selectFormalityLevel(LearningProfile? profile) {
    // Less formal for younger students
    return 0.4; // Casual and friendly
  }

  List<String> _selectSpecialties(LearningProfile? profile) {
    final specialties = <String>[];

    if (profile?.strengths.contains(GameCategory.geometry) ?? false) {
      specialties.add('Geometry Visualization');
    }
    if (profile?.strengths.contains(GameCategory.algebra) ?? false) {
      specialties.add('Algebraic Thinking');
    }

    specialties.add('Adaptive Learning');
    return specialties;
  }

  ExplanationStyle _selectExplanationStyle(LearningProfile? profile) {
    if (profile?.learningStyle == LearningStyle.kinesthetic) {
      return ExplanationStyle.handson;
    } else if (profile?.learningStyle == LearningStyle.visual) {
      return ExplanationStyle.visual;
    } else {
      return ExplanationStyle.stepByStep;
    }
  }

  // Context and parameter calculation methods

  Future<List<String>> _getTopicObjectives(
    String topic,
    GradeLevel gradeLevel,
  ) async {
    // Return learning objectives for the topic and grade level
    return [
      'Understand the concept of $topic',
      'Apply $topic in problem-solving',
      'Recognize patterns in $topic',
    ];
  }

  Future<List<String>> _getPrerequisites(
    String topic,
    GradeLevel gradeLevel,
  ) async {
    // Return prerequisite knowledge for the topic
    return ['Basic number recognition', 'Counting skills', 'Simple operations'];
  }

  double _calculateOptimalHintFrequency(LearningProfile? profile) {
    if (profile?.cognitiveLoad == CognitiveLoad.high) {
      return 0.8; // More frequent hints
    } else if (profile?.confidenceScore != null &&
        profile!.confidenceScore > 0.8) {
      return 0.3; // Less frequent hints for confident students
    }
    return 0.5; // Moderate hint frequency
  }

  double _calculateOptimalEncouragementFrequency(LearningProfile? profile) {
    if (profile?.motivationFactors.contains(MotivationFactor.achievement) ??
        false) {
      return 0.7; // More encouragement for achievement-motivated students
    }
    return 0.5;
  }

  double _calculateDifficultyAdjustmentSensitivity(LearningProfile? profile) {
    if (profile?.cognitiveLoad == CognitiveLoad.high) {
      return 0.9; // High sensitivity to difficulty changes
    }
    return 0.6; // Moderate sensitivity
  }

  // Content generation methods

  Future<String> _personalizeHintContent(
    String baseContent,
    TutorPersonality personality,
    StudentBehavior behavior,
  ) async {
    String personalizedContent = baseContent;

    // Add personality-based modifications
    if (personality.humorLevel > 0.7 && behavior.boredomLevel > 0.5) {
      personalizedContent = _addHumorToContent(personalizedContent);
    }

    if (personality.encouragementLevel > 0.8 &&
        behavior.frustrationLevel > 0.6) {
      personalizedContent = _addEncouragementToContent(personalizedContent);
    }

    return personalizedContent;
  }

  Future<String> _generateContextualEncouragement(
    TutorPersonality personality,
    StudentBehavior behavior,
    SessionContext context,
  ) async {
    if (behavior.frustrationLevel > 0.7) {
      return "Don't worry, ${personality.name} is here to help! This is a tricky one, but we'll figure it out together.";
    } else if (behavior.engagementLevel < 0.4) {
      return "Hey, you're doing great! Let's make this more interesting.";
    } else {
      return "You're on the right track! Keep going!";
    }
  }

  String _addHumorToContent(String content) {
    final humorPhrases = [
      "Let's tackle this math monster! 🐉",
      "Time to be a math detective! 🕵️",
      "This problem is like a puzzle waiting to be solved! 🧩",
    ];

    final randomPhrase = humorPhrases[Random().nextInt(humorPhrases.length)];
    return "$randomPhrase $content";
  }

  String _addEncouragementToContent(String content) {
    final encouragementPhrases = [
      "You've got this! ",
      "I believe in you! ",
      "You're doing amazing! ",
    ];

    final randomPhrase =
        encouragementPhrases[Random().nextInt(encouragementPhrases.length)];
    return "$randomPhrase$content";
  }

  // Emotional analysis methods

  double _detectFrustrationIndicators(String input, StudentBehavior behavior) {
    double frustrationScore = behavior.frustrationLevel;

    // Analyze text for frustration indicators
    final frustrationWords = [
      'hard',
      'difficult',
      'confused',
      'don\'t understand',
      'stuck',
    ];
    for (final word in frustrationWords) {
      if (input.toLowerCase().contains(word)) {
        frustrationScore += 0.1;
      }
    }

    return frustrationScore.clamp(0.0, 1.0);
  }

  double _detectConfidenceIndicators(String input, StudentBehavior behavior) {
    double confidenceScore = 1.0 - behavior.frustrationLevel;

    // Analyze text for confidence indicators
    final confidenceWords = ['easy', 'got it', 'understand', 'know', 'sure'];
    for (final word in confidenceWords) {
      if (input.toLowerCase().contains(word)) {
        confidenceScore += 0.1;
      }
    }

    return confidenceScore.clamp(0.0, 1.0);
  }

  double _detectEngagementIndicators(
    String input,
    StudentBehavior behavior,
    EngagementMetrics metrics,
  ) {
    double engagementScore = behavior.engagementLevel;

    // Consider interaction frequency
    if (metrics.totalInteractions > 0) {
      final avgResponseTime = metrics.averageResponseTime.inSeconds;
      if (avgResponseTime < 30) {
        engagementScore += 0.2; // Quick responses indicate engagement
      }
    }

    return engagementScore.clamp(0.0, 1.0);
  }

  EmotionalState _determineOverallEmotionalState(
    double frustration,
    double confidence,
    double engagement,
  ) {
    if (frustration > 0.7) {
      return EmotionalState.frustrated;
    } else if (engagement < 0.3) {
      return EmotionalState.disengaged;
    } else if (confidence > 0.8 && engagement > 0.7) {
      return EmotionalState.confident;
    } else {
      return EmotionalState.neutral;
    }
  }

  ResponseStrategy _recommendResponseStrategy(
    double frustration,
    double confidence,
    double engagement,
  ) {
    if (frustration > 0.7) {
      return ResponseStrategy.supportive;
    } else if (engagement < 0.4) {
      return ResponseStrategy.engaging;
    } else if (confidence > 0.8) {
      return ResponseStrategy.challenging;
    } else {
      return ResponseStrategy.encouraging;
    }
  }

  // Storage methods

  Future<void> _saveEnhancedSession(EnhancedTutorSession session) async {
    try {
      final sessionsString = _prefs.getString(_enhancedSessionsKey);
      final sessionsMap = sessionsString != null
          ? Map<String, dynamic>.from(jsonDecode(sessionsString))
          : <String, dynamic>{};

      sessionsMap[session.id] = session.toJson();

      await _prefs.setString(_enhancedSessionsKey, jsonEncode(sessionsMap));

      // Also save to Hive for better performance
      if (_hiveBox != null) {
        await _hiveBox.put(
          '${_enhancedSessionsKey}_${session.id}',
          session.toJson(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving enhanced session: $e');
      }
    }
  }

  Future<void> _updateSessionWithHint(
    String sessionId,
    EnhancedHint hint,
  ) async {
    final session = await getEnhancedSession(sessionId);
    if (session != null) {
      final updatedHints = List<EnhancedHint>.from(session.adaptiveHints)
        ..add(hint);
      final updatedSession = session.copyWith(
        adaptiveHints: updatedHints,
        lastInteraction: DateTime.now(),
      );
      await _saveEnhancedSession(updatedSession);
    }
  }

  Future<void> _updateSessionEngagement(
    String sessionId,
    EngagementMetrics metrics,
  ) async {
    final session = await getEnhancedSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        engagementMetrics: metrics,
        lastInteraction: DateTime.now(),
      );
      await _saveEnhancedSession(updatedSession);
    }
  }

  Future<void> _updateSessionWithInsights(
    String sessionId,
    List<LearningInsight> insights,
  ) async {
    final session = await getEnhancedSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        learningInsights: insights,
        lastInteraction: DateTime.now(),
      );
      await _saveEnhancedSession(updatedSession);
    }
  }

  Future<void> _updateSessionPersonality(
    String sessionId,
    TutorPersonality personality,
  ) async {
    final session = await getEnhancedSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        tutorPersonality: personality,
        lastInteraction: DateTime.now(),
      );
      await _saveEnhancedSession(updatedSession);
    }
  }

  // Utility methods

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Duration _calculateUpdatedAverageResponseTime(
    Duration currentAverage,
    Duration newResponseTime,
    int totalInteractions,
  ) {
    final currentTotal =
        currentAverage.inMilliseconds * (totalInteractions - 1);
    final newTotal = currentTotal + newResponseTime.inMilliseconds;
    return Duration(milliseconds: newTotal ~/ totalInteractions);
  }

  double _calculateEngagementTrend(
    EngagementMetrics metrics,
    StudentBehavior behavior,
  ) {
    // Simple trend calculation - in production this would be more sophisticated
    final currentEngagement = behavior.engagementLevel;
    final previousEngagement =
        metrics.engagementTrend + 0.5; // Assuming 0.5 baseline

    return (currentEngagement - previousEngagement).clamp(-1.0, 1.0);
  }

  // Placeholder methods for complex functionality

  DeliveryStyle _selectDeliveryStyle(
    TutorPersonality personality,
    StudentBehavior behavior,
  ) {
    if (behavior.attentionLevel < 0.4) {
      return DeliveryStyle.animated;
    } else if (personality.formalityLevel > 0.7) {
      return DeliveryStyle.formal;
    } else {
      return DeliveryStyle.conversational;
    }
  }

  EmotionalTone _selectEmotionalTone(
    TutorPersonality personality,
    StudentBehavior behavior,
  ) {
    if (behavior.frustrationLevel > 0.7) {
      return EmotionalTone.supportive;
    } else if (behavior.engagementLevel > 0.8) {
      return EmotionalTone.enthusiastic;
    } else {
      return EmotionalTone.encouraging;
    }
  }

  Future<List<VisualEnhancement>> _generateVisualEnhancements(
    AdaptiveHint hint,
    TutorPersonality personality,
  ) async {
    return [VisualEnhancement.colorCoding, VisualEnhancement.animation];
  }

  Future<List<AudioEnhancement>> _generateAudioEnhancements(
    AdaptiveHint hint,
    TutorPersonality personality,
  ) async {
    return [AudioEnhancement.voiceOver, AudioEnhancement.soundEffects];
  }

  Future<List<InteractiveEnhancement>> _generateInteractiveEnhancements(
    AdaptiveHint hint,
    TutorPersonality personality,
  ) async {
    return [InteractiveEnhancement.dragDrop, InteractiveEnhancement.gesture];
  }

  Future<String> _generateResponseContent(
    String studentInput,
    EmotionalAnalysis analysis,
    TutorPersonality personality,
    QuestionContext context,
  ) async {
    // Generate contextual response based on analysis
    return "I understand you're working on ${context.topic}. Let me help you with that!";
  }

  ResponseType _determineResponseType(
    EmotionalAnalysis analysis,
    QuestionContext context,
  ) {
    if (analysis.frustrationLevel > 0.7) {
      return ResponseType.supportive;
    } else if (analysis.confidenceLevel > 0.8) {
      return ResponseType.challenging;
    } else {
      return ResponseType.helpful;
    }
  }

  DeliveryStyle _adaptDeliveryStyle(
    TutorPersonality personality,
    EmotionalAnalysis analysis,
  ) {
    if (analysis.engagementLevel < 0.4) {
      return DeliveryStyle.animated;
    } else {
      return DeliveryStyle.conversational;
    }
  }

  EmotionalTone _selectResponseTone(
    TutorPersonality personality,
    EmotionalAnalysis analysis,
  ) {
    if (analysis.frustrationLevel > 0.7) {
      return EmotionalTone.supportive;
    } else {
      return EmotionalTone.encouraging;
    }
  }

  Future<List<String>> _generateFollowUpQuestions(
    QuestionContext context,
    EmotionalAnalysis analysis,
  ) async {
    return [
      "What part of this problem seems most challenging?",
      "Can you tell me what you understand so far?",
      "Would you like to try a similar but easier problem first?",
    ];
  }

  Future<List<String>> _suggestAdditionalResources(
    SessionContext context,
    EmotionalAnalysis analysis,
  ) async {
    return [
      "Practice problems for ${context.topic}",
      "Visual aids for ${context.category}",
      "Step-by-step tutorials",
    ];
  }

  double _predictResponseHelpfulness(
    EmotionalAnalysis analysis,
    TutorPersonality personality,
  ) {
    // Predict how helpful the response will be
    double helpfulness = 0.7; // Base helpfulness

    if (personality.adaptabilityScore > 0.8) {
      helpfulness += 0.1;
    }

    if (analysis.recommendedResponse == ResponseStrategy.supportive &&
        personality.encouragementLevel > 0.8) {
      helpfulness += 0.1;
    }

    return helpfulness.clamp(0.0, 1.0);
  }

  Future<TutorPersonality> _adaptPersonalityBasedOnFeedback(
    TutorPersonality currentPersonality,
    StudentFeedback feedback,
    EngagementMetrics metrics,
  ) async {
    // Adapt personality based on student feedback
    double newEncouragementLevel = currentPersonality.encouragementLevel;
    double newHumorLevel = currentPersonality.humorLevel;
    double newPatienceLevel = currentPersonality.patienceLevel;

    if (feedback.likesEncouragement) {
      newEncouragementLevel = (newEncouragementLevel + 0.1).clamp(0.0, 1.0);
    }

    if (feedback.likesHumor) {
      newHumorLevel = (newHumorLevel + 0.1).clamp(0.0, 1.0);
    }

    if (metrics.frustrationEvents > 2) {
      newPatienceLevel = (newPatienceLevel + 0.1).clamp(0.0, 1.0);
    }

    return currentPersonality.copyWith(
      encouragementLevel: newEncouragementLevel,
      humorLevel: newHumorLevel,
      patienceLevel: newPatienceLevel,
    );
  }

  MotivationType _determineBestMotivationType(
    StudentBehavior behavior,
    List<GameResult> results,
    TutorPersonality personality,
  ) {
    if (behavior.frustrationLevel > 0.7) {
      return MotivationType.reassurance;
    } else if (results.isNotEmpty && results.last.accuracy > 0.8) {
      return MotivationType.celebration;
    } else if (behavior.engagementLevel < 0.4) {
      return MotivationType.energizing;
    } else {
      return MotivationType.encouragement;
    }
  }

  Future<MotivationalSupport> _generateMotivationalContent(
    MotivationType type,
    TutorPersonality personality,
    SessionContext context,
    List<GameResult> results,
  ) async {
    String message;
    List<String> actions;

    switch (type) {
      case MotivationType.reassurance:
        message =
            "It's okay to find this challenging! Every mathematician has been where you are now.";
        actions = [
          "Take a deep breath",
          "Try a simpler version",
          "Ask for help",
        ];
        break;
      case MotivationType.celebration:
        message = "Fantastic work! You're really getting the hang of this!";
        actions = [
          "Try a harder problem",
          "Teach someone else",
          "Celebrate your success",
        ];
        break;
      case MotivationType.energizing:
        message =
            "Let's make this more exciting! Math can be like solving puzzles!";
        actions = ["Try a math game", "Use visual aids", "Work with a friend"];
        break;
      case MotivationType.encouragement:
        message = "You're making great progress! Keep up the excellent work!";
        actions = [
          "Continue practicing",
          "Try variations",
          "Build on your success",
        ];
        break;
      case MotivationType.challenge:
        message = "You're ready for the next level! Let's push your limits!";
        actions = [
          "Try advanced problems",
          "Explore new concepts",
          "Set higher goals",
        ];
        break;
    }

    return MotivationalSupport(
      type: type,
      message: message,
      suggestedActions: actions,
      personalizedElements: await _addPersonalizedElements(
        personality,
        context,
      ),
      deliveryStyle: _selectMotivationalDeliveryStyle(personality, type),
      createdAt: DateTime.now(),
    );
  }

  Future<List<String>> _addPersonalizedElements(
    TutorPersonality personality,
    SessionContext context,
  ) async {
    final elements = <String>[];

    if (personality.humorLevel > 0.7) {
      elements.add("Add some fun math jokes");
    }

    if (personality.encouragementLevel > 0.8) {
      elements.add("Extra positive reinforcement");
    }

    return elements;
  }

  DeliveryStyle _selectMotivationalDeliveryStyle(
    TutorPersonality personality,
    MotivationType type,
  ) {
    if (type == MotivationType.celebration) {
      return DeliveryStyle.animated;
    } else if (type == MotivationType.reassurance) {
      return DeliveryStyle.gentle;
    } else {
      return DeliveryStyle.conversational;
    }
  }
}

/// Riverpod providers for enhanced AI tutor
final enhancedAITutorServiceProvider = Provider<EnhancedAITutorService>((ref) {
  throw UnimplementedError('EnhancedAITutorService must be initialized');
});

final enhancedTutorSessionProvider =
    FutureProvider.family<EnhancedTutorSession?, String>((
      ref,
      sessionId,
    ) async {
      final service = ref.read(enhancedAITutorServiceProvider);
      return service.getEnhancedSession(sessionId);
    });

final studentTutorSessionsProvider =
    FutureProvider.family<List<EnhancedTutorSession>, String>((
      ref,
      studentId,
    ) async {
      final service = ref.read(enhancedAITutorServiceProvider);
      return service.getStudentSessions(studentId);
    });

final enhancedHintProvider =
    FutureProvider.family<EnhancedHint, EnhancedHintParams>((
      ref,
      params,
    ) async {
      final service = ref.read(enhancedAITutorServiceProvider);
      return service.generateEnhancedHint(
        sessionId: params.sessionId,
        question: params.question,
        previousAttempts: params.previousAttempts,
        timeSpent: params.timeSpent,
        currentBehavior: params.currentBehavior,
      );
    });

final tutorResponseProvider =
    FutureProvider.family<TutorResponse, TutorResponseParams>((
      ref,
      params,
    ) async {
      final service = ref.read(enhancedAITutorServiceProvider);
      return service.provideTutoringResponse(
        sessionId: params.sessionId,
        studentInput: params.studentInput,
        currentBehavior: params.currentBehavior,
        questionContext: params.questionContext,
      );
    });

final learningInsightsProvider =
    FutureProvider.family<List<LearningInsight>, LearningInsightsParams>((
      ref,
      params,
    ) async {
      final service = ref.read(enhancedAITutorServiceProvider);
      return service.generateLearningInsights(
        sessionId: params.sessionId,
        sessionDuration: params.sessionDuration,
      );
    });

final motivationalSupportProvider =
    FutureProvider.family<MotivationalSupport, MotivationalSupportParams>((
      ref,
      params,
    ) async {
      final service = ref.read(enhancedAITutorServiceProvider);
      return service.provideMotivationalSupport(
        sessionId: params.sessionId,
        currentBehavior: params.currentBehavior,
        recentResults: params.recentResults,
      );
    });

// Parameter classes for providers
class EnhancedHintParams {
  final String sessionId;
  final AIQuestion question;
  final List<String> previousAttempts;
  final Duration timeSpent;
  final StudentBehavior currentBehavior;

  EnhancedHintParams({
    required this.sessionId,
    required this.question,
    required this.previousAttempts,
    required this.timeSpent,
    required this.currentBehavior,
  });
}

class TutorResponseParams {
  final String sessionId;
  final String studentInput;
  final StudentBehavior currentBehavior;
  final QuestionContext questionContext;

  TutorResponseParams({
    required this.sessionId,
    required this.studentInput,
    required this.currentBehavior,
    required this.questionContext,
  });
}

class LearningInsightsParams {
  final String sessionId;
  final Duration sessionDuration;

  LearningInsightsParams({
    required this.sessionId,
    required this.sessionDuration,
  });
}

class MotivationalSupportParams {
  final String sessionId;
  final StudentBehavior currentBehavior;
  final List<GameResult> recentResults;

  MotivationalSupportParams({
    required this.sessionId,
    required this.currentBehavior,
    required this.recentResults,
  });
}
