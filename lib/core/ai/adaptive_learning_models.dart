// Core imports
import '../../features/game/models/game_model.dart';

/// Learning profile for personalized education
class LearningProfile {
  final String studentId;
  final LearningStyle learningStyle;
  final List<GameCategory> strengths;
  final List<GameCategory> weaknesses;
  final GameDifficulty optimalDifficulty;
  final Duration preferredSessionLength;
  final List<MotivationFactor> motivationFactors;
  final CognitiveLoad cognitiveLoad;
  final DateTime lastUpdated;
  final double confidenceScore;
  final List<AdaptationRecord> adaptationHistory;

  const LearningProfile({
    required this.studentId,
    required this.learningStyle,
    required this.strengths,
    required this.weaknesses,
    required this.optimalDifficulty,
    required this.preferredSessionLength,
    required this.motivationFactors,
    required this.cognitiveLoad,
    required this.lastUpdated,
    required this.confidenceScore,
    required this.adaptationHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'learningStyle': learningStyle.toString(),
      'strengths': strengths.map((s) => s.toString()).toList(),
      'weaknesses': weaknesses.map((w) => w.toString()).toList(),
      'optimalDifficulty': optimalDifficulty.toString(),
      'preferredSessionLength': preferredSessionLength.inMinutes,
      'motivationFactors': motivationFactors.map((m) => m.toString()).toList(),
      'cognitiveLoad': cognitiveLoad.toString(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'confidenceScore': confidenceScore,
      'adaptationHistory': adaptationHistory.map((a) => a.toJson()).toList(),
    };
  }

  factory LearningProfile.fromJson(Map<String, dynamic> json) {
    return LearningProfile(
      studentId: json['studentId'] as String,
      learningStyle: LearningStyle.values.firstWhere(
        (e) => e.toString() == json['learningStyle'],
        orElse: () => LearningStyle.visual,
      ),
      strengths: (json['strengths'] as List)
          .map(
            (s) => GameCategory.values.firstWhere(
              (e) => e.toString() == s,
              orElse: () => GameCategory.addition,
            ),
          )
          .toList(),
      weaknesses: (json['weaknesses'] as List)
          .map(
            (w) => GameCategory.values.firstWhere(
              (e) => e.toString() == w,
              orElse: () => GameCategory.addition,
            ),
          )
          .toList(),
      optimalDifficulty: GameDifficulty.values.firstWhere(
        (e) => e.toString() == json['optimalDifficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      preferredSessionLength: Duration(
        minutes: json['preferredSessionLength'] as int,
      ),
      motivationFactors: (json['motivationFactors'] as List)
          .map(
            (m) => MotivationFactor.values.firstWhere(
              (e) => e.toString() == m,
              orElse: () => MotivationFactor.progress,
            ),
          )
          .toList(),
      cognitiveLoad: CognitiveLoad.values.firstWhere(
        (e) => e.toString() == json['cognitiveLoad'],
        orElse: () => CognitiveLoad.medium,
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      adaptationHistory: (json['adaptationHistory'] as List)
          .map((a) => AdaptationRecord.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  LearningProfile copyWith({
    String? studentId,
    LearningStyle? learningStyle,
    List<GameCategory>? strengths,
    List<GameCategory>? weaknesses,
    GameDifficulty? optimalDifficulty,
    Duration? preferredSessionLength,
    List<MotivationFactor>? motivationFactors,
    CognitiveLoad? cognitiveLoad,
    DateTime? lastUpdated,
    double? confidenceScore,
    List<AdaptationRecord>? adaptationHistory,
  }) {
    return LearningProfile(
      studentId: studentId ?? this.studentId,
      learningStyle: learningStyle ?? this.learningStyle,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      optimalDifficulty: optimalDifficulty ?? this.optimalDifficulty,
      preferredSessionLength:
          preferredSessionLength ?? this.preferredSessionLength,
      motivationFactors: motivationFactors ?? this.motivationFactors,
      cognitiveLoad: cognitiveLoad ?? this.cognitiveLoad,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      adaptationHistory: adaptationHistory ?? this.adaptationHistory,
    );
  }
}

/// Learning path with personalized objectives
class LearningPath {
  final String id;
  final String studentId;
  final GradeLevel gradeLevel;
  final List<LearningObjective> objectives;
  final Duration estimatedDuration;
  final GameDifficulty difficulty;
  final DateTime createdAt;
  final List<PathAdjustment> adaptiveAdjustments;
  final double completionPrediction;

  const LearningPath({
    required this.id,
    required this.studentId,
    required this.gradeLevel,
    required this.objectives,
    required this.estimatedDuration,
    required this.difficulty,
    required this.createdAt,
    required this.adaptiveAdjustments,
    required this.completionPrediction,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'gradeLevel': gradeLevel.toString(),
      'objectives': objectives.map((o) => o.toJson()).toList(),
      'estimatedDuration': estimatedDuration.inMinutes,
      'difficulty': difficulty.toString(),
      'createdAt': createdAt.toIso8601String(),
      'adaptiveAdjustments': adaptiveAdjustments
          .map((a) => a.toJson())
          .toList(),
      'completionPrediction': completionPrediction,
    };
  }

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.toString() == json['gradeLevel'],
        orElse: () => GradeLevel.grade1,
      ),
      objectives: (json['objectives'] as List)
          .map((o) => LearningObjective.fromJson(o as Map<String, dynamic>))
          .toList(),
      estimatedDuration: Duration(minutes: json['estimatedDuration'] as int),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      adaptiveAdjustments: (json['adaptiveAdjustments'] as List)
          .map((a) => PathAdjustment.fromJson(a as Map<String, dynamic>))
          .toList(),
      completionPrediction: (json['completionPrediction'] as num).toDouble(),
    );
  }
}

/// Learning objective with prerequisites and metadata
class LearningObjective {
  final String id;
  final String title;
  final String description;
  final GradeLevel gradeLevel;
  final GameCategory category;
  final List<String> prerequisites;
  final Duration estimatedDuration;

  const LearningObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.gradeLevel,
    required this.category,
    required this.prerequisites,
    required this.estimatedDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'gradeLevel': gradeLevel.toString(),
      'category': category.toString(),
      'prerequisites': prerequisites,
      'estimatedDuration': estimatedDuration.inMinutes,
    };
  }

  factory LearningObjective.fromJson(Map<String, dynamic> json) {
    return LearningObjective(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.toString() == json['gradeLevel'],
        orElse: () => GradeLevel.grade1,
      ),
      category: GameCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GameCategory.addition,
      ),
      prerequisites: List<String>.from(json['prerequisites'] as List),
      estimatedDuration: Duration(minutes: json['estimatedDuration'] as int),
    );
  }
}

/// Engagement optimization strategy
class EngagementStrategy {
  final String studentId;
  final Duration recommendedBreakInterval;
  final List<String> motivationalMessages;
  final List<GamificationElement> gamificationElements;
  final DifficultyAdjustment difficultyAdjustment;
  final List<InterventionTrigger> interventionTriggers;
  final DateTime createdAt;

  const EngagementStrategy({
    required this.studentId,
    required this.recommendedBreakInterval,
    required this.motivationalMessages,
    required this.gamificationElements,
    required this.difficultyAdjustment,
    required this.interventionTriggers,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'recommendedBreakInterval': recommendedBreakInterval.inMinutes,
      'motivationalMessages': motivationalMessages,
      'gamificationElements': gamificationElements
          .map((g) => g.toString())
          .toList(),
      'difficultyAdjustment': difficultyAdjustment.toString(),
      'interventionTriggers': interventionTriggers
          .map((i) => i.toString())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EngagementStrategy.fromJson(Map<String, dynamic> json) {
    return EngagementStrategy(
      studentId: json['studentId'] as String,
      recommendedBreakInterval: Duration(
        minutes: json['recommendedBreakInterval'] as int,
      ),
      motivationalMessages: List<String>.from(
        json['motivationalMessages'] as List,
      ),
      gamificationElements: (json['gamificationElements'] as List)
          .map(
            (g) => GamificationElement.values.firstWhere(
              (e) => e.toString() == g,
              orElse: () => GamificationElement.pointsBoost,
            ),
          )
          .toList(),
      difficultyAdjustment: DifficultyAdjustment.values.firstWhere(
        (e) => e.toString() == json['difficultyAdjustment'],
        orElse: () => DifficultyAdjustment.maintain,
      ),
      interventionTriggers: (json['interventionTriggers'] as List)
          .map(
            (i) => InterventionTrigger.values.firstWhere(
              (e) => e.toString() == i,
              orElse: () => InterventionTrigger.lowAttention,
            ),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Advanced adaptive hint with multi-modal support
class AdaptiveHint {
  final String id;
  final String questionId;
  final String studentId;
  final HintLevel hintLevel;
  final String content;
  final List<VisualAid> visualAids;
  final AudioSupport audioSupport;
  final List<InteractiveElement> interactiveElements;
  final LearningStyle learningStyle;
  final double estimatedHelpfulness;
  final DateTime createdAt;

  const AdaptiveHint({
    required this.id,
    required this.questionId,
    required this.studentId,
    required this.hintLevel,
    required this.content,
    required this.visualAids,
    required this.audioSupport,
    required this.interactiveElements,
    required this.learningStyle,
    required this.estimatedHelpfulness,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'studentId': studentId,
      'hintLevel': hintLevel.toString(),
      'content': content,
      'visualAids': visualAids.map((v) => v.toString()).toList(),
      'audioSupport': audioSupport.toJson(),
      'interactiveElements': interactiveElements
          .map((i) => i.toString())
          .toList(),
      'learningStyle': learningStyle.toString(),
      'estimatedHelpfulness': estimatedHelpfulness,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdaptiveHint.fromJson(Map<String, dynamic> json) {
    return AdaptiveHint(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      studentId: json['studentId'] as String,
      hintLevel: HintLevel.values.firstWhere(
        (e) => e.toString() == json['hintLevel'],
        orElse: () => HintLevel.gentle,
      ),
      content: json['content'] as String,
      visualAids: (json['visualAids'] as List)
          .map(
            (v) => VisualAid.values.firstWhere(
              (e) => e.toString() == v,
              orElse: () => VisualAid.diagram,
            ),
          )
          .toList(),
      audioSupport: AudioSupport.fromJson(
        json['audioSupport'] as Map<String, dynamic>,
      ),
      interactiveElements: (json['interactiveElements'] as List)
          .map(
            (i) => InteractiveElement.values.firstWhere(
              (e) => e.toString() == i,
              orElse: () => InteractiveElement.dragDrop,
            ),
          )
          .toList(),
      learningStyle: LearningStyle.values.firstWhere(
        (e) => e.toString() == json['learningStyle'],
        orElse: () => LearningStyle.visual,
      ),
      estimatedHelpfulness: (json['estimatedHelpfulness'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Learning outcome prediction with confidence intervals
class LearningOutcomePrediction {
  final String studentId;
  final Duration timeHorizon;
  final Map<String, double> predictedMastery;
  final List<RiskFactor> riskFactors;
  final List<InterventionRecommendation> interventionRecommendations;
  final double confidenceInterval;
  final List<LearningMilestone> expectedMilestones;
  final DateTime createdAt;

  const LearningOutcomePrediction({
    required this.studentId,
    required this.timeHorizon,
    required this.predictedMastery,
    required this.riskFactors,
    required this.interventionRecommendations,
    required this.confidenceInterval,
    required this.expectedMilestones,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'timeHorizon': timeHorizon.inDays,
      'predictedMastery': predictedMastery,
      'riskFactors': riskFactors.map((r) => r.toString()).toList(),
      'interventionRecommendations': interventionRecommendations
          .map((i) => i.toJson())
          .toList(),
      'confidenceInterval': confidenceInterval,
      'expectedMilestones': expectedMilestones.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LearningOutcomePrediction.fromJson(Map<String, dynamic> json) {
    return LearningOutcomePrediction(
      studentId: json['studentId'] as String,
      timeHorizon: Duration(days: json['timeHorizon'] as int),
      predictedMastery: Map<String, double>.from(
        json['predictedMastery'] as Map,
      ),
      riskFactors: (json['riskFactors'] as List)
          .map(
            (r) => RiskFactor.values.firstWhere(
              (e) => e.toString() == r,
              orElse: () => RiskFactor.lowPerformance,
            ),
          )
          .toList(),
      interventionRecommendations: (json['interventionRecommendations'] as List)
          .map(
            (i) =>
                InterventionRecommendation.fromJson(i as Map<String, dynamic>),
          )
          .toList(),
      confidenceInterval: (json['confidenceInterval'] as num).toDouble(),
      expectedMilestones: (json['expectedMilestones'] as List)
          .map((m) => LearningMilestone.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Student behavior tracking for real-time adaptation
class StudentBehavior {
  final double attentionLevel; // 0.0 - 1.0
  final double engagementLevel; // 0.0 - 1.0
  final double frustrationLevel; // 0.0 - 1.0
  final double boredomLevel; // 0.0 - 1.0
  final int consecutiveErrors;
  final Duration sessionDuration;
  final int hintsRequested;
  final double responseTimeVariation;

  const StudentBehavior({
    required this.attentionLevel,
    required this.engagementLevel,
    required this.frustrationLevel,
    required this.boredomLevel,
    required this.consecutiveErrors,
    required this.sessionDuration,
    required this.hintsRequested,
    required this.responseTimeVariation,
  });

  Map<String, dynamic> toJson() {
    return {
      'attentionLevel': attentionLevel,
      'engagementLevel': engagementLevel,
      'frustrationLevel': frustrationLevel,
      'boredomLevel': boredomLevel,
      'consecutiveErrors': consecutiveErrors,
      'sessionDuration': sessionDuration.inSeconds,
      'hintsRequested': hintsRequested,
      'responseTimeVariation': responseTimeVariation,
    };
  }

  factory StudentBehavior.fromJson(Map<String, dynamic> json) {
    return StudentBehavior(
      attentionLevel: (json['attentionLevel'] as num).toDouble(),
      engagementLevel: (json['engagementLevel'] as num).toDouble(),
      frustrationLevel: (json['frustrationLevel'] as num).toDouble(),
      boredomLevel: (json['boredomLevel'] as num).toDouble(),
      consecutiveErrors: json['consecutiveErrors'] as int,
      sessionDuration: Duration(seconds: json['sessionDuration'] as int),
      hintsRequested: json['hintsRequested'] as int,
      responseTimeVariation: (json['responseTimeVariation'] as num).toDouble(),
    );
  }
}

// Supporting data classes

class PerformanceData {
  final double overallAccuracy;
  final double averageResponseTime;
  final double consistencyScore;
  final double improvementRate;
  final double overallConfidence;
  final Map<GameCategory, double> categoryBreakdown;

  const PerformanceData({
    required this.overallAccuracy,
    required this.averageResponseTime,
    required this.consistencyScore,
    required this.improvementRate,
    required this.overallConfidence,
    required this.categoryBreakdown,
  });
}

class StrengthsWeaknesses {
  final List<GameCategory> strengths;
  final List<GameCategory> weaknesses;

  const StrengthsWeaknesses({
    required this.strengths,
    required this.weaknesses,
  });
}

class CategoryPerformance {
  final double accuracy;
  final Duration averageSpeed;
  final double consistency;

  const CategoryPerformance({
    required this.accuracy,
    required this.averageSpeed,
    required this.consistency,
  });
}

class Trend {
  final double current;
  final double slope;

  const Trend({required this.current, required this.slope});
}

class AdaptationRecord {
  final DateTime timestamp;
  final String adaptationType;
  final String reason;
  final Map<String, dynamic> parameters;

  const AdaptationRecord({
    required this.timestamp,
    required this.adaptationType,
    required this.reason,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'adaptationType': adaptationType,
      'reason': reason,
      'parameters': parameters,
    };
  }

  factory AdaptationRecord.fromJson(Map<String, dynamic> json) {
    return AdaptationRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      adaptationType: json['adaptationType'] as String,
      reason: json['reason'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    );
  }
}

class PathAdjustment {
  final DateTime timestamp;
  final String adjustmentType;
  final String reason;
  final Map<String, dynamic> changes;

  const PathAdjustment({
    required this.timestamp,
    required this.adjustmentType,
    required this.reason,
    required this.changes,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'adjustmentType': adjustmentType,
      'reason': reason,
      'changes': changes,
    };
  }

  factory PathAdjustment.fromJson(Map<String, dynamic> json) {
    return PathAdjustment(
      timestamp: DateTime.parse(json['timestamp'] as String),
      adjustmentType: json['adjustmentType'] as String,
      reason: json['reason'] as String,
      changes: Map<String, dynamic>.from(json['changes'] as Map),
    );
  }
}

class AudioSupport {
  final bool questionReading;
  final bool hintReading;
  final bool encouragement;

  const AudioSupport({
    required this.questionReading,
    required this.hintReading,
    required this.encouragement,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionReading': questionReading,
      'hintReading': hintReading,
      'encouragement': encouragement,
    };
  }

  factory AudioSupport.fromJson(Map<String, dynamic> json) {
    return AudioSupport(
      questionReading: json['questionReading'] as bool,
      hintReading: json['hintReading'] as bool,
      encouragement: json['encouragement'] as bool,
    );
  }
}

class InterventionRecommendation {
  final InterventionType type;
  final String description;
  final Priority priority;

  const InterventionRecommendation({
    required this.type,
    required this.description,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'description': description,
      'priority': priority.toString(),
    };
  }

  factory InterventionRecommendation.fromJson(Map<String, dynamic> json) {
    return InterventionRecommendation(
      type: InterventionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => InterventionType.difficultyReduction,
      ),
      description: json['description'] as String,
      priority: Priority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => Priority.medium,
      ),
    );
  }
}

class LearningMilestone {
  final String objectiveId;
  final String title;
  final DateTime estimatedCompletionDate;
  final double confidenceLevel;

  const LearningMilestone({
    required this.objectiveId,
    required this.title,
    required this.estimatedCompletionDate,
    required this.confidenceLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'objectiveId': objectiveId,
      'title': title,
      'estimatedCompletionDate': estimatedCompletionDate.toIso8601String(),
      'confidenceLevel': confidenceLevel,
    };
  }

  factory LearningMilestone.fromJson(Map<String, dynamic> json) {
    return LearningMilestone(
      objectiveId: json['objectiveId'] as String,
      title: json['title'] as String,
      estimatedCompletionDate: DateTime.parse(
        json['estimatedCompletionDate'] as String,
      ),
      confidenceLevel: (json['confidenceLevel'] as num).toDouble(),
    );
  }
}

class EngagementData {
  final DateTime timestamp;
  final double engagementLevel;
  final double attentionLevel;
  final Duration sessionLength;

  const EngagementData({
    required this.timestamp,
    required this.engagementLevel,
    required this.attentionLevel,
    required this.sessionLength,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'engagementLevel': engagementLevel,
      'attentionLevel': attentionLevel,
      'sessionLength': sessionLength.inSeconds,
    };
  }

  factory EngagementData.fromJson(Map<String, dynamic> json) {
    return EngagementData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      engagementLevel: (json['engagementLevel'] as num).toDouble(),
      attentionLevel: (json['attentionLevel'] as num).toDouble(),
      sessionLength: Duration(seconds: json['sessionLength'] as int),
    );
  }
}

class PerformanceDataPoint {
  final DateTime timestamp;
  final GameCategory category;
  final double accuracy;
  final Duration responseTime;
  final double engagementLevel;

  const PerformanceDataPoint({
    required this.timestamp,
    required this.category,
    required this.accuracy,
    required this.responseTime,
    required this.engagementLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'category': category.toString(),
      'accuracy': accuracy,
      'responseTime': responseTime.inSeconds,
      'engagementLevel': engagementLevel,
    };
  }

  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: GameCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GameCategory.addition,
      ),
      accuracy: (json['accuracy'] as num).toDouble(),
      responseTime: Duration(seconds: json['responseTime'] as int),
      engagementLevel: (json['engagementLevel'] as num).toDouble(),
    );
  }
}

// GameResult is defined in game_model.dart

// Enums for adaptive learning system

enum LearningStyle { visual, auditory, kinesthetic, readingWriting }

enum MotivationFactor {
  rewards,
  social,
  progress,
  achievement,
  competition,
  exploration,
}

enum CognitiveLoad { low, medium, high }

enum HintLevel { none, gentle, moderate, detailed }

enum VisualAid { diagram, colorCoding, shapes, measurement, graph, animation }

enum InteractiveElement {
  dragDrop,
  manipulation,
  counter,
  slider,
  drawing,
  gesture,
}

enum GamificationElement {
  pointsBoost,
  badgeUnlock,
  leaderboard,
  collaboration,
  miniGame,
  animation,
  soundEffect,
}

enum DifficultyAdjustment { increase, decrease, maintain }

enum InterventionTrigger {
  highFrustration,
  lowAttention,
  repeatedErrors,
  decliningPerformance,
  timeoutPattern,
}

enum RiskFactor {
  lowPerformance,
  decliningEngagement,
  cognitiveOverload,
  inconsistentAttendance,
  socialIsolation,
}

enum InterventionType {
  difficultyReduction,
  breakReminder,
  motivationalBoost,
  tutorAssistance,
  peerSupport,
}

enum Priority { low, medium, high, critical }

/// Extension methods for better usability
extension LearningStyleExtension on LearningStyle {
  String get displayName {
    switch (this) {
      case LearningStyle.visual:
        return 'Visual Learner';
      case LearningStyle.auditory:
        return 'Auditory Learner';
      case LearningStyle.kinesthetic:
        return 'Kinesthetic Learner';
      case LearningStyle.readingWriting:
        return 'Reading/Writing Learner';
    }
  }

  String get description {
    switch (this) {
      case LearningStyle.visual:
        return 'Learns best through visual aids, diagrams, and colors';
      case LearningStyle.auditory:
        return 'Learns best through listening and verbal instruction';
      case LearningStyle.kinesthetic:
        return 'Learns best through hands-on activities and movement';
      case LearningStyle.readingWriting:
        return 'Learns best through reading and writing activities';
    }
  }
}

extension CognitiveLoadExtension on CognitiveLoad {
  String get displayName {
    switch (this) {
      case CognitiveLoad.low:
        return 'Low Cognitive Load';
      case CognitiveLoad.medium:
        return 'Medium Cognitive Load';
      case CognitiveLoad.high:
        return 'High Cognitive Load';
    }
  }

  String get recommendation {
    switch (this) {
      case CognitiveLoad.low:
        return 'Can handle more challenging content';
      case CognitiveLoad.medium:
        return 'Optimal learning conditions';
      case CognitiveLoad.high:
        return 'Needs simplified content and more support';
    }
  }
}
