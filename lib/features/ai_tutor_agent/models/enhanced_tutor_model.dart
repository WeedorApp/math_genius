// Enhanced tutor models - standalone implementation

/// Enhanced AI tutor models with advanced conversation and learning features

/// Learning styles for personalized tutoring
enum LearningStyle {
  visual,
  auditory,
  kinesthetic,
  readingWriting,
  multimodal,
}

/// Conversation context for maintaining dialogue state
enum ConversationContext {
  greeting,
  problemSolving,
  explanation,
  encouragement,
  assessment,
  review,
  challenge,
  farewell,
}

/// Tutoring strategies based on student needs
enum TutoringStrategy {
  scaffolding,
  socraticMethod,
  directInstruction,
  guidedDiscovery,
  collaborative,
  gamification,
  storytelling,
  realWorldApplication,
}

/// Enhanced tutor personality with emotional intelligence
class TutorPersonality {
  final String name;
  final String description;
  final Map<String, double> traits; // personality traits (0.0 to 1.0)
  final LearningStyle preferredStyle;
  final List<TutoringStrategy> strategies;
  final Map<String, String> responses; // context -> response templates

  const TutorPersonality({
    required this.name,
    required this.description,
    this.traits = const {},
    this.preferredStyle = LearningStyle.multimodal,
    this.strategies = const [],
    this.responses = const {},
  });

  double get enthusiasm => traits['enthusiasm'] ?? 0.7;
  double get patience => traits['patience'] ?? 0.8;
  double get friendliness => traits['friendliness'] ?? 0.9;
  double get formality => traits['formality'] ?? 0.3;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'traits': traits,
      'preferredStyle': preferredStyle.name,
      'strategies': strategies.map((s) => s.name).toList(),
      'responses': responses,
    };
  }

  factory TutorPersonality.fromJson(Map<String, dynamic> json) {
    return TutorPersonality(
      name: json['name'],
      description: json['description'],
      traits: Map<String, double>.from(json['traits'] ?? {}),
      preferredStyle: LearningStyle.values.byName(
        json['preferredStyle'] ?? 'multimodal',
      ),
      strategies: (json['strategies'] as List<dynamic>? ?? [])
          .map((s) => TutoringStrategy.values.byName(s))
          .toList(),
      responses: Map<String, String>.from(json['responses'] ?? {}),
    );
  }
}

/// Student learning profile for personalization
class StudentProfile {
  final String studentId;
  final String name;
  final int age;
  final int gradeLevel;
  final LearningStyle preferredLearningStyle;
  final Map<String, double> subjectProficiency; // subject -> proficiency (0.0 to 1.0)
  final List<String> learningGoals;
  final Map<String, dynamic> preferences;
  final DateTime lastActive;
  final int totalSessions;
  final double averageEngagement;
  final List<String> strugglingTopics;
  final List<String> masteredTopics;

  const StudentProfile({
    required this.studentId,
    required this.name,
    this.age = 10,
    this.gradeLevel = 5,
    this.preferredLearningStyle = LearningStyle.multimodal,
    this.subjectProficiency = const {},
    this.learningGoals = const [],
    this.preferences = const {},
    required this.lastActive,
    this.totalSessions = 0,
    this.averageEngagement = 0.0,
    this.strugglingTopics = const [],
    this.masteredTopics = const [],
  });

  double getMathProficiency() => subjectProficiency['math'] ?? 0.5;
  
  bool isStruggling(String topic) => strugglingTopics.contains(topic);
  bool hasMastered(String topic) => masteredTopics.contains(topic);

  StudentProfile copyWith({
    String? studentId,
    String? name,
    int? age,
    int? gradeLevel,
    LearningStyle? preferredLearningStyle,
    Map<String, double>? subjectProficiency,
    List<String>? learningGoals,
    Map<String, dynamic>? preferences,
    DateTime? lastActive,
    int? totalSessions,
    double? averageEngagement,
    List<String>? strugglingTopics,
    List<String>? masteredTopics,
  }) {
    return StudentProfile(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      age: age ?? this.age,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      preferredLearningStyle:
          preferredLearningStyle ?? this.preferredLearningStyle,
      subjectProficiency: subjectProficiency ?? this.subjectProficiency,
      learningGoals: learningGoals ?? this.learningGoals,
      preferences: preferences ?? this.preferences,
      lastActive: lastActive ?? this.lastActive,
      totalSessions: totalSessions ?? this.totalSessions,
      averageEngagement: averageEngagement ?? this.averageEngagement,
      strugglingTopics: strugglingTopics ?? this.strugglingTopics,
      masteredTopics: masteredTopics ?? this.masteredTopics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'age': age,
      'gradeLevel': gradeLevel,
      'preferredLearningStyle': preferredLearningStyle.name,
      'subjectProficiency': subjectProficiency,
      'learningGoals': learningGoals,
      'preferences': preferences,
      'lastActive': lastActive.toIso8601String(),
      'totalSessions': totalSessions,
      'averageEngagement': averageEngagement,
      'strugglingTopics': strugglingTopics,
      'masteredTopics': masteredTopics,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['studentId'],
      name: json['name'],
      age: json['age'] ?? 10,
      gradeLevel: json['gradeLevel'] ?? 5,
      preferredLearningStyle: LearningStyle.values.byName(
        json['preferredLearningStyle'] ?? 'multimodal',
      ),
      subjectProficiency: Map<String, double>.from(
        json['subjectProficiency'] ?? {},
      ),
      learningGoals: List<String>.from(json['learningGoals'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      lastActive: DateTime.parse(json['lastActive']),
      totalSessions: json['totalSessions'] ?? 0,
      averageEngagement: (json['averageEngagement'] ?? 0.0).toDouble(),
      strugglingTopics: List<String>.from(json['strugglingTopics'] ?? []),
      masteredTopics: List<String>.from(json['masteredTopics'] ?? []),
    );
  }
}

/// Enhanced conversation message with context and metadata
class ConversationMessage {
  final String id;
  final String content;
  final bool isFromTutor;
  final DateTime timestamp;
  final ConversationContext context;
  final Map<String, dynamic> metadata;
  final double confidence;
  final List<String> suggestedResponses;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic> analytics;

  const ConversationMessage({
    required this.id,
    required this.content,
    required this.isFromTutor,
    required this.timestamp,
    this.context = ConversationContext.problemSolving,
    this.metadata = const {},
    this.confidence = 1.0,
    this.suggestedResponses = const [],
    this.imageUrl,
    this.audioUrl,
    this.analytics = const {},
  });

  bool get hasMultimedia => imageUrl != null || audioUrl != null;
  bool get isHighConfidence => confidence >= 0.8;

  ConversationMessage copyWith({
    String? id,
    String? content,
    bool? isFromTutor,
    DateTime? timestamp,
    ConversationContext? context,
    Map<String, dynamic>? metadata,
    double? confidence,
    List<String>? suggestedResponses,
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? analytics,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromTutor: isFromTutor ?? this.isFromTutor,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
      confidence: confidence ?? this.confidence,
      suggestedResponses: suggestedResponses ?? this.suggestedResponses,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      analytics: analytics ?? this.analytics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isFromTutor': isFromTutor,
      'timestamp': timestamp.toIso8601String(),
      'context': context.name,
      'metadata': metadata,
      'confidence': confidence,
      'suggestedResponses': suggestedResponses,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'analytics': analytics,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'],
      content: json['content'],
      isFromTutor: json['isFromTutor'],
      timestamp: DateTime.parse(json['timestamp']),
      context: ConversationContext.values.byName(
        json['context'] ?? 'problemSolving',
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      suggestedResponses: List<String>.from(json['suggestedResponses'] ?? []),
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      analytics: Map<String, dynamic>.from(json['analytics'] ?? {}),
    );
  }
}

/// Session status for enhanced tutor sessions
enum EnhancedSessionStatus { 
  waiting, 
  active, 
  paused, 
  completed, 
  cancelled 
}

/// Enhanced tutor session with learning analytics
class EnhancedTutorSession {
  final String id;
  final String studentId;
  final String tutorId;
  final DateTime startTime;
  final DateTime? endTime;
  final EnhancedSessionStatus status;
  final String subject;
  final String notes;
  final StudentProfile studentProfile;
  final TutorPersonality tutorPersonality;
  final List<ConversationMessage> messages;
  final ConversationContext currentContext;
  final Map<String, dynamic> sessionAnalytics;
  final List<String> topicsDiscussed;
  final double studentEngagement;
  final int questionsAsked;
  final int questionsAnswered;
  final Map<String, int> emotionalStates; // emotion -> count
  final List<String> learningObjectives;
  final Map<String, double> conceptUnderstanding; // concept -> understanding level

  const EnhancedTutorSession({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.startTime,
    this.endTime,
    this.status = EnhancedSessionStatus.active,
    this.subject = 'Math',
    this.notes = '',
    required this.studentProfile,
    required this.tutorPersonality,
    this.messages = const [],
    this.currentContext = ConversationContext.greeting,
    this.sessionAnalytics = const {},
    this.topicsDiscussed = const [],
    this.studentEngagement = 0.0,
    this.questionsAsked = 0,
    this.questionsAnswered = 0,
    this.emotionalStates = const {},
    this.learningObjectives = const [],
    this.conceptUnderstanding = const {},
  });

  Duration get sessionDuration => endTime != null
      ? endTime!.difference(startTime)
      : DateTime.now().difference(startTime);

  double get responseRate => questionsAsked > 0
      ? questionsAnswered / questionsAsked
      : 0.0;

  String get dominantEmotion {
    if (emotionalStates.isEmpty) return 'neutral';
    return emotionalStates.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  EnhancedTutorSession copyWith({
    String? id,
    String? studentId,
    String? tutorId,
    DateTime? startTime,
    DateTime? endTime,
    EnhancedSessionStatus? status,
    String? subject,
    String? notes,
    StudentProfile? studentProfile,
    TutorPersonality? tutorPersonality,
    List<ConversationMessage>? messages,
    ConversationContext? currentContext,
    Map<String, dynamic>? sessionAnalytics,
    List<String>? topicsDiscussed,
    double? studentEngagement,
    int? questionsAsked,
    int? questionsAnswered,
    Map<String, int>? emotionalStates,
    List<String>? learningObjectives,
    Map<String, double>? conceptUnderstanding,
  }) {
    return EnhancedTutorSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      notes: notes ?? this.notes,
      studentProfile: studentProfile ?? this.studentProfile,
      tutorPersonality: tutorPersonality ?? this.tutorPersonality,
      messages: messages ?? this.messages,
      currentContext: currentContext ?? this.currentContext,
      sessionAnalytics: sessionAnalytics ?? this.sessionAnalytics,
      topicsDiscussed: topicsDiscussed ?? this.topicsDiscussed,
      studentEngagement: studentEngagement ?? this.studentEngagement,
      questionsAsked: questionsAsked ?? this.questionsAsked,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      emotionalStates: emotionalStates ?? this.emotionalStates,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      conceptUnderstanding: conceptUnderstanding ?? this.conceptUnderstanding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'tutorId': tutorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'subject': subject,
      'notes': notes,
      'studentProfile': studentProfile.toJson(),
      'tutorPersonality': tutorPersonality.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'currentContext': currentContext.name,
      'sessionAnalytics': sessionAnalytics,
      'topicsDiscussed': topicsDiscussed,
      'studentEngagement': studentEngagement,
      'questionsAsked': questionsAsked,
      'questionsAnswered': questionsAnswered,
      'emotionalStates': emotionalStates,
      'learningObjectives': learningObjectives,
      'conceptUnderstanding': conceptUnderstanding,
    };
  }

  factory EnhancedTutorSession.fromJson(Map<String, dynamic> json) {
    return EnhancedTutorSession(
      id: json['id'],
      studentId: json['studentId'],
      tutorId: json['tutorId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: EnhancedSessionStatus.values.byName(json['status'] ?? 'active'),
      subject: json['subject'] ?? 'Math',
      notes: json['notes'] ?? '',
      studentProfile: StudentProfile.fromJson(json['studentProfile']),
      tutorPersonality: TutorPersonality.fromJson(json['tutorPersonality']),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      currentContext: ConversationContext.values.byName(
        json['currentContext'] ?? 'greeting',
      ),
      sessionAnalytics: Map<String, dynamic>.from(
        json['sessionAnalytics'] ?? {},
      ),
      topicsDiscussed: List<String>.from(json['topicsDiscussed'] ?? []),
      studentEngagement: (json['studentEngagement'] ?? 0.0).toDouble(),
      questionsAsked: json['questionsAsked'] ?? 0,
      questionsAnswered: json['questionsAnswered'] ?? 0,
      emotionalStates: Map<String, int>.from(json['emotionalStates'] ?? {}),
      learningObjectives: List<String>.from(json['learningObjectives'] ?? []),
      conceptUnderstanding: Map<String, double>.from(
        json['conceptUnderstanding'] ?? {},
      ),
    );
  }
}

/// Adaptive response suggestion system
class ResponseSuggestion {
  final String id;
  final String content;
  final ConversationContext context;
  final TutoringStrategy strategy;
  final double relevanceScore;
  final Map<String, dynamic> parameters;
  final List<String> followUpQuestions;

  const ResponseSuggestion({
    required this.id,
    required this.content,
    required this.context,
    required this.strategy,
    this.relevanceScore = 1.0,
    this.parameters = const {},
    this.followUpQuestions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'context': context.name,
      'strategy': strategy.name,
      'relevanceScore': relevanceScore,
      'parameters': parameters,
      'followUpQuestions': followUpQuestions,
    };
  }

  factory ResponseSuggestion.fromJson(Map<String, dynamic> json) {
    return ResponseSuggestion(
      id: json['id'],
      content: json['content'],
      context: ConversationContext.values.byName(json['context']),
      strategy: TutoringStrategy.values.byName(json['strategy']),
      relevanceScore: (json['relevanceScore'] ?? 1.0).toDouble(),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      followUpQuestions: List<String>.from(json['followUpQuestions'] ?? []),
    );
  }
}

/// Learning progress tracking
class LearningProgress {
  final String studentId;
  final String topic;
  final double initialProficiency;
  final double currentProficiency;
  final List<DateTime> practiceTimestamps;
  final Map<String, double> skillBreakdown;
  final double masteryThreshold;
  final bool isMastered;
  final DateTime lastUpdated;

  const LearningProgress({
    required this.studentId,
    required this.topic,
    this.initialProficiency = 0.0,
    required this.currentProficiency,
    this.practiceTimestamps = const [],
    this.skillBreakdown = const {},
    this.masteryThreshold = 0.8,
    required this.lastUpdated,
  }) : isMastered = currentProficiency >= masteryThreshold;

  double get improvementRate => currentProficiency - initialProficiency;
  
  int get practiceCount => practiceTimestamps.length;

  bool get needsMorePractice => currentProficiency < masteryThreshold;

  LearningProgress copyWith({
    String? studentId,
    String? topic,
    double? initialProficiency,
    double? currentProficiency,
    List<DateTime>? practiceTimestamps,
    Map<String, double>? skillBreakdown,
    double? masteryThreshold,
    DateTime? lastUpdated,
  }) {
    return LearningProgress(
      studentId: studentId ?? this.studentId,
      topic: topic ?? this.topic,
      initialProficiency: initialProficiency ?? this.initialProficiency,
      currentProficiency: currentProficiency ?? this.currentProficiency,
      practiceTimestamps: practiceTimestamps ?? this.practiceTimestamps,
      skillBreakdown: skillBreakdown ?? this.skillBreakdown,
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'topic': topic,
      'initialProficiency': initialProficiency,
      'currentProficiency': currentProficiency,
      'practiceTimestamps': practiceTimestamps
          .map((t) => t.toIso8601String())
          .toList(),
      'skillBreakdown': skillBreakdown,
      'masteryThreshold': masteryThreshold,
      'isMastered': isMastered,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      studentId: json['studentId'],
      topic: json['topic'],
      initialProficiency: (json['initialProficiency'] ?? 0.0).toDouble(),
      currentProficiency: (json['currentProficiency']).toDouble(),
      practiceTimestamps: (json['practiceTimestamps'] as List<dynamic>? ?? [])
          .map((t) => DateTime.parse(t))
          .toList(),
      skillBreakdown: Map<String, double>.from(json['skillBreakdown'] ?? {}),
      masteryThreshold: (json['masteryThreshold'] ?? 0.8).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
