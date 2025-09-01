import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

/// Mixin for handling consistent navigation patterns across all game screens
mixin GameNavigationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Timer? _autosaveTimer;
  bool _hasUnsavedProgress = false;

  // Abstract properties that implementing classes must define
  bool get isGameActive;
  bool get hasGameProgress;
  String get gameMode;
  Map<String, dynamic> get currentGameState;

  // Abstract methods that implementing classes must implement
  Future<void> saveGameProgress();
  Future<void> pauseGame();
  Future<void> resumeGame();
  void resetGame();

  /// Initialize navigation handling
  void initializeGameNavigation() {
    // Start autosave timer for game progress
    _startAutosaveTimer();
  }

  /// Handle back navigation with game state preservation
  Future<bool> handleBackNavigation() async {
    if (!isGameActive) {
      return true; // Allow normal back navigation
    }

    // Game is active - show confirmation
    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit == true) {
      await _handleGameExit();
      return true;
    }
    return false; // Prevent navigation
  }

  /// Navigate to specific route with game state handling
  Future<void> navigateToRoute(
    String route, {
    Map<String, dynamic>? extra,
  }) async {
    if (isGameActive) {
      final shouldNavigate = await _showNavigationConfirmationDialog(route);
      if (shouldNavigate == true) {
        await _handleGameExit();
        if (mounted && context.mounted) {
          context.push(route, extra: extra);
        }
      }
    } else {
      if (mounted && context.mounted) {
        context.push(route, extra: extra);
      }
    }
  }

  /// Navigate to game results with current state
  Future<void> navigateToGameResults(Map<String, dynamic> results) async {
    if (mounted && context.mounted) {
      context.push(
        '/game-selection/results',
        extra: {
          'gameMode': gameMode,
          'results': results,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Navigate to settings with return context
  Future<void> navigateToSettings({String? specificSetting}) async {
    final settingsRoute = specificSetting != null
        ? '/settings/$specificSetting'
        : '/settings';

    await navigateToRoute(settingsRoute);
  }

  /// Quick restart current game
  Future<void> restartGame() async {
    final shouldRestart = await _showRestartConfirmationDialog();
    if (shouldRestart == true) {
      resetGame();
      await resumeGame();
    }
  }

  /// Handle game completion and navigate to results
  Future<void> completeGameAndNavigate(Map<String, dynamic> results) async {
    await saveGameProgress();
    _stopAutosaveTimer();
    await navigateToGameResults(results);
  }

  /// Show exit confirmation dialog
  Future<bool?> _showExitConfirmationDialog() async {
    if (!mounted || !context.mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.orange),
              SizedBox(width: 8),
              Text('Pause Game?'),
            ],
          ),
          content: const Text(
            'Your progress will be automatically saved. You can resume this game later.',
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
  }

  /// Show navigation confirmation dialog
  Future<bool?> _showNavigationConfirmationDialog(String destination) async {
    if (!mounted || !context.mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.navigation, color: Colors.blue),
              SizedBox(width: 8),
              Text('Leave Game?'),
            ],
          ),
          content: Text(
            'You\'re about to leave the current game. Your progress will be saved automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & Go'),
            ),
          ],
        );
      },
    );
  }

  /// Show restart confirmation dialog
  Future<bool?> _showRestartConfirmationDialog() async {
    if (!mounted || !context.mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.green),
              SizedBox(width: 8),
              Text('Restart Game?'),
            ],
          ),
          content: const Text(
            'This will start a new game with the same settings. Your current progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  /// Handle game exit with proper cleanup
  Future<void> _handleGameExit() async {
    try {
      await pauseGame();
      await saveGameProgress();
      _stopAutosaveTimer();
      _hasUnsavedProgress = false;
    } catch (e) {
      debugPrint('Error handling game exit: $e');
    }
  }

  /// Start autosave timer for game progress
  void _startAutosaveTimer() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isGameActive && hasGameProgress) {
        saveGameProgress();
        _hasUnsavedProgress = false;
      }
    });
  }

  /// Stop autosave timer
  void _stopAutosaveTimer() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
  }

  /// Mark that there's unsaved progress
  void markProgressChanged() {
    _hasUnsavedProgress = true;
  }

  /// Check if there's unsaved progress
  bool get hasUnsavedProgress => _hasUnsavedProgress;

  /// Create navigation-aware app bar for games
  PreferredSizeWidget buildGameAppBar({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
  }) {
    return AppBar(
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final canNavigateBack = await handleBackNavigation();
                if (canNavigateBack && mounted && context.mounted) {
                  context.pop();
                }
              },
            )
          : null,
      actions: [
        // Game-specific actions
        if (isGameActive) ...[
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Pause Game',
            onPressed: () async {
              await pauseGame();
              await saveGameProgress();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart Game',
            onPressed: restartGame,
          ),
        ],

        // Settings access
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Game Settings',
          onPressed: () => navigateToSettings(specificSetting: 'games'),
        ),

        // Custom actions
        ...?actions,
      ],
    );
  }

  /// Create floating action button for game controls
  Widget? buildGameFloatingActionButton() {
    if (!isGameActive) return null;

    return FloatingActionButton.extended(
      onPressed: () async {
        await pauseGame();
        await saveGameProgress();
        if (mounted && context.mounted) {
          context.push('/game-selection');
        }
      },
      icon: const Icon(Icons.home),
      label: const Text('Home'),
      tooltip: 'Save & Go Home',
    );
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (isGameActive) {
          pauseGame();
          saveGameProgress();
        }
        break;
      case AppLifecycleState.resumed:
        if (hasGameProgress && !isGameActive) {
          // Optionally resume game
          _showResumeGameDialog();
        }
        break;
      case AppLifecycleState.detached:
        _handleGameExit();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  /// Show resume game dialog when app is resumed
  Future<void> _showResumeGameDialog() async {
    if (!mounted || !context.mounted) return;

    final shouldResume = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.play_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Resume Game?'),
            ],
          ),
          content: const Text(
            'You have a saved game in progress. Would you like to continue where you left off?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Start New Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );

    if (shouldResume == true) {
      await resumeGame();
    } else {
      resetGame();
    }
  }

  @override
  void dispose() {
    _stopAutosaveTimer();
    if (isGameActive) {
      _handleGameExit();
    }
    super.dispose();
  }
}
