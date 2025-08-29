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

/// Advanced adaptive learning engine for personalized education
class AdaptiveLearningEngine {
  static const String _learningProfilesKey = 'learning_profiles';
  static const String _learningPathsKey = 'learning_paths';
  static const String _engagementDataKey = 'engagement_data';

  final SharedPreferences _prefs;
  final Box? _hiveBox;

  AdaptiveLearningEngine(this._prefs, this._hiveBox);

  /// Generate personalized learning profile for a student
  Future<LearningProfile> generateLearningProfile(
    String studentId,
    List<GameSession> historicalSessions,
  ) async {
    try {
      final performanceData = await _analyzePerformancePatterns(
        historicalSessions,
      );
      final learningStyle = _identifyLearningStyle(historicalSessions);
      final strengthsWeaknesses = _identifyStrengthsWeaknesses(
        historicalSessions,
      );
      final optimalDifficulty = _calculateOptimalDifficulty(performanceData);

      final profile = LearningProfile(
        studentId: studentId,
        learningStyle: learningStyle,
        strengths: strengthsWeaknesses.strengths,
        weaknesses: strengthsWeaknesses.weaknesses,
        optimalDifficulty: optimalDifficulty,
        preferredSessionLength: _calculateOptimalSessionLength(
          historicalSessions,
        ),
        motivationFactors: _identifyMotivationFactors(historicalSessions),
        cognitiveLoad: _assessCognitiveLoad(performanceData),
        lastUpdated: DateTime.now(),
        confidenceScore: performanceData.overallConfidence,
        adaptationHistory: [],
      );

      await _saveLearningProfile(profile);
      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating learning profile: $e');
      }
      rethrow;
    }
  }

  /// Predict optimal difficulty for next question
  Future<GameDifficulty> predictOptimalDifficulty(
    String studentId,
    GameCategory category,
    List<GameResult> recentResults,
  ) async {
    try {
      final profile = await getLearningProfile(studentId);
      if (profile == null) {
        return GameDifficulty.normal; // Default fallback
      }

      final categoryPerformance = _analyzeCategoryPerformance(
        recentResults,
        category,
      );
      final adaptiveScore = _calculateAdaptiveScore(
        profile,
        categoryPerformance,
        recentResults,
      );

      // AI-based difficulty prediction algorithm
      if (adaptiveScore >= 0.8) {
        return _shouldIncreaseChallenge(profile, categoryPerformance)
            ? GameDifficulty.quantum
            : GameDifficulty.genius;
      } else if (adaptiveScore >= 0.6) {
        return GameDifficulty.normal;
      } else if (adaptiveScore >= 0.4) {
        return GameDifficulty.easy;
      } else {
        return GameDifficulty.easy;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error predicting optimal difficulty: $e');
      }
      return GameDifficulty.normal;
    }
  }

  /// Generate personalized learning path
  Future<LearningPath> generateLearningPath(
    String studentId,
    GradeLevel gradeLevel,
    List<LearningObjective> masteredObjectives,
  ) async {
    try {
      final profile = await getLearningProfile(studentId);
      final availableObjectives = _getAvailableObjectives(gradeLevel);
      final nextObjectives = _selectNextObjectives(
        availableObjectives,
        masteredObjectives,
        profile,
      );

      final path = LearningPath(
        id: _generateId(),
        studentId: studentId,
        gradeLevel: gradeLevel,
        objectives: nextObjectives,
        estimatedDuration: _estimatePathDuration(nextObjectives, profile),
        difficulty: profile?.optimalDifficulty ?? GameDifficulty.normal,
        createdAt: DateTime.now(),
        adaptiveAdjustments: [],
        completionPrediction: _predictCompletionSuccess(
          nextObjectives,
          profile,
        ),
      );

      await _saveLearningPath(path);
      return path;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating learning path: $e');
      }
      rethrow;
    }
  }

  /// Optimize engagement based on real-time behavior
  Future<EngagementStrategy> optimizeEngagement(
    String studentId,
    StudentBehavior currentBehavior,
  ) async {
    try {
      final profile = await getLearningProfile(studentId);
      final engagementHistory = await _getEngagementHistory(studentId);

      final strategy = EngagementStrategy(
        studentId: studentId,
        recommendedBreakInterval: _calculateOptimalBreakInterval(
          currentBehavior,
          profile,
        ),
        motivationalMessages: _generateMotivationalMessages(
          currentBehavior,
          profile,
        ),
        gamificationElements: _selectOptimalGamification(
          currentBehavior,
          profile,
        ),
        difficultyAdjustment: _recommendDifficultyAdjustment(
          currentBehavior,
          profile,
        ),
        interventionTriggers: _identifyInterventionTriggers(
          currentBehavior,
          engagementHistory,
        ),
        createdAt: DateTime.now(),
      );

      await _saveEngagementStrategy(strategy);
      return strategy;
    } catch (e) {
      if (kDebugMode) {
        print('Error optimizing engagement: $e');
      }
      rethrow;
    }
  }

  /// Advanced hint generation with context awareness
  Future<AdaptiveHint> generateContextualHint(
    String studentId,
    AIQuestion question,
    List<String> previousAttempts,
    Duration timeSpent,
  ) async {
    try {
      final profile = await getLearningProfile(studentId);
      final hintLevel = _determineHintLevel(
        previousAttempts,
        timeSpent,
        profile,
      );

      final hint = AdaptiveHint(
        id: _generateId(),
        questionId: question.id,
        studentId: studentId,
        hintLevel: hintLevel,
        content: await _generateHintContent(question, hintLevel, profile),
        visualAids: await _generateVisualAids(question, profile),
        audioSupport: await _generateAudioSupport(question, profile),
        interactiveElements: await _generateInteractiveElements(
          question,
          profile,
        ),
        learningStyle: profile?.learningStyle ?? LearningStyle.visual,
        estimatedHelpfulness: _predictHintHelpfulness(
          question,
          hintLevel,
          profile,
        ),
        createdAt: DateTime.now(),
      );

      await _saveAdaptiveHint(hint);
      return hint;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating contextual hint: $e');
      }
      rethrow;
    }
  }

  /// Predict learning outcomes based on current trajectory
  Future<LearningOutcomePrediction> predictLearningOutcomes(
    String studentId,
    Duration timeHorizon,
  ) async {
    try {
      final profile = await getLearningProfile(studentId);
      final historicalData = await _getHistoricalPerformanceData(studentId);
      final currentPath = await _getCurrentLearningPath(studentId);

      final prediction = LearningOutcomePrediction(
        studentId: studentId,
        timeHorizon: timeHorizon,
        predictedMastery: _predictMasteryLevels(
          historicalData,
          currentPath,
          profile,
        ),
        riskFactors: _identifyRiskFactors(historicalData, profile),
        interventionRecommendations: _generateInterventionRecommendations(
          historicalData,
          profile,
        ),
        confidenceInterval: _calculatePredictionConfidence(historicalData),
        expectedMilestones: _predictMilestones(currentPath, profile),
        createdAt: DateTime.now(),
      );

      await _saveLearningOutcomePrediction(prediction);
      return prediction;
    } catch (e) {
      if (kDebugMode) {
        print('Error predicting learning outcomes: $e');
      }
      rethrow;
    }
  }

  // Private helper methods

  Future<PerformanceData> _analyzePerformancePatterns(
    List<GameSession> sessions,
  ) async {
    final accuracyTrend = _calculateAccuracyTrend(sessions);
    final speedTrend = _calculateSpeedTrend(sessions);
    final consistencyScore = _calculateConsistencyScore(sessions);

    return PerformanceData(
      overallAccuracy: accuracyTrend.current,
      averageResponseTime: speedTrend.current,
      consistencyScore: consistencyScore,
      improvementRate: accuracyTrend.slope,
      overallConfidence: _calculateOverallConfidence(sessions),
      categoryBreakdown: _analyzeCategoryBreakdown(sessions),
    );
  }

  LearningStyle _identifyLearningStyle(List<GameSession> sessions) {
    // Analyze interaction patterns to identify learning style
    final visualPreference = _calculateVisualPreference(sessions);
    final auditoryPreference = _calculateAuditoryPreference(sessions);
    final kinestheticPreference = _calculateKinestheticPreference(sessions);

    if (visualPreference > auditoryPreference &&
        visualPreference > kinestheticPreference) {
      return LearningStyle.visual;
    } else if (auditoryPreference > kinestheticPreference) {
      return LearningStyle.auditory;
    } else {
      return LearningStyle.kinesthetic;
    }
  }

  StrengthsWeaknesses _identifyStrengthsWeaknesses(List<GameSession> sessions) {
    final categoryPerformance = <GameCategory, double>{};

    for (final category in GameCategory.values) {
      final categoryAccuracy = _calculateCategoryAccuracy(sessions, category);
      categoryPerformance[category] = categoryAccuracy;
    }

    final sortedCategories = categoryPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StrengthsWeaknesses(
      strengths: sortedCategories.take(3).map((e) => e.key).toList(),
      weaknesses: sortedCategories.reversed.take(3).map((e) => e.key).toList(),
    );
  }

  double _calculateAdaptiveScore(
    LearningProfile? profile,
    CategoryPerformance categoryPerformance,
    List<GameResult> recentResults,
  ) {
    // Complex algorithm combining multiple factors
    final accuracyWeight = 0.4;
    final speedWeight = 0.2;
    final consistencyWeight = 0.2;
    final confidenceWeight = 0.2;

    final accuracyScore = categoryPerformance.accuracy;
    final speedScore = _normalizeSpeed(categoryPerformance.averageSpeed);
    final consistencyScore = categoryPerformance.consistency;
    final confidenceScore = profile?.confidenceScore ?? 0.5;

    return (accuracyScore * accuracyWeight) +
        (speedScore * speedWeight) +
        (consistencyScore * consistencyWeight) +
        (confidenceScore * confidenceWeight);
  }

  // Storage methods

  Future<LearningProfile?> getLearningProfile(String studentId) async {
    try {
      final profilesString = _prefs.getString(_learningProfilesKey);
      if (profilesString == null) return null;

      final profilesMap = jsonDecode(profilesString) as Map<String, dynamic>;
      final profileData = profilesMap[studentId];
      if (profileData == null) return null;

      return LearningProfile.fromJson(profileData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting learning profile: $e');
      }
      return null;
    }
  }

  Future<void> _saveLearningProfile(LearningProfile profile) async {
    try {
      final profilesString = _prefs.getString(_learningProfilesKey);
      final profilesMap = profilesString != null
          ? Map<String, dynamic>.from(jsonDecode(profilesString))
          : <String, dynamic>{};

      profilesMap[profile.studentId] = profile.toJson();

      await _prefs.setString(_learningProfilesKey, jsonEncode(profilesMap));

      // Also save to Hive for better performance
      if (_hiveBox != null) {
        await _hiveBox.put(
          '${_learningProfilesKey}_${profile.studentId}',
          profile.toJson(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving learning profile: $e');
      }
    }
  }

  Future<void> _saveLearningPath(LearningPath path) async {
    try {
      final pathsString = _prefs.getString(_learningPathsKey);
      final pathsMap = pathsString != null
          ? Map<String, dynamic>.from(jsonDecode(pathsString))
          : <String, dynamic>{};

      pathsMap[path.id] = path.toJson();
      await _prefs.setString(_learningPathsKey, jsonEncode(pathsMap));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving learning path: $e');
      }
    }
  }

  Future<void> _saveEngagementStrategy(EngagementStrategy strategy) async {
    try {
      final strategiesString = _prefs.getString(_engagementDataKey);
      final strategiesMap = strategiesString != null
          ? Map<String, dynamic>.from(jsonDecode(strategiesString))
          : <String, dynamic>{};

      strategiesMap[strategy.studentId] = strategy.toJson();
      await _prefs.setString(_engagementDataKey, jsonEncode(strategiesMap));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving engagement strategy: $e');
      }
    }
  }

  Future<void> _saveAdaptiveHint(AdaptiveHint hint) async {
    try {
      final hintsString = _prefs.getString('adaptive_hints');
      final hintsList = hintsString != null
          ? List<Map<String, dynamic>>.from(jsonDecode(hintsString))
          : <Map<String, dynamic>>[];

      hintsList.add(hint.toJson());

      // Keep only last 100 hints to manage storage
      if (hintsList.length > 100) {
        hintsList.removeRange(0, hintsList.length - 100);
      }

      await _prefs.setString('adaptive_hints', jsonEncode(hintsList));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving adaptive hint: $e');
      }
    }
  }

  Future<void> _saveLearningOutcomePrediction(
    LearningOutcomePrediction prediction,
  ) async {
    try {
      final predictionsString = _prefs.getString('outcome_predictions');
      final predictionsMap = predictionsString != null
          ? Map<String, dynamic>.from(jsonDecode(predictionsString))
          : <String, dynamic>{};

      predictionsMap[prediction.studentId] = prediction.toJson();
      await _prefs.setString('outcome_predictions', jsonEncode(predictionsMap));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving learning outcome prediction: $e');
      }
    }
  }

  // Utility methods

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  double _normalizeSpeed(Duration speed) {
    // Normalize speed to 0-1 scale (faster = higher score)
    final seconds = speed.inSeconds;
    if (seconds <= 5) return 1.0;
    if (seconds >= 60) return 0.0;
    return 1.0 - (seconds - 5) / 55;
  }

  // Placeholder implementations for complex algorithms
  // These would be replaced with actual ML models in production

  Trend _calculateAccuracyTrend(List<GameSession> sessions) {
    if (sessions.isEmpty) return Trend(current: 0.5, slope: 0.0);

    // Calculate accuracy based on available session data
    final accuracies = sessions
        .map((s) => _calculateSessionAccuracy(s))
        .toList();
    final current = accuracies.last;
    final slope = accuracies.length > 1
        ? (accuracies.last - accuracies.first) / (accuracies.length - 1)
        : 0.0;

    return Trend(current: current, slope: slope);
  }

  double _calculateSessionAccuracy(GameSession session) {
    // Calculate accuracy based on session completion and status
    if (session.status == GameStatus.completed) {
      return 0.8; // Placeholder - would calculate based on actual results
    } else if (session.status == GameStatus.active) {
      return 0.6; // Placeholder for ongoing sessions
    } else {
      return 0.5; // Default for other statuses
    }
  }

  Trend _calculateSpeedTrend(List<GameSession> sessions) {
    if (sessions.isEmpty) return Trend(current: 30.0, slope: 0.0);

    final speeds = sessions.map((s) => _calculateSessionSpeed(s)).toList();
    final current = speeds.last;
    final slope = speeds.length > 1
        ? (speeds.last - speeds.first) / (speeds.length - 1)
        : 0.0;

    return Trend(current: current, slope: slope);
  }

  double _calculateSessionSpeed(GameSession session) {
    // Calculate average response time based on session data
    if (session.endedAt != null && session.startedAt != null) {
      final duration = session.endedAt!.difference(session.startedAt!);
      final avgTimePerQuestion = duration.inSeconds / session.totalQuestions;
      return avgTimePerQuestion.toDouble();
    }
    return 30.0; // Default response time
  }

  double _calculateConsistencyScore(List<GameSession> sessions) {
    if (sessions.length < 2) return 0.5;

    final accuracies = sessions
        .map((s) => _calculateSessionAccuracy(s))
        .toList();
    final mean = accuracies.reduce((a, b) => a + b) / accuracies.length;
    final variance =
        accuracies.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) /
        accuracies.length;

    // Convert variance to consistency score (lower variance = higher consistency)
    return 1.0 - variance.clamp(0.0, 1.0);
  }

  double _calculateOverallConfidence(List<GameSession> sessions) {
    // Simple confidence calculation based on recent performance
    if (sessions.isEmpty) return 0.5;

    final recentSessions = sessions.length > 5
        ? sessions.sublist(sessions.length - 5)
        : sessions;
    final avgAccuracy =
        recentSessions
            .map((s) => _calculateSessionAccuracy(s))
            .reduce((a, b) => a + b) /
        recentSessions.length;

    return avgAccuracy;
  }

  Map<GameCategory, double> _analyzeCategoryBreakdown(
    List<GameSession> sessions,
  ) {
    final breakdown = <GameCategory, double>{};

    for (final category in GameCategory.values) {
      breakdown[category] = _calculateCategoryAccuracy(sessions, category);
    }

    return breakdown;
  }

  double _calculateCategoryAccuracy(
    List<GameSession> sessions,
    GameCategory category,
  ) {
    final categorySessions = sessions
        .where((s) => s.category == category)
        .toList();
    if (categorySessions.isEmpty) return 0.5;

    final avgAccuracy =
        categorySessions
            .map((s) => _calculateSessionAccuracy(s))
            .reduce((a, b) => a + b) /
        categorySessions.length;
    return avgAccuracy;
  }

  double _calculateVisualPreference(List<GameSession> sessions) {
    // Analyze if student performs better with visual aids
    // This would be based on actual interaction data
    return 0.7; // Placeholder
  }

  double _calculateAuditoryPreference(List<GameSession> sessions) {
    // Analyze if student performs better with audio support
    return 0.5; // Placeholder
  }

  double _calculateKinestheticPreference(List<GameSession> sessions) {
    // Analyze if student performs better with interactive elements
    return 0.6; // Placeholder
  }

  CategoryPerformance _analyzeCategoryPerformance(
    List<GameResult> results,
    GameCategory category,
  ) {
    // Since GameResult doesn't have category info, we'll use all results as a placeholder
    if (results.isEmpty) {
      return CategoryPerformance(
        accuracy: 0.5,
        averageSpeed: const Duration(seconds: 30),
        consistency: 0.5,
      );
    }

    final accuracy =
        results.map((r) => r.accuracy).reduce((a, b) => a + b) / results.length;
    final avgSpeed = Duration(
      milliseconds:
          results
              .map((r) => r.timeSpent.inMilliseconds ~/ r.totalQuestions)
              .reduce((a, b) => a + b) ~/
          results.length,
    );
    final consistency = _calculateResultsConsistency(results);

    return CategoryPerformance(
      accuracy: accuracy,
      averageSpeed: avgSpeed,
      consistency: consistency,
    );
  }

  double _calculateResultsConsistency(List<GameResult> results) {
    if (results.length < 2) return 0.5;

    final accuracies = results.map((r) => r.accuracy).toList();
    final mean = accuracies.reduce((a, b) => a + b) / accuracies.length;
    final variance =
        accuracies.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) /
        accuracies.length;

    return 1.0 - variance.clamp(0.0, 1.0);
  }

  bool _shouldIncreaseChallenge(
    LearningProfile? profile,
    CategoryPerformance performance,
  ) {
    if (profile == null) return false;

    return performance.accuracy > 0.8 &&
        performance.consistency > 0.7 &&
        performance.averageSpeed.inSeconds < 20;
  }

  GameDifficulty _calculateOptimalDifficulty(PerformanceData data) {
    if (data.overallAccuracy >= 0.85 && data.consistencyScore >= 0.8) {
      return GameDifficulty.quantum;
    } else if (data.overallAccuracy >= 0.7 && data.consistencyScore >= 0.6) {
      return GameDifficulty.genius;
    } else if (data.overallAccuracy >= 0.5) {
      return GameDifficulty.normal;
    } else {
      return GameDifficulty.easy;
    }
  }

  Duration _calculateOptimalSessionLength(List<GameSession> sessions) {
    if (sessions.isEmpty) return const Duration(minutes: 15);

    // Analyze when performance starts to decline
    final avgDuration =
        sessions
            .map((s) => _calculateSessionDuration(s))
            .reduce((a, b) => a + b) /
        sessions.length;

    return Duration(minutes: avgDuration.round().clamp(10, 30));
  }

  int _calculateSessionDuration(GameSession session) {
    if (session.endedAt != null && session.startedAt != null) {
      return session.endedAt!.difference(session.startedAt!).inMinutes;
    }
    return 15; // Default duration
  }

  List<MotivationFactor> _identifyMotivationFactors(
    List<GameSession> sessions,
  ) {
    // Analyze what motivates the student based on session data
    final factors = <MotivationFactor>[];

    // Check if rewards improve performance (placeholder logic)
    // This would analyze actual reward data in a real implementation
    if (sessions.length > 3) {
      factors.add(MotivationFactor.rewards);
    }

    // Check if social elements help (placeholder logic)
    // This would analyze multiplayer session data in a real implementation
    if (sessions.any((s) => s.players.length > 1)) {
      factors.add(MotivationFactor.social);
    }

    // Default motivators
    if (factors.isEmpty) {
      factors.addAll([MotivationFactor.progress, MotivationFactor.achievement]);
    }

    return factors;
  }

  CognitiveLoad _assessCognitiveLoad(PerformanceData data) {
    // Assess cognitive load based on performance patterns
    if (data.averageResponseTime > 45 && data.consistencyScore < 0.5) {
      return CognitiveLoad.high;
    } else if (data.averageResponseTime > 25 || data.consistencyScore < 0.7) {
      return CognitiveLoad.medium;
    } else {
      return CognitiveLoad.low;
    }
  }

  List<LearningObjective> _getAvailableObjectives(GradeLevel gradeLevel) {
    // Return grade-appropriate learning objectives
    // This would be loaded from a curriculum database
    return [
      LearningObjective(
        id: 'addition_basic',
        title: 'Basic Addition',
        description: 'Single-digit addition problems',
        gradeLevel: gradeLevel,
        category: GameCategory.addition,
        prerequisites: [],
        estimatedDuration: const Duration(hours: 2),
      ),
      // Add more objectives based on grade level
    ];
  }

  List<LearningObjective> _selectNextObjectives(
    List<LearningObjective> available,
    List<LearningObjective> mastered,
    LearningProfile? profile,
  ) {
    // Select next objectives based on prerequisites and student profile
    final masteredIds = mastered.map((o) => o.id).toSet();

    return available
        .where((obj) {
          // Check if prerequisites are met
          final prerequisitesMet = obj.prerequisites.every(
            (prereq) => masteredIds.contains(prereq),
          );

          // Check if objective matches student's strengths/weaknesses
          final isWeakArea =
              profile?.weaknesses.contains(obj.category) ?? false;

          return prerequisitesMet && (isWeakArea || masteredIds.isEmpty);
        })
        .take(3)
        .toList();
  }

  Duration _estimatePathDuration(
    List<LearningObjective> objectives,
    LearningProfile? profile,
  ) {
    final baseDuration = objectives.fold<Duration>(
      Duration.zero,
      (total, obj) => total + obj.estimatedDuration,
    );

    // Adjust based on student profile
    if (profile != null) {
      final difficultyMultiplier =
          profile.optimalDifficulty == GameDifficulty.quantum
          ? 0.8
          : profile.optimalDifficulty == GameDifficulty.easy
          ? 1.3
          : 1.0;

      return Duration(
        milliseconds: (baseDuration.inMilliseconds * difficultyMultiplier)
            .round(),
      );
    }

    return baseDuration;
  }

  double _predictCompletionSuccess(
    List<LearningObjective> objectives,
    LearningProfile? profile,
  ) {
    if (profile == null) return 0.7;

    // Predict success based on profile confidence and objective difficulty
    final baseSuccess = profile.confidenceScore;
    final objectiveDifficulty =
        objectives.length * 0.1; // More objectives = slightly harder

    return (baseSuccess - objectiveDifficulty).clamp(0.1, 0.95);
  }

  Duration _calculateOptimalBreakInterval(
    StudentBehavior behavior,
    LearningProfile? profile,
  ) {
    // Calculate when student should take breaks based on behavior patterns
    if (behavior.attentionLevel < 0.3) {
      return const Duration(minutes: 5); // Immediate break needed
    } else if (behavior.attentionLevel < 0.6) {
      return const Duration(minutes: 10);
    } else {
      return const Duration(minutes: 20);
    }
  }

  List<String> _generateMotivationalMessages(
    StudentBehavior behavior,
    LearningProfile? profile,
  ) {
    final messages = <String>[];

    if (behavior.frustrationLevel > 0.7) {
      messages.addAll([
        "You're doing great! Every mistake is a step toward learning.",
        "Take a deep breath. You've got this!",
        "Remember, even Einstein made mistakes while learning.",
      ]);
    } else if (behavior.engagementLevel < 0.4) {
      messages.addAll([
        "Let's try a different approach to make this more fun!",
        "You're closer to mastering this than you think!",
        "Every problem you solve makes you stronger in math!",
      ]);
    } else {
      messages.addAll([
        "Excellent focus! Keep up the great work!",
        "You're on fire! Your math skills are really improving!",
        "Amazing progress! You should be proud of yourself!",
      ]);
    }

    return messages;
  }

  List<GamificationElement> _selectOptimalGamification(
    StudentBehavior behavior,
    LearningProfile? profile,
  ) {
    final elements = <GamificationElement>[];

    if (profile?.motivationFactors.contains(MotivationFactor.rewards) ??
        false) {
      elements.add(GamificationElement.pointsBoost);
      elements.add(GamificationElement.badgeUnlock);
    }

    if (profile?.motivationFactors.contains(MotivationFactor.social) ?? false) {
      elements.add(GamificationElement.leaderboard);
      elements.add(GamificationElement.collaboration);
    }

    if (behavior.engagementLevel < 0.5) {
      elements.add(GamificationElement.miniGame);
      elements.add(GamificationElement.animation);
    }

    return elements;
  }

  DifficultyAdjustment _recommendDifficultyAdjustment(
    StudentBehavior behavior,
    LearningProfile? profile,
  ) {
    if (behavior.frustrationLevel > 0.8) {
      return DifficultyAdjustment.decrease;
    } else if (behavior.boredomLevel > 0.7) {
      return DifficultyAdjustment.increase;
    } else {
      return DifficultyAdjustment.maintain;
    }
  }

  List<InterventionTrigger> _identifyInterventionTriggers(
    StudentBehavior behavior,
    List<EngagementData> history,
  ) {
    final triggers = <InterventionTrigger>[];

    if (behavior.frustrationLevel > 0.8) {
      triggers.add(InterventionTrigger.highFrustration);
    }

    if (behavior.attentionLevel < 0.3) {
      triggers.add(InterventionTrigger.lowAttention);
    }

    if (behavior.consecutiveErrors > 3) {
      triggers.add(InterventionTrigger.repeatedErrors);
    }

    return triggers;
  }

  HintLevel _determineHintLevel(
    List<String> previousAttempts,
    Duration timeSpent,
    LearningProfile? profile,
  ) {
    if (previousAttempts.isEmpty && timeSpent.inSeconds < 10) {
      return HintLevel.none;
    } else if (previousAttempts.length == 1 || timeSpent.inSeconds < 30) {
      return HintLevel.gentle;
    } else if (previousAttempts.length == 2 || timeSpent.inSeconds < 60) {
      return HintLevel.moderate;
    } else {
      return HintLevel.detailed;
    }
  }

  Future<String> _generateHintContent(
    AIQuestion question,
    HintLevel level,
    LearningProfile? profile,
  ) async {
    // Generate contextual hints based on question and student profile
    switch (level) {
      case HintLevel.none:
        return "";
      case HintLevel.gentle:
        return "Think about what operation you need to use here.";
      case HintLevel.moderate:
        return "Try breaking this problem into smaller steps. What do you need to find first?";
      case HintLevel.detailed:
        return "Let's solve this step by step: ${question.hint ?? 'Start by identifying the key numbers in the problem.'}";
    }
  }

  Future<List<VisualAid>> _generateVisualAids(
    AIQuestion question,
    LearningProfile? profile,
  ) async {
    final aids = <VisualAid>[];

    if (profile?.learningStyle == LearningStyle.visual) {
      aids.add(VisualAid.diagram);
      aids.add(VisualAid.colorCoding);
    }

    if (question.category == GameCategory.geometry) {
      aids.add(VisualAid.shapes);
      aids.add(VisualAid.measurement);
    }

    return aids;
  }

  Future<AudioSupport> _generateAudioSupport(
    AIQuestion question,
    LearningProfile? profile,
  ) async {
    if (profile?.learningStyle == LearningStyle.auditory) {
      return AudioSupport(
        questionReading: true,
        hintReading: true,
        encouragement: true,
      );
    }

    return AudioSupport(
      questionReading: false,
      hintReading: false,
      encouragement: false,
    );
  }

  Future<List<InteractiveElement>> _generateInteractiveElements(
    AIQuestion question,
    LearningProfile? profile,
  ) async {
    final elements = <InteractiveElement>[];

    if (profile?.learningStyle == LearningStyle.kinesthetic) {
      elements.add(InteractiveElement.dragDrop);
      elements.add(InteractiveElement.manipulation);
    }

    if (question.category == GameCategory.addition ||
        question.category == GameCategory.subtraction) {
      elements.add(InteractiveElement.counter);
    }

    return elements;
  }

  double _predictHintHelpfulness(
    AIQuestion question,
    HintLevel level,
    LearningProfile? profile,
  ) {
    // Predict how helpful this hint will be for the student
    double baseHelpfulness = 0.7;

    if (profile?.learningStyle == LearningStyle.visual &&
        level == HintLevel.detailed) {
      baseHelpfulness += 0.2;
    }

    if (profile?.weaknesses.contains(question.category) ?? false) {
      baseHelpfulness += 0.1;
    }

    return baseHelpfulness.clamp(0.0, 1.0);
  }

  Future<List<EngagementData>> _getEngagementHistory(String studentId) async {
    // Retrieve engagement history for the student
    try {
      final historyString = _prefs.getString('engagement_history_$studentId');
      if (historyString == null) return [];

      final historyList = jsonDecode(historyString) as List;
      return historyList
          .map((data) => EngagementData.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting engagement history: $e');
      }
      return [];
    }
  }

  Future<List<PerformanceDataPoint>> _getHistoricalPerformanceData(
    String studentId,
  ) async {
    // Retrieve historical performance data
    try {
      final dataString = _prefs.getString('performance_history_$studentId');
      if (dataString == null) return [];

      final dataList = jsonDecode(dataString) as List;
      return dataList
          .map(
            (data) =>
                PerformanceDataPoint.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting historical performance data: $e');
      }
      return [];
    }
  }

  Future<LearningPath?> _getCurrentLearningPath(String studentId) async {
    // Get the current active learning path for the student
    try {
      final pathsString = _prefs.getString(_learningPathsKey);
      if (pathsString == null) return null;

      final pathsMap = jsonDecode(pathsString) as Map<String, dynamic>;

      // Find the most recent path for this student
      LearningPath? currentPath;
      DateTime? latestDate;

      for (final pathData in pathsMap.values) {
        final path = LearningPath.fromJson(pathData as Map<String, dynamic>);
        if (path.studentId == studentId) {
          if (latestDate == null || path.createdAt.isAfter(latestDate)) {
            currentPath = path;
            latestDate = path.createdAt;
          }
        }
      }

      return currentPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current learning path: $e');
      }
      return null;
    }
  }

  Map<String, double> _predictMasteryLevels(
    List<PerformanceDataPoint> historicalData,
    LearningPath? currentPath,
    LearningProfile? profile,
  ) {
    final masteryLevels = <String, double>{};

    // Predict mastery for each category based on historical trends
    for (final category in GameCategory.values) {
      final categoryData = historicalData
          .where((d) => d.category == category)
          .toList();

      if (categoryData.isNotEmpty) {
        final trend = _calculateMasteryTrend(categoryData);
        masteryLevels[category.toString()] = trend;
      } else {
        masteryLevels[category.toString()] = 0.5; // Default
      }
    }

    return masteryLevels;
  }

  double _calculateMasteryTrend(List<PerformanceDataPoint> categoryData) {
    if (categoryData.isEmpty) return 0.5;

    // Simple linear trend calculation
    final accuracies = categoryData.map((d) => d.accuracy).toList();
    final latest = accuracies.last;

    if (accuracies.length > 1) {
      final slope =
          (accuracies.last - accuracies.first) / (accuracies.length - 1);
      return (latest + slope * 5).clamp(0.0, 1.0); // Project 5 sessions ahead
    }

    return latest;
  }

  List<RiskFactor> _identifyRiskFactors(
    List<PerformanceDataPoint> historicalData,
    LearningProfile? profile,
  ) {
    final riskFactors = <RiskFactor>[];

    if (historicalData.isNotEmpty) {
      final recentAccuracy = historicalData.last.accuracy;
      if (recentAccuracy < 0.4) {
        riskFactors.add(RiskFactor.lowPerformance);
      }

      final engagementTrend = _calculateEngagementTrend(historicalData);
      if (engagementTrend < -0.1) {
        riskFactors.add(RiskFactor.decliningEngagement);
      }
    }

    if (profile?.cognitiveLoad == CognitiveLoad.high) {
      riskFactors.add(RiskFactor.cognitiveOverload);
    }

    return riskFactors;
  }

  double _calculateEngagementTrend(List<PerformanceDataPoint> data) {
    if (data.length < 2) return 0.0;

    final engagementScores = data.map((d) => d.engagementLevel).toList();
    return (engagementScores.last - engagementScores.first) /
        (engagementScores.length - 1);
  }

  List<InterventionRecommendation> _generateInterventionRecommendations(
    List<PerformanceDataPoint> historicalData,
    LearningProfile? profile,
  ) {
    final recommendations = <InterventionRecommendation>[];

    if (historicalData.isNotEmpty && historicalData.last.accuracy < 0.5) {
      recommendations.add(
        InterventionRecommendation(
          type: InterventionType.difficultyReduction,
          description: "Reduce difficulty to build confidence",
          priority: Priority.high,
        ),
      );
    }

    if (profile?.cognitiveLoad == CognitiveLoad.high) {
      recommendations.add(
        InterventionRecommendation(
          type: InterventionType.breakReminder,
          description: "Encourage more frequent breaks",
          priority: Priority.medium,
        ),
      );
    }

    return recommendations;
  }

  double _calculatePredictionConfidence(
    List<PerformanceDataPoint> historicalData,
  ) {
    // Calculate confidence in predictions based on data quality and quantity
    if (historicalData.length < 5) return 0.5;
    if (historicalData.length < 10) return 0.7;
    return 0.9;
  }

  List<LearningMilestone> _predictMilestones(
    LearningPath? currentPath,
    LearningProfile? profile,
  ) {
    if (currentPath == null) return [];

    final milestones = <LearningMilestone>[];
    var cumulativeDuration = Duration.zero;

    for (final objective in currentPath.objectives) {
      cumulativeDuration += objective.estimatedDuration;

      milestones.add(
        LearningMilestone(
          objectiveId: objective.id,
          title: objective.title,
          estimatedCompletionDate: DateTime.now().add(cumulativeDuration),
          confidenceLevel: _predictObjectiveSuccess(objective, profile),
        ),
      );
    }

    return milestones;
  }

  double _predictObjectiveSuccess(
    LearningObjective objective,
    LearningProfile? profile,
  ) {
    if (profile == null) return 0.7;

    // Higher success rate for strengths, lower for weaknesses
    if (profile.strengths.contains(objective.category)) {
      return 0.85;
    } else if (profile.weaknesses.contains(objective.category)) {
      return 0.6;
    } else {
      return 0.75;
    }
  }
}

/// Riverpod providers for adaptive learning
final adaptiveLearningEngineProvider = Provider<AdaptiveLearningEngine>((ref) {
  throw UnimplementedError('AdaptiveLearningEngine must be initialized');
});

final learningProfileProvider = FutureProvider.family<LearningProfile?, String>(
  (ref, studentId) async {
    final engine = ref.read(adaptiveLearningEngineProvider);
    return engine.getLearningProfile(studentId);
  },
);

final optimalDifficultyProvider =
    FutureProvider.family<GameDifficulty, OptimalDifficultyParams>((
      ref,
      params,
    ) async {
      final engine = ref.read(adaptiveLearningEngineProvider);
      return engine.predictOptimalDifficulty(
        params.studentId,
        params.category,
        params.recentResults,
      );
    });

final learningPathProvider =
    FutureProvider.family<LearningPath, LearningPathParams>((
      ref,
      params,
    ) async {
      final engine = ref.read(adaptiveLearningEngineProvider);
      return engine.generateLearningPath(
        params.studentId,
        params.gradeLevel,
        params.masteredObjectives,
      );
    });

final engagementStrategyProvider =
    FutureProvider.family<EngagementStrategy, EngagementParams>((
      ref,
      params,
    ) async {
      final engine = ref.read(adaptiveLearningEngineProvider);
      return engine.optimizeEngagement(
        params.studentId,
        params.currentBehavior,
      );
    });

final adaptiveHintProvider =
    FutureProvider.family<AdaptiveHint, AdaptiveHintParams>((
      ref,
      params,
    ) async {
      final engine = ref.read(adaptiveLearningEngineProvider);
      return engine.generateContextualHint(
        params.studentId,
        params.question,
        params.previousAttempts,
        params.timeSpent,
      );
    });

final learningOutcomePredictionProvider =
    FutureProvider.family<LearningOutcomePrediction, LearningOutcomeParams>((
      ref,
      params,
    ) async {
      final engine = ref.read(adaptiveLearningEngineProvider);
      return engine.predictLearningOutcomes(
        params.studentId,
        params.timeHorizon,
      );
    });

// Parameter classes for providers
class OptimalDifficultyParams {
  final String studentId;
  final GameCategory category;
  final List<GameResult> recentResults;

  OptimalDifficultyParams({
    required this.studentId,
    required this.category,
    required this.recentResults,
  });
}

class LearningPathParams {
  final String studentId;
  final GradeLevel gradeLevel;
  final List<LearningObjective> masteredObjectives;

  LearningPathParams({
    required this.studentId,
    required this.gradeLevel,
    required this.masteredObjectives,
  });
}

class EngagementParams {
  final String studentId;
  final StudentBehavior currentBehavior;

  EngagementParams({required this.studentId, required this.currentBehavior});
}

class AdaptiveHintParams {
  final String studentId;
  final AIQuestion question;
  final List<String> previousAttempts;
  final Duration timeSpent;

  AdaptiveHintParams({
    required this.studentId,
    required this.question,
    required this.previousAttempts,
    required this.timeSpent,
  });
}

class LearningOutcomeParams {
  final String studentId;
  final Duration timeHorizon;

  LearningOutcomeParams({required this.studentId, required this.timeHorizon});
}
