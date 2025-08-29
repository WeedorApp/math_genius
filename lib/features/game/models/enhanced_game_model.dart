import 'game_model.dart';

/// Enhanced game mechanics and progression system
/// Provides advanced features for Math Genius games

/// Game progression levels with detailed requirements
enum GameProgression {
  novice,
  apprentice,
  skilled,
  expert,
  master,
  grandmaster,
}

/// Achievement types for gamification
enum AchievementType {
  streakMaster,
  speedDemon,
  perfectionist,
  explorer,
  challenger,
  socialBee,
  studyBuddy,
  mathWizard,
}

/// Power-ups available during games
enum PowerUpType {
  timeExtension,
  skipQuestion,
  fiftyFifty,
  doublePoints,
  hintReveal,
  freezeTime,
  bonusLife,
  multiplier,
}

/// Game modes with different mechanics
enum GameMode {
  classic,
  timeAttack,
  endless,
  multiplayer,
  tournament,
  practice,
  adaptive,
  story,
}

/// Enhanced game statistics
class GameStats {
  final int totalGamesPlayed;
  final int totalQuestionsAnswered;
  final int correctAnswers;
  final int totalTimeSpent; // in seconds
  final double averageAccuracy;
  final double averageResponseTime;
  final int currentStreak;
  final int longestStreak;
  final Map<GameCategory, int> categoryMastery;
  final Map<GameDifficulty, int> difficultyProgress;
  final List<String> unlockedAchievements;
  final int totalPoints;
  final GameProgression currentLevel;
  final DateTime lastPlayed;
  final Map<String, dynamic> personalBests;

  const GameStats({
    this.totalGamesPlayed = 0,
    this.totalQuestionsAnswered = 0,
    this.correctAnswers = 0,
    this.totalTimeSpent = 0,
    this.averageAccuracy = 0.0,
    this.averageResponseTime = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.categoryMastery = const {},
    this.difficultyProgress = const {},
    this.unlockedAchievements = const [],
    this.totalPoints = 0,
    this.currentLevel = GameProgression.novice,
    required this.lastPlayed,
    this.personalBests = const {},
  });

  double get accuracyPercentage => totalQuestionsAnswered > 0
      ? (correctAnswers / totalQuestionsAnswered) * 100
      : 0.0;

  int get incorrectAnswers => totalQuestionsAnswered - correctAnswers;

  GameStats copyWith({
    int? totalGamesPlayed,
    int? totalQuestionsAnswered,
    int? correctAnswers,
    int? totalTimeSpent,
    double? averageAccuracy,
    double? averageResponseTime,
    int? currentStreak,
    int? longestStreak,
    Map<GameCategory, int>? categoryMastery,
    Map<GameDifficulty, int>? difficultyProgress,
    List<String>? unlockedAchievements,
    int? totalPoints,
    GameProgression? currentLevel,
    DateTime? lastPlayed,
    Map<String, dynamic>? personalBests,
  }) {
    return GameStats(
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      categoryMastery: categoryMastery ?? this.categoryMastery,
      difficultyProgress: difficultyProgress ?? this.difficultyProgress,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      personalBests: personalBests ?? this.personalBests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'correctAnswers': correctAnswers,
      'totalTimeSpent': totalTimeSpent,
      'averageAccuracy': averageAccuracy,
      'averageResponseTime': averageResponseTime,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'categoryMastery': categoryMastery.map((k, v) => MapEntry(k.name, v)),
      'difficultyProgress': difficultyProgress.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'unlockedAchievements': unlockedAchievements,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel.name,
      'lastPlayed': lastPlayed.toIso8601String(),
      'personalBests': personalBests,
    };
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
      averageResponseTime: (json['averageResponseTime'] ?? 0.0).toDouble(),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      categoryMastery: Map<GameCategory, int>.from(
        (json['categoryMastery'] ?? {}).map(
          (k, v) => MapEntry(GameCategory.values.byName(k), v),
        ),
      ),
      difficultyProgress: Map<GameDifficulty, int>.from(
        (json['difficultyProgress'] ?? {}).map(
          (k, v) => MapEntry(GameDifficulty.values.byName(k), v),
        ),
      ),
      unlockedAchievements: List<String>.from(
        json['unlockedAchievements'] ?? [],
      ),
      totalPoints: json['totalPoints'] ?? 0,
      currentLevel: GameProgression.values.byName(
        json['currentLevel'] ?? 'novice',
      ),
      lastPlayed: DateTime.parse(json['lastPlayed']),
      personalBests: Map<String, dynamic>.from(json['personalBests'] ?? {}),
    );
  }
}

/// Achievement model with detailed information
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final int pointsReward;
  final Map<String, dynamic> requirements;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    this.pointsReward = 100,
    this.requirements = const {},
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.maxProgress = 1,
  });

  double get progressPercentage =>
      maxProgress > 0 ? (progress / maxProgress) * 100 : 0.0;

  bool get isCompleted => progress >= maxProgress;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? type,
    int? pointsReward,
    Map<String, dynamic>? requirements,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? maxProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      type: type ?? this.type,
      pointsReward: pointsReward ?? this.pointsReward,
      requirements: requirements ?? this.requirements,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'type': type.name,
      'pointsReward': pointsReward,
      'requirements': requirements,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
      'maxProgress': maxProgress,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['iconPath'],
      type: AchievementType.values.byName(json['type']),
      pointsReward: json['pointsReward'] ?? 100,
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      progress: json['progress'] ?? 0,
      maxProgress: json['maxProgress'] ?? 1,
    );
  }
}

/// Power-up model for in-game enhancements
class PowerUp {
  final String id;
  final String name;
  final String description;
  final PowerUpType type;
  final int duration; // in seconds, 0 for instant
  final int cost; // in points
  final String iconPath;
  final bool isAvailable;
  final int quantity;
  final Map<String, dynamic> effects;

  const PowerUp({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.duration = 0,
    this.cost = 50,
    required this.iconPath,
    this.isAvailable = true,
    this.quantity = 0,
    this.effects = const {},
  });

  bool get isInstant => duration == 0;
  bool get canUse => isAvailable && quantity > 0;

  PowerUp copyWith({
    String? id,
    String? name,
    String? description,
    PowerUpType? type,
    int? duration,
    int? cost,
    String? iconPath,
    bool? isAvailable,
    int? quantity,
    Map<String, dynamic>? effects,
  }) {
    return PowerUp(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      cost: cost ?? this.cost,
      iconPath: iconPath ?? this.iconPath,
      isAvailable: isAvailable ?? this.isAvailable,
      quantity: quantity ?? this.quantity,
      effects: effects ?? this.effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'duration': duration,
      'cost': cost,
      'iconPath': iconPath,
      'isAvailable': isAvailable,
      'quantity': quantity,
      'effects': effects,
    };
  }

  factory PowerUp.fromJson(Map<String, dynamic> json) {
    return PowerUp(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: PowerUpType.values.byName(json['type']),
      duration: json['duration'] ?? 0,
      cost: json['cost'] ?? 50,
      iconPath: json['iconPath'],
      isAvailable: json['isAvailable'] ?? true,
      quantity: json['quantity'] ?? 0,
      effects: Map<String, dynamic>.from(json['effects'] ?? {}),
    );
  }
}

/// Enhanced game session with advanced features
class EnhancedGameSession {
  final String id;
  final String name;
  final String userId;
  final GameDifficulty difficulty;
  final GameCategory category;
  final List<GameQuestion> questions;
  final List<int> answers;
  final GameStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int currentQuestionIndex;
  final int score;
  final int timeLimit;
  final GameMode gameMode;
  final List<PowerUp> availablePowerUps;
  final List<PowerUp> usedPowerUps;
  final int bonusPoints;
  final int multiplier;
  final Map<String, dynamic> gameModifiers;
  final List<Achievement> unlockedAchievements;
  final bool isRanked;
  final String? tournamentId;

  const EnhancedGameSession({
    required this.id,
    required this.name,
    required this.userId,
    required this.difficulty,
    required this.category,
    required this.questions,
    this.answers = const [],
    this.status = GameStatus.waiting,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.currentQuestionIndex = 0,
    this.score = 0,
    this.timeLimit = 600,
    this.gameMode = GameMode.classic,
    this.availablePowerUps = const [],
    this.usedPowerUps = const [],
    this.bonusPoints = 0,
    this.multiplier = 1,
    this.gameModifiers = const {},
    this.unlockedAchievements = const [],
    this.isRanked = false,
    this.tournamentId,
  });

  int get totalScore => score + bonusPoints;
  int get finalScore => totalScore * multiplier;

  EnhancedGameSession copyWith({
    String? id,
    String? name,
    String? userId,
    GameDifficulty? difficulty,
    GameCategory? category,
    List<GameQuestion>? questions,
    List<int>? answers,
    GameStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? currentQuestionIndex,
    int? score,
    int? timeLimit,
    GameMode? gameMode,
    List<PowerUp>? availablePowerUps,
    List<PowerUp>? usedPowerUps,
    int? bonusPoints,
    int? multiplier,
    Map<String, dynamic>? gameModifiers,
    List<Achievement>? unlockedAchievements,
    bool? isRanked,
    String? tournamentId,
  }) {
    return EnhancedGameSession(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      timeLimit: timeLimit ?? this.timeLimit,
      gameMode: gameMode ?? this.gameMode,
      availablePowerUps: availablePowerUps ?? this.availablePowerUps,
      usedPowerUps: usedPowerUps ?? this.usedPowerUps,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      multiplier: multiplier ?? this.multiplier,
      gameModifiers: gameModifiers ?? this.gameModifiers,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      isRanked: isRanked ?? this.isRanked,
      tournamentId: tournamentId ?? this.tournamentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'difficulty': difficulty.name,
      'category': category.name,
      'questions': questions.map((q) => q.toJson()).toList(),
      'answers': answers,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'score': score,
      'timeLimit': timeLimit,
      'gameMode': gameMode.name,
      'availablePowerUps': availablePowerUps.map((p) => p.toJson()).toList(),
      'usedPowerUps': usedPowerUps.map((p) => p.toJson()).toList(),
      'bonusPoints': bonusPoints,
      'multiplier': multiplier,
      'gameModifiers': gameModifiers,
      'unlockedAchievements': unlockedAchievements
          .map((a) => a.toJson())
          .toList(),
      'isRanked': isRanked,
      'tournamentId': tournamentId,
    };
  }

  factory EnhancedGameSession.fromJson(Map<String, dynamic> json) {
    return EnhancedGameSession(
      id: json['id'],
      name: json['name'],
      userId: json['userId'],
      difficulty: GameDifficulty.values.byName(json['difficulty']),
      category: GameCategory.values.byName(json['category']),
      questions: (json['questions'] as List<dynamic>)
          .map((q) => GameQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      answers: List<int>.from(json['answers'] ?? []),
      status: GameStatus.values.byName(json['status'] ?? 'waiting'),
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      score: json['score'] ?? 0,
      timeLimit: json['timeLimit'] ?? 600,
      gameMode: GameMode.values.byName(json['gameMode'] ?? 'classic'),
      availablePowerUps: (json['availablePowerUps'] as List<dynamic>? ?? [])
          .map((p) => PowerUp.fromJson(p as Map<String, dynamic>))
          .toList(),
      usedPowerUps: (json['usedPowerUps'] as List<dynamic>? ?? [])
          .map((p) => PowerUp.fromJson(p as Map<String, dynamic>))
          .toList(),
      bonusPoints: json['bonusPoints'] ?? 0,
      multiplier: json['multiplier'] ?? 1,
      gameModifiers: Map<String, dynamic>.from(json['gameModifiers'] ?? {}),
      unlockedAchievements:
          (json['unlockedAchievements'] as List<dynamic>? ?? [])
              .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
              .toList(),
      isRanked: json['isRanked'] ?? false,
      tournamentId: json['tournamentId'],
    );
  }
}
