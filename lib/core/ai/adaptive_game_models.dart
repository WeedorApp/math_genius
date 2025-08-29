// Core imports
import 'adaptive_learning_models.dart';
import '../../features/game/models/game_model.dart';

/// Adaptive game session with comprehensive tracking
class AdaptiveGameSession {
  final String id;
  final String studentId;
  final GradeLevel gradeLevel;
  final GameCategory category;
  final GameDifficulty optimalDifficulty;
  final LearningProfile? learningProfile;
  final LearningPath? learningPath;
  final String tutorSessionId;
  final StudentBehaviorTracking behaviorTracking;
  final List<AdaptationEvent> adaptationEvents;
  final AdaptivePerformanceMetrics performanceMetrics;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isActive;

  const AdaptiveGameSession({
    required this.id,
    required this.studentId,
    required this.gradeLevel,
    required this.category,
    required this.optimalDifficulty,
    this.learningProfile,
    this.learningPath,
    required this.tutorSessionId,
    required this.behaviorTracking,
    required this.adaptationEvents,
    required this.performanceMetrics,
    required this.createdAt,
    required this.lastUpdated,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'gradeLevel': gradeLevel.toString(),
      'category': category.toString(),
      'optimalDifficulty': optimalDifficulty.toString(),
      'learningProfile': learningProfile?.toJson(),
      'learningPath': learningPath?.toJson(),
      'tutorSessionId': tutorSessionId,
      'behaviorTracking': behaviorTracking.toJson(),
      'adaptationEvents': adaptationEvents.map((e) => e.toJson()).toList(),
      'performanceMetrics': performanceMetrics.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AdaptiveGameSession.fromJson(Map<String, dynamic> json) {
    return AdaptiveGameSession(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.toString() == json['gradeLevel'],
        orElse: () => GradeLevel.grade1,
      ),
      category: GameCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GameCategory.addition,
      ),
      optimalDifficulty: GameDifficulty.values.firstWhere(
        (e) => e.toString() == json['optimalDifficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      learningProfile: json['learningProfile'] != null
          ? LearningProfile.fromJson(
              json['learningProfile'] as Map<String, dynamic>,
            )
          : null,
      learningPath: json['learningPath'] != null
          ? LearningPath.fromJson(json['learningPath'] as Map<String, dynamic>)
          : null,
      tutorSessionId: json['tutorSessionId'] as String,
      behaviorTracking: StudentBehaviorTracking.fromJson(
        json['behaviorTracking'] as Map<String, dynamic>,
      ),
      adaptationEvents: (json['adaptationEvents'] as List)
          .map((e) => AdaptationEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      performanceMetrics: AdaptivePerformanceMetrics.fromJson(
        json['performanceMetrics'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isActive: json['isActive'] as bool,
    );
  }

  AdaptiveGameSession copyWith({
    String? id,
    String? studentId,
    GradeLevel? gradeLevel,
    GameCategory? category,
    GameDifficulty? optimalDifficulty,
    LearningProfile? learningProfile,
    LearningPath? learningPath,
    String? tutorSessionId,
    StudentBehaviorTracking? behaviorTracking,
    List<AdaptationEvent>? adaptationEvents,
    AdaptivePerformanceMetrics? performanceMetrics,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return AdaptiveGameSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      category: category ?? this.category,
      optimalDifficulty: optimalDifficulty ?? this.optimalDifficulty,
      learningProfile: learningProfile ?? this.learningProfile,
      learningPath: learningPath ?? this.learningPath,
      tutorSessionId: tutorSessionId ?? this.tutorSessionId,
      behaviorTracking: behaviorTracking ?? this.behaviorTracking,
      adaptationEvents: adaptationEvents ?? this.adaptationEvents,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Student behavior tracking with historical data
class StudentBehaviorTracking {
  final List<StudentBehavior> behaviorHistory;
  final BehaviorTrends trends;
  final List<BehaviorAlert> alerts;
  final DateTime lastUpdated;

  const StudentBehaviorTracking({
    required this.behaviorHistory,
    required this.trends,
    required this.alerts,
    required this.lastUpdated,
  });

  factory StudentBehaviorTracking.initial() {
    return StudentBehaviorTracking(
      behaviorHistory: [],
      trends: BehaviorTrends.initial(),
      alerts: [],
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'behaviorHistory': behaviorHistory.map((b) => b.toJson()).toList(),
      'trends': trends.toJson(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory StudentBehaviorTracking.fromJson(Map<String, dynamic> json) {
    return StudentBehaviorTracking(
      behaviorHistory: (json['behaviorHistory'] as List)
          .map((b) => StudentBehavior.fromJson(b as Map<String, dynamic>))
          .toList(),
      trends: BehaviorTrends.fromJson(json['trends'] as Map<String, dynamic>),
      alerts: (json['alerts'] as List)
          .map((a) => BehaviorAlert.fromJson(a as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  StudentBehaviorTracking addBehaviorPoint(StudentBehavior behavior) {
    final updatedHistory = List<StudentBehavior>.from(behaviorHistory)
      ..add(behavior);

    // Keep only last 50 behavior points to manage memory
    if (updatedHistory.length > 50) {
      updatedHistory.removeRange(0, updatedHistory.length - 50);
    }

    final updatedTrends = _calculateTrends(updatedHistory);
    final updatedAlerts = _checkForAlerts(behavior, updatedTrends);

    return StudentBehaviorTracking(
      behaviorHistory: updatedHistory,
      trends: updatedTrends,
      alerts: updatedAlerts,
      lastUpdated: DateTime.now(),
    );
  }

  BehaviorTrends _calculateTrends(List<StudentBehavior> history) {
    if (history.length < 2) return BehaviorTrends.initial();

    final recentBehaviors = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    return BehaviorTrends(
      attentionTrend: _calculateTrend(
        recentBehaviors.map((b) => b.attentionLevel).toList(),
      ),
      engagementTrend: _calculateTrend(
        recentBehaviors.map((b) => b.engagementLevel).toList(),
      ),
      frustrationTrend: _calculateTrend(
        recentBehaviors.map((b) => b.frustrationLevel).toList(),
      ),
      boredomTrend: _calculateTrend(
        recentBehaviors.map((b) => b.boredomLevel).toList(),
      ),
      lastCalculated: DateTime.now(),
    );
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    // Simple linear trend calculation
    final firstValue = values.first;
    final lastValue = values.last;
    return (lastValue - firstValue) / (values.length - 1);
  }

  List<BehaviorAlert> _checkForAlerts(
    StudentBehavior currentBehavior,
    BehaviorTrends trends,
  ) {
    final alerts = <BehaviorAlert>[];

    // High frustration alert
    if (currentBehavior.frustrationLevel > 0.8) {
      alerts.add(
        BehaviorAlert(
          type: AlertType.highFrustration,
          severity: AlertSeverity.high,
          message: 'Student showing high frustration levels',
          timestamp: DateTime.now(),
        ),
      );
    }

    // Low engagement alert
    if (currentBehavior.engagementLevel < 0.3) {
      alerts.add(
        BehaviorAlert(
          type: AlertType.lowEngagement,
          severity: AlertSeverity.medium,
          message: 'Student engagement is low',
          timestamp: DateTime.now(),
        ),
      );
    }

    // Declining attention trend alert
    if (trends.attentionTrend < -0.2) {
      alerts.add(
        BehaviorAlert(
          type: AlertType.decliningAttention,
          severity: AlertSeverity.medium,
          message: 'Student attention is declining',
          timestamp: DateTime.now(),
        ),
      );
    }

    return alerts;
  }
}

/// Behavior trends analysis
class BehaviorTrends {
  final double attentionTrend; // -1.0 to 1.0
  final double engagementTrend; // -1.0 to 1.0
  final double frustrationTrend; // -1.0 to 1.0
  final double boredomTrend; // -1.0 to 1.0
  final DateTime lastCalculated;

  const BehaviorTrends({
    required this.attentionTrend,
    required this.engagementTrend,
    required this.frustrationTrend,
    required this.boredomTrend,
    required this.lastCalculated,
  });

  factory BehaviorTrends.initial() {
    return BehaviorTrends(
      attentionTrend: 0.0,
      engagementTrend: 0.0,
      frustrationTrend: 0.0,
      boredomTrend: 0.0,
      lastCalculated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attentionTrend': attentionTrend,
      'engagementTrend': engagementTrend,
      'frustrationTrend': frustrationTrend,
      'boredomTrend': boredomTrend,
      'lastCalculated': lastCalculated.toIso8601String(),
    };
  }

  factory BehaviorTrends.fromJson(Map<String, dynamic> json) {
    return BehaviorTrends(
      attentionTrend: (json['attentionTrend'] as num).toDouble(),
      engagementTrend: (json['engagementTrend'] as num).toDouble(),
      frustrationTrend: (json['frustrationTrend'] as num).toDouble(),
      boredomTrend: (json['boredomTrend'] as num).toDouble(),
      lastCalculated: DateTime.parse(json['lastCalculated'] as String),
    );
  }
}

/// Behavior alert for intervention triggers
class BehaviorAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;

  const BehaviorAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BehaviorAlert.fromJson(Map<String, dynamic> json) {
    return BehaviorAlert(
      type: AlertType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AlertType.other,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == json['severity'],
        orElse: () => AlertSeverity.low,
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Adaptive performance metrics with detailed tracking
class AdaptivePerformanceMetrics {
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy; // 0.0 - 1.0
  final double recentAccuracy; // Last 10 questions
  final List<bool> recentResults; // Last 10 results
  final Duration averageResponseTime;
  final Map<GameDifficulty, double> difficultyAccuracy;
  final Map<GameCategory, double> categoryAccuracy;
  final DateTime lastUpdated;

  const AdaptivePerformanceMetrics({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.recentAccuracy,
    required this.recentResults,
    required this.averageResponseTime,
    required this.difficultyAccuracy,
    required this.categoryAccuracy,
    required this.lastUpdated,
  });

  factory AdaptivePerformanceMetrics.initial() {
    return AdaptivePerformanceMetrics(
      totalQuestions: 0,
      correctAnswers: 0,
      accuracy: 0.0,
      recentAccuracy: 0.0,
      recentResults: [],
      averageResponseTime: const Duration(seconds: 30),
      difficultyAccuracy: {},
      categoryAccuracy: {},
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'recentAccuracy': recentAccuracy,
      'recentResults': recentResults,
      'averageResponseTime': averageResponseTime.inSeconds,
      'difficultyAccuracy': difficultyAccuracy.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'categoryAccuracy': categoryAccuracy.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory AdaptivePerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return AdaptivePerformanceMetrics(
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      recentAccuracy: (json['recentAccuracy'] as num).toDouble(),
      recentResults: List<bool>.from(json['recentResults'] as List),
      averageResponseTime: Duration(
        seconds: json['averageResponseTime'] as int,
      ),
      difficultyAccuracy: (json['difficultyAccuracy'] as Map<String, dynamic>)
          .map(
            (k, v) => MapEntry(
              GameDifficulty.values.firstWhere(
                (e) => e.toString() == k,
                orElse: () => GameDifficulty.normal,
              ),
              (v as num).toDouble(),
            ),
          ),
      categoryAccuracy: (json['categoryAccuracy'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          GameCategory.values.firstWhere(
            (e) => e.toString() == k,
            orElse: () => GameCategory.addition,
          ),
          (v as num).toDouble(),
        ),
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  AdaptivePerformanceMetrics copyWith({
    int? totalQuestions,
    int? correctAnswers,
    double? accuracy,
    double? recentAccuracy,
    List<bool>? recentResults,
    Duration? averageResponseTime,
    Map<GameDifficulty, double>? difficultyAccuracy,
    Map<GameCategory, double>? categoryAccuracy,
    DateTime? lastUpdated,
  }) {
    return AdaptivePerformanceMetrics(
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      accuracy: accuracy ?? this.accuracy,
      recentAccuracy: recentAccuracy ?? this.recentAccuracy,
      recentResults: recentResults ?? this.recentResults,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      difficultyAccuracy: difficultyAccuracy ?? this.difficultyAccuracy,
      categoryAccuracy: categoryAccuracy ?? this.categoryAccuracy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Adaptation event tracking
class AdaptationEvent {
  final String id;
  final String sessionId;
  final AdaptationTrigger trigger;
  final AdaptationType adaptationType;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const AdaptationEvent({
    required this.id,
    required this.sessionId,
    required this.trigger,
    required this.adaptationType,
    required this.parameters,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'trigger': trigger.toString(),
      'adaptationType': adaptationType.toString(),
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AdaptationEvent.fromJson(Map<String, dynamic> json) {
    return AdaptationEvent(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      trigger: AdaptationTrigger.values.firstWhere(
        (e) => e.toString() == json['trigger'],
        orElse: () => AdaptationTrigger.other,
      ),
      adaptationType: AdaptationType.values.firstWhere(
        (e) => e.toString() == json['adaptationType'],
        orElse: () => AdaptationType.other,
      ),
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Adaptive feedback with personalization
class AdaptiveFeedback {
  final String id;
  final String questionId;
  final String studentAnswer;
  final bool isCorrect;
  final FeedbackType type;
  final String message;
  final List<String> suggestions;
  final List<String> personalizedElements;
  final DateTime createdAt;

  const AdaptiveFeedback({
    required this.id,
    required this.questionId,
    required this.studentAnswer,
    required this.isCorrect,
    required this.type,
    required this.message,
    required this.suggestions,
    required this.personalizedElements,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'studentAnswer': studentAnswer,
      'isCorrect': isCorrect,
      'type': type.toString(),
      'message': message,
      'suggestions': suggestions,
      'personalizedElements': personalizedElements,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdaptiveFeedback.fromJson(Map<String, dynamic> json) {
    return AdaptiveFeedback(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      studentAnswer: json['studentAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      type: FeedbackType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => FeedbackType.neutral,
      ),
      message: json['message'] as String,
      suggestions: List<String>.from(json['suggestions'] as List),
      personalizedElements: List<String>.from(
        json['personalizedElements'] as List,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Behavior analysis results
class BehaviorAnalysis {
  final double frustrationTrend;
  final double engagementTrend;
  final bool needsIntervention;
  final List<String> recommendedActions;

  const BehaviorAnalysis({
    required this.frustrationTrend,
    required this.engagementTrend,
    required this.needsIntervention,
    required this.recommendedActions,
  });

  Map<String, dynamic> toJson() {
    return {
      'frustrationTrend': frustrationTrend,
      'engagementTrend': engagementTrend,
      'needsIntervention': needsIntervention,
      'recommendedActions': recommendedActions,
    };
  }

  factory BehaviorAnalysis.fromJson(Map<String, dynamic> json) {
    return BehaviorAnalysis(
      frustrationTrend: (json['frustrationTrend'] as num).toDouble(),
      engagementTrend: (json['engagementTrend'] as num).toDouble(),
      needsIntervention: json['needsIntervention'] as bool,
      recommendedActions: List<String>.from(json['recommendedActions'] as List),
    );
  }
}

/// Hint usage event for analytics
class HintUsageEvent {
  final String sessionId;
  final String hintId;
  final HintLevel hintLevel;
  final StudentBehavior studentBehavior;
  final DateTime timestamp;

  const HintUsageEvent({
    required this.sessionId,
    required this.hintId,
    required this.hintLevel,
    required this.studentBehavior,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'hintId': hintId,
      'hintLevel': hintLevel.toString(),
      'studentBehavior': studentBehavior.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HintUsageEvent.fromJson(Map<String, dynamic> json) {
    return HintUsageEvent(
      sessionId: json['sessionId'] as String,
      hintId: json['hintId'] as String,
      hintLevel: HintLevel.values.firstWhere(
        (e) => e.toString() == json['hintLevel'],
        orElse: () => HintLevel.gentle,
      ),
      studentBehavior: StudentBehavior.fromJson(
        json['studentBehavior'] as Map<String, dynamic>,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Engagement strategy application tracking
class EngagementStrategyApplication {
  final String sessionId;
  final EngagementStrategy strategy;
  final DateTime appliedAt;

  const EngagementStrategyApplication({
    required this.sessionId,
    required this.strategy,
    required this.appliedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'strategy': strategy.toJson(),
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  factory EngagementStrategyApplication.fromJson(Map<String, dynamic> json) {
    return EngagementStrategyApplication(
      sessionId: json['sessionId'] as String,
      strategy: EngagementStrategy.fromJson(
        json['strategy'] as Map<String, dynamic>,
      ),
      appliedAt: DateTime.parse(json['appliedAt'] as String),
    );
  }
}

// Enums for adaptive game system

enum AlertType {
  highFrustration,
  lowEngagement,
  decliningAttention,
  poorPerformance,
  boredom,
  other,
}

enum AlertSeverity { low, medium, high, critical }

enum AdaptationTrigger {
  highFrustration,
  lowEngagement,
  poorPerformance,
  boredom,
  timeoutPattern,
  other,
}

enum AdaptationType {
  difficultyReduction,
  difficultyIncrease,
  engagementBoost,
  hintFrequencyAdjustment,
  encouragementIncrease,
  breakSuggestion,
  other,
}

enum FeedbackType { positive, corrective, supportive, encouraging, neutral }

/// Extension methods for better usability
extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.highFrustration:
        return 'High Frustration';
      case AlertType.lowEngagement:
        return 'Low Engagement';
      case AlertType.decliningAttention:
        return 'Declining Attention';
      case AlertType.poorPerformance:
        return 'Poor Performance';
      case AlertType.boredom:
        return 'Boredom';
      case AlertType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case AlertType.highFrustration:
        return '😤';
      case AlertType.lowEngagement:
        return '😴';
      case AlertType.decliningAttention:
        return '👀';
      case AlertType.poorPerformance:
        return '📉';
      case AlertType.boredom:
        return '😑';
      case AlertType.other:
        return '⚠️';
    }
  }
}

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String get color {
    switch (this) {
      case AlertSeverity.low:
        return '#4CAF50'; // Green
      case AlertSeverity.medium:
        return '#FF9800'; // Orange
      case AlertSeverity.high:
        return '#F44336'; // Red
      case AlertSeverity.critical:
        return '#9C27B0'; // Purple
    }
  }
}

extension AdaptationTriggerExtension on AdaptationTrigger {
  String get displayName {
    switch (this) {
      case AdaptationTrigger.highFrustration:
        return 'High Frustration';
      case AdaptationTrigger.lowEngagement:
        return 'Low Engagement';
      case AdaptationTrigger.poorPerformance:
        return 'Poor Performance';
      case AdaptationTrigger.boredom:
        return 'Boredom';
      case AdaptationTrigger.timeoutPattern:
        return 'Timeout Pattern';
      case AdaptationTrigger.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case AdaptationTrigger.highFrustration:
        return 'Student showing signs of frustration';
      case AdaptationTrigger.lowEngagement:
        return 'Student engagement has dropped';
      case AdaptationTrigger.poorPerformance:
        return 'Student performance is below expected level';
      case AdaptationTrigger.boredom:
        return 'Student appears to be bored with current content';
      case AdaptationTrigger.timeoutPattern:
        return 'Student consistently running out of time';
      case AdaptationTrigger.other:
        return 'Other adaptation trigger';
    }
  }
}

extension AdaptationTypeExtension on AdaptationType {
  String get displayName {
    switch (this) {
      case AdaptationType.difficultyReduction:
        return 'Difficulty Reduction';
      case AdaptationType.difficultyIncrease:
        return 'Difficulty Increase';
      case AdaptationType.engagementBoost:
        return 'Engagement Boost';
      case AdaptationType.hintFrequencyAdjustment:
        return 'Hint Frequency Adjustment';
      case AdaptationType.encouragementIncrease:
        return 'Encouragement Increase';
      case AdaptationType.breakSuggestion:
        return 'Break Suggestion';
      case AdaptationType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case AdaptationType.difficultyReduction:
        return 'Reduce question difficulty to build confidence';
      case AdaptationType.difficultyIncrease:
        return 'Increase difficulty to maintain challenge';
      case AdaptationType.engagementBoost:
        return 'Add engaging elements to recapture attention';
      case AdaptationType.hintFrequencyAdjustment:
        return 'Adjust how often hints are provided';
      case AdaptationType.encouragementIncrease:
        return 'Provide more frequent encouragement';
      case AdaptationType.breakSuggestion:
        return 'Suggest taking a break';
      case AdaptationType.other:
        return 'Other type of adaptation';
    }
  }
}

extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.positive:
        return 'Positive';
      case FeedbackType.corrective:
        return 'Corrective';
      case FeedbackType.supportive:
        return 'Supportive';
      case FeedbackType.encouraging:
        return 'Encouraging';
      case FeedbackType.neutral:
        return 'Neutral';
    }
  }

  String get icon {
    switch (this) {
      case FeedbackType.positive:
        return '🎉';
      case FeedbackType.corrective:
        return '🔄';
      case FeedbackType.supportive:
        return '🤝';
      case FeedbackType.encouraging:
        return '💪';
      case FeedbackType.neutral:
        return 'ℹ️';
    }
  }
}
