import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../models/game_model.dart';

/// Advanced analytics for game performance and learning insights
class GameAnalyticsService {
  static const String _performanceDataKey = 'game_performance_data';
  static const String _learningInsightsKey = 'learning_insights';
  static const String _difficultyProgressionKey = 'difficulty_progression';
  static const String _topicMasteryKey = 'topic_mastery';

  final SharedPreferences _prefs;

  GameAnalyticsService(this._prefs);

  /// Track question performance
  Future<void> trackQuestionPerformance({
    required String userId,
    required String questionId,
    required GameCategory category,
    required GameDifficulty difficulty,
    required GradeLevel gradeLevel,
    required bool isCorrect,
    required Duration responseTime,
    required int hintsUsed,
    required String gameMode,
  }) async {
    try {
      final performanceData = {
        'userId': userId,
        'questionId': questionId,
        'category': category.name,
        'difficulty': difficulty.name,
        'gradeLevel': gradeLevel.name,
        'isCorrect': isCorrect,
        'responseTimeMs': responseTime.inMilliseconds,
        'hintsUsed': hintsUsed,
        'gameMode': gameMode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _savePerformanceData(performanceData);
      await _updateTopicMastery(userId, category, isCorrect, responseTime);
      await _updateDifficultyProgression(userId, difficulty, isCorrect);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error tracking question performance: $e');
      }
    }
  }

  /// Generate learning insights for a user
  Future<Map<String, dynamic>> generateLearningInsights(String userId) async {
    try {
      final performanceHistory = await _getUserPerformanceHistory(userId);
      if (performanceHistory.isEmpty) {
        return _getDefaultInsights();
      }

      final insights = {
        'overallAccuracy': _calculateOverallAccuracy(performanceHistory),
        'averageResponseTime': _calculateAverageResponseTime(
          performanceHistory,
        ),
        'strongestTopics': _identifyStrongestTopics(performanceHistory),
        'weakestTopics': _identifyWeakestTopics(performanceHistory),
        'difficultyRecommendation': _recommendDifficulty(performanceHistory),
        'learningTrends': _analyzeLearningTrends(performanceHistory),
        'timeOfDayPerformance': _analyzeTimeOfDayPerformance(
          performanceHistory,
        ),
        'streakData': _calculateStreaks(performanceHistory),
        'improvementAreas': _identifyImprovementAreas(performanceHistory),
        'nextChallenges': _suggestNextChallenges(performanceHistory),
      };

      await _saveLearningInsights(userId, insights);
      return insights;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating learning insights: $e');
      }
      return _getDefaultInsights();
    }
  }

  /// Calculate topic mastery levels
  Future<Map<GameCategory, double>> getTopicMasteryLevels(String userId) async {
    try {
      final masteryString = _prefs.getString('${_topicMasteryKey}_$userId');
      if (masteryString == null) return {};

      final masteryData = jsonDecode(masteryString) as Map<String, dynamic>;
      final masteryLevels = <GameCategory, double>{};

      for (final entry in masteryData.entries) {
        final category = GameCategory.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => GameCategory.addition,
        );
        masteryLevels[category] = (entry.value as num).toDouble();
      }

      return masteryLevels;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting topic mastery levels: $e');
      }
      return {};
    }
  }

  /// Get performance trends over time
  Future<List<Map<String, dynamic>>> getPerformanceTrends(
    String userId,
    Duration timeRange,
  ) async {
    try {
      final performanceHistory = await _getUserPerformanceHistory(userId);
      final cutoffTime = DateTime.now().subtract(timeRange);

      final recentPerformance = performanceHistory.where((data) {
        final timestamp = DateTime.parse(data['timestamp']);
        return timestamp.isAfter(cutoffTime);
      }).toList();

      // Group by day and calculate daily averages
      final dailyPerformance = <String, List<Map<String, dynamic>>>{};
      for (final data in recentPerformance) {
        final date = DateTime.parse(
          data['timestamp'],
        ).toIso8601String().substring(0, 10);
        dailyPerformance.putIfAbsent(date, () => []).add(data);
      }

      final trends = <Map<String, dynamic>>[];
      for (final entry in dailyPerformance.entries) {
        final dayData = entry.value;
        final accuracy =
            dayData.where((d) => d['isCorrect'] == true).length /
            dayData.length;
        final avgResponseTime =
            dayData
                .map((d) => d['responseTimeMs'] as int)
                .reduce((a, b) => a + b) /
            dayData.length;

        trends.add({
          'date': entry.key,
          'accuracy': accuracy,
          'averageResponseTime': avgResponseTime,
          'questionsAnswered': dayData.length,
          'categories': dayData.map((d) => d['category']).toSet().toList(),
        });
      }

      trends.sort((a, b) => a['date'].compareTo(b['date']));
      return trends;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting performance trends: $e');
      }
      return [];
    }
  }

  /// Predict optimal difficulty for user
  Future<GameDifficulty> predictOptimalDifficulty(
    String userId,
    GameCategory category,
  ) async {
    try {
      final performanceHistory = await _getUserPerformanceHistory(userId);
      final categoryHistory = performanceHistory
          .where((data) => data['category'] == category.name)
          .toList();

      if (categoryHistory.isEmpty) {
        return GameDifficulty.normal; // Default for new users
      }

      // Analyze recent performance (last 20 questions)
      final recentHistory = categoryHistory.take(20).toList();
      final accuracy =
          recentHistory.where((d) => d['isCorrect'] == true).length /
          recentHistory.length;
      final avgResponseTime =
          recentHistory
              .map((d) => d['responseTimeMs'] as int)
              .reduce((a, b) => a + b) /
          recentHistory.length;

      // Decision logic based on performance
      if (accuracy >= 0.9 && avgResponseTime < 15000) {
        return GameDifficulty.quantum; // Excellent performance
      } else if (accuracy >= 0.8 && avgResponseTime < 20000) {
        return GameDifficulty.genius; // Good performance
      } else if (accuracy >= 0.7 && avgResponseTime < 30000) {
        return GameDifficulty.normal; // Average performance
      } else {
        return GameDifficulty.easy; // Needs more practice
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error predicting optimal difficulty: $e');
      }
      return GameDifficulty.normal;
    }
  }

  /// Generate personalized learning recommendations
  Future<List<String>> generateLearningRecommendations(String userId) async {
    try {
      final insights = await generateLearningInsights(userId);
      final recommendations = <String>[];

      // Accuracy-based recommendations
      final accuracy = insights['overallAccuracy'] as double;
      if (accuracy < 0.6) {
        recommendations.add(
          'Focus on fundamental concepts with easier questions',
        );
        recommendations.add(
          'Use visual aids and manipulatives for better understanding',
        );
      } else if (accuracy > 0.9) {
        recommendations.add('Ready for more challenging problems!');
        recommendations.add(
          'Try advanced topics to expand mathematical thinking',
        );
      }

      // Response time recommendations
      final avgResponseTime = insights['averageResponseTime'] as double;
      if (avgResponseTime > 45000) {
        // > 45 seconds
        recommendations.add(
          'Take time to think through problems - accuracy is more important than speed',
        );
      } else if (avgResponseTime < 10000) {
        // < 10 seconds
        recommendations.add(
          'Excellent speed! Try more complex problems for greater challenge',
        );
      }

      // Topic-specific recommendations
      final weakTopics = insights['weakestTopics'] as List<String>;
      if (weakTopics.isNotEmpty) {
        recommendations.add(
          'Practice ${weakTopics.first} with additional exercises',
        );
      }

      final strongTopics = insights['strongestTopics'] as List<String>;
      if (strongTopics.isNotEmpty) {
        recommendations.add(
          'Excellent work in ${strongTopics.first}! Try related advanced topics',
        );
      }

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating learning recommendations: $e');
      }
      return ['Continue practicing to improve your math skills!'];
    }
  }

  // Helper methods for analytics calculations
  double _calculateOverallAccuracy(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.0;
    final correctCount = history.where((d) => d['isCorrect'] == true).length;
    return correctCount / history.length;
  }

  double _calculateAverageResponseTime(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.0;
    final totalTime = history
        .map((d) => d['responseTimeMs'] as int)
        .reduce((a, b) => a + b);
    return totalTime / history.length;
  }

  List<String> _identifyStrongestTopics(List<Map<String, dynamic>> history) {
    final topicAccuracy = <String, List<bool>>{};

    for (final data in history) {
      final category = data['category'] as String;
      final isCorrect = data['isCorrect'] as bool;
      topicAccuracy.putIfAbsent(category, () => []).add(isCorrect);
    }

    final sortedTopics = topicAccuracy.entries.toList()
      ..sort((a, b) {
        final aAccuracy = a.value.where((c) => c).length / a.value.length;
        final bAccuracy = b.value.where((c) => c).length / b.value.length;
        return bAccuracy.compareTo(aAccuracy);
      });

    return sortedTopics.take(3).map((e) => e.key).toList();
  }

  List<String> _identifyWeakestTopics(List<Map<String, dynamic>> history) {
    final topicAccuracy = <String, List<bool>>{};

    for (final data in history) {
      final category = data['category'] as String;
      final isCorrect = data['isCorrect'] as bool;
      topicAccuracy.putIfAbsent(category, () => []).add(isCorrect);
    }

    final sortedTopics = topicAccuracy.entries.toList()
      ..sort((a, b) {
        final aAccuracy = a.value.where((c) => c).length / a.value.length;
        final bAccuracy = b.value.where((c) => c).length / b.value.length;
        return aAccuracy.compareTo(bAccuracy);
      });

    return sortedTopics.take(3).map((e) => e.key).toList();
  }

  GameDifficulty _recommendDifficulty(List<Map<String, dynamic>> history) {
    final recentHistory = history.take(10).toList();
    if (recentHistory.isEmpty) return GameDifficulty.normal;

    final accuracy = _calculateOverallAccuracy(recentHistory);
    final avgTime = _calculateAverageResponseTime(recentHistory);

    if (accuracy >= 0.9 && avgTime < 15000) return GameDifficulty.quantum;
    if (accuracy >= 0.8 && avgTime < 20000) return GameDifficulty.genius;
    if (accuracy >= 0.7) return GameDifficulty.normal;
    return GameDifficulty.easy;
  }

  Map<String, dynamic> _analyzeLearningTrends(
    List<Map<String, dynamic>> history,
  ) {
    if (history.length < 10) return {'trend': 'insufficient_data'};

    final recent = history.take(10).toList();
    final older = history.skip(10).take(10).toList();

    if (older.isEmpty) return {'trend': 'insufficient_data'};

    final recentAccuracy = _calculateOverallAccuracy(recent);
    final olderAccuracy = _calculateOverallAccuracy(older);

    final improvement = recentAccuracy - olderAccuracy;

    if (improvement > 0.1) {
      return {'trend': 'improving', 'improvement': improvement};
    } else if (improvement < -0.1) {
      return {'trend': 'declining', 'decline': -improvement};
    } else {
      return {'trend': 'stable', 'accuracy': recentAccuracy};
    }
  }

  Map<String, double> _analyzeTimeOfDayPerformance(
    List<Map<String, dynamic>> history,
  ) {
    final timePerformance = <int, List<bool>>{};

    for (final data in history) {
      final timestamp = DateTime.parse(data['timestamp']);
      final hour = timestamp.hour;
      final isCorrect = data['isCorrect'] as bool;
      timePerformance.putIfAbsent(hour, () => []).add(isCorrect);
    }

    final hourlyAccuracy = <String, double>{};
    for (final entry in timePerformance.entries) {
      final accuracy = entry.value.where((c) => c).length / entry.value.length;
      hourlyAccuracy['${entry.key}:00'] = accuracy;
    }

    return hourlyAccuracy;
  }

  Map<String, int> _calculateStreaks(List<Map<String, dynamic>> history) {
    int currentStreak = 0;
    int longestStreak = 0;
    int currentWrongStreak = 0;

    for (final data in history.reversed) {
      final isCorrect = data['isCorrect'] as bool;

      if (isCorrect) {
        currentStreak++;
        longestStreak = math.max(longestStreak, currentStreak);
        currentWrongStreak = 0;
      } else {
        currentStreak = 0;
        currentWrongStreak++;
      }
    }

    return {
      'currentCorrectStreak': currentStreak,
      'longestCorrectStreak': longestStreak,
      'currentWrongStreak': currentWrongStreak,
    };
  }

  List<String> _identifyImprovementAreas(List<Map<String, dynamic>> history) {
    final areas = <String>[];

    // Analyze response times
    final avgTime = _calculateAverageResponseTime(history);
    if (avgTime > 30000) {
      areas.add('Speed up problem-solving with practice');
    }

    // Analyze accuracy patterns
    final accuracy = _calculateOverallAccuracy(history);
    if (accuracy < 0.7) {
      areas.add('Focus on accuracy before attempting harder problems');
    }

    // Analyze hint usage
    final avgHints = history.isEmpty
        ? 0.0
        : history
                  .map((d) => d['hintsUsed'] as int? ?? 0)
                  .reduce((a, b) => a + b) /
              history.length;
    if (avgHints > 2) {
      areas.add('Try solving problems independently before using hints');
    }

    return areas;
  }

  List<String> _suggestNextChallenges(List<Map<String, dynamic>> history) {
    final challenges = <String>[];
    final strongTopics = _identifyStrongestTopics(history);

    if (strongTopics.contains('addition')) {
      challenges.add('Try two-digit addition with regrouping');
    }
    if (strongTopics.contains('multiplication')) {
      challenges.add('Explore multiplication word problems');
    }
    if (strongTopics.contains('fractions')) {
      challenges.add('Practice adding and subtracting fractions');
    }

    return challenges;
  }

  // Storage helper methods
  Future<void> _savePerformanceData(Map<String, dynamic> data) async {
    try {
      final existingData = await _getUserPerformanceHistory(data['userId']);
      existingData.insert(0, data);

      // Keep only last 1000 entries
      if (existingData.length > 1000) {
        existingData.removeRange(1000, existingData.length);
      }

      await _prefs.setString(
        '${_performanceDataKey}_${data['userId']}',
        jsonEncode(existingData),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving performance data: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getUserPerformanceHistory(
    String userId,
  ) async {
    try {
      final dataString = _prefs.getString('${_performanceDataKey}_$userId');
      if (dataString == null) return [];

      final dataList = jsonDecode(dataString) as List;
      return dataList.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user performance history: $e');
      }
      return [];
    }
  }

  Future<void> _updateTopicMastery(
    String userId,
    GameCategory category,
    bool isCorrect,
    Duration responseTime,
  ) async {
    try {
      final masteryLevels = await getTopicMasteryLevels(userId);
      final currentMastery = masteryLevels[category] ?? 50.0; // Start at 50%

      // Calculate mastery adjustment based on performance
      double adjustment = 0.0;
      if (isCorrect) {
        adjustment = 2.0; // Base increase for correct answer
        if (responseTime.inMilliseconds < 15000) {
          adjustment += 1.0; // Bonus for quick response
        }
      } else {
        adjustment = -1.5; // Decrease for incorrect answer
      }

      final newMastery = (currentMastery + adjustment).clamp(0.0, 100.0);
      masteryLevels[category] = newMastery;

      // Save updated mastery levels
      final masteryData = <String, double>{};
      for (final entry in masteryLevels.entries) {
        masteryData[entry.key.name] = entry.value;
      }

      await _prefs.setString(
        '${_topicMasteryKey}_$userId',
        jsonEncode(masteryData),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating topic mastery: $e');
      }
    }
  }

  Future<void> _updateDifficultyProgression(
    String userId,
    GameDifficulty difficulty,
    bool isCorrect,
  ) async {
    try {
      final progressionString = _prefs.getString(
        '${_difficultyProgressionKey}_$userId',
      );
      final progression = progressionString != null
          ? Map<String, dynamic>.from(jsonDecode(progressionString))
          : <String, dynamic>{};

      final difficultyKey = difficulty.name;
      final currentData =
          progression[difficultyKey] ?? {'attempts': 0, 'correct': 0};

      currentData['attempts'] = (currentData['attempts'] as int) + 1;
      if (isCorrect) {
        currentData['correct'] = (currentData['correct'] as int) + 1;
      }

      progression[difficultyKey] = currentData;

      await _prefs.setString(
        '${_difficultyProgressionKey}_$userId',
        jsonEncode(progression),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating difficulty progression: $e');
      }
    }
  }

  Future<void> _saveLearningInsights(
    String userId,
    Map<String, dynamic> insights,
  ) async {
    try {
      await _prefs.setString(
        '${_learningInsightsKey}_$userId',
        jsonEncode(insights),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving learning insights: $e');
      }
    }
  }

  Map<String, dynamic> _getDefaultInsights() {
    return {
      'overallAccuracy': 0.0,
      'averageResponseTime': 30000.0,
      'strongestTopics': <String>[],
      'weakestTopics': <String>[],
      'difficultyRecommendation': GameDifficulty.normal.name,
      'learningTrends': {'trend': 'new_user'},
      'timeOfDayPerformance': <String, double>{},
      'streakData': {'currentCorrectStreak': 0, 'longestCorrectStreak': 0},
      'improvementAreas': ['Start with basic problems to build confidence'],
      'nextChallenges': ['Begin with addition and subtraction'],
    };
  }
}

/// Provider for game analytics service
final gameAnalyticsServiceProvider = Provider<GameAnalyticsService>((ref) {
  throw UnimplementedError('GameAnalyticsService must be initialized');
});
