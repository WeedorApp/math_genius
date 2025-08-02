/// Live session status
enum LiveSessionStatus { waiting, active, paused, completed, cancelled }

/// Session access types
enum SessionAccessType { public, private, inviteOnly, passwordProtected }

/// Question display modes
enum QuestionDisplayMode { allAtOnce, oneByOne, timed, adaptive }

/// Live session model
class LiveSession {
  final String id;
  final String hostId;
  final String hostName;
  final String title;
  final String description;
  final LiveSessionStatus status;
  final SessionAccessType accessType;
  final String? password;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final List<LiveQuestion> questions;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> metadata;

  const LiveSession({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.title,
    required this.description,
    this.status = LiveSessionStatus.waiting,
    this.accessType = SessionAccessType.public,
    this.password,
    this.qrCode,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.maxParticipants = 50,
    this.currentParticipants = 0,
    this.participantIds = const [],
    this.questions = const [],
    this.settings = const {},
    this.metadata = const {},
  });

  LiveSession copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? title,
    String? description,
    LiveSessionStatus? status,
    SessionAccessType? accessType,
    String? password,
    String? qrCode,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? participantIds,
    List<LiveQuestion>? questions,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return LiveSession(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      accessType: accessType ?? this.accessType,
      password: password ?? this.password,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participantIds: participantIds ?? this.participantIds,
      questions: questions ?? this.questions,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'title': title,
      'description': description,
      'status': status.name,
      'accessType': accessType.name,
      'password': password,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'participantIds': participantIds,
      'questions': questions.map((q) => q.toJson()).toList(),
      'settings': settings,
      'metadata': metadata,
    };
  }

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: LiveSessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      accessType: SessionAccessType.values.firstWhere(
        (e) => e.name == json['accessType'],
      ),
      password: json['password'] as String?,
      qrCode: json['qrCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      maxParticipants: json['maxParticipants'] as int? ?? 50,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      participantIds: List<String>.from(json['participantIds'] as List),
      questions: (json['questions'] as List)
          .map((q) => LiveQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : {},
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Live question model
class LiveQuestion {
  final String id;
  final String sessionId;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String? explanation;
  final int timeLimit; // in seconds
  final DateTime? displayedAt;
  final DateTime? answeredAt;
  final Map<String, int> participantAnswers; // participantId -> answerIndex
  final Map<String, dynamic> metadata;

  const LiveQuestion({
    required this.id,
    required this.sessionId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.timeLimit = 30,
    this.displayedAt,
    this.answeredAt,
    this.participantAnswers = const {},
    this.metadata = const {},
  });

  LiveQuestion copyWith({
    String? id,
    String? sessionId,
    String? question,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    int? timeLimit,
    DateTime? displayedAt,
    DateTime? answeredAt,
    Map<String, int>? participantAnswers,
    Map<String, dynamic>? metadata,
  }) {
    return LiveQuestion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      timeLimit: timeLimit ?? this.timeLimit,
      displayedAt: displayedAt ?? this.displayedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      participantAnswers: participantAnswers ?? this.participantAnswers,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'timeLimit': timeLimit,
      'displayedAt': displayedAt?.toIso8601String(),
      'answeredAt': answeredAt?.toIso8601String(),
      'participantAnswers': participantAnswers,
      'metadata': metadata,
    };
  }

  factory LiveQuestion.fromJson(Map<String, dynamic> json) {
    return LiveQuestion(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String?,
      timeLimit: json['timeLimit'] as int? ?? 30,
      displayedAt: json['displayedAt'] != null
          ? DateTime.parse(json['displayedAt'] as String)
          : null,
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      participantAnswers: Map<String, int>.from(
        json['participantAnswers'] as Map,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Live participant model
class LiveParticipant {
  final String id;
  final String sessionId;
  final String name;
  final String? avatar;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isActive;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final Map<String, dynamic> metadata;

  const LiveParticipant({
    required this.id,
    required this.sessionId,
    required this.name,
    this.avatar,
    required this.joinedAt,
    this.leftAt,
    this.isActive = true,
    this.score = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.metadata = const {},
  });

  LiveParticipant copyWith({
    String? id,
    String? sessionId,
    String? name,
    String? avatar,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isActive,
    int? score,
    int? correctAnswers,
    int? totalQuestions,
    Map<String, dynamic>? metadata,
  }) {
    return LiveParticipant(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isActive: isActive ?? this.isActive,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'name': name,
      'avatar': avatar,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'isActive': isActive,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'metadata': metadata,
    };
  }

  factory LiveParticipant.fromJson(Map<String, dynamic> json) {
    return LiveParticipant(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] != null
          ? DateTime.parse(json['leftAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      score: json['score'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Live session result model
class LiveSessionResult {
  final String id;
  final String sessionId;
  final String participantId;
  final String participantName;
  final int finalScore;
  final int correctAnswers;
  final int totalQuestions;
  final double accuracy;
  final Duration totalTime;
  final DateTime completedAt;
  final Map<String, int> questionResults; // questionId -> answerIndex
  final Map<String, dynamic> metadata;

  const LiveSessionResult({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.participantName,
    required this.finalScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.accuracy,
    required this.totalTime,
    required this.completedAt,
    this.questionResults = const {},
    this.metadata = const {},
  });

  LiveSessionResult copyWith({
    String? id,
    String? sessionId,
    String? participantId,
    String? participantName,
    int? finalScore,
    int? correctAnswers,
    int? totalQuestions,
    double? accuracy,
    Duration? totalTime,
    DateTime? completedAt,
    Map<String, int>? questionResults,
    Map<String, dynamic>? metadata,
  }) {
    return LiveSessionResult(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      finalScore: finalScore ?? this.finalScore,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      accuracy: accuracy ?? this.accuracy,
      totalTime: totalTime ?? this.totalTime,
      completedAt: completedAt ?? this.completedAt,
      questionResults: questionResults ?? this.questionResults,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'participantId': participantId,
      'participantName': participantName,
      'finalScore': finalScore,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'accuracy': accuracy,
      'totalTime': totalTime.inMilliseconds,
      'completedAt': completedAt.toIso8601String(),
      'questionResults': questionResults,
      'metadata': metadata,
    };
  }

  factory LiveSessionResult.fromJson(Map<String, dynamic> json) {
    return LiveSessionResult(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String,
      finalScore: json['finalScore'] as int,
      correctAnswers: json['correctAnswers'] as int,
      totalQuestions: json['totalQuestions'] as int,
      accuracy: json['accuracy'] as double,
      totalTime: Duration(milliseconds: json['totalTime'] as int),
      completedAt: DateTime.parse(json['completedAt'] as String),
      questionResults: Map<String, int>.from(json['questionResults'] as Map),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Live session settings model
class LiveSessionSettings {
  final QuestionDisplayMode displayMode;
  final int questionTimeLimit;
  final bool showLeaderboard;
  final bool allowLateJoins;
  final bool autoStart;
  final bool showCorrectAnswers;
  final bool showExplanations;
  final Map<String, dynamic> customSettings;

  const LiveSessionSettings({
    this.displayMode = QuestionDisplayMode.oneByOne,
    this.questionTimeLimit = 30,
    this.showLeaderboard = true,
    this.allowLateJoins = true,
    this.autoStart = false,
    this.showCorrectAnswers = true,
    this.showExplanations = true,
    this.customSettings = const {},
  });

  LiveSessionSettings copyWith({
    QuestionDisplayMode? displayMode,
    int? questionTimeLimit,
    bool? showLeaderboard,
    bool? allowLateJoins,
    bool? autoStart,
    bool? showCorrectAnswers,
    bool? showExplanations,
    Map<String, dynamic>? customSettings,
  }) {
    return LiveSessionSettings(
      displayMode: displayMode ?? this.displayMode,
      questionTimeLimit: questionTimeLimit ?? this.questionTimeLimit,
      showLeaderboard: showLeaderboard ?? this.showLeaderboard,
      allowLateJoins: allowLateJoins ?? this.allowLateJoins,
      autoStart: autoStart ?? this.autoStart,
      showCorrectAnswers: showCorrectAnswers ?? this.showCorrectAnswers,
      showExplanations: showExplanations ?? this.showExplanations,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayMode': displayMode.name,
      'questionTimeLimit': questionTimeLimit,
      'showLeaderboard': showLeaderboard,
      'allowLateJoins': allowLateJoins,
      'autoStart': autoStart,
      'showCorrectAnswers': showCorrectAnswers,
      'showExplanations': showExplanations,
      'customSettings': customSettings,
    };
  }

  factory LiveSessionSettings.fromJson(Map<String, dynamic> json) {
    return LiveSessionSettings(
      displayMode: QuestionDisplayMode.values.firstWhere(
        (e) => e.name == json['displayMode'],
      ),
      questionTimeLimit: json['questionTimeLimit'] as int? ?? 30,
      showLeaderboard: json['showLeaderboard'] as bool? ?? true,
      allowLateJoins: json['allowLateJoins'] as bool? ?? true,
      autoStart: json['autoStart'] as bool? ?? false,
      showCorrectAnswers: json['showCorrectAnswers'] as bool? ?? true,
      showExplanations: json['showExplanations'] as bool? ?? true,
      customSettings: json['customSettings'] != null
          ? Map<String, dynamic>.from(json['customSettings'] as Map)
          : {},
    );
  }
}
