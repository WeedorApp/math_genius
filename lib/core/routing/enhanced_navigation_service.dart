import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import '../barrel.dart';

/// Enhanced navigation service with game-specific navigation patterns
class EnhancedNavigationService {
  static final EnhancedNavigationService _instance =
      EnhancedNavigationService._internal();
  factory EnhancedNavigationService() => _instance;
  EnhancedNavigationService._internal();

  /// Navigate to game with proper state management
  static Future<void> navigateToGame({
    required BuildContext context,
    required String gameMode,
    Map<String, dynamic>? gameConfig,
  }) async {
    try {
      String route;
      switch (gameMode) {
        case 'classic':
          route = '/game-selection/classic';
          break;
        case 'ai_native':
          route = '/game-selection/ai-native';
          break;
        case 'chatgpt':
          route = '/game-selection/chatgpt';
          break;
        default:
          route = AppRoutes.gameSelection;
      }

      // Save navigation state for recovery
      await _saveNavigationState(context, route, gameConfig);

      if (context.mounted) {
        context.push(route, extra: gameConfig);
      }
    } catch (e) {
      debugPrint('Error navigating to game: $e');
      // Fallback to game selection
      if (context.mounted) {
        context.push(AppRoutes.gameSelection);
      }
    }
  }

  /// Navigate with confirmation for active games
  static Future<bool> navigateWithGameConfirmation({
    required BuildContext context,
    required String destination,
    required bool isGameActive,
    Map<String, dynamic>? extra,
  }) async {
    if (!isGameActive) {
      if (context.mounted) context.push(destination, extra: extra);
      return true;
    }

    final shouldExit = await _showGameExitDialog(context);
    if (shouldExit == true && context.mounted) {
      context.push(destination, extra: extra);
      return true;
    }
    return false;
  }

  /// Safe back navigation with game state preservation
  static Future<void> safeGoBack({
    required BuildContext context,
    required bool isGameActive,
    VoidCallback? onGameSave,
  }) async {
    if (isGameActive && onGameSave != null) {
      final shouldExit = await _showGameExitDialog(context);
      if (shouldExit == true && context.mounted) {
        onGameSave();
        _performBackNavigation(context);
      }
    } else {
      if (context.mounted) _performBackNavigation(context);
    }
  }

  /// Perform actual back navigation
  static void _performBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Navigate to game results with session data
  static void navigateToGameResults({
    required BuildContext context,
    required String sessionId,
    required Map<String, dynamic> results,
  }) {
    context.push(
      '${AppRoutes.gameSelection}/results?sessionId=$sessionId',
      extra: results,
    );
  }

  /// Navigate to settings with return context
  static void navigateToSettingsWithReturn({
    required BuildContext context,
    required String settingsPath,
    String? returnRoute,
  }) {
    final fullPath = returnRoute != null
        ? '$settingsPath?returnTo=$returnRoute'
        : settingsPath;
    context.push(fullPath);
  }

  /// Handle deep links for game sessions
  static Future<void> handleGameDeepLink({
    required BuildContext context,
    required String gameMode,
    required String sessionId,
    Map<String, dynamic>? config,
  }) async {
    try {
      // Validate session exists
      final isValidSession = await _validateGameSession(sessionId);
      if (!isValidSession) {
        if (context.mounted) _showInvalidSessionDialog(context);
        return;
      }

      // Navigate to specific game with session
      final route = '/game-selection/$gameMode?sessionId=$sessionId';
      if (context.mounted) context.push(route, extra: config);
    } catch (e) {
      debugPrint('Error handling game deep link: $e');
      if (context.mounted) context.push(AppRoutes.gameSelection);
    }
  }

  /// Show game exit confirmation dialog
  static Future<bool?> _showGameExitDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.pause_circle, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Pause Game?'),
            ],
          ),
          content: const Text(
            'Your progress will be saved. You can resume this game later from where you left off.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Continue Playing'),
            ),
            ElevatedButton(
              onPressed: () => context.pop(true),
              child: const Text('Save & Exit'),
            ),
          ],
        );
      },
    );
  }

  /// Save navigation state for recovery
  static Future<void> _saveNavigationState(
    BuildContext context,
    String route,
    Map<String, dynamic>? config,
  ) async {
    try {
      // TODO: Implement navigation state persistence
      debugPrint('Navigation state saved: $route');
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  /// Validate game session exists
  static Future<bool> _validateGameSession(String sessionId) async {
    try {
      // TODO: Implement actual session validation
      return sessionId.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating game session: $e');
      return false;
    }
  }

  /// Show invalid session dialog
  static void _showInvalidSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Session Not Found'),
            ],
          ),
          content: const Text(
            'The game session you\'re trying to join no longer exists or has expired.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop();
                if (context.mounted) context.push(AppRoutes.gameSelection);
              },
              child: const Text('Start New Game'),
            ),
          ],
        );
      },
    );
  }
}

/// Navigation state management for complex game flows
class GameNavigationState {
  final String currentRoute;
  final Map<String, dynamic> gameState;
  final DateTime timestamp;
  final bool canResume;

  const GameNavigationState({
    required this.currentRoute,
    required this.gameState,
    required this.timestamp,
    this.canResume = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentRoute': currentRoute,
      'gameState': gameState,
      'timestamp': timestamp.toIso8601String(),
      'canResume': canResume,
    };
  }

  factory GameNavigationState.fromJson(Map<String, dynamic> json) {
    return GameNavigationState(
      currentRoute: json['currentRoute'] as String,
      gameState: json['gameState'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      canResume: json['canResume'] as bool? ?? false,
    );
  }
}

/// Enhanced route guards with proper authentication
class EnhancedRouteGuards {
  static Future<String?> authenticationGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      // TODO: Implement actual authentication check
      final isAuthenticated = await _checkAuthentication();

      if (!isAuthenticated && !_isPublicRoute(state.uri.path)) {
        return AppRoutes.auth;
      }

      return null; // No redirect needed
    } catch (e) {
      debugPrint('Authentication guard error: $e');
      return AppRoutes.auth;
    }
  }

  static Future<String?> roleBasedGuard(
    BuildContext context,
    GoRouterState state,
    String requiredRole,
  ) async {
    try {
      final userRole = await _getCurrentUserRole();

      if (!_hasRequiredRole(userRole, requiredRole)) {
        return AppRoutes.home; // Redirect to home if insufficient permissions
      }

      return null;
    } catch (e) {
      debugPrint('Role-based guard error: $e');
      return AppRoutes.home;
    }
  }

  // Helper methods
  static Future<bool> _checkAuthentication() async {
    // TODO: Implement actual authentication check
    return true;
  }

  static Future<String?> _getCurrentUserRole() async {
    // TODO: Implement actual role retrieval
    return 'student';
  }

  static bool _hasRequiredRole(String? userRole, String requiredRole) {
    // TODO: Implement role hierarchy checking
    return true;
  }

  static bool _isPublicRoute(String path) {
    const publicRoutes = [
      AppRoutes.welcome,
      AppRoutes.auth,
      AppRoutes.help,
      AppRoutes.faq,
    ];
    return publicRoutes.contains(path);
  }
}

/// Provider for enhanced navigation service
final enhancedNavigationServiceProvider = Provider<EnhancedNavigationService>((
  ref,
) {
  return EnhancedNavigationService();
});
