import 'package:flutter/material.dart';

/// AI difficulty levels for adaptive learning
enum AIDifficulty { beginner, intermediate, advanced, expert }

/// AI difficulty model with adaptive properties
class AIDifficultyModel {
  final AIDifficulty difficulty;
  final String name;
  final String description;
  final Color color;
  final int minScore;
  final int maxScore;
  final double complexityMultiplier;

  const AIDifficultyModel({
    required this.difficulty,
    required this.name,
    required this.description,
    required this.color,
    required this.minScore,
    required this.maxScore,
    required this.complexityMultiplier,
  });

  /// Get difficulty model by enum
  static AIDifficultyModel fromEnum(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return const AIDifficultyModel(
          difficulty: AIDifficulty.beginner,
          name: 'Beginner',
          description: 'Perfect for new learners',
          color: Colors.green,
          minScore: 0,
          maxScore: 25,
          complexityMultiplier: 0.5,
        );
      case AIDifficulty.intermediate:
        return const AIDifficultyModel(
          difficulty: AIDifficulty.intermediate,
          name: 'Intermediate',
          description: 'For students with basic knowledge',
          color: Colors.blue,
          minScore: 26,
          maxScore: 50,
          complexityMultiplier: 1.0,
        );
      case AIDifficulty.advanced:
        return const AIDifficultyModel(
          difficulty: AIDifficulty.advanced,
          name: 'Advanced',
          description: 'Challenging problems for experienced learners',
          color: Colors.orange,
          minScore: 51,
          maxScore: 75,
          complexityMultiplier: 1.5,
        );
      case AIDifficulty.expert:
        return const AIDifficultyModel(
          difficulty: AIDifficulty.expert,
          name: 'Expert',
          description: 'Complex problems for math masters',
          color: Colors.red,
          minScore: 76,
          maxScore: 100,
          complexityMultiplier: 2.0,
        );
    }
  }

  /// Get all difficulty models
  static List<AIDifficultyModel> getAll() {
    return AIDifficulty.values.map(fromEnum).toList();
  }

  /// Get difficulty based on score
  static AIDifficultyModel fromScore(int score) {
    if (score <= 25) return fromEnum(AIDifficulty.beginner);
    if (score <= 50) return fromEnum(AIDifficulty.intermediate);
    if (score <= 75) return fromEnum(AIDifficulty.advanced);
    return fromEnum(AIDifficulty.expert);
  }
}
