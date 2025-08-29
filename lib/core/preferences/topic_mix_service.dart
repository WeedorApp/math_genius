import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Game models
import '../../features/game/models/game_model.dart';

/// Topic mixing options for comprehensive learning
enum TopicMixMode {
  single,           // Single topic only
  basicOperations,  // Addition, Subtraction, Multiplication, Division
  gradeLevel,       // Topics appropriate for grade level
  customMix,        // User-selected topic combination
  comprehensive,    // All available topics
  adaptive,         // AI-selected based on performance
}

/// Topic mix configuration
class TopicMixConfiguration {
  final TopicMixMode mode;
  final List<GameCategory> selectedTopics;
  final Map<GameCategory, double> topicWeights; // 0.0 to 1.0
  final bool enableAdaptiveWeighting;
  final int minTopicsPerSession;
  final int maxTopicsPerSession;

  const TopicMixConfiguration({
    this.mode = TopicMixMode.single,
    this.selectedTopics = const [],
    this.topicWeights = const {},
    this.enableAdaptiveWeighting = true,
    this.minTopicsPerSession = 1,
    this.maxTopicsPerSession = 3,
  });

  TopicMixConfiguration copyWith({
    TopicMixMode? mode,
    List<GameCategory>? selectedTopics,
    Map<GameCategory, double>? topicWeights,
    bool? enableAdaptiveWeighting,
    int? minTopicsPerSession,
    int? maxTopicsPerSession,
  }) {
    return TopicMixConfiguration(
      mode: mode ?? this.mode,
      selectedTopics: selectedTopics ?? this.selectedTopics,
      topicWeights: topicWeights ?? this.topicWeights,
      enableAdaptiveWeighting: enableAdaptiveWeighting ?? this.enableAdaptiveWeighting,
      minTopicsPerSession: minTopicsPerSession ?? this.minTopicsPerSession,
      maxTopicsPerSession: maxTopicsPerSession ?? this.maxTopicsPerSession,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'selectedTopics': selectedTopics.map((t) => t.name).toList(),
      'topicWeights': topicWeights.map((k, v) => MapEntry(k.name, v)),
      'enableAdaptiveWeighting': enableAdaptiveWeighting,
      'minTopicsPerSession': minTopicsPerSession,
      'maxTopicsPerSession': maxTopicsPerSession,
    };
  }

  factory TopicMixConfiguration.fromJson(Map<String, dynamic> json) {
    return TopicMixConfiguration(
      mode: TopicMixMode.values.byName(json['mode'] ?? 'single'),
      selectedTopics: (json['selectedTopics'] as List<dynamic>? ?? [])
          .map((t) => GameCategory.values.byName(t))
          .toList(),
      topicWeights: Map<GameCategory, double>.from(
        (json['topicWeights'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(GameCategory.values.byName(k), (v as num).toDouble()),
        ),
      ),
      enableAdaptiveWeighting: json['enableAdaptiveWeighting'] ?? true,
      minTopicsPerSession: json['minTopicsPerSession'] ?? 1,
      maxTopicsPerSession: json['maxTopicsPerSession'] ?? 3,
    );
  }
}

/// Service for managing topic mixing and selection
class TopicMixService {
  static const String _topicMixKey = 'topic_mix_configuration';
  // Future: _customTopicsKey for advanced custom topic selection

  final SharedPreferences _prefs;

  TopicMixService(this._prefs);

  /// Get current topic mix configuration
  Future<TopicMixConfiguration> getTopicMixConfiguration() async {
    try {
      final configString = _prefs.getString(_topicMixKey);
      if (configString == null) {
        return const TopicMixConfiguration();
      }
      return TopicMixConfiguration.fromJson(jsonDecode(configString));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting topic mix configuration: $e');
      }
      return const TopicMixConfiguration();
    }
  }

  /// Save topic mix configuration
  Future<void> saveTopicMixConfiguration(TopicMixConfiguration config) async {
    try {
      await _prefs.setString(_topicMixKey, jsonEncode(config.toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving topic mix configuration: $e');
      }
    }
  }

  /// Get topics for a game session based on configuration
  List<GameCategory> getTopicsForSession(TopicMixConfiguration config) {
    switch (config.mode) {
      case TopicMixMode.single:
        return config.selectedTopics.isNotEmpty 
            ? [config.selectedTopics.first] 
            : [GameCategory.addition];
      
      case TopicMixMode.basicOperations:
        return [
          GameCategory.addition,
          GameCategory.subtraction,
          GameCategory.multiplication,
          GameCategory.division,
        ];
      
      case TopicMixMode.gradeLevel:
        // This would be based on user's grade level
        return _getGradeLevelTopics(5); // Default grade 5
      
      case TopicMixMode.customMix:
        return config.selectedTopics.isNotEmpty 
            ? config.selectedTopics 
            : [GameCategory.addition];
      
      case TopicMixMode.comprehensive:
        return GameCategory.values;
      
      case TopicMixMode.adaptive:
        // This would be based on user performance analytics
        return _getAdaptiveTopics(config);
    }
  }

  /// Get topics appropriate for grade level
  List<GameCategory> _getGradeLevelTopics(int grade) {
    if (grade <= 2) {
      return [
        GameCategory.addition,
        GameCategory.subtraction,
        GameCategory.patterns,
      ];
    } else if (grade <= 5) {
      return [
        GameCategory.addition,
        GameCategory.subtraction,
        GameCategory.multiplication,
        GameCategory.division,
        GameCategory.fractions,
        GameCategory.measurement,
      ];
    } else if (grade <= 8) {
      return [
        GameCategory.multiplication,
        GameCategory.division,
        GameCategory.fractions,
        GameCategory.decimals,
        GameCategory.percentages,
        GameCategory.algebra,
        GameCategory.geometry,
      ];
    } else {
      return [
        GameCategory.algebra,
        GameCategory.geometry,
        GameCategory.calculus,
        GameCategory.dataAnalysis,
        GameCategory.wordProblems,
      ];
    }
  }

  /// Get adaptive topics based on performance
  List<GameCategory> _getAdaptiveTopics(TopicMixConfiguration config) {
    // This would analyze user performance and select topics they need practice with
    // For now, return a balanced mix
    return [
      GameCategory.addition,
      GameCategory.multiplication,
      GameCategory.fractions,
    ];
  }

  /// Generate mixed questions for a session
  List<GameCategory> generateSessionTopics(
    TopicMixConfiguration config,
    int totalQuestions,
  ) {
    final availableTopics = getTopicsForSession(config);
    final sessionTopics = <GameCategory>[];
    
    if (availableTopics.length == 1) {
      // Single topic - use it for all questions
      return List.filled(totalQuestions, availableTopics.first);
    }
    
    // Multiple topics - distribute based on weights or evenly
    final topicsToUse = availableTopics.take(config.maxTopicsPerSession).toList();
    
    if (config.topicWeights.isNotEmpty) {
      // Use weighted distribution
      sessionTopics.addAll(_distributeTopicsWeighted(topicsToUse, config.topicWeights, totalQuestions));
    } else {
      // Even distribution
      sessionTopics.addAll(_distributeTopicsEvenly(topicsToUse, totalQuestions));
    }
    
    // Shuffle for variety
    sessionTopics.shuffle();
    
    return sessionTopics;
  }

  /// Distribute topics evenly across questions
  List<GameCategory> _distributeTopicsEvenly(
    List<GameCategory> topics,
    int totalQuestions,
  ) {
    final result = <GameCategory>[];
    
    for (int i = 0; i < totalQuestions; i++) {
      result.add(topics[i % topics.length]);
    }
    
    return result;
  }

  /// Distribute topics based on weights
  List<GameCategory> _distributeTopicsWeighted(
    List<GameCategory> topics,
    Map<GameCategory, double> weights,
    int totalQuestions,
  ) {
    final result = <GameCategory>[];
    
    for (final topic in topics) {
      final weight = weights[topic] ?? (1.0 / topics.length);
      final questionsForTopic = (totalQuestions * weight).round();
      
      for (int i = 0; i < questionsForTopic && result.length < totalQuestions; i++) {
        result.add(topic);
      }
    }
    
    // Fill remaining slots if any
    while (result.length < totalQuestions) {
      result.add(topics[result.length % topics.length]);
    }
    
    return result;
  }

  /// Get predefined topic mixes
  List<TopicMixConfiguration> getPredefinedMixes() {
    return [
      const TopicMixConfiguration(
        mode: TopicMixMode.basicOperations,
        selectedTopics: [
          GameCategory.addition,
          GameCategory.subtraction,
          GameCategory.multiplication,
          GameCategory.division,
        ],
      ),
      const TopicMixConfiguration(
        mode: TopicMixMode.gradeLevel,
        selectedTopics: [], // Will be determined by grade
      ),
      const TopicMixConfiguration(
        mode: TopicMixMode.comprehensive,
        selectedTopics: GameCategory.values,
      ),
    ];
  }
}
