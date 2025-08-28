import 'package:flutter/foundation.dart';

/// Student Progress Model
/// Tracks learning progress, achievements, and performance metrics
class StudentProgress {
  final String studentId;
  final int questionsAnswered;
  final double accuracyRate;
  final int currentStreak;
  final int totalStreak;
  final int level;
  final int experiencePoints;
  final Map<String, TopicProgress> topicProgress;
  final List<Achievement> achievements;
  final DateTime lastActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentProgress({
    required this.studentId,
    required this.questionsAnswered,
    required this.accuracyRate,
    required this.currentStreak,
    required this.totalStreak,
    required this.level,
    required this.experiencePoints,
    required this.topicProgress,
    required this.achievements,
    required this.lastActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new student progress instance
  factory StudentProgress.create(String studentId) {
    final now = DateTime.now();
    return StudentProgress(
      studentId: studentId,
      questionsAnswered: 0,
      accuracyRate: 0.0,
      currentStreak: 0,
      totalStreak: 0,
      level: 1,
      experiencePoints: 0,
      topicProgress: {},
      achievements: [],
      lastActive: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with updated values
  StudentProgress copyWith({
    String? studentId,
    int? questionsAnswered,
    double? accuracyRate,
    int? currentStreak,
    int? totalStreak,
    int? level,
    int? experiencePoints,
    Map<String, TopicProgress>? topicProgress,
    List<Achievement>? achievements,
    DateTime? lastActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProgress(
      studentId: studentId ?? this.studentId,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      currentStreak: currentStreak ?? this.currentStreak,
      totalStreak: totalStreak ?? this.totalStreak,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      topicProgress: topicProgress ?? this.topicProgress,
      achievements: achievements ?? this.achievements,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'questionsAnswered': questionsAnswered,
      'accuracyRate': accuracyRate,
      'currentStreak': currentStreak,
      'totalStreak': totalStreak,
      'level': level,
      'experiencePoints': experiencePoints,
      'topicProgress': topicProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'achievements': achievements
          .map((achievement) => achievement.toJson())
          .toList(),
      'lastActive': lastActive.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      studentId: json['studentId'] as String,
      questionsAnswered: json['questionsAnswered'] as int,
      accuracyRate: (json['accuracyRate'] as num).toDouble(),
      currentStreak: json['currentStreak'] as int,
      totalStreak: json['totalStreak'] as int,
      level: json['level'] as int,
      experiencePoints: json['experiencePoints'] as int,
      topicProgress: (json['topicProgress'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          TopicProgress.fromJson(value as Map<String, dynamic>),
        ),
      ),
      achievements: (json['achievements'] as List<dynamic>)
          .map(
            (achievement) =>
                Achievement.fromJson(achievement as Map<String, dynamic>),
          )
          .toList(),
      lastActive: DateTime.parse(json['lastActive'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentProgress &&
        other.studentId == studentId &&
        other.questionsAnswered == questionsAnswered &&
        other.accuracyRate == accuracyRate &&
        other.currentStreak == currentStreak &&
        other.totalStreak == totalStreak &&
        other.level == level &&
        other.experiencePoints == experiencePoints &&
        mapEquals(other.topicProgress, topicProgress) &&
        listEquals(other.achievements, achievements) &&
        other.lastActive == lastActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      studentId,
      questionsAnswered,
      accuracyRate,
      currentStreak,
      totalStreak,
      level,
      experiencePoints,
      topicProgress,
      achievements,
      lastActive,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'StudentProgress(studentId: $studentId, questionsAnswered: $questionsAnswered, accuracyRate: $accuracyRate, currentStreak: $currentStreak, level: $level)';
  }
}

/// Topic Progress Model
/// Tracks progress for specific math topics
class TopicProgress {
  final String topicId;
  final String topicName;
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracyRate;
  final int masteryLevel;
  final DateTime lastPracticed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TopicProgress({
    required this.topicId,
    required this.topicName,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.masteryLevel,
    required this.lastPracticed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new topic progress instance
  factory TopicProgress.create(String topicId, String topicName) {
    final now = DateTime.now();
    return TopicProgress(
      topicId: topicId,
      topicName: topicName,
      questionsAnswered: 0,
      correctAnswers: 0,
      accuracyRate: 0.0,
      masteryLevel: 0,
      lastPracticed: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with updated values
  TopicProgress copyWith({
    String? topicId,
    String? topicName,
    int? questionsAnswered,
    int? correctAnswers,
    double? accuracyRate,
    int? masteryLevel,
    DateTime? lastPracticed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicProgress(
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'accuracyRate': accuracyRate,
      'masteryLevel': masteryLevel,
      'lastPracticed': lastPracticed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TopicProgress.fromJson(Map<String, dynamic> json) {
    return TopicProgress(
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      questionsAnswered: json['questionsAnswered'] as int,
      correctAnswers: json['correctAnswers'] as int,
      accuracyRate: (json['accuracyRate'] as num).toDouble(),
      masteryLevel: json['masteryLevel'] as int,
      lastPracticed: DateTime.parse(json['lastPracticed'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopicProgress &&
        other.topicId == topicId &&
        other.topicName == topicName &&
        other.questionsAnswered == questionsAnswered &&
        other.correctAnswers == correctAnswers &&
        other.accuracyRate == accuracyRate &&
        other.masteryLevel == masteryLevel &&
        other.lastPracticed == lastPracticed &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      topicId,
      topicName,
      questionsAnswered,
      correctAnswers,
      accuracyRate,
      masteryLevel,
      lastPracticed,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'TopicProgress(topicId: $topicId, topicName: $topicName, questionsAnswered: $questionsAnswered, accuracyRate: $accuracyRate, masteryLevel: $masteryLevel)';
  }
}

/// Achievement Model
/// Represents student achievements and badges
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementLevel level;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.level,
    required this.isUnlocked,
    this.unlockedAt,
    required this.createdAt,
  });

  /// Create a new achievement instance
  factory Achievement.create({
    required String id,
    required String title,
    required String description,
    required String icon,
    required AchievementType type,
    required AchievementLevel level,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      type: type,
      level: level,
      isUnlocked: false,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with updated values
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    AchievementLevel? level,
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      level: level ?? this.level,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.name,
      'level': level.name,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: AchievementType.values.firstWhere((e) => e.name == json['type']),
      level: AchievementLevel.values.firstWhere((e) => e.name == json['level']),
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.icon == icon &&
        other.type == type &&
        other.level == level &&
        other.isUnlocked == isUnlocked &&
        other.unlockedAt == unlockedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      icon,
      type,
      level,
      isUnlocked,
      unlockedAt,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, type: $type, level: $level, isUnlocked: $isUnlocked)';
  }
}

/// Achievement Types
enum AchievementType { streak, accuracy, speed, mastery, exploration }

/// Achievement Levels
enum AchievementLevel { bronze, silver, gold, platinum, diamond }
