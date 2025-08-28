/// Game difficulty levels
enum GameDifficulty { easy, normal, genius, quantum }

/// Grade levels for PreK-12
enum GradeLevel {
  preK,
  kindergarten,
  grade1,
  grade2,
  grade3,
  grade4,
  grade5,
  grade6,
  grade7,
  grade8,
  grade9,
  grade10,
  grade11,
  grade12,
}

/// Game categories with grade-appropriate content
enum GameCategory {
  addition,
  subtraction,
  multiplication,
  division,
  algebra,
  geometry,
  calculus,
  fractions,
  decimals,
  percentages,
  wordProblems,
  patterns,
  measurement,
  dataAnalysis,
}

/// Game status
enum GameStatus { waiting, active, paused, completed, cancelled }

/// Player role in multiplayer
enum PlayerRole { host, participant, spectator }

/// AI-powered question model
class AIQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final GameCategory category;
  final GameDifficulty difficulty;
  final GradeLevel gradeLevel;
  final String? explanation;
  final String? hint;
  final int timeLimit;
  final Map<String, dynamic> aiMetadata;
  final double confidence;
  final List<String> learningObjectives;
  final String? visualAid;

  const AIQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.difficulty,
    required this.gradeLevel,
    this.explanation,
    this.hint,
    this.timeLimit = 30,
    this.aiMetadata = const {},
    this.confidence = 1.0,
    this.learningObjectives = const [],
    this.visualAid,
  });

  AIQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswer,
    GameCategory? category,
    GameDifficulty? difficulty,
    GradeLevel? gradeLevel,
    String? explanation,
    String? hint,
    int? timeLimit,
    Map<String, dynamic>? aiMetadata,
    double? confidence,
    List<String>? learningObjectives,
    String? visualAid,
  }) {
    return AIQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      explanation: explanation ?? this.explanation,
      hint: hint ?? this.hint,
      timeLimit: timeLimit ?? this.timeLimit,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      confidence: confidence ?? this.confidence,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      visualAid: visualAid ?? this.visualAid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'category': category.name,
      'difficulty': difficulty.name,
      'gradeLevel': gradeLevel.name,
      'explanation': explanation,
      'hint': hint,
      'timeLimit': timeLimit,
      'aiMetadata': aiMetadata,
      'confidence': confidence,
      'learningObjectives': learningObjectives,
      'visualAid': visualAid,
    };
  }

  factory AIQuestion.fromJson(Map<String, dynamic> json) {
    return AIQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      category: GameCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
      gradeLevel: GradeLevel.values.firstWhere(
        (e) => e.name == json['gradeLevel'],
      ),
      explanation: json['explanation'] as String?,
      hint: json['hint'] as String?,
      timeLimit: json['timeLimit'] as int? ?? 30,
      aiMetadata: json['aiMetadata'] != null
          ? Map<String, dynamic>.from(json['aiMetadata'] as Map)
          : {},
      confidence: json['confidence'] as double? ?? 1.0,
      learningObjectives: json['learningObjectives'] != null
          ? List<String>.from(json['learningObjectives'] as List)
          : [],
      visualAid: json['visualAid'] as String?,
    );
  }
}

/// Question model (backward compatibility)
class GameQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final GameCategory category;
  final GameDifficulty difficulty;
  final GradeLevel? gradeLevel;
  final String? explanation;
  final String? hint;
  final int timeLimit; // in seconds
  final Map<String, dynamic>? aiMetadata;
  final double? confidence;
  final List<String>? learningObjectives;
  final String? visualAid;

  const GameQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.difficulty,
    this.gradeLevel,
    this.explanation,
    this.hint,
    this.timeLimit = 30,
    this.aiMetadata,
    this.confidence,
    this.learningObjectives,
    this.visualAid,
  });

  GameQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswer,
    GameCategory? category,
    GameDifficulty? difficulty,
    GradeLevel? gradeLevel,
    String? explanation,
    String? hint,
    int? timeLimit,
    Map<String, dynamic>? aiMetadata,
    double? confidence,
    List<String>? learningObjectives,
    String? visualAid,
  }) {
    return GameQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      explanation: explanation ?? this.explanation,
      hint: hint ?? this.hint,
      timeLimit: timeLimit ?? this.timeLimit,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      confidence: confidence ?? this.confidence,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      visualAid: visualAid ?? this.visualAid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'category': category.name,
      'difficulty': difficulty.name,
      'gradeLevel': gradeLevel?.name,
      'explanation': explanation,
      'hint': hint,
      'timeLimit': timeLimit,
      'aiMetadata': aiMetadata,
      'confidence': confidence,
      'learningObjectives': learningObjectives,
      'visualAid': visualAid,
    };
  }

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    return GameQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      category: GameCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
      gradeLevel: json['gradeLevel'] != null
          ? GradeLevel.values.firstWhere((e) => e.name == json['gradeLevel'])
          : null,
      explanation: json['explanation'] as String?,
      hint: json['hint'] as String?,
      timeLimit: json['timeLimit'] as int? ?? 30,
      aiMetadata: json['aiMetadata'] != null
          ? Map<String, dynamic>.from(json['aiMetadata'] as Map)
          : null,
      confidence: json['confidence'] as double?,
      learningObjectives: json['learningObjectives'] != null
          ? List<String>.from(json['learningObjectives'] as List)
          : null,
      visualAid: json['visualAid'] as String?,
    );
  }
}

/// Player model
class GamePlayer {
  final String id;
  final String name;
  final String? avatar;
  final PlayerRole role;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final bool isOnline;
  final DateTime lastActive;

  const GamePlayer({
    required this.id,
    required this.name,
    this.avatar,
    this.role = PlayerRole.participant,
    this.score = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.isOnline = true,
    required this.lastActive,
  });

  GamePlayer copyWith({
    String? id,
    String? name,
    String? avatar,
    PlayerRole? role,
    int? score,
    int? correctAnswers,
    int? totalQuestions,
    bool? isOnline,
    DateTime? lastActive,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'role': role.name,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'isOnline': isOnline,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: PlayerRole.values.firstWhere((e) => e.name == json['role']),
      score: json['score'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? true,
      lastActive: DateTime.parse(json['lastActive'] as String),
    );
  }
}

/// Game session model
class GameSession {
  final String id;
  final String name;
  final GameDifficulty difficulty;
  final GameCategory category;
  final List<GameQuestion> questions;
  final List<GamePlayer> players;
  final GameStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int timeLimit; // total time in seconds

  const GameSession({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.category,
    required this.questions,
    required this.players,
    this.status = GameStatus.waiting,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.currentQuestionIndex = 0,
    this.totalQuestions = 0,
    this.timeLimit = 600, // 10 minutes default
  });

  GameSession copyWith({
    String? id,
    String? name,
    GameDifficulty? difficulty,
    GameCategory? category,
    List<GameQuestion>? questions,
    List<GamePlayer>? players,
    GameStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? currentQuestionIndex,
    int? totalQuestions,
    int? timeLimit,
  }) {
    return GameSession(
      id: id ?? this.id,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      questions: questions ?? this.questions,
      players: players ?? this.players,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty.name,
      'category': category.name,
      'questions': questions.map((q) => q.toJson()).toList(),
      'players': players.map((p) => p.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'totalQuestions': totalQuestions,
      'timeLimit': timeLimit,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      name: json['name'] as String,
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
      category: GameCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      questions: (json['questions'] as List)
          .map((q) => GameQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      players: (json['players'] as List)
          .map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: GameStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      timeLimit: json['timeLimit'] as int? ?? 600,
    );
  }
}

/// Game result model
class GameResult {
  final String id;
  final String sessionId;
  final String playerId;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final double accuracy;
  final Duration timeSpent;
  final DateTime completedAt;
  final List<Map<String, dynamic>> answers; // questionId -> answer data

  const GameResult({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.accuracy,
    required this.timeSpent,
    required this.completedAt,
    required this.answers,
  });

  GameResult copyWith({
    String? id,
    String? sessionId,
    String? playerId,
    int? score,
    int? correctAnswers,
    int? totalQuestions,
    double? accuracy,
    Duration? timeSpent,
    DateTime? completedAt,
    List<Map<String, dynamic>>? answers,
  }) {
    return GameResult(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      accuracy: accuracy ?? this.accuracy,
      timeSpent: timeSpent ?? this.timeSpent,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'playerId': playerId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'accuracy': accuracy,
      'timeSpent': timeSpent.inSeconds,
      'completedAt': completedAt.toIso8601String(),
      'answers': answers,
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      playerId: json['playerId'] as String,
      score: json['score'] as int,
      correctAnswers: json['correctAnswers'] as int,
      totalQuestions: json['totalQuestions'] as int,
      accuracy: json['accuracy'] as double,
      timeSpent: Duration(seconds: json['timeSpent'] as int),
      completedAt: DateTime.parse(json['completedAt'] as String),
      answers: List<Map<String, dynamic>>.from(json['answers'] as List),
    );
  }
}
