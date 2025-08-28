import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Models
import '../models/class_model.dart';

// Game models for difficulty levels
import '../../game/models/game_model.dart';

/// Comprehensive class management service for Math Genius
class ClassManagementService {
  static const String _userClassAccessKey = 'user_class_access';
  static const String _availableClassesKey = 'available_classes';
  static const String _userProgressKey = 'user_class_progress';

  final SharedPreferences _prefs;

  ClassManagementService(this._prefs);

  /// Initialize user's class access during registration
  Future<void> initializeUserClassAccess(
    String userId,
    ClassLevel selectedClass,
  ) async {
    try {
      // Get all available classes
      final allClasses = await _getAvailableClasses();

      // Create user access for all classes
      final userClassAccess = <UserClassAccess>[];

      for (final mathClass in allClasses) {
        final status = mathClass.level == selectedClass
            ? ClassStatus.active
            : ClassStatus.locked;

        final access = UserClassAccess(
          userId: userId,
          classId: mathClass.id,
          status: status,
          unlockedAt: DateTime.now(),
          currentScore: 0,
          maxScore: _calculateMaxScore(mathClass),
          completionPercentage: 0.0,
          categoryScores: _initializeCategoryScores(mathClass),
          categoryCompletion: _initializeCategoryCompletion(mathClass),
          achievements: [],
          isActive: status == ClassStatus.active,
        );

        userClassAccess.add(access);
      }

      // Save user's class access
      await _saveUserClassAccess(userId, userClassAccess);

      if (kDebugMode) {
        print(
          'Initialized class access for user $userId with selected class: ${selectedClass.name}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing user class access: $e');
      }
      rethrow;
    }
  }

  /// Get user's class access and progress
  Future<List<UserClassAccess>> getUserClassAccess(String userId) async {
    try {
      final accessString = _prefs.getString('${_userClassAccessKey}_$userId');
      if (accessString == null) return [];

      final accessList = jsonDecode(accessString) as List;
      return accessList
          .map(
            (access) =>
                UserClassAccess.fromJson(access as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user class access: $e');
      }
      return [];
    }
  }

  /// Get user's active class
  Future<UserClassAccess?> getUserActiveClass(String userId) async {
    try {
      final allAccess = await getUserClassAccess(userId);
      return allAccess.firstWhere((access) => access.isActive);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user active class: $e');
      }
      return null;
    }
  }

  /// Check if user can upgrade to a specific class
  Future<bool> canUpgradeToClass(String userId, String targetClassId) async {
    try {
      final userAccess = await getUserClassAccess(userId);
      final targetAccess = userAccess.firstWhere(
        (access) => access.classId == targetClassId,
      );

      if (targetAccess.status == ClassStatus.locked) {
        // Check prerequisites
        final allClasses = await _getAvailableClasses();
        final targetClass = allClasses.firstWhere(
          (cls) => cls.id == targetClassId,
        );

        if (targetClass.prerequisiteClass != null) {
          final prerequisiteAccess = userAccess.firstWhere(
            (access) => access.classId == targetClass.prerequisiteClass,
          );

          // Check if prerequisite class is completed with required score
          return prerequisiteAccess.status == ClassStatus.completed &&
              prerequisiteAccess.currentScore >= targetClass.requiredScore;
        }
      }

      return targetAccess.status != ClassStatus.locked;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking upgrade eligibility: $e');
      }
      return false;
    }
  }

  /// Upgrade user to a specific class
  Future<bool> upgradeToClass(String userId, String targetClassId) async {
    try {
      final canUpgrade = await canUpgradeToClass(userId, targetClassId);
      if (!canUpgrade) {
        if (kDebugMode) {
          print('User $userId cannot upgrade to class $targetClassId');
        }
        return false;
      }

      final userAccess = await getUserClassAccess(userId);
      final updatedAccess = userAccess.map((access) {
        if (access.classId == targetClassId) {
          return access.copyWith(
            status: ClassStatus.active,
            isActive: true,
            unlockedAt: DateTime.now(),
          );
        } else if (access.isActive) {
          return access.copyWith(status: ClassStatus.unlocked, isActive: false);
        }
        return access;
      }).toList();

      await _saveUserClassAccess(userId, updatedAccess);

      if (kDebugMode) {
        print('User $userId upgraded to class $targetClassId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error upgrading user to class: $e');
      }
      return false;
    }
  }

  /// Update user's class progress
  Future<void> updateClassProgress(
    String userId,
    String classId,
    ClassContentCategory category,
    int score,
    bool completed,
  ) async {
    try {
      final userAccess = await getUserClassAccess(userId);
      final classAccess = userAccess.firstWhere(
        (access) => access.classId == classId,
      );

      // Update category scores and completion
      final updatedCategoryScores = Map<ClassContentCategory, int>.from(
        classAccess.categoryScores,
      );
      final updatedCategoryCompletion = Map<ClassContentCategory, bool>.from(
        classAccess.categoryCompletion,
      );

      updatedCategoryScores[category] = score;
      updatedCategoryCompletion[category] = completed;

      // Calculate new total score and completion percentage
      final totalScore = updatedCategoryScores.values.reduce((a, b) => a + b);
      final completedCategories = updatedCategoryCompletion.values
          .where((completed) => completed)
          .length;
      final totalCategories = updatedCategoryCompletion.length;
      final completionPercentage = totalCategories > 0
          ? (completedCategories / totalCategories) * 100
          : 0.0;

      // Check if class is completed
      final newStatus =
          completionPercentage >= 80.0 &&
              totalScore >= classAccess.maxScore * 0.8
          ? ClassStatus.completed
          : classAccess.status;

      final updatedAccess = classAccess.copyWith(
        currentScore: totalScore,
        completionPercentage: completionPercentage,
        categoryScores: updatedCategoryScores,
        categoryCompletion: updatedCategoryCompletion,
        completedAt: newStatus == ClassStatus.completed
            ? DateTime.now()
            : classAccess.completedAt,
        status: newStatus,
      );

      // Update the access list
      final updatedUserAccess = userAccess.map((access) {
        return access.classId == classId ? updatedAccess : access;
      }).toList();

      await _saveUserClassAccess(userId, updatedUserAccess);

      if (kDebugMode) {
        print(
          'Updated progress for user $userId in class $classId: $completionPercentage% complete',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating class progress: $e');
      }
    }
  }

  /// Get available classes for the system
  Future<List<MathClass>> _getAvailableClasses() async {
    // This would typically come from a database or API
    // For now, we'll return predefined classes
    return [
      MathClass(
        id: 'prek_math',
        level: ClassLevel.preK,
        name: 'Pre-K Mathematics',
        description: 'Introduction to basic counting and number recognition',
        displayName: 'Pre-K',
        minAge: 3,
        maxAge: 5,
        availableCategories: [
          ClassContentCategory.arithmetic,
          ClassContentCategory.mentalMath,
        ],
        learningObjectives: {
          ClassContentCategory.arithmetic: [
            'Count to 10',
            'Number recognition',
            'Basic addition',
          ],
          ClassContentCategory.mentalMath: [
            'Quick counting',
            'Number patterns',
          ],
        },
        questionCounts: {
          ClassContentCategory.arithmetic: 10,
          ClassContentCategory.mentalMath: 8,
        },
        difficultyLevels: {
          ClassContentCategory.arithmetic: GameDifficulty.easy,
          ClassContentCategory.mentalMath: GameDifficulty.easy,
        },
      ),
      MathClass(
        id: 'kindergarten_math',
        level: ClassLevel.kindergarten,
        name: 'Kindergarten Mathematics',
        description: 'Basic arithmetic and number sense development',
        displayName: 'Kindergarten',
        minAge: 5,
        maxAge: 6,
        availableCategories: [
          ClassContentCategory.arithmetic,
          ClassContentCategory.wordProblems,
        ],
        learningObjectives: {
          ClassContentCategory.arithmetic: [
            'Addition and subtraction',
            'Number bonds',
            'Place value',
          ],
          ClassContentCategory.wordProblems: [
            'Simple word problems',
            'Real-world applications',
          ],
        },
        questionCounts: {
          ClassContentCategory.arithmetic: 15,
          ClassContentCategory.wordProblems: 10,
        },
        difficultyLevels: {
          ClassContentCategory.arithmetic: GameDifficulty.easy,
          ClassContentCategory.wordProblems: GameDifficulty.easy,
        },
        prerequisiteClass: 'prek_math',
        requiredScore: 70,
      ),
      MathClass(
        id: 'grade1_math',
        level: ClassLevel.grade1,
        name: 'Grade 1 Mathematics',
        description: 'First grade math concepts and problem solving',
        displayName: 'Grade 1',
        minAge: 6,
        maxAge: 7,
        availableCategories: [
          ClassContentCategory.arithmetic,
          ClassContentCategory.geometry,
          ClassContentCategory.wordProblems,
        ],
        learningObjectives: {
          ClassContentCategory.arithmetic: [
            'Two-digit addition',
            'Subtraction strategies',
            'Number patterns',
          ],
          ClassContentCategory.geometry: [
            'Basic shapes',
            'Measurement',
            'Spatial awareness',
          ],
          ClassContentCategory.wordProblems: [
            'Multi-step problems',
            'Critical thinking',
          ],
        },
        questionCounts: {
          ClassContentCategory.arithmetic: 20,
          ClassContentCategory.geometry: 15,
          ClassContentCategory.wordProblems: 12,
        },
        difficultyLevels: {
          ClassContentCategory.arithmetic: GameDifficulty.normal,
          ClassContentCategory.geometry: GameDifficulty.easy,
          ClassContentCategory.wordProblems: GameDifficulty.normal,
        },
        prerequisiteClass: 'kindergarten_math',
        requiredScore: 75,
      ),
      // Add more classes for grades 2-12...
    ];
  }

  /// Cache available classes for offline access
  Future<void> cacheAvailableClasses(List<MathClass> classes) async {
    try {
      final classesJson = classes.map((cls) => cls.toJson()).toList();
      await _prefs.setString(_availableClassesKey, jsonEncode(classesJson));
    } catch (e) {
      if (kDebugMode) {
        print('Error caching available classes: $e');
      }
    }
  }

  /// Get cached available classes
  Future<List<MathClass>?> getCachedAvailableClasses() async {
    try {
      final classesString = _prefs.getString(_availableClassesKey);
      if (classesString == null) return null;

      final classesList = jsonDecode(classesString) as List;
      return classesList
          .map((cls) => MathClass.fromJson(cls as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached available classes: $e');
      }
      return null;
    }
  }

  /// Calculate maximum score for a class
  int _calculateMaxScore(MathClass mathClass) {
    int totalScore = 0;
    for (final category in mathClass.availableCategories) {
      final questionCount = mathClass.questionCounts[category] ?? 10;
      totalScore += questionCount * 10; // 10 points per question
    }
    return totalScore;
  }

  /// Initialize category scores
  Map<ClassContentCategory, int> _initializeCategoryScores(
    MathClass mathClass,
  ) {
    final scores = <ClassContentCategory, int>{};
    for (final category in mathClass.availableCategories) {
      scores[category] = 0;
    }
    return scores;
  }

  /// Initialize category completion status
  Map<ClassContentCategory, bool> _initializeCategoryCompletion(
    MathClass mathClass,
  ) {
    final completion = <ClassContentCategory, bool>{};
    for (final category in mathClass.availableCategories) {
      completion[category] = false;
    }
    return completion;
  }

  /// Save user's class access
  Future<void> _saveUserClassAccess(
    String userId,
    List<UserClassAccess> access,
  ) async {
    try {
      await _prefs.setString(
        '${_userClassAccessKey}_$userId',
        jsonEncode(access.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user class access: $e');
      }
    }
  }

  /// Save user's detailed progress data
  Future<void> saveUserProgress(
    String userId,
    Map<String, dynamic> progressData,
  ) async {
    try {
      await _prefs.setString(
        '${_userProgressKey}_$userId',
        jsonEncode(progressData),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user progress: $e');
      }
    }
  }

  /// Get user's detailed progress data
  Future<Map<String, dynamic>?> getUserProgress(String userId) async {
    try {
      final progressString = _prefs.getString('${_userProgressKey}_$userId');
      if (progressString == null) return null;
      return jsonDecode(progressString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user progress: $e');
      }
      return null;
    }
  }
}

/// Riverpod providers for class management
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences should be initialized in main.dart',
  );
});

final classManagementServiceProvider = Provider<ClassManagementService>((ref) {
  return ClassManagementService(ref.read(sharedPreferencesProvider));
});

final userClassAccessProvider =
    FutureProvider.family<List<UserClassAccess>, String>((ref, userId) {
      return ref
          .read(classManagementServiceProvider)
          .getUserClassAccess(userId);
    });

final userActiveClassProvider = FutureProvider.family<UserClassAccess?, String>(
  (ref, userId) {
    return ref.read(classManagementServiceProvider).getUserActiveClass(userId);
  },
);
