import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Analytics event types
enum AnalyticsEventType {
  questionStarted,
  questionAnswered,
  questionSkipped,
  gameStarted,
  gameCompleted,
  sessionStarted,
  sessionEnded,
  rewardEarned,
  errorOccurred,
  featureUsed,
  timeSpent,
}

/// Analytics event model
class AnalyticsEvent {
  final String id;
  final AnalyticsEventType type;
  final String userId;
  final String? sessionId;
  final String? questionId;
  final String? topic;
  final String? category;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration? duration;
  final bool? isCorrect;
  final int? score;
  final String? errorMessage;

  const AnalyticsEvent({
    required this.id,
    required this.type,
    required this.userId,
    this.sessionId,
    this.questionId,
    this.topic,
    this.category,
    this.data = const {},
    required this.timestamp,
    this.duration,
    this.isCorrect,
    this.score,
    this.errorMessage,
  });

  AnalyticsEvent copyWith({
    String? id,
    AnalyticsEventType? type,
    String? userId,
    String? sessionId,
    String? questionId,
    String? topic,
    String? category,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    Duration? duration,
    bool? isCorrect,
    int? score,
    String? errorMessage,
  }) {
    return AnalyticsEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      questionId: questionId ?? this.questionId,
      topic: topic ?? this.topic,
      category: category ?? this.category,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'sessionId': sessionId,
      'questionId': questionId,
      'topic': topic,
      'category': category,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'isCorrect': isCorrect,
      'score': score,
      'errorMessage': errorMessage,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'] as String,
      type: AnalyticsEventType.values.firstWhere((e) => e.name == json['type']),
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String?,
      questionId: json['questionId'] as String?,
      topic: json['topic'] as String?,
      category: json['category'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      isCorrect: json['isCorrect'] as bool?,
      score: json['score'] as int?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Analytics service for Math Genius
class AnalyticsService {
  static const String _eventsKey = 'analytics_events';
  static const String _userStatsKey = 'user_analytics_stats';
  static const String _topicStatsKey = 'topic_analytics_stats';

  final SharedPreferences _prefs;
  Timer? _syncTimer;
  bool _isEnabled = true;

  AnalyticsService(this._prefs) {
    _startPeriodicSync();
  }

  /// Check if analytics is enabled
  bool get isEnabled => _isEnabled;

  /// Enable/disable analytics
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Track question started
  Future<void> trackQuestionStarted({
    required String userId,
    required String questionId,
    required String topic,
    String? category,
    String? sessionId,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.questionStarted,
        userId: userId,
        questionId: questionId,
        topic: topic,
        category: category,
        sessionId: sessionId,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Track question answered
  Future<void> trackQuestionAnswered({
    required String userId,
    required String questionId,
    required String topic,
    required bool isCorrect,
    required Duration timeSpent,
    int? score,
    String? category,
    String? sessionId,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.questionAnswered,
        userId: userId,
        questionId: questionId,
        topic: topic,
        category: category,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        duration: timeSpent,
        isCorrect: isCorrect,
        score: score,
      ),
    );
  }

  /// Track game started
  Future<void> trackGameStarted({
    required String userId,
    required String gameType,
    String? sessionId,
    Map<String, dynamic>? gameData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.gameStarted,
        userId: userId,
        sessionId: sessionId,
        category: gameType,
        data: gameData ?? {},
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Track game completed
  Future<void> trackGameCompleted({
    required String userId,
    required String gameType,
    required int finalScore,
    required Duration totalTime,
    String? sessionId,
    Map<String, dynamic>? gameData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.gameCompleted,
        userId: userId,
        sessionId: sessionId,
        category: gameType,
        data: gameData ?? {},
        timestamp: DateTime.now(),
        duration: totalTime,
        score: finalScore,
      ),
    );
  }

  /// Track session started
  Future<void> trackSessionStarted({
    required String userId,
    required String sessionType,
    String? sessionId,
    Map<String, dynamic>? sessionData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.sessionStarted,
        userId: userId,
        sessionId: sessionId,
        category: sessionType,
        data: sessionData ?? {},
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Track session ended
  Future<void> trackSessionEnded({
    required String userId,
    required String sessionType,
    required Duration totalTime,
    String? sessionId,
    Map<String, dynamic>? sessionData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.sessionEnded,
        userId: userId,
        sessionId: sessionId,
        category: sessionType,
        data: sessionData ?? {},
        timestamp: DateTime.now(),
        duration: totalTime,
      ),
    );
  }

  /// Track reward earned
  Future<void> trackRewardEarned({
    required String userId,
    required String rewardType,
    required String rewardId,
    int? points,
    String? category,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.rewardEarned,
        userId: userId,
        category: category,
        data: {
          'rewardType': rewardType,
          'rewardId': rewardId,
          'points': points,
        },
        timestamp: DateTime.now(),
        score: points,
      ),
    );
  }

  /// Track error occurred
  Future<void> trackError({
    required String userId,
    required String errorType,
    required String errorMessage,
    String? feature,
    Map<String, dynamic>? errorData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.errorOccurred,
        userId: userId,
        category: feature,
        data: errorData ?? {},
        timestamp: DateTime.now(),
        errorMessage: errorMessage,
      ),
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsed({
    required String userId,
    required String featureName,
    Duration? timeSpent,
    Map<String, dynamic>? featureData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.featureUsed,
        userId: userId,
        category: featureName,
        data: featureData ?? {},
        timestamp: DateTime.now(),
        duration: timeSpent,
      ),
    );
  }

  /// Track time spent
  Future<void> trackTimeSpent({
    required String userId,
    required String activity,
    required Duration timeSpent,
    String? category,
    Map<String, dynamic>? activityData,
  }) async {
    if (!_isEnabled) return;

    await _logEvent(
      AnalyticsEvent(
        id: _generateId(),
        type: AnalyticsEventType.timeSpent,
        userId: userId,
        category: category,
        data: activityData ?? {},
        timestamp: DateTime.now(),
        duration: timeSpent,
      ),
    );
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final events = await getAllEvents();
      final userEvents = events.where((e) => e.userId == userId).toList();

      final stats = <String, dynamic>{
        'totalQuestions': 0,
        'correctAnswers': 0,
        'incorrectAnswers': 0,
        'totalTimeSpent': Duration.zero,
        'averageTimePerQuestion': Duration.zero,
        'accuracyRate': 0.0,
        'topics': <String, dynamic>{},
        'recentActivity': <Map<String, dynamic>>[],
      };

      for (final event in userEvents) {
        switch (event.type) {
          case AnalyticsEventType.questionStarted:
          case AnalyticsEventType.questionSkipped:
          case AnalyticsEventType.gameStarted:
          case AnalyticsEventType.gameCompleted:
          case AnalyticsEventType.sessionStarted:
          case AnalyticsEventType.sessionEnded:
          case AnalyticsEventType.rewardEarned:
          case AnalyticsEventType.errorOccurred:
          case AnalyticsEventType.featureUsed:
            // Track these events but don't affect question stats
            break;
          case AnalyticsEventType.questionAnswered:
            stats['totalQuestions'] = (stats['totalQuestions'] as int) + 1;
            if (event.isCorrect == true) {
              stats['correctAnswers'] = (stats['correctAnswers'] as int) + 1;
            } else {
              stats['incorrectAnswers'] =
                  (stats['incorrectAnswers'] as int) + 1;
            }
            if (event.duration != null) {
              stats['totalTimeSpent'] =
                  (stats['totalTimeSpent'] as Duration) + event.duration!;
            }
            break;
          case AnalyticsEventType.timeSpent:
            if (event.duration != null) {
              stats['totalTimeSpent'] =
                  (stats['totalTimeSpent'] as Duration) + event.duration!;
            }
            break;
        }

        // Track topic performance
        if (event.topic != null) {
          if (!stats['topics'].containsKey(event.topic)) {
            stats['topics'][event.topic] = {
              'totalQuestions': 0,
              'correctAnswers': 0,
              'totalTime': Duration.zero,
            };
          }
          final topicStats =
              stats['topics'][event.topic] as Map<String, dynamic>;
          if (event.type == AnalyticsEventType.questionAnswered) {
            topicStats['totalQuestions'] =
                (topicStats['totalQuestions'] as int) + 1;
            if (event.isCorrect == true) {
              topicStats['correctAnswers'] =
                  (topicStats['correctAnswers'] as int) + 1;
            }
          }
          if (event.duration != null) {
            topicStats['totalTime'] =
                (topicStats['totalTime'] as Duration) + event.duration!;
          }
        }

        // Track recent activity
        if (event.timestamp.isAfter(
          DateTime.now().subtract(const Duration(days: 7)),
        )) {
          stats['recentActivity'].add(event.toJson());
        }
      }

      // Calculate averages
      final totalQuestions = stats['totalQuestions'] as int;
      if (totalQuestions > 0) {
        final totalTime = stats['totalTimeSpent'] as Duration;
        stats['averageTimePerQuestion'] = Duration(
          milliseconds: totalTime.inMilliseconds ~/ totalQuestions,
        );
        stats['accuracyRate'] =
            (stats['correctAnswers'] as int) / totalQuestions;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user stats: $e');
      }
      return {};
    }
  }

  /// Get topic statistics
  Future<Map<String, dynamic>> getTopicStats(String topic) async {
    try {
      final events = await getAllEvents();
      final topicEvents = events.where((e) => e.topic == topic).toList();

      final stats = <String, dynamic>{
        'totalQuestions': 0,
        'correctAnswers': 0,
        'averageTime': Duration.zero,
        'errorRate': 0.0,
        'improvementRate': 0.0,
      };

      int totalTime = 0;
      int questionCount = 0;

      for (final event in topicEvents) {
        if (event.type == AnalyticsEventType.questionAnswered) {
          stats['totalQuestions'] = (stats['totalQuestions'] as int) + 1;
          if (event.isCorrect == true) {
            stats['correctAnswers'] = (stats['correctAnswers'] as int) + 1;
          }
          if (event.duration != null) {
            totalTime += event.duration!.inMilliseconds;
            questionCount++;
          }
        }
      }

      if (questionCount > 0) {
        stats['averageTime'] = Duration(
          milliseconds: totalTime ~/ questionCount,
        );
        stats['errorRate'] =
            1.0 -
            ((stats['correctAnswers'] as int) /
                (stats['totalQuestions'] as int));
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting topic stats: $e');
      }
      return {};
    }
  }

  /// Get all analytics events
  Future<List<AnalyticsEvent>> getAllEvents() async {
    try {
      final eventsString = _prefs.getString(_eventsKey);
      if (eventsString == null) return [];

      final eventsList = jsonDecode(eventsString) as List;
      return eventsList
          .map(
            (event) => AnalyticsEvent.fromJson(event as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all events: $e');
      }
      return [];
    }
  }

  /// Clear old events (older than 30 days)
  Future<void> clearOldEvents() async {
    try {
      final events = await getAllEvents();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final recentEvents = events
          .where((e) => e.timestamp.isAfter(cutoffDate))
          .toList();

      final eventsJson = jsonEncode(
        recentEvents.map((e) => e.toJson()).toList(),
      );
      await _prefs.setString(_eventsKey, eventsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing old events: $e');
      }
    }
  }

  /// Log event to storage
  Future<void> _logEvent(AnalyticsEvent event) async {
    try {
      final events = await getAllEvents();
      events.add(event);

      // Limit to last 1000 events
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }

      final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
      await _prefs.setString(_eventsKey, eventsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging event: $e');
      }
    }
  }

  /// Start periodic sync (every 5 minutes)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      clearOldEvents();
    });
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }
}

/// Riverpod providers for analytics
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  throw UnimplementedError('AnalyticsService must be initialized');
});

final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return analyticsService.getUserStats(userId);
});

final topicStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  topic,
) async {
  final analyticsService = ref.read(analyticsServiceProvider);
  return analyticsService.getTopicStats(topic);
});
