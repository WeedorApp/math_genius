/// Reward types
enum RewardType { star, badge, message, achievement, bonus }

/// Badge categories
enum BadgeCategory { math, speed, accuracy, streak, social, special }

/// Achievement levels
enum AchievementLevel { bronze, silver, gold, platinum, diamond }

/// Star types
enum StarType { one, two, three, four, five }

/// Reward model
class Reward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final String? icon;
  final String? color;
  final int points;
  final DateTime createdAt;
  final DateTime? awardedAt;
  final String? awardedTo;
  final Map<String, dynamic> metadata;
  final bool isActive;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.icon,
    this.color,
    this.points = 0,
    required this.createdAt,
    this.awardedAt,
    this.awardedTo,
    this.metadata = const {},
    this.isActive = true,
  });

  Reward copyWith({
    String? id,
    String? name,
    String? description,
    RewardType? type,
    String? icon,
    String? color,
    int? points,
    DateTime? createdAt,
    DateTime? awardedAt,
    String? awardedTo,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      awardedAt: awardedAt ?? this.awardedAt,
      awardedTo: awardedTo ?? this.awardedTo,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'icon': icon,
      'color': color,
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'awardedAt': awardedAt?.toIso8601String(),
      'awardedTo': awardedTo,
      'metadata': metadata,
      'isActive': isActive,
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: RewardType.values.firstWhere((e) => e.name == json['type']),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      points: json['points'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      awardedAt: json['awardedAt'] != null
          ? DateTime.parse(json['awardedAt'] as String)
          : null,
      awardedTo: json['awardedTo'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Badge model
class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeCategory category;
  final AchievementLevel level;
  final String? icon;
  final String? color;
  final int requiredPoints;
  final DateTime? unlockedAt;
  final String? unlockedBy;
  final Map<String, dynamic> criteria;
  final bool isUnlocked;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.level,
    this.icon,
    this.color,
    required this.requiredPoints,
    this.unlockedAt,
    this.unlockedBy,
    this.criteria = const {},
    this.isUnlocked = false,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    BadgeCategory? category,
    AchievementLevel? level,
    String? icon,
    String? color,
    int? requiredPoints,
    DateTime? unlockedAt,
    String? unlockedBy,
    Map<String, dynamic>? criteria,
    bool? isUnlocked,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedBy: unlockedBy ?? this.unlockedBy,
      criteria: criteria ?? this.criteria,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'level': level.name,
      'icon': icon,
      'color': color,
      'requiredPoints': requiredPoints,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'unlockedBy': unlockedBy,
      'criteria': criteria,
      'isUnlocked': isUnlocked,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      level: AchievementLevel.values.firstWhere((e) => e.name == json['level']),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      requiredPoints: json['requiredPoints'] as int,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      unlockedBy: json['unlockedBy'] as String?,
      criteria: json['criteria'] != null
          ? Map<String, dynamic>.from(json['criteria'] as Map)
          : {},
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );
  }
}

/// Star model
class Star {
  final String id;
  final StarType type;
  final String? awardedFor;
  final DateTime awardedAt;
  final String awardedTo;
  final Map<String, dynamic> metadata;

  const Star({
    required this.id,
    required this.type,
    this.awardedFor,
    required this.awardedAt,
    required this.awardedTo,
    this.metadata = const {},
  });

  Star copyWith({
    String? id,
    StarType? type,
    String? awardedFor,
    DateTime? awardedAt,
    String? awardedTo,
    Map<String, dynamic>? metadata,
  }) {
    return Star(
      id: id ?? this.id,
      type: type ?? this.type,
      awardedFor: awardedFor ?? this.awardedFor,
      awardedAt: awardedAt ?? this.awardedAt,
      awardedTo: awardedTo ?? this.awardedTo,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'awardedFor': awardedFor,
      'awardedAt': awardedAt.toIso8601String(),
      'awardedTo': awardedTo,
      'metadata': metadata,
    };
  }

  factory Star.fromJson(Map<String, dynamic> json) {
    return Star(
      id: json['id'] as String,
      type: StarType.values.firstWhere((e) => e.name == json['type']),
      awardedFor: json['awardedFor'] as String?,
      awardedAt: DateTime.parse(json['awardedAt'] as String),
      awardedTo: json['awardedTo'] as String,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Achievement model
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementLevel level;
  final int requiredPoints;
  final String? icon;
  final String? color;
  final DateTime? unlockedAt;
  final String? unlockedBy;
  final Map<String, dynamic> criteria;
  final bool isUnlocked;
  final int progress; // 0-100

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.requiredPoints,
    this.icon,
    this.color,
    this.unlockedAt,
    this.unlockedBy,
    this.criteria = const {},
    this.isUnlocked = false,
    this.progress = 0,
  });

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementLevel? level,
    int? requiredPoints,
    String? icon,
    String? color,
    DateTime? unlockedAt,
    String? unlockedBy,
    Map<String, dynamic>? criteria,
    bool? isUnlocked,
    int? progress,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedBy: unlockedBy ?? this.unlockedBy,
      criteria: criteria ?? this.criteria,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level.name,
      'requiredPoints': requiredPoints,
      'icon': icon,
      'color': color,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'unlockedBy': unlockedBy,
      'criteria': criteria,
      'isUnlocked': isUnlocked,
      'progress': progress,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      level: AchievementLevel.values.firstWhere((e) => e.name == json['level']),
      requiredPoints: json['requiredPoints'] as int,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      unlockedBy: json['unlockedBy'] as String?,
      criteria: json['criteria'] != null
          ? Map<String, dynamic>.from(json['criteria'] as Map)
          : {},
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      progress: json['progress'] as int? ?? 0,
    );
  }
}

/// Reward message model
class RewardMessage {
  final String id;
  final String title;
  final String message;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime? readAt;
  final String recipientId;
  final bool isRead;
  final Map<String, dynamic> metadata;

  const RewardMessage({
    required this.id,
    required this.title,
    required this.message,
    this.icon,
    this.color,
    required this.createdAt,
    this.readAt,
    required this.recipientId,
    this.isRead = false,
    this.metadata = const {},
  });

  RewardMessage copyWith({
    String? id,
    String? title,
    String? message,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? readAt,
    String? recipientId,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return RewardMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      recipientId: recipientId ?? this.recipientId,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'recipientId': recipientId,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory RewardMessage.fromJson(Map<String, dynamic> json) {
    return RewardMessage(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      recipientId: json['recipientId'] as String,
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// User reward progress model
class UserRewardProgress {
  final String userId;
  final int totalPoints;
  final int totalStars;
  final int totalBadges;
  final int totalAchievements;
  final List<String> unlockedBadges;
  final List<String> unlockedAchievements;
  final DateTime lastUpdated;
  final Map<String, int> categoryPoints; // category -> points
  final Map<String, dynamic> metadata;

  const UserRewardProgress({
    required this.userId,
    this.totalPoints = 0,
    this.totalStars = 0,
    this.totalBadges = 0,
    this.totalAchievements = 0,
    this.unlockedBadges = const [],
    this.unlockedAchievements = const [],
    required this.lastUpdated,
    this.categoryPoints = const {},
    this.metadata = const {},
  });

  UserRewardProgress copyWith({
    String? userId,
    int? totalPoints,
    int? totalStars,
    int? totalBadges,
    int? totalAchievements,
    List<String>? unlockedBadges,
    List<String>? unlockedAchievements,
    DateTime? lastUpdated,
    Map<String, int>? categoryPoints,
    Map<String, dynamic>? metadata,
  }) {
    return UserRewardProgress(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      totalStars: totalStars ?? this.totalStars,
      totalBadges: totalBadges ?? this.totalBadges,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      categoryPoints: categoryPoints ?? this.categoryPoints,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'totalStars': totalStars,
      'totalBadges': totalBadges,
      'totalAchievements': totalAchievements,
      'unlockedBadges': unlockedBadges,
      'unlockedAchievements': unlockedAchievements,
      'lastUpdated': lastUpdated.toIso8601String(),
      'categoryPoints': categoryPoints,
      'metadata': metadata,
    };
  }

  factory UserRewardProgress.fromJson(Map<String, dynamic> json) {
    return UserRewardProgress(
      userId: json['userId'] as String,
      totalPoints: json['totalPoints'] as int? ?? 0,
      totalStars: json['totalStars'] as int? ?? 0,
      totalBadges: json['totalBadges'] as int? ?? 0,
      totalAchievements: json['totalAchievements'] as int? ?? 0,
      unlockedBadges: List<String>.from(json['unlockedBadges'] as List),
      unlockedAchievements: List<String>.from(
        json['unlockedAchievements'] as List,
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      categoryPoints: Map<String, int>.from(json['categoryPoints'] as Map),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}
