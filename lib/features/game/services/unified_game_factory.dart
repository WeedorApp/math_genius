import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../core/barrel.dart';

// Game widgets
import '../widgets/ultra_optimized_quiz.dart';
import '../widgets/ai_native_game_screen.dart';
import '../widgets/chatgpt_enhanced_game_screen.dart';

/// Unified Game Factory
/// Creates the appropriate game screen based on preferences and context
class UnifiedGameFactory {
  /// Create game screen based on preferences and user context
  static Widget createGameScreen({
    required String gameType,
    required WidgetRef ref,
    Map<String, dynamic>? gameConfig,
  }) {
    switch (gameType.toLowerCase()) {
      case 'ai_native':
      case 'ai':
        return const AINativeGameScreen();
      
      case 'chatgpt':
      case 'chatgpt_enhanced':
        return const ChatGPTEnhancedGameScreen();
      
      case 'classic':
      case 'traditional':
      default:
        return const UltraOptimizedQuiz();
    }
  }

  /// Get recommended game type based on user profile and performance
  static String getRecommendedGameType({
    required Ref ref,
    Map<String, dynamic>? userAnalytics,
  }) {
    try {
      // Get current preferences
      final prefs = ref.read(currentUserGamePreferencesProvider);
      
      // If user has preferences, use their last game mode
      if (prefs != null) {
        return prefs.lastGameMode;
      }

      // Analyze user performance to recommend game type
      if (userAnalytics != null) {
        final accuracy = userAnalytics['accuracy'] as double? ?? 0.0;
        final gamesPlayed = userAnalytics['gamesPlayed'] as int? ?? 0;
        
        // Recommend AI games for users who need adaptive help
        if (accuracy < 0.6 && gamesPlayed > 5) {
          return 'ai_native';
        }
        
        // Recommend ChatGPT for advanced learners
        if (accuracy > 0.85 && gamesPlayed > 10) {
          return 'chatgpt';
        }
      }

      // Default to classic for new users
      return 'classic';
    } catch (e) {
      // Fallback to classic on any error
      return 'classic';
    }
  }

  /// Get game type display information
  static GameTypeInfo getGameTypeInfo(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'ai_native':
        return GameTypeInfo(
          name: 'AI Native',
          description: 'Advanced AI-powered adaptive learning',
          icon: Icons.psychology,
          color: Colors.purple,
          features: [
            'Adaptive difficulty',
            'Personalized questions',
            'Real-time adjustments',
            'Advanced analytics',
          ],
          complexity: GameComplexity.advanced,
        );
      
      case 'chatgpt':
        return GameTypeInfo(
          name: 'ChatGPT Enhanced',
          description: 'Conversational AI tutoring experience',
          icon: Icons.chat,
          color: Colors.green,
          features: [
            'Natural conversation',
            'Contextual explanations',
            'Personalized feedback',
            'Advanced reasoning',
          ],
          complexity: GameComplexity.expert,
        );
      
      default: // classic
        return GameTypeInfo(
          name: 'Classic Quiz',
          description: 'Traditional math quiz experience',
          icon: Icons.quiz,
          color: Colors.blue,
          features: [
            'Grade-appropriate questions',
            'Comprehensive analytics',
            'Multiple choice format',
            'Progress tracking',
          ],
          complexity: GameComplexity.beginner,
        );
    }
  }

  /// Get all available game types
  static List<String> getAvailableGameTypes() {
    return ['classic', 'ai_native', 'chatgpt'];
  }

  /// Check if game type is available based on user permissions/subscription
  static bool isGameTypeAvailable(String gameType, WidgetRef ref) {
    // For now, all game types are available
    // In production, this could check subscription status, user level, etc.
    return true;
  }
}

/// Game type information model
class GameTypeInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  final GameComplexity complexity;

  const GameTypeInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    required this.complexity,
  });
}

/// Game complexity levels
enum GameComplexity {
  beginner,
  intermediate, 
  advanced,
  expert,
}

/// Riverpod providers for unified game factory
final unifiedGameFactoryProvider = Provider<UnifiedGameFactory>((ref) {
  return UnifiedGameFactory();
});

final recommendedGameTypeProvider = Provider<String>((ref) {
  return UnifiedGameFactory.getRecommendedGameType(ref: ref);
});

final availableGameTypesProvider = Provider<List<String>>((ref) {
  return UnifiedGameFactory.getAvailableGameTypes();
});

final gameTypeInfoProvider = Provider.family<GameTypeInfo, String>((ref, gameType) {
  return UnifiedGameFactory.getGameTypeInfo(gameType);
});
