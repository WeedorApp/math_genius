import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

// Models
import '../models/reward_model.dart';

/// Reward Service for Math Genius
class RewardService {
  static const String _rewardsKey = 'rewards';
  static const String _badgesKey = 'badges';
  static const String _starsKey = 'stars';
  static const String _achievementsKey = 'achievements';
  static const String _messagesKey = 'reward_messages';
  static const String _userProgressKey = 'user_reward_progress';

  final SharedPreferences _prefs;
  final Box? _hiveBox;

  RewardService(this._prefs, this._hiveBox);

  /// Award a star to a user
  Future<Star> awardStar(
    String userId,
    StarType type,
    String? awardedFor,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final star = Star(
        id: _generateId(),
        type: type,
        awardedFor: awardedFor,
        awardedAt: DateTime.now(),
        awardedTo: userId,
        metadata: metadata ?? {},
      );

      await _saveStar(star);
      await _updateUserProgress(userId, starType: type);
      await _checkForBadgeUnlock(userId);
      await _checkForAchievementUnlock(userId);

      return star;
    } catch (e) {
      if (kDebugMode) {
        print('Error awarding star: $e');
      }
      rethrow;
    }
  }

  /// Award points to a user
  Future<void> awardPoints(
    String userId,
    int points,
    String? reason,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final reward = Reward(
        id: _generateId(),
        name: 'Points Awarded',
        description: reason ?? 'Points earned for excellent work!',
        type: RewardType.bonus,
        points: points,
        createdAt: DateTime.now(),
        awardedAt: DateTime.now(),
        awardedTo: userId,
        metadata: metadata ?? {},
      );

      await _saveReward(reward);
      await _updateUserProgress(userId, points: points);
      await _checkForBadgeUnlock(userId);
      await _checkForAchievementUnlock(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error awarding points: $e');
      }
    }
  }

  /// Send a reward message
  Future<RewardMessage> sendRewardMessage(
    String recipientId,
    String title,
    String message,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final rewardMessage = RewardMessage(
        id: _generateId(),
        title: title,
        message: message,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
        recipientId: recipientId,
        metadata: metadata ?? {},
      );

      await _saveRewardMessage(rewardMessage);
      return rewardMessage;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending reward message: $e');
      }
      rethrow;
    }
  }

  /// Mark reward message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final messages = await getAllRewardMessages();
      final messageIndex = messages.indexWhere((m) => m.id == messageId);

      if (messageIndex >= 0) {
        final message = messages[messageIndex];
        final updatedMessage = message.copyWith(
          readAt: DateTime.now(),
          isRead: true,
        );

        messages[messageIndex] = updatedMessage;
        await _saveAllRewardMessages(messages);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking message as read: $e');
      }
    }
  }

  /// Get user reward progress
  Future<UserRewardProgress> getUserProgress(String userId) async {
    try {
      final progressString = _prefs.getString('${_userProgressKey}_$userId');
      if (progressString == null) {
        return UserRewardProgress(userId: userId, lastUpdated: DateTime.now());
      }

      final progressJson = jsonDecode(progressString) as Map<String, dynamic>;
      return UserRewardProgress.fromJson(progressJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user progress: $e');
      }
      return UserRewardProgress(userId: userId, lastUpdated: DateTime.now());
    }
  }

  /// Get all stars for a user
  Future<List<Star>> getUserStars(String userId) async {
    try {
      final stars = await getAllStars();
      return stars.where((star) => star.awardedTo == userId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user stars: $e');
      }
      return [];
    }
  }

  /// Get all badges for a user
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final badges = await getAllBadges();
      return badges.where((badge) => badge.unlockedBy == userId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user badges: $e');
      }
      return [];
    }
  }

  /// Get all achievements for a user
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final achievements = await getAllAchievements();
      return achievements
          .where((achievement) => achievement.unlockedBy == userId)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user achievements: $e');
      }
      return [];
    }
  }

  /// Get unread reward messages for a user
  Future<List<RewardMessage>> getUnreadMessages(String userId) async {
    try {
      final messages = await getAllRewardMessages();
      return messages
          .where((message) => message.recipientId == userId && !message.isRead)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread messages: $e');
      }
      return [];
    }
  }

  /// Get all reward messages for a user
  Future<List<RewardMessage>> getUserMessages(String userId) async {
    try {
      final messages = await getAllRewardMessages();
      return messages
          .where((message) => message.recipientId == userId)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user messages: $e');
      }
      return [];
    }
  }

  /// Create a new badge
  Future<Badge> createBadge({
    required String name,
    required String description,
    required BadgeCategory category,
    required AchievementLevel level,
    required int requiredPoints,
    String? icon,
    String? color,
    Map<String, dynamic>? criteria,
  }) async {
    try {
      final badge = Badge(
        id: _generateId(),
        name: name,
        description: description,
        category: category,
        level: level,
        icon: icon,
        color: color,
        requiredPoints: requiredPoints,
        criteria: criteria ?? {},
      );

      await _saveBadge(badge);
      return badge;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating badge: $e');
      }
      rethrow;
    }
  }

  /// Create a new achievement
  Future<Achievement> createAchievement({
    required String name,
    required String description,
    required AchievementLevel level,
    required int requiredPoints,
    String? icon,
    String? color,
    Map<String, dynamic>? criteria,
  }) async {
    try {
      final achievement = Achievement(
        id: _generateId(),
        name: name,
        description: description,
        level: level,
        requiredPoints: requiredPoints,
        icon: icon,
        color: color,
        criteria: criteria ?? {},
      );

      await _saveAchievement(achievement);
      return achievement;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating achievement: $e');
      }
      rethrow;
    }
  }

  /// Initialize default badges and achievements
  Future<void> initializeDefaultRewards() async {
    try {
      // Create default badges
      await createBadge(
        name: 'Math Beginner',
        description: 'Complete your first math problem',
        category: BadgeCategory.math,
        level: AchievementLevel.bronze,
        requiredPoints: 10,
        icon: '🎯',
        color: '#FFD700',
      );

      await createBadge(
        name: 'Speed Demon',
        description: 'Solve 10 problems in under 5 minutes',
        category: BadgeCategory.speed,
        level: AchievementLevel.silver,
        requiredPoints: 50,
        icon: '⚡',
        color: '#FF6B6B',
      );

      await createBadge(
        name: 'Perfect Score',
        description: 'Get 100% accuracy on a quiz',
        category: BadgeCategory.accuracy,
        level: AchievementLevel.gold,
        requiredPoints: 100,
        icon: '🏆',
        color: '#4ECDC4',
      );

      // Create default achievements
      await createAchievement(
        name: 'First Steps',
        description: 'Complete your first learning session',
        level: AchievementLevel.bronze,
        requiredPoints: 25,
        icon: '👣',
        color: '#FFD700',
      );

      await createAchievement(
        name: 'Math Master',
        description: 'Earn 500 total points',
        level: AchievementLevel.silver,
        requiredPoints: 500,
        icon: '🧮',
        color: '#C0C0C0',
      );

      await createAchievement(
        name: 'Genius Level',
        description: 'Earn 1000 total points',
        level: AchievementLevel.gold,
        requiredPoints: 1000,
        icon: '🧠',
        color: '#FFD700',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing default rewards: $e');
      }
    }
  }

  /// Check for badge unlock
  Future<void> _checkForBadgeUnlock(String userId) async {
    try {
      final progress = await getUserProgress(userId);
      final badges = await getAllBadges();

      for (final badge in badges) {
        if (!badge.isUnlocked && progress.totalPoints >= badge.requiredPoints) {
          final unlockedBadge = badge.copyWith(
            unlockedAt: DateTime.now(),
            unlockedBy: userId,
            isUnlocked: true,
          );

          await _saveBadge(unlockedBadge);
          await _updateUserProgress(userId, badges: 1);

          // Send congratulatory message
          await sendRewardMessage(
            userId,
            '🎉 Badge Unlocked!',
            'Congratulations! You\'ve earned the "${badge.name}" badge!',
            badge.icon,
            badge.color,
            null,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for badge unlock: $e');
      }
    }
  }

  /// Check for achievement unlock
  Future<void> _checkForAchievementUnlock(String userId) async {
    try {
      final progress = await getUserProgress(userId);
      final achievements = await getAllAchievements();

      for (final achievement in achievements) {
        if (!achievement.isUnlocked &&
            progress.totalPoints >= achievement.requiredPoints) {
          final unlockedAchievement = achievement.copyWith(
            unlockedAt: DateTime.now(),
            unlockedBy: userId,
            isUnlocked: true,
            progress: 100,
          );

          await _saveAchievement(unlockedAchievement);
          await _updateUserProgress(userId, achievements: 1);

          // Send congratulatory message
          await sendRewardMessage(
            userId,
            '🏆 Achievement Unlocked!',
            'Amazing! You\'ve achieved "${achievement.name}"!',
            achievement.icon,
            achievement.color,
            null,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for achievement unlock: $e');
      }
    }
  }

  /// Update user progress
  Future<void> _updateUserProgress(
    String userId, {
    StarType? starType,
    int? points,
    int? badges,
    int? achievements,
  }) async {
    try {
      final currentProgress = await getUserProgress(userId);

      int newTotalPoints = currentProgress.totalPoints + (points ?? 0);
      int newTotalStars =
          currentProgress.totalStars + (starType != null ? 1 : 0);
      int newTotalBadges = currentProgress.totalBadges + (badges ?? 0);
      int newTotalAchievements =
          currentProgress.totalAchievements + (achievements ?? 0);

      final updatedProgress = currentProgress.copyWith(
        totalPoints: newTotalPoints,
        totalStars: newTotalStars,
        totalBadges: newTotalBadges,
        totalAchievements: newTotalAchievements,
        lastUpdated: DateTime.now(),
      );

      await _saveUserProgress(updatedProgress);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user progress: $e');
      }
    }
  }

  /// Get all rewards
  Future<List<Reward>> getAllRewards() async {
    try {
      final rewardsString = _prefs.getString(_rewardsKey);
      if (rewardsString == null) return [];

      final rewardsList = jsonDecode(rewardsString) as List;
      return rewardsList
          .map((reward) => Reward.fromJson(reward as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all rewards: $e');
      }
      return [];
    }
  }

  /// Get all badges
  Future<List<Badge>> getAllBadges() async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final badgesData = _hiveBox.get(_badgesKey);
        if (badgesData != null) {
          final badgesList = jsonDecode(badgesData as String) as List;
          return badgesList
              .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
              .toList();
        }
      }

      // Fallback to SharedPreferences
      final badgesString = _prefs.getString(_badgesKey);
      if (badgesString == null) return [];

      final badgesList = jsonDecode(badgesString) as List;
      return badgesList
          .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all badges: $e');
      }
      return [];
    }
  }

  /// Get all stars
  Future<List<Star>> getAllStars() async {
    try {
      final starsString = _prefs.getString(_starsKey);
      if (starsString == null) return [];

      final starsList = jsonDecode(starsString) as List;
      return starsList
          .map((star) => Star.fromJson(star as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all stars: $e');
      }
      return [];
    }
  }

  /// Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final achievementsString = _prefs.getString(_achievementsKey);
      if (achievementsString == null) return [];

      final achievementsList = jsonDecode(achievementsString) as List;
      return achievementsList
          .map(
            (achievement) =>
                Achievement.fromJson(achievement as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all achievements: $e');
      }
      return [];
    }
  }

  /// Get all reward messages
  Future<List<RewardMessage>> getAllRewardMessages() async {
    try {
      final messagesString = _prefs.getString(_messagesKey);
      if (messagesString == null) return [];

      final messagesList = jsonDecode(messagesString) as List;
      return messagesList
          .map(
            (message) =>
                RewardMessage.fromJson(message as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all reward messages: $e');
      }
      return [];
    }
  }

  /// Save reward
  Future<void> _saveReward(Reward reward) async {
    try {
      final rewards = await getAllRewards();
      rewards.add(reward);

      final rewardsJson = jsonEncode(rewards.map((r) => r.toJson()).toList());
      await _prefs.setString(_rewardsKey, rewardsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving reward: $e');
      }
    }
  }

  /// Save badge
  Future<void> _saveBadge(Badge badge) async {
    try {
      final badges = await getAllBadges();
      final existingIndex = badges.indexWhere((b) => b.id == badge.id);

      if (existingIndex >= 0) {
        badges[existingIndex] = badge;
      } else {
        badges.add(badge);
      }

      final badgesJson = jsonEncode(badges.map((b) => b.toJson()).toList());

      // Save to both Hive and SharedPreferences
      if (_hiveBox != null) {
        await _hiveBox.put(_badgesKey, badgesJson);
      }
      await _prefs.setString(_badgesKey, badgesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving badge: $e');
      }
    }
  }

  /// Save star
  Future<void> _saveStar(Star star) async {
    try {
      final stars = await getAllStars();
      stars.add(star);

      final starsJson = jsonEncode(stars.map((s) => s.toJson()).toList());
      await _prefs.setString(_starsKey, starsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving star: $e');
      }
    }
  }

  /// Save achievement
  Future<void> _saveAchievement(Achievement achievement) async {
    try {
      final achievements = await getAllAchievements();
      final existingIndex = achievements.indexWhere(
        (a) => a.id == achievement.id,
      );

      if (existingIndex >= 0) {
        achievements[existingIndex] = achievement;
      } else {
        achievements.add(achievement);
      }

      final achievementsJson = jsonEncode(
        achievements.map((a) => a.toJson()).toList(),
      );
      await _prefs.setString(_achievementsKey, achievementsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving achievement: $e');
      }
    }
  }

  /// Save reward message
  Future<void> _saveRewardMessage(RewardMessage message) async {
    try {
      final messages = await getAllRewardMessages();
      messages.add(message);

      final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      await _prefs.setString(_messagesKey, messagesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving reward message: $e');
      }
    }
  }

  /// Save all reward messages
  Future<void> _saveAllRewardMessages(List<RewardMessage> messages) async {
    try {
      final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      await _prefs.setString(_messagesKey, messagesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving all reward messages: $e');
      }
    }
  }

  /// Save user progress
  Future<void> _saveUserProgress(UserRewardProgress progress) async {
    try {
      final progressJson = jsonEncode(progress.toJson());
      await _prefs.setString(
        '${_userProgressKey}_${progress.userId}',
        progressJson,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user progress: $e');
      }
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}

/// Riverpod providers for reward management
final rewardServiceProvider = Provider<RewardService>((ref) {
  throw UnimplementedError('RewardService must be initialized');
});

final userProgressProvider = FutureProvider.family<UserRewardProgress, String>((
  ref,
  userId,
) async {
  final rewardService = ref.read(rewardServiceProvider);
  return rewardService.getUserProgress(userId);
});

final userStarsProvider = FutureProvider.family<List<Star>, String>((
  ref,
  userId,
) async {
  final rewardService = ref.read(rewardServiceProvider);
  return rewardService.getUserStars(userId);
});

final userBadgesProvider = FutureProvider.family<List<Badge>, String>((
  ref,
  userId,
) async {
  final rewardService = ref.read(rewardServiceProvider);
  return rewardService.getUserBadges(userId);
});

final userAchievementsProvider =
    FutureProvider.family<List<Achievement>, String>((ref, userId) async {
      final rewardService = ref.read(rewardServiceProvider);
      return rewardService.getUserAchievements(userId);
    });

final userMessagesProvider = FutureProvider.family<List<RewardMessage>, String>(
  (ref, userId) async {
    final rewardService = ref.read(rewardServiceProvider);
    return rewardService.getUserMessages(userId);
  },
);

final unreadMessagesProvider =
    FutureProvider.family<List<RewardMessage>, String>((ref, userId) async {
      final rewardService = ref.read(rewardServiceProvider);
      return rewardService.getUnreadMessages(userId);
    });
