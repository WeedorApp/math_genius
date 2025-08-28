// Import game models for difficulty levels
import '../../game/models/game_model.dart';

/// Class/Grade levels for the Math Genius system
enum ClassLevel {
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

/// Class status for user access
enum ClassStatus {
  locked, // Not accessible
  unlocked, // Available for access
  active, // Currently selected
  completed, // Finished with high performance
  premium, // Premium access features
}

/// Class content categories
enum ClassContentCategory {
  arithmetic, // Basic math operations
  algebra, // Algebraic concepts
  geometry, // Geometric shapes and measurements
  calculus, // Advanced mathematical concepts
  statistics, // Data analysis and probability
  wordProblems, // Real-world problem solving
  mentalMath, // Quick calculation skills
  logicPuzzles, // Critical thinking problems
}

/// Class model for Math Genius
class MathClass {
  final String id;
  final ClassLevel level;
  final String name;
  final String description;
  final String displayName;
  final int minAge;
  final int maxAge;
  final List<ClassContentCategory> availableCategories;
  final Map<ClassContentCategory, List<String>> learningObjectives;
  final Map<ClassContentCategory, int> questionCounts;
  final Map<ClassContentCategory, GameDifficulty> difficultyLevels;
  final String? prerequisiteClass;
  final int requiredScore;
  final bool isPremium;
  final String? iconPath;
  final String? colorTheme;

  const MathClass({
    required this.id,
    required this.level,
    required this.name,
    required this.description,
    required this.displayName,
    required this.minAge,
    required this.maxAge,
    required this.availableCategories,
    required this.learningObjectives,
    required this.questionCounts,
    required this.difficultyLevels,
    this.prerequisiteClass,
    this.requiredScore = 0,
    this.isPremium = false,
    this.iconPath,
    this.colorTheme,
  });

  MathClass copyWith({
    String? id,
    ClassLevel? level,
    String? name,
    String? description,
    String? displayName,
    int? minAge,
    int? maxAge,
    List<ClassContentCategory>? availableCategories,
    Map<ClassContentCategory, List<String>>? learningObjectives,
    Map<ClassContentCategory, int>? questionCounts,
    Map<ClassContentCategory, GameDifficulty>? difficultyLevels,
    String? prerequisiteClass,
    int? requiredScore,
    bool? isPremium,
    String? iconPath,
    String? colorTheme,
  }) {
    return MathClass(
      id: id ?? this.id,
      level: level ?? this.level,
      name: name ?? this.name,
      description: description ?? this.description,
      displayName: displayName ?? this.displayName,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      availableCategories: availableCategories ?? this.availableCategories,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      questionCounts: questionCounts ?? this.questionCounts,
      difficultyLevels: difficultyLevels ?? this.difficultyLevels,
      prerequisiteClass: prerequisiteClass ?? this.prerequisiteClass,
      requiredScore: requiredScore ?? this.requiredScore,
      isPremium: isPremium ?? this.isPremium,
      iconPath: iconPath ?? this.iconPath,
      colorTheme: colorTheme ?? this.colorTheme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.name,
      'name': name,
      'description': description,
      'displayName': displayName,
      'minAge': minAge,
      'maxAge': maxAge,
      'availableCategories': availableCategories.map((e) => e.name).toList(),
      'learningObjectives': learningObjectives.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'questionCounts': questionCounts.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'difficultyLevels': difficultyLevels.map(
        (key, value) => MapEntry(key.name, value.name),
      ),
      'prerequisiteClass': prerequisiteClass,
      'requiredScore': requiredScore,
      'isPremium': isPremium,
      'iconPath': iconPath,
      'colorTheme': colorTheme,
    };
  }

  factory MathClass.fromJson(Map<String, dynamic> json) {
    return MathClass(
      id: json['id'] as String,
      level: ClassLevel.values.firstWhere((e) => e.name == json['level']),
      name: json['name'] as String,
      description: json['description'] as String,
      displayName: json['displayName'] as String,
      minAge: json['minAge'] as int,
      maxAge: json['maxAge'] as int,
      availableCategories: (json['availableCategories'] as List)
          .map(
            (e) => ClassContentCategory.values.firstWhere(
              (category) => category.name == e,
            ),
          )
          .toList(),
      learningObjectives: (json['learningObjectives'] as Map<String, dynamic>)
          .map(
            (key, value) => MapEntry(
              ClassContentCategory.values.firstWhere(
                (category) => category.name == key,
              ),
              List<String>.from(value as List),
            ),
          ),
      questionCounts: (json['questionCounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          ClassContentCategory.values.firstWhere(
            (category) => category.name == key,
          ),
          value as int,
        ),
      ),
      difficultyLevels: (json['difficultyLevels'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          ClassContentCategory.values.firstWhere(
            (category) => category.name == key,
          ),
          GameDifficulty.values.firstWhere(
            (difficulty) => difficulty.name == value as String,
          ),
        ),
      ),
      prerequisiteClass: json['prerequisiteClass'] as String?,
      requiredScore: json['requiredScore'] as int? ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      iconPath: json['iconPath'] as String?,
      colorTheme: json['colorTheme'] as String?,
    );
  }
}

/// User's class access and progress
class UserClassAccess {
  final String userId;
  final String classId;
  final ClassStatus status;
  final DateTime unlockedAt;
  final DateTime? completedAt;
  final int currentScore;
  final int maxScore;
  final double completionPercentage;
  final Map<ClassContentCategory, int> categoryScores;
  final Map<ClassContentCategory, bool> categoryCompletion;
  final List<String> achievements;
  final bool isActive;

  const UserClassAccess({
    required this.userId,
    required this.classId,
    required this.status,
    required this.unlockedAt,
    this.completedAt,
    required this.currentScore,
    required this.maxScore,
    required this.completionPercentage,
    required this.categoryScores,
    required this.categoryCompletion,
    required this.achievements,
    required this.isActive,
  });

  UserClassAccess copyWith({
    String? userId,
    String? classId,
    ClassStatus? status,
    DateTime? unlockedAt,
    DateTime? completedAt,
    int? currentScore,
    int? maxScore,
    double? completionPercentage,
    Map<ClassContentCategory, int>? categoryScores,
    Map<ClassContentCategory, bool>? categoryCompletion,
    List<String>? achievements,
    bool? isActive,
  }) {
    return UserClassAccess(
      userId: userId ?? this.userId,
      classId: classId ?? this.classId,
      status: status ?? this.status,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      completedAt: completedAt ?? this.completedAt,
      currentScore: currentScore ?? this.currentScore,
      maxScore: maxScore ?? this.maxScore,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      categoryScores: categoryScores ?? this.categoryScores,
      categoryCompletion: categoryCompletion ?? this.categoryCompletion,
      achievements: achievements ?? this.achievements,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'classId': classId,
      'status': status.name,
      'unlockedAt': unlockedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'currentScore': currentScore,
      'maxScore': maxScore,
      'completionPercentage': completionPercentage,
      'categoryScores': categoryScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'categoryCompletion': categoryCompletion.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'achievements': achievements,
      'isActive': isActive,
    };
  }

  factory UserClassAccess.fromJson(Map<String, dynamic> json) {
    return UserClassAccess(
      userId: json['userId'] as String,
      classId: json['classId'] as String,
      status: ClassStatus.values.firstWhere((e) => e.name == json['status']),
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      currentScore: json['currentScore'] as int,
      maxScore: json['maxScore'] as int,
      completionPercentage: json['completionPercentage'] as double,
      categoryScores: (json['categoryScores'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          ClassContentCategory.values.firstWhere(
            (category) => category.name == key,
          ),
          value as int,
        ),
      ),
      categoryCompletion: (json['categoryCompletion'] as Map<String, dynamic>)
          .map(
            (key, value) => MapEntry(
              ClassContentCategory.values.firstWhere(
                (category) => category.name == key,
              ),
              value as bool,
            ),
          ),
      achievements: List<String>.from(json['achievements'] as List),
      isActive: json['isActive'] as bool,
    );
  }
}
