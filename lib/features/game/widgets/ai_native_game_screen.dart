import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

// Core imports
import '../../../core/barrel.dart';

// Models
import '../models/game_model.dart';
import '../models/ai_difficulty_model.dart';

// Services
import '../services/ai_native_game_service.dart';

/// Advanced AI-Native Game Screen
/// The most sophisticated AI-powered learning interface in the market
class AINativeGameScreen extends ConsumerStatefulWidget {
  const AINativeGameScreen({super.key});

  @override
  ConsumerState<AINativeGameScreen> createState() => _AINativeGameScreenState();
}

class _AINativeGameScreenState extends ConsumerState<AINativeGameScreen>
    with TickerProviderStateMixin {
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _showDifficultySelection = true;
  bool _showTopicSelection = false;
  bool _showQuestionCountSelection = false;
  bool _showTimeLimitSelection = false;
  AIDifficulty? _selectedDifficulty;
  GameCategory? _selectedTopic;
  int? _selectedQuestionCount;
  List<AIQuestion>? _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isAnswerSelected = false;
  int? _selectedAnswerIndex;
  bool _showResults = false;
  Map<String, dynamic>? _gameResults;
  DateTime? _gameStartTime;

  // Layout mode state
  bool _isGridView = true; // true for GridView, false for ListView

  // Time limit state
  int _selectedTimeLimit = 30; // Default 30 seconds

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefsService = ref.read(userPreferencesServiceProvider);
      final preferences = await prefsService.getGamePreferences();

      // Auto-configure based on user preferences
      setState(() {
        _selectedDifficulty = _mapGameDifficultyToAI(
          preferences.preferredDifficulty,
        );
        _selectedTopic = preferences.preferredCategory;
        _selectedQuestionCount = preferences.preferredQuestionCount;
        _timeRemaining = preferences.preferredTimeLimit;

        // Skip selection screens if preferences are set
        if (_selectedDifficulty != null &&
            _selectedTopic != null &&
            _selectedQuestionCount != null) {
          _showDifficultySelection = false;
          _showTopicSelection = false;
          _showQuestionCountSelection = false;
          _showTimeLimitSelection = false;

          // Auto-start the game
          _startGame();
        }
      });
    } catch (e) {
      // Continue with manual selection if preferences loading fails
      if (kDebugMode) {
        print('Failed to load user preferences: $e');
      }
    }
  }

  AIDifficulty _mapGameDifficultyToAI(GameDifficulty gameDifficulty) {
    switch (gameDifficulty) {
      case GameDifficulty.easy:
        return AIDifficulty.beginner;
      case GameDifficulty.normal:
        return AIDifficulty.intermediate;
      case GameDifficulty.genius:
        return AIDifficulty.advanced;
      case GameDifficulty.quantum:
        return AIDifficulty.expert;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectDifficulty(AIDifficulty difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
      _showDifficultySelection = false;
      _showTopicSelection = true;
    });
    _slideController.forward();
  }

  void _selectTopic(GameCategory topic) {
    setState(() {
      _selectedTopic = topic;
      _showTopicSelection = false;
      _showQuestionCountSelection = true;
    });
    _slideController.forward();
  }

  void _selectQuestionCount(int count) {
    setState(() {
      _selectedQuestionCount = count;
      _showQuestionCountSelection = false;
      _showTimeLimitSelection = true;
    });
    _slideController.forward();
  }

  void _selectTimeLimit(int timeLimit) {
    setState(() {
      _selectedTimeLimit = timeLimit;
      _showTimeLimitSelection = false;
      _startGame();
    });
    _slideController.forward();
  }

  void _startGame() async {
    if (_selectedDifficulty == null ||
        _selectedTopic == null ||
        _selectedQuestionCount == null) {
      setState(() {
        _errorMessage = 'Please select all options before starting';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final aiNativeGameService = ref.read(aiNativeGameServiceProvider);
      final questions = await aiNativeGameService.generateAINativeQuestions(
        difficultyLevel: _selectedDifficulty!,
        category: _selectedTopic!,
        count: _selectedQuestionCount!,
        userId: 'demo_user', // Replace with actual user ID
      );

      if (questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _currentQuestionIndex = 0;
          _score = 0;
          _timeRemaining = _selectedTimeLimit;
          _isAnswerSelected = false;
          _selectedAnswerIndex = null;
          _showResults = false;
          _gameResults = null;
          _gameStartTime = DateTime.now();
        });
        _startTimer();
      } else {
        setState(() {
          _errorMessage = 'Failed to generate questions. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting game: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _endGame();
        }
      });
    });
  }

  void _submitAnswer(int answerIndex) {
    if (_isAnswerSelected || _questions == null) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _isAnswerSelected = true;
    });

    // Safety check to prevent RangeError
    if (_questions == null || _questions!.isEmpty || _currentQuestionIndex >= _questions!.length) {
      return;
    }
    
    final currentQuestion = _questions![_currentQuestionIndex];
    final isCorrect = answerIndex == currentQuestion.correctAnswer;

    if (isCorrect) {
      setState(() {
        _score += 10;
      });
    }

    // Wait 2 seconds before moving to next question
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_questions == null) return;

    setState(() {
      _isAnswerSelected = false;
      _selectedAnswerIndex = null;
    });

    if (_currentQuestionIndex < _questions!.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _timeRemaining = _selectedTimeLimit;
      });
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _timer?.cancel();

    if (_gameStartTime != null) {
      final gameDuration = DateTime.now().difference(_gameStartTime!);

      setState(() {
        _gameResults = {
          'totalQuestions': _questions?.length ?? 0,
          'correctAnswers': _score ~/ 10,
          'score': _score,
          'timeSpent': gameDuration.inSeconds,
          'accuracy': _questions != null && _questions!.isNotEmpty
              ? (_score ~/ 10) / _questions!.length
              : 0.0,
        };
        _showResults = true;
      });
    }
  }

  void _restartGame() {
    setState(() {
      _showDifficultySelection = true;
      _showTopicSelection = false;
      _showQuestionCountSelection = false;
      _showTimeLimitSelection = false;
      _selectedDifficulty = null;
      _selectedTopic = null;
      _selectedQuestionCount = null;
      _questions = null;
      _currentQuestionIndex = 0;
      _score = 0;
      _timeRemaining = 0;
      _isAnswerSelected = false;
      _selectedAnswerIndex = null;
      _showResults = false;
      _gameResults = null;
      _gameStartTime = null;
      _errorMessage = null;
    });
    _timer?.cancel();
  }

  void _showRestartDialog() {
    AdaptiveUISystem.showAdaptiveDialog(
      context: context,
      child: AlertDialog(
        title: const Text('Restart Game?'),
        content: const Text('Are you sure you want to restart the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);
    final layoutService = ref.watch(responsiveLayoutServiceProvider);
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);

    final navigationItems = [
      const NavigationItem(title: 'Home', icon: Icons.home, route: '/home'),
      const NavigationItem(
        title: 'Games',
        icon: Icons.games,
        route: '/game-selection',
      ),
      const NavigationItem(
        title: 'AI Tutor',
        icon: Icons.smart_toy,
        route: '/ai-tutor',
      ),
      const NavigationItem(
        title: 'Family',
        icon: Icons.family_restroom,
        route: '/family',
      ),
      const NavigationItem(
        title: 'Live',
        icon: Icons.video_call,
        route: '/live-session',
      ),
      const NavigationItem(
        title: 'Rewards',
        icon: Icons.star,
        route: '/rewards',
      ),
    ];

    return ResponsiveLayout(
      currentRoute: '/ai-native-quiz',
      navigationItems: navigationItems,
      child: _buildGameContent(
        context,
        ref,
        colorScheme,
        screenType,
        layoutService,
        isSidebarCollapsed,
      ),
    );
  }

  Widget _buildGameContent(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
    bool isSidebarCollapsed,
  ) {
    // For all screen types, use the same layout (tablet-like)
    // Desktop now behaves like tablet
    if (_isLoading) {
      return _buildLoadingScreen(ref.watch(themeDataProvider), colorScheme);
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(ref.watch(themeDataProvider), colorScheme);
    }

    if (_showResults) {
      return _buildResultsScreen(ref.watch(themeDataProvider), colorScheme);
    }

    if (_questions != null) {
      return _buildGameScreen(ref.watch(themeDataProvider), colorScheme);
    }

    if (_showTimeLimitSelection) {
      return _buildTimeLimitSelectionScreen(
        ref.watch(themeDataProvider),
        colorScheme,
      );
    }

    if (_showQuestionCountSelection) {
      return _buildQuestionCountSelectionScreen(
        ref.watch(themeDataProvider),
        colorScheme,
      );
    }

    if (_showTopicSelection) {
      return _buildTopicSelectionScreen(
        ref.watch(themeDataProvider),
        colorScheme,
      );
    }

    if (_showDifficultySelection) {
      return _buildDifficultySelectionScreen(
        ref.watch(themeDataProvider),
        colorScheme,
      );
    }

    return _buildDifficultySelectionScreen(
      ref.watch(themeDataProvider),
      colorScheme,
    );
  }

  Widget _buildLoadingScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Generating AI Questions...',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.adaptiveLayout.sectionSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              SizedBox(height: context.adaptiveLayout.cardSpacing + 4),
              Text(
                'Oops! Something went wrong',
                style: themeData.typography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
              Text(
                _errorMessage ?? 'Failed to load game',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),
              ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    // Add null safety checks
    if (_questions == null || _questions!.isEmpty) {
      if (kDebugMode) {
        print('Error: Questions is null or empty in _buildGameScreen');
        print('Questions: $_questions');
        print('Questions length: ${_questions?.length}');
      }
      return _buildErrorScreen(themeData, colorScheme);
    }

    if (_currentQuestionIndex >= _questions!.length) {
      if (kDebugMode) {
        print('Error: Current question index out of bounds');
        print('Current index: $_currentQuestionIndex');
        print('Questions length: ${_questions!.length}');
      }
      return _buildErrorScreen(themeData, colorScheme);
    }

    final currentQuestion = _questions![_currentQuestionIndex];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'AI-Native Quiz',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          // Restart button
          IconButton(
            onPressed: _showRestartDialog,
            icon: Icon(Icons.refresh, color: colorScheme.error),
            tooltip: 'Restart Game',
          ),
          // View toggle button
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: colorScheme.primary,
            ),
            tooltip: _isGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.adaptiveLayout.sectionSpacing),
          child: Column(
            children: [
              // Header with timer and score
              Container(
                padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.adaptiveLayout.cardSpacing / 2,
                        vertical: context.adaptiveLayout.cardSpacing / 4,
                      ),
                      decoration: BoxDecoration(
                        color: _timeRemaining <= 10
                            ? colorScheme.error
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_timeRemaining',
                        style: themeData.typography.titleSmall.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Score
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.adaptiveLayout.cardSpacing,
                        vertical: context.adaptiveLayout.cardSpacing / 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Score: $_score',
                          style: themeData.typography.titleMedium.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${_questions!.length}',
                          style: themeData.typography.labelMedium.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${((_currentQuestionIndex + 1) / _questions!.length * 100).round()}%',
                          style: themeData.typography.labelMedium.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions!.length,
                      backgroundColor: colorScheme.outline.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Question content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.quiz,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Question ${_currentQuestionIndex + 1}',
                                style: themeData.typography.labelSmall.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Question text
                        Text(
                          currentQuestion.question,
                          style: themeData.typography.titleLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Answer options
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: _isGridView
                              ? _buildGridViewOptions(
                                  currentQuestion,
                                  themeData,
                                  colorScheme,
                                )
                              : _buildListViewOptions(
                                  currentQuestion,
                                  themeData,
                                  colorScheme,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridViewOptions(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.0,
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return _buildAnswerOption(
          index,
          option,
          question,
          themeData,
          colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildListViewOptions(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildAnswerOption(
            index,
            option,
            question,
            themeData,
            colorScheme,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnswerOption(
    int index,
    String option,
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = _isAnswerSelected && index == question.correctAnswer;
    final isWrong = _isAnswerSelected && isSelected && !isCorrect;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (_isAnswerSelected) {
      if (isCorrect) {
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isWrong) {
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        textColor = Colors.red;
      } else {
        backgroundColor = colorScheme.surfaceContainerHighest;
        borderColor = colorScheme.outline;
        textColor = colorScheme.onSurface;
      }
    } else {
      backgroundColor = isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest;
      borderColor = isSelected ? colorScheme.primary : colorScheme.outline;
      textColor = isSelected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: _isAnswerSelected ? null : () => _submitAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Option letter
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D...
                  style: themeData.typography.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                option,
                style: themeData.typography.bodyLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Status icon
            if (_isAnswerSelected)
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : isWrong
                    ? Icons.cancel
                    : Icons.radio_button_unchecked,
                color: isCorrect
                    ? Colors.green
                    : isWrong
                    ? Colors.red
                    : colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final results = _gameResults!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Quiz Results',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Results header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quiz Complete!',
                      style: themeData.typography.headlineMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great job completing the AI-Native quiz!',
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Results stats
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Results',
                        style: themeData.typography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildResultRow(
                        'Total Questions',
                        '${results['totalQuestions']}',
                      ),
                      _buildResultRow(
                        'Correct Answers',
                        '${results['correctAnswers']}',
                      ),
                      _buildResultRow('Score', '${results['score']}'),
                      _buildResultRow(
                        'Time Spent',
                        '${results['timeSpent']} seconds',
                      ),
                      _buildResultRow(
                        'Accuracy',
                        '${(results['accuracy'] * 100).round()}%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back to Menu'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelectionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Select Difficulty',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Challenge Level',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'AI will adapt to your skill level',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDifficultyCard(
                      AIDifficulty.beginner,
                      'Easy',
                      'Perfect for beginners',
                      Icons.school,
                      Colors.green,
                      themeData,
                      colorScheme,
                    ),
                    _buildDifficultyCard(
                      AIDifficulty.intermediate,
                      'Standard',
                      'Balanced challenge',
                      Icons.trending_up,
                      Colors.blue,
                      themeData,
                      colorScheme,
                    ),
                    _buildDifficultyCard(
                      AIDifficulty.advanced,
                      'Hard',
                      'Advanced concepts',
                      Icons.psychology,
                      Colors.orange,
                      themeData,
                      colorScheme,
                    ),
                    _buildDifficultyCard(
                      AIDifficulty.expert,
                      'Expert',
                      'Genius level',
                      Icons.auto_awesome,
                      Colors.purple,
                      themeData,
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    AIDifficulty difficulty,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _selectDifficulty(difficulty),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: themeData.typography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicSelectionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Topic',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Math Topic',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'From PreK to Grade 12',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Basic Operations
                      _buildTopicSection(
                        'Basic Operations',
                        [
                          _buildTopicCard(
                            GameCategory.addition,
                            'Addition',
                            'Adding numbers together',
                            Icons.add,
                            Colors.green,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.subtraction,
                            'Subtraction',
                            'Taking away numbers',
                            Icons.remove,
                            Colors.red,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.multiplication,
                            'Multiplication',
                            'Repeated addition',
                            Icons.close,
                            Colors.blue,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.division,
                            'Division',
                            'Sharing equally',
                            Icons.call_split,
                            Colors.orange,
                            themeData,
                            colorScheme,
                          ),
                        ],
                        themeData,
                        colorScheme,
                      ),
                      const SizedBox(height: 24),

                      // Advanced Operations
                      _buildTopicSection(
                        'Advanced Operations',
                        [
                          _buildTopicCard(
                            GameCategory.fractions,
                            'Fractions',
                            'Parts of a whole',
                            Icons.pie_chart,
                            Colors.purple,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.decimals,
                            'Decimals',
                            'Numbers with points',
                            Icons.timeline,
                            Colors.teal,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.percentages,
                            'Percentages',
                            'Parts per hundred',
                            Icons.percent,
                            Colors.indigo,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.algebra,
                            'Algebra',
                            'Using letters for numbers',
                            Icons.functions,
                            Colors.amber,
                            themeData,
                            colorScheme,
                          ),
                        ],
                        themeData,
                        colorScheme,
                      ),
                      const SizedBox(height: 24),

                      // Geometry & Measurement
                      _buildTopicSection(
                        'Geometry & Measurement',
                        [
                          _buildTopicCard(
                            GameCategory.geometry,
                            'Geometry',
                            'Shapes and space',
                            Icons.shape_line,
                            Colors.cyan,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.measurement,
                            'Measurement',
                            'Length, weight, time',
                            Icons.straighten,
                            Colors.lime,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.dataAnalysis,
                            'Data Analysis',
                            'Charts and graphs',
                            Icons.analytics,
                            Colors.deepOrange,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.calculus,
                            'Calculus',
                            'Advanced mathematics',
                            Icons.trending_up,
                            Colors.deepPurple,
                            themeData,
                            colorScheme,
                          ),
                        ],
                        themeData,
                        colorScheme,
                      ),
                      const SizedBox(height: 24),

                      // Mixed Topics
                      _buildTopicSection(
                        'Mixed Topics',
                        [
                          _buildTopicCard(
                            GameCategory.addition,
                            'Mixed Topics',
                            'All topics combined',
                            Icons.shuffle,
                            Colors.grey,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.wordProblems,
                            'Word Problems',
                            'Real-world scenarios',
                            Icons.text_fields,
                            Colors.brown,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.patterns,
                            'Patterns',
                            'Number sequences',
                            Icons.pattern,
                            Colors.pink,
                            themeData,
                            colorScheme,
                          ),
                          _buildTopicCard(
                            GameCategory.algebra,
                            'Problem Solving',
                            'Critical thinking',
                            Icons.psychology,
                            Colors.blueGrey,
                            themeData,
                            colorScheme,
                          ),
                        ],
                        themeData,
                        colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicSection(
    String title,
    List<Widget> children,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: themeData.typography.titleMedium.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: children,
        ),
      ],
    );
  }

  Widget _buildTopicCard(
    GameCategory topic,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _selectTopic(topic),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: themeData.typography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountSelectionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Question Count',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How many questions?',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your quiz length',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildQuestionCountCard(
                      5,
                      'Quick Quiz',
                      '5 questions',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCountCard(
                      10,
                      'Standard Quiz',
                      '10 questions',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCountCard(
                      15,
                      'Extended Quiz',
                      '15 questions',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCountCard(
                      20,
                      'Comprehensive Quiz',
                      '20 questions',
                      themeData,
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountCard(
    int count,
    String title,
    String subtitle,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _selectQuestionCount(count),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.quiz, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeData.typography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLimitSelectionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Time Limit',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How much time per question?',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your pace',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildTimeLimitCard(
                      15,
                      'Quick',
                      '15 seconds',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeLimitCard(
                      30,
                      'Standard',
                      '30 seconds',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeLimitCard(
                      45,
                      'Relaxed',
                      '45 seconds',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeLimitCard(
                      60,
                      'No Rush',
                      '60 seconds',
                      themeData,
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeLimitCard(
    int timeLimit,
    String title,
    String subtitle,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _selectTimeLimit(timeLimit),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.timer, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeData.typography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
