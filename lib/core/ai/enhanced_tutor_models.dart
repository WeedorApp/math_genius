// Core imports
import 'adaptive_learning_models.dart';
import '../../features/game/models/game_model.dart';

/// Enhanced tutor session with adaptive capabilities
class EnhancedTutorSession {
  final String id;
  final String studentId;
  final String topic;
  final GradeLevel gradeLevel;
  final GameCategory category;
  final TutorPersonality tutorPersonality;
  final SessionContext sessionContext;
  final List<EnhancedHint> adaptiveHints;
  final List<LearningInsight> learningInsights;
  final EngagementMetrics engagementMetrics;
  final DateTime startedAt;
  final DateTime lastInteraction;
  final bool isActive;
  final String? parentSessionId;

  const EnhancedTutorSession({
    required this.id,
    required this.studentId,
    required this.topic,
    required this.gradeLevel,
    required this.category,
    required this.tutorPersonality,
    required this.sessionContext,
    required this.adaptiveHints,
    required this.learningInsights,
    required this.engagementMetrics,
    required this.startedAt,
    required this.lastInteraction,
    required this.isActive,
    this.parentSessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'topic': topic,
      'gradeLevel': gradeLevel.toString(),
      'category': category.toString(),
      'tutorPersonality': tutorPersonality.toJson(),
      'sessionContext': sessionContext.toJson(),
      'adaptiveHints': adaptiveHints.map((h) => h.toJson()).toList(),
      'learningInsights': learningInsights.map((i) => i.toJson()).toList(),
      'engagementMetrics': engagementMetrics.toJson(),
      'startedAt': startedAt.toIso8601String(),
      'lastInteraction': lastInteraction.toIso8601String(),
      'isActive': isActive,
      'parentSessionId': parentSessionId,
    };
  }

  factory EnhancedTutorSession.fromJson(Map<String, dynamic> json) {
    return EnhancedTutorSession(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      topic: json['topic'] as String,
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.toString() == json['gradeLevel'],
        orElse: () => GradeLevel.grade1,
      ),
      category: GameCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GameCategory.addition,
      ),
      tutorPersonality: TutorPersonality.fromJson(
        json['tutorPersonality'] as Map<String, dynamic>,
      ),
      sessionContext: SessionContext.fromJson(
        json['sessionContext'] as Map<String, dynamic>,
      ),
      adaptiveHints: (json['adaptiveHints'] as List)
          .map((h) => EnhancedHint.fromJson(h as Map<String, dynamic>))
          .toList(),
      learningInsights: (json['learningInsights'] as List)
          .map((i) => LearningInsight.fromJson(i as Map<String, dynamic>))
          .toList(),
      engagementMetrics: EngagementMetrics.fromJson(
        json['engagementMetrics'] as Map<String, dynamic>,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastInteraction: DateTime.parse(json['lastInteraction'] as String),
      isActive: json['isActive'] as bool,
      parentSessionId: json['parentSessionId'] as String?,
    );
  }

  EnhancedTutorSession copyWith({
    String? id,
    String? studentId,
    String? topic,
    GradeLevel? gradeLevel,
    GameCategory? category,
    TutorPersonality? tutorPersonality,
    SessionContext? sessionContext,
    List<EnhancedHint>? adaptiveHints,
    List<LearningInsight>? learningInsights,
    EngagementMetrics? engagementMetrics,
    DateTime? startedAt,
    DateTime? lastInteraction,
    bool? isActive,
    String? parentSessionId,
  }) {
    return EnhancedTutorSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      topic: topic ?? this.topic,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      category: category ?? this.category,
      tutorPersonality: tutorPersonality ?? this.tutorPersonality,
      sessionContext: sessionContext ?? this.sessionContext,
      adaptiveHints: adaptiveHints ?? this.adaptiveHints,
      learningInsights: learningInsights ?? this.learningInsights,
      engagementMetrics: engagementMetrics ?? this.engagementMetrics,
      startedAt: startedAt ?? this.startedAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      isActive: isActive ?? this.isActive,
      parentSessionId: parentSessionId ?? this.parentSessionId,
    );
  }
}

/// Tutor personality with adaptive characteristics
class TutorPersonality {
  final String name;
  final CommunicationStyle communicationStyle;
  final double encouragementLevel; // 0.0 - 1.0
  final double patienceLevel; // 0.0 - 1.0
  final double humorLevel; // 0.0 - 1.0
  final double formalityLevel; // 0.0 - 1.0
  final double adaptabilityScore; // 0.0 - 1.0
  final List<String> specialties;
  final ExplanationStyle preferredExplanationStyle;

  const TutorPersonality({
    required this.name,
    required this.communicationStyle,
    required this.encouragementLevel,
    required this.patienceLevel,
    required this.humorLevel,
    required this.formalityLevel,
    required this.adaptabilityScore,
    required this.specialties,
    required this.preferredExplanationStyle,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'communicationStyle': communicationStyle.toString(),
      'encouragementLevel': encouragementLevel,
      'patienceLevel': patienceLevel,
      'humorLevel': humorLevel,
      'formalityLevel': formalityLevel,
      'adaptabilityScore': adaptabilityScore,
      'specialties': specialties,
      'preferredExplanationStyle': preferredExplanationStyle.toString(),
    };
  }

  factory TutorPersonality.fromJson(Map<String, dynamic> json) {
    return TutorPersonality(
      name: json['name'] as String,
      communicationStyle: CommunicationStyle.values.firstWhere(
        (e) => e.toString() == json['communicationStyle'],
        orElse: () => CommunicationStyle.conversational,
      ),
      encouragementLevel: (json['encouragementLevel'] as num).toDouble(),
      patienceLevel: (json['patienceLevel'] as num).toDouble(),
      humorLevel: (json['humorLevel'] as num).toDouble(),
      formalityLevel: (json['formalityLevel'] as num).toDouble(),
      adaptabilityScore: (json['adaptabilityScore'] as num).toDouble(),
      specialties: List<String>.from(json['specialties'] as List),
      preferredExplanationStyle: ExplanationStyle.values.firstWhere(
        (e) => e.toString() == json['preferredExplanationStyle'],
        orElse: () => ExplanationStyle.stepByStep,
      ),
    );
  }

  TutorPersonality copyWith({
    String? name,
    CommunicationStyle? communicationStyle,
    double? encouragementLevel,
    double? patienceLevel,
    double? humorLevel,
    double? formalityLevel,
    double? adaptabilityScore,
    List<String>? specialties,
    ExplanationStyle? preferredExplanationStyle,
  }) {
    return TutorPersonality(
      name: name ?? this.name,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      encouragementLevel: encouragementLevel ?? this.encouragementLevel,
      patienceLevel: patienceLevel ?? this.patienceLevel,
      humorLevel: humorLevel ?? this.humorLevel,
      formalityLevel: formalityLevel ?? this.formalityLevel,
      adaptabilityScore: adaptabilityScore ?? this.adaptabilityScore,
      specialties: specialties ?? this.specialties,
      preferredExplanationStyle:
          preferredExplanationStyle ?? this.preferredExplanationStyle,
    );
  }
}

/// Session context with adaptive parameters
class SessionContext {
  final String studentId;
  final String topic;
  final GradeLevel gradeLevel;
  final GameCategory category;
  final List<String> learningObjectives;
  final List<String> prerequisiteKnowledge;
  final GameDifficulty difficultyLevel;
  final Duration estimatedDuration;
  final AdaptiveParameters adaptiveParameters;

  const SessionContext({
    required this.studentId,
    required this.topic,
    required this.gradeLevel,
    required this.category,
    required this.learningObjectives,
    required this.prerequisiteKnowledge,
    required this.difficultyLevel,
    required this.estimatedDuration,
    required this.adaptiveParameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'topic': topic,
      'gradeLevel': gradeLevel.toString(),
      'category': category.toString(),
      'learningObjectives': learningObjectives,
      'prerequisiteKnowledge': prerequisiteKnowledge,
      'difficultyLevel': difficultyLevel.toString(),
      'estimatedDuration': estimatedDuration.inMinutes,
      'adaptiveParameters': adaptiveParameters.toJson(),
    };
  }

  factory SessionContext.fromJson(Map<String, dynamic> json) {
    return SessionContext(
      studentId: json['studentId'] as String,
      topic: json['topic'] as String,
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.toString() == json['gradeLevel'],
        orElse: () => GradeLevel.grade1,
      ),
      category: GameCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GameCategory.addition,
      ),
      learningObjectives: List<String>.from(json['learningObjectives'] as List),
      prerequisiteKnowledge: List<String>.from(
        json['prerequisiteKnowledge'] as List,
      ),
      difficultyLevel: GameDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficultyLevel'],
        orElse: () => GameDifficulty.normal,
      ),
      estimatedDuration: Duration(minutes: json['estimatedDuration'] as int),
      adaptiveParameters: AdaptiveParameters.fromJson(
        json['adaptiveParameters'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Adaptive parameters for session customization
class AdaptiveParameters {
  final double hintFrequency; // 0.0 - 1.0
  final double encouragementFrequency; // 0.0 - 1.0
  final double difficultyAdjustmentSensitivity; // 0.0 - 1.0

  const AdaptiveParameters({
    required this.hintFrequency,
    required this.encouragementFrequency,
    required this.difficultyAdjustmentSensitivity,
  });

  Map<String, dynamic> toJson() {
    return {
      'hintFrequency': hintFrequency,
      'encouragementFrequency': encouragementFrequency,
      'difficultyAdjustmentSensitivity': difficultyAdjustmentSensitivity,
    };
  }

  factory AdaptiveParameters.fromJson(Map<String, dynamic> json) {
    return AdaptiveParameters(
      hintFrequency: (json['hintFrequency'] as num).toDouble(),
      encouragementFrequency: (json['encouragementFrequency'] as num)
          .toDouble(),
      difficultyAdjustmentSensitivity:
          (json['difficultyAdjustmentSensitivity'] as num).toDouble(),
    );
  }
}

/// Enhanced hint with multi-modal support
class EnhancedHint {
  final String id;
  final AdaptiveHint baseHint;
  final String personalizedContent;
  final String encouragement;
  final DeliveryStyle deliveryStyle;
  final EmotionalTone emotionalTone;
  final List<VisualEnhancement> visualEnhancements;
  final List<AudioEnhancement> audioEnhancements;
  final List<InteractiveEnhancement> interactiveEnhancements;
  final DateTime createdAt;

  const EnhancedHint({
    required this.id,
    required this.baseHint,
    required this.personalizedContent,
    required this.encouragement,
    required this.deliveryStyle,
    required this.emotionalTone,
    required this.visualEnhancements,
    required this.audioEnhancements,
    required this.interactiveEnhancements,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baseHint': baseHint.toJson(),
      'personalizedContent': personalizedContent,
      'encouragement': encouragement,
      'deliveryStyle': deliveryStyle.toString(),
      'emotionalTone': emotionalTone.toString(),
      'visualEnhancements': visualEnhancements
          .map((v) => v.toString())
          .toList(),
      'audioEnhancements': audioEnhancements.map((a) => a.toString()).toList(),
      'interactiveEnhancements': interactiveEnhancements
          .map((i) => i.toString())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EnhancedHint.fromJson(Map<String, dynamic> json) {
    return EnhancedHint(
      id: json['id'] as String,
      baseHint: AdaptiveHint.fromJson(json['baseHint'] as Map<String, dynamic>),
      personalizedContent: json['personalizedContent'] as String,
      encouragement: json['encouragement'] as String,
      deliveryStyle: DeliveryStyle.values.firstWhere(
        (e) => e.toString() == json['deliveryStyle'],
        orElse: () => DeliveryStyle.conversational,
      ),
      emotionalTone: EmotionalTone.values.firstWhere(
        (e) => e.toString() == json['emotionalTone'],
        orElse: () => EmotionalTone.encouraging,
      ),
      visualEnhancements: (json['visualEnhancements'] as List)
          .map(
            (v) => VisualEnhancement.values.firstWhere(
              (e) => e.toString() == v,
              orElse: () => VisualEnhancement.colorCoding,
            ),
          )
          .toList(),
      audioEnhancements: (json['audioEnhancements'] as List)
          .map(
            (a) => AudioEnhancement.values.firstWhere(
              (e) => e.toString() == a,
              orElse: () => AudioEnhancement.voiceOver,
            ),
          )
          .toList(),
      interactiveEnhancements: (json['interactiveEnhancements'] as List)
          .map(
            (i) => InteractiveEnhancement.values.firstWhere(
              (e) => e.toString() == i,
              orElse: () => InteractiveEnhancement.dragDrop,
            ),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Learning insight with actionable recommendations
class LearningInsight {
  final InsightType type;
  final String title;
  final String description;
  final String recommendation;
  final double confidence; // 0.0 - 1.0
  final Priority priority;
  final DateTime createdAt;

  const LearningInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.confidence,
    required this.priority,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'confidence': confidence,
      'priority': priority.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LearningInsight.fromJson(Map<String, dynamic> json) {
    return LearningInsight(
      type: InsightType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => InsightType.performance,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      recommendation: json['recommendation'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      priority: Priority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => Priority.medium,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Engagement metrics for session tracking
class EngagementMetrics {
  final int totalInteractions;
  final Duration averageResponseTime;
  final double engagementTrend; // -1.0 to 1.0
  final int frustrationEvents;
  final int successfulHints;
  final DateTime lastUpdated;

  const EngagementMetrics({
    required this.totalInteractions,
    required this.averageResponseTime,
    required this.engagementTrend,
    required this.frustrationEvents,
    required this.successfulHints,
    required this.lastUpdated,
  });

  factory EngagementMetrics.initial() {
    return EngagementMetrics(
      totalInteractions: 0,
      averageResponseTime: const Duration(seconds: 30),
      engagementTrend: 0.0,
      frustrationEvents: 0,
      successfulHints: 0,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalInteractions': totalInteractions,
      'averageResponseTime': averageResponseTime.inSeconds,
      'engagementTrend': engagementTrend,
      'frustrationEvents': frustrationEvents,
      'successfulHints': successfulHints,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      totalInteractions: json['totalInteractions'] as int,
      averageResponseTime: Duration(
        seconds: json['averageResponseTime'] as int,
      ),
      engagementTrend: (json['engagementTrend'] as num).toDouble(),
      frustrationEvents: json['frustrationEvents'] as int,
      successfulHints: json['successfulHints'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  EngagementMetrics copyWith({
    int? totalInteractions,
    Duration? averageResponseTime,
    double? engagementTrend,
    int? frustrationEvents,
    int? successfulHints,
    DateTime? lastUpdated,
  }) {
    return EngagementMetrics(
      totalInteractions: totalInteractions ?? this.totalInteractions,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      engagementTrend: engagementTrend ?? this.engagementTrend,
      frustrationEvents: frustrationEvents ?? this.frustrationEvents,
      successfulHints: successfulHints ?? this.successfulHints,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Emotional analysis for adaptive responses
class EmotionalAnalysis {
  final double frustrationLevel; // 0.0 - 1.0
  final double confidenceLevel; // 0.0 - 1.0
  final double engagementLevel; // 0.0 - 1.0
  final EmotionalState emotionalState;
  final ResponseStrategy recommendedResponse;

  const EmotionalAnalysis({
    required this.frustrationLevel,
    required this.confidenceLevel,
    required this.engagementLevel,
    required this.emotionalState,
    required this.recommendedResponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'frustrationLevel': frustrationLevel,
      'confidenceLevel': confidenceLevel,
      'engagementLevel': engagementLevel,
      'emotionalState': emotionalState.toString(),
      'recommendedResponse': recommendedResponse.toString(),
    };
  }

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      frustrationLevel: (json['frustrationLevel'] as num).toDouble(),
      confidenceLevel: (json['confidenceLevel'] as num).toDouble(),
      engagementLevel: (json['engagementLevel'] as num).toDouble(),
      emotionalState: EmotionalState.values.firstWhere(
        (e) => e.toString() == json['emotionalState'],
        orElse: () => EmotionalState.neutral,
      ),
      recommendedResponse: ResponseStrategy.values.firstWhere(
        (e) => e.toString() == json['recommendedResponse'],
        orElse: () => ResponseStrategy.encouraging,
      ),
    );
  }
}

/// Tutor response with adaptive characteristics
class TutorResponse {
  final String id;
  final String content;
  final ResponseType responseType;
  final DeliveryStyle deliveryStyle;
  final EmotionalTone emotionalTone;
  final List<String> followUpQuestions;
  final List<String> additionalResources;
  final double estimatedHelpfulness; // 0.0 - 1.0
  final DateTime createdAt;

  const TutorResponse({
    required this.id,
    required this.content,
    required this.responseType,
    required this.deliveryStyle,
    required this.emotionalTone,
    required this.followUpQuestions,
    required this.additionalResources,
    required this.estimatedHelpfulness,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'responseType': responseType.toString(),
      'deliveryStyle': deliveryStyle.toString(),
      'emotionalTone': emotionalTone.toString(),
      'followUpQuestions': followUpQuestions,
      'additionalResources': additionalResources,
      'estimatedHelpfulness': estimatedHelpfulness,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TutorResponse.fromJson(Map<String, dynamic> json) {
    return TutorResponse(
      id: json['id'] as String,
      content: json['content'] as String,
      responseType: ResponseType.values.firstWhere(
        (e) => e.toString() == json['responseType'],
        orElse: () => ResponseType.helpful,
      ),
      deliveryStyle: DeliveryStyle.values.firstWhere(
        (e) => e.toString() == json['deliveryStyle'],
        orElse: () => DeliveryStyle.conversational,
      ),
      emotionalTone: EmotionalTone.values.firstWhere(
        (e) => e.toString() == json['emotionalTone'],
        orElse: () => EmotionalTone.encouraging,
      ),
      followUpQuestions: List<String>.from(json['followUpQuestions'] as List),
      additionalResources: List<String>.from(
        json['additionalResources'] as List,
      ),
      estimatedHelpfulness: (json['estimatedHelpfulness'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Student feedback for tutor adaptation
class StudentFeedback {
  final String sessionId;
  final bool likesEncouragement;
  final bool likesHumor;
  final bool prefersVisualAids;
  final bool prefersAudioSupport;
  final double satisfactionLevel; // 0.0 - 1.0
  final String? additionalComments;
  final DateTime providedAt;

  const StudentFeedback({
    required this.sessionId,
    required this.likesEncouragement,
    required this.likesHumor,
    required this.prefersVisualAids,
    required this.prefersAudioSupport,
    required this.satisfactionLevel,
    this.additionalComments,
    required this.providedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'likesEncouragement': likesEncouragement,
      'likesHumor': likesHumor,
      'prefersVisualAids': prefersVisualAids,
      'prefersAudioSupport': prefersAudioSupport,
      'satisfactionLevel': satisfactionLevel,
      'additionalComments': additionalComments,
      'providedAt': providedAt.toIso8601String(),
    };
  }

  factory StudentFeedback.fromJson(Map<String, dynamic> json) {
    return StudentFeedback(
      sessionId: json['sessionId'] as String,
      likesEncouragement: json['likesEncouragement'] as bool,
      likesHumor: json['likesHumor'] as bool,
      prefersVisualAids: json['prefersVisualAids'] as bool,
      prefersAudioSupport: json['prefersAudioSupport'] as bool,
      satisfactionLevel: (json['satisfactionLevel'] as num).toDouble(),
      additionalComments: json['additionalComments'] as String?,
      providedAt: DateTime.parse(json['providedAt'] as String),
    );
  }
}

/// Question context for adaptive responses
class QuestionContext {
  final String questionId;
  final String topic;
  final GameCategory category;
  final GameDifficulty difficulty;
  final List<String> previousAttempts;
  final Duration timeSpent;
  final int hintCount;

  const QuestionContext({
    required this.questionId,
    required this.topic,
    required this.category,
    required this.difficulty,
    required this.previousAttempts,
    required this.timeSpent,
    required this.hintCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'topic': topic,
      'category': category.toString(),
      'difficulty': difficulty.toString(),
      'previousAttempts': previousAttempts,
      'timeSpent': timeSpent.inSeconds,
      'hintCount': hintCount,
    };
  }

  factory QuestionContext.fromJson(Map<String, dynamic> json) {
    return QuestionContext(
      questionId: json['questionId'] as String,
      topic: json['topic'] as String,
      category: GameCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GameCategory.addition,
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      previousAttempts: List<String>.from(json['previousAttempts'] as List),
      timeSpent: Duration(seconds: json['timeSpent'] as int),
      hintCount: json['hintCount'] as int,
    );
  }
}

/// Motivational support with personalized content
class MotivationalSupport {
  final MotivationType type;
  final String message;
  final List<String> suggestedActions;
  final List<String> personalizedElements;
  final DeliveryStyle deliveryStyle;
  final DateTime createdAt;

  const MotivationalSupport({
    required this.type,
    required this.message,
    required this.suggestedActions,
    required this.personalizedElements,
    required this.deliveryStyle,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'message': message,
      'suggestedActions': suggestedActions,
      'personalizedElements': personalizedElements,
      'deliveryStyle': deliveryStyle.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MotivationalSupport.fromJson(Map<String, dynamic> json) {
    return MotivationalSupport(
      type: MotivationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MotivationType.encouragement,
      ),
      message: json['message'] as String,
      suggestedActions: List<String>.from(json['suggestedActions'] as List),
      personalizedElements: List<String>.from(
        json['personalizedElements'] as List,
      ),
      deliveryStyle: DeliveryStyle.values.firstWhere(
        (e) => e.toString() == json['deliveryStyle'],
        orElse: () => DeliveryStyle.conversational,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// Enums for enhanced tutor system

enum CommunicationStyle {
  conversational,
  formal,
  playful,
  descriptive,
  interactive,
}

enum ExplanationStyle { stepByStep, visual, conceptual, handson, analogical }

enum DeliveryStyle { conversational, formal, animated, gentle, enthusiastic }

enum EmotionalTone { encouraging, supportive, enthusiastic, calm, playful }

enum VisualEnhancement { colorCoding, animation, diagram, highlighting, icons }

enum AudioEnhancement { voiceOver, soundEffects, musicBackground, emphasis }

enum InteractiveEnhancement { dragDrop, gesture, touch, voice, drawing }

enum InsightType {
  performance,
  engagement,
  learningStyle,
  recommendation,
  warning,
}

enum EmotionalState {
  frustrated,
  confident,
  neutral,
  excited,
  confused,
  disengaged,
}

enum ResponseStrategy {
  supportive,
  challenging,
  encouraging,
  engaging,
  simplifying,
}

enum ResponseType { helpful, supportive, challenging, clarifying, motivational }

enum MotivationType {
  encouragement,
  celebration,
  reassurance,
  energizing,
  challenge,
}

/// Extension methods for better usability
extension CommunicationStyleExtension on CommunicationStyle {
  String get displayName {
    switch (this) {
      case CommunicationStyle.conversational:
        return 'Conversational';
      case CommunicationStyle.formal:
        return 'Formal';
      case CommunicationStyle.playful:
        return 'Playful';
      case CommunicationStyle.descriptive:
        return 'Descriptive';
      case CommunicationStyle.interactive:
        return 'Interactive';
    }
  }

  String get description {
    switch (this) {
      case CommunicationStyle.conversational:
        return 'Natural, friendly conversation style';
      case CommunicationStyle.formal:
        return 'Professional and structured approach';
      case CommunicationStyle.playful:
        return 'Fun and engaging with humor';
      case CommunicationStyle.descriptive:
        return 'Detailed explanations with examples';
      case CommunicationStyle.interactive:
        return 'Encourages participation and questions';
    }
  }
}

extension ExplanationStyleExtension on ExplanationStyle {
  String get displayName {
    switch (this) {
      case ExplanationStyle.stepByStep:
        return 'Step-by-Step';
      case ExplanationStyle.visual:
        return 'Visual';
      case ExplanationStyle.conceptual:
        return 'Conceptual';
      case ExplanationStyle.handson:
        return 'Hands-On';
      case ExplanationStyle.analogical:
        return 'Analogical';
    }
  }

  String get description {
    switch (this) {
      case ExplanationStyle.stepByStep:
        return 'Break down problems into clear steps';
      case ExplanationStyle.visual:
        return 'Use diagrams and visual representations';
      case ExplanationStyle.conceptual:
        return 'Focus on underlying concepts and principles';
      case ExplanationStyle.handson:
        return 'Interactive and manipulative approaches';
      case ExplanationStyle.analogical:
        return 'Use analogies and real-world connections';
    }
  }
}

extension EmotionalStateExtension on EmotionalState {
  String get displayName {
    switch (this) {
      case EmotionalState.frustrated:
        return 'Frustrated';
      case EmotionalState.confident:
        return 'Confident';
      case EmotionalState.neutral:
        return 'Neutral';
      case EmotionalState.excited:
        return 'Excited';
      case EmotionalState.confused:
        return 'Confused';
      case EmotionalState.disengaged:
        return 'Disengaged';
    }
  }

  String get recommendedAction {
    switch (this) {
      case EmotionalState.frustrated:
        return 'Provide extra support and encouragement';
      case EmotionalState.confident:
        return 'Offer more challenging problems';
      case EmotionalState.neutral:
        return 'Maintain current approach';
      case EmotionalState.excited:
        return 'Channel enthusiasm into learning';
      case EmotionalState.confused:
        return 'Clarify concepts with simpler explanations';
      case EmotionalState.disengaged:
        return 'Use engaging activities to re-capture attention';
    }
  }
}

extension InsightTypeExtension on InsightType {
  String get displayName {
    switch (this) {
      case InsightType.performance:
        return 'Performance Insight';
      case InsightType.engagement:
        return 'Engagement Insight';
      case InsightType.learningStyle:
        return 'Learning Style Insight';
      case InsightType.recommendation:
        return 'Recommendation';
      case InsightType.warning:
        return 'Warning';
    }
  }

  String get icon {
    switch (this) {
      case InsightType.performance:
        return '📊';
      case InsightType.engagement:
        return '🎯';
      case InsightType.learningStyle:
        return '🧠';
      case InsightType.recommendation:
        return '💡';
      case InsightType.warning:
        return '⚠️';
    }
  }
}
