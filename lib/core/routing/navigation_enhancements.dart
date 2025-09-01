import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple but comprehensive navigation enhancements
class NavigationEnhancements {
  /// Enhanced back navigation with confirmation for active games
  static Future<bool> handleGameBackNavigation({
    required BuildContext context,
    required bool isGameActive,
    required VoidCallback onSaveProgress,
  }) async {
    if (!isGameActive) {
      return true; // Allow normal navigation
    }

    // Show confirmation dialog for active games
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.orange),
              SizedBox(width: 8),
              Text('Exit Game?'),
            ],
          ),
          content: const Text(
            'Your progress will be saved automatically. You can resume this game later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue Playing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & Exit'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      onSaveProgress(); // Save game progress before exiting
      return true;
    }
    return false;
  }

  /// Enhanced navigation with game state awareness
  static Future<void> navigateWithGameAwareness({
    required BuildContext context,
    required String route,
    required bool isGameActive,
    VoidCallback? onSaveProgress,
    Object? extra,
  }) async {
    if (isGameActive) {
      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Leave Current Game?'),
            content: const Text(
              'Your progress will be saved before navigating.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay Here'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save & Go'),
              ),
            ],
          );
        },
      );

      if (shouldNavigate == true) {
        onSaveProgress?.call();
        if (context.mounted) {
          if (extra != null) {
            context.push(route, extra: extra);
          } else {
            context.push(route);
          }
        }
      }
    } else {
      if (context.mounted) {
        if (extra != null) {
          context.push(route, extra: extra);
        } else {
          context.push(route);
        }
      }
    }
  }

  /// Save navigation state for recovery
  static Future<void> saveNavigationState({
    required SharedPreferences prefs,
    required String route,
    required Map<String, dynamic> state,
  }) async {
    try {
      final navigationState = {
        'route': route,
        'state': state,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString('navigation_state', jsonEncode(navigationState));
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  /// Restore navigation state after app restart
  static Future<Map<String, dynamic>?> restoreNavigationState(
    SharedPreferences prefs,
  ) async {
    try {
      final stateString = prefs.getString('navigation_state');
      if (stateString == null) return null;

      final navigationState = jsonDecode(stateString) as Map<String, dynamic>;

      // Check if state is still valid (within 1 hour)
      final timestamp = DateTime.parse(navigationState['timestamp'] as String);
      final age = DateTime.now().difference(timestamp);

      if (age.inHours > 1) {
        await prefs.remove('navigation_state');
        return null;
      }

      return navigationState;
    } catch (e) {
      debugPrint('Error restoring navigation state: $e');
      return null;
    }
  }

  /// Simple authentication check
  static Future<bool> isUserAuthenticated(SharedPreferences prefs) async {
    try {
      final userString = prefs.getString('current_user');
      final sessionString = prefs.getString('current_session');

      if (userString == null || sessionString == null) {
        return false;
      }

      // Basic session validation
      final sessionData = jsonDecode(sessionString) as Map<String, dynamic>;
      final loginTime = DateTime.parse(sessionData['loginTime'] as String);
      final sessionAge = DateTime.now().difference(loginTime);

      // Sessions expire after 30 days
      return sessionAge.inDays <= 30;
    } catch (e) {
      debugPrint('Authentication check error: $e');
      return false;
    }
  }

  /// Create game-aware app bar
  static PreferredSizeWidget buildGameAppBar({
    required BuildContext context,
    required String title,
    required bool isGameActive,
    required VoidCallback onSaveProgress,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final canGoBack = await handleGameBackNavigation(
            context: context,
            isGameActive: isGameActive,
            onSaveProgress: onSaveProgress,
          );

          if (canGoBack && context.mounted) {
            context.pop();
          }
        },
      ),
      actions: [
        if (isGameActive) ...[
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Pause Game',
            onPressed: onSaveProgress,
          ),
        ],
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => navigateWithGameAwareness(
            context: context,
            route: '/settings/games',
            isGameActive: isGameActive,
            onSaveProgress: onSaveProgress,
          ),
        ),
        ...?actions,
      ],
    );
  }
}

/// Game session recovery service
class GameSessionRecovery {
  static const String _gameSessionKey = 'recoverable_game_session';

  /// Save game session for recovery
  static Future<void> saveGameSession({
    required SharedPreferences prefs,
    required String gameMode,
    required Map<String, dynamic> gameState,
  }) async {
    try {
      final sessionData = {
        'gameMode': gameMode,
        'gameState': gameState,
        'timestamp': DateTime.now().toIso8601String(),
        'canRecover': true,
      };

      await prefs.setString(_gameSessionKey, jsonEncode(sessionData));
      debugPrint('💾 Game session saved for recovery: $gameMode');
    } catch (e) {
      debugPrint('Error saving game session: $e');
    }
  }

  /// Check for recoverable game session
  static Future<Map<String, dynamic>?> checkRecoverableSession(
    SharedPreferences prefs,
  ) async {
    try {
      final sessionString = prefs.getString(_gameSessionKey);
      if (sessionString == null) return null;

      final sessionData = jsonDecode(sessionString) as Map<String, dynamic>;

      // Check if session is still valid (within 24 hours)
      final timestamp = DateTime.parse(sessionData['timestamp'] as String);
      final age = DateTime.now().difference(timestamp);

      if (age.inHours > 24) {
        await clearRecoverableSession(prefs);
        return null;
      }

      return sessionData;
    } catch (e) {
      debugPrint('Error checking recoverable session: $e');
      return null;
    }
  }

  /// Clear recoverable session
  static Future<void> clearRecoverableSession(SharedPreferences prefs) async {
    try {
      await prefs.remove(_gameSessionKey);
      debugPrint('💾 Recoverable game session cleared');
    } catch (e) {
      debugPrint('Error clearing recoverable session: $e');
    }
  }

  /// Show recovery dialog
  static Future<bool?> showRecoveryDialog(
    BuildContext context,
    String gameMode,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restore, color: Colors.blue),
              SizedBox(width: 8),
              Text('Resume Game?'),
            ],
          ),
          content: Text(
            'You have an unfinished $gameMode game. Would you like to continue where you left off?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Start New Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );
  }
}
