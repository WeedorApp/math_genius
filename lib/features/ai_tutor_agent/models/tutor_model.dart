/// AI Tutor context and state management
enum TutorMood { encouraging, neutral, challenging, celebratory }

enum TutorMode { hint, explanation, stepByStep, practice }

enum VoiceState { listening, processing, speaking, idle }

/// Tutor context model for personalized tutoring
class TutorContext {
  final String studentId;
  final int grade;
  final TutorMood mood;
  final List<String> recentTopics;
  final Map<String, int> topicProgress; // topic -> mastery level (0-100)
  final List<String> learningGoals;
  final DateTime lastSession;
  final int totalSessions;
  final double averageScore;

  const TutorContext({
    required this.studentId,
    required this.grade,
    this.mood = TutorMood.encouraging,
    this.recentTopics = const [],
    this.topicProgress = const {},
    this.learningGoals = const [],
    required this.lastSession,
    this.totalSessions = 0,
    this.averageScore = 0.0,
  });

  TutorContext copyWith({
    String? studentId,
    int? grade,
    TutorMood? mood,
    List<String>? recentTopics,
    Map<String, int>? topicProgress,
    List<String>? learningGoals,
    DateTime? lastSession,
    int? totalSessions,
    double? averageScore,
  }) {
    return TutorContext(
      studentId: studentId ?? this.studentId,
      grade: grade ?? this.grade,
      mood: mood ?? this.mood,
      recentTopics: recentTopics ?? this.recentTopics,
      topicProgress: topicProgress ?? this.topicProgress,
      learningGoals: learningGoals ?? this.learningGoals,
      lastSession: lastSession ?? this.lastSession,
      totalSessions: totalSessions ?? this.totalSessions,
      averageScore: averageScore ?? this.averageScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'grade': grade,
      'mood': mood.name,
      'recentTopics': recentTopics,
      'topicProgress': topicProgress,
      'learningGoals': learningGoals,
      'lastSession': lastSession.toIso8601String(),
      'totalSessions': totalSessions,
      'averageScore': averageScore,
    };
  }

  factory TutorContext.fromJson(Map<String, dynamic> json) {
    return TutorContext(
      studentId: json['studentId'] as String,
      grade: json['grade'] as int,
      mood: TutorMood.values.firstWhere((e) => e.name == json['mood']),
      recentTopics: List<String>.from(json['recentTopics'] as List),
      topicProgress: Map<String, int>.from(json['topicProgress'] as Map),
      learningGoals: List<String>.from(json['learningGoals'] as List),
      lastSession: DateTime.parse(json['lastSession'] as String),
      totalSessions: json['totalSessions'] as int? ?? 0,
      averageScore: json['averageScore'] as double? ?? 0.0,
    );
  }
}

/// Tutor message model for chat interface
class TutorMessage {
  final String id;
  final String content;
  final bool isFromTutor;
  final DateTime timestamp;
  final TutorMode? mode;
  final String? topic;
  final Map<String, dynamic>? metadata;

  const TutorMessage({
    required this.id,
    required this.content,
    required this.isFromTutor,
    required this.timestamp,
    this.mode,
    this.topic,
    this.metadata,
  });

  TutorMessage copyWith({
    String? id,
    String? content,
    bool? isFromTutor,
    DateTime? timestamp,
    TutorMode? mode,
    String? topic,
    Map<String, dynamic>? metadata,
  }) {
    return TutorMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromTutor: isFromTutor ?? this.isFromTutor,
      timestamp: timestamp ?? this.timestamp,
      mode: mode ?? this.mode,
      topic: topic ?? this.topic,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isFromTutor': isFromTutor,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode?.name,
      'topic': topic,
      'metadata': metadata,
    };
  }

  factory TutorMessage.fromJson(Map<String, dynamic> json) {
    return TutorMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isFromTutor: json['isFromTutor'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mode: json['mode'] != null
          ? TutorMode.values.firstWhere((e) => e.name == json['mode'])
          : null,
      topic: json['topic'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}

/// Tutor session model
class TutorSession {
  final String id;
  final String studentId;
  final TutorContext context;
  final List<TutorMessage> messages;
  final DateTime startTime;
  final DateTime? endTime;
  final String? currentTopic;
  final TutorMode currentMode;
  final VoiceState voiceState;
  final bool isActive;

  const TutorSession({
    required this.id,
    required this.studentId,
    required this.context,
    this.messages = const [],
    required this.startTime,
    this.endTime,
    this.currentTopic,
    this.currentMode = TutorMode.hint,
    this.voiceState = VoiceState.idle,
    this.isActive = true,
  });

  TutorSession copyWith({
    String? id,
    String? studentId,
    TutorContext? context,
    List<TutorMessage>? messages,
    DateTime? startTime,
    DateTime? endTime,
    String? currentTopic,
    TutorMode? currentMode,
    VoiceState? voiceState,
    bool? isActive,
  }) {
    return TutorSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      context: context ?? this.context,
      messages: messages ?? this.messages,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentTopic: currentTopic ?? this.currentTopic,
      currentMode: currentMode ?? this.currentMode,
      voiceState: voiceState ?? this.voiceState,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'context': context.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'currentTopic': currentTopic,
      'currentMode': currentMode.name,
      'voiceState': voiceState.name,
      'isActive': isActive,
    };
  }

  factory TutorSession.fromJson(Map<String, dynamic> json) {
    return TutorSession(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      context: TutorContext.fromJson(json['context'] as Map<String, dynamic>),
      messages: (json['messages'] as List)
          .map((m) => TutorMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      currentTopic: json['currentTopic'] as String?,
      currentMode: TutorMode.values.firstWhere(
        (e) => e.name == json['currentMode'],
      ),
      voiceState: VoiceState.values.firstWhere(
        (e) => e.name == json['voiceState'],
      ),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// AI hint model for step-by-step guidance
class AIHint {
  final String id;
  final String question;
  final String hint;
  final List<String> steps;
  final String explanation;
  final String topic;
  final int difficulty;
  final Map<String, dynamic>? metadata;

  const AIHint({
    required this.id,
    required this.question,
    required this.hint,
    required this.steps,
    required this.explanation,
    required this.topic,
    required this.difficulty,
    this.metadata,
  });

  AIHint copyWith({
    String? id,
    String? question,
    String? hint,
    List<String>? steps,
    String? explanation,
    String? topic,
    int? difficulty,
    Map<String, dynamic>? metadata,
  }) {
    return AIHint(
      id: id ?? this.id,
      question: question ?? this.question,
      hint: hint ?? this.hint,
      steps: steps ?? this.steps,
      explanation: explanation ?? this.explanation,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'hint': hint,
      'steps': steps,
      'explanation': explanation,
      'topic': topic,
      'difficulty': difficulty,
      'metadata': metadata,
    };
  }

  factory AIHint.fromJson(Map<String, dynamic> json) {
    return AIHint(
      id: json['id'] as String,
      question: json['question'] as String,
      hint: json['hint'] as String,
      steps: List<String>.from(json['steps'] as List),
      explanation: json['explanation'] as String,
      topic: json['topic'] as String,
      difficulty: json['difficulty'] as int,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}
