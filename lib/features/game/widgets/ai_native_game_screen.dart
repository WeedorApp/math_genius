import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

// Core imports
import '../../../core/barrel.dart';

// Models
import '../models/game_model.dart';
import '../models/ai_difficulty_model.dart';
import '../mixins/game_preferences_mixin.dart';

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
    with TickerProviderStateMixin, GamePreferencesMixin<AINativeGameScreen> {
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
    initializePreferencesSync(); // Initialize preferences synchronization
    _loadUserPreferences();
  }

  // GamePreferencesMixin implementation
  @override
  GameDifficulty? get selectedDifficulty => _selectedDifficulty != null
      ? _mapAIDifficultyToGame(_selectedDifficulty!)
      : null;

  @override
  GameCategory? get selectedCategory => _selectedTopic;

  @override
  int? get selectedQuestionCount => _selectedQuestionCount;

  @override
  int get selectedTimeLimit => _selectedTimeLimit;

  @override
  bool get soundEnabled => true; // AI Native games always have sound

  @override
  bool get hapticFeedbackEnabled => true; // AI Native games always have haptic

  @override
  String get gameMode => 'ai_native';

  @override
  void onDifficultyChanged(GameDifficulty difficulty) {
    if (mounted) {
      setState(() {
        _selectedDifficulty = _mapGameDifficultyToAI(difficulty);
      });
      _regenerateQuestionsIfNeeded();
    }
  }

  @override
  void onCategoryChanged(GameCategory category) {
    if (mounted) {
      setState(() {
        _selectedTopic = category;
      });
      _regenerateQuestionsIfNeeded();
    }
  }

  @override
  void onQuestionCountChanged(int count) {
    if (mounted) {
      setState(() {
        _selectedQuestionCount = count;
      });
      _regenerateQuestionsIfNeeded();
    }
  }

  @override
  void onTimeLimitChanged(int timeLimit) {
    if (mounted) {
      setState(() {
        _selectedTimeLimit = timeLimit;
        _timeRemaining = timeLimit;
      });
      _restartTimer();
    }
  }

  @override
  void onSoundEnabledChanged(bool enabled) {
    // AI Native games always have sound - no action needed
  }

  @override
  void onHapticFeedbackChanged(bool enabled) {
    // AI Native games always have haptic - no action needed
  }

  @override
  void onPreferencesLoaded(UserGamePreferences preferences) {
    if (mounted) {
      setState(() {
        _selectedDifficulty = _mapGameDifficultyToAI(
          preferences.preferredDifficulty,
        );
        _selectedTopic = preferences.preferredCategory;
        _selectedQuestionCount = preferences.preferredQuestionCount;
        _timeRemaining = preferences.preferredTimeLimit;
        _selectedTimeLimit = preferences.preferredTimeLimit;
      });

      // Auto-start if all preferences are set
      if (_selectedDifficulty != null &&
          _selectedTopic != null &&
          _selectedQuestionCount != null) {
        _showDifficultySelection = false;
        _showTopicSelection = false;
        _showQuestionCountSelection = false;
        _showTimeLimitSelection = false;
        _startGame();
      }
    }
  }

  /// Regenerate questions when preferences change during gameplay
  void _regenerateQuestionsIfNeeded() {
    if (!_showResults && _questions != null && _questions!.isNotEmpty) {
      _startGame(); // Restart with new preferences
    }
  }

  /// Restart timer with current time limit
  void _restartTimer() {
    _timer?.cancel();
    _timeRemaining = _selectedTimeLimit;
    _startTimer();
  }

  /// Map GameDifficulty to AIDifficulty
  AIDifficulty _mapGameDifficultyToAI(GameDifficulty difficulty) {
    switch (difficulty) {
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

  /// Map AIDifficulty to GameDifficulty
  GameDifficulty _mapAIDifficultyToGame(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return GameDifficulty.easy;
      case AIDifficulty.intermediate:
        return GameDifficulty.normal;
      case AIDifficulty.advanced:
        return GameDifficulty.genius;
      case AIDifficulty.expert:
        return GameDifficulty.quantum;
    }
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

  void _selectAnswer(int answerIndex) {
    if (_isAnswerSelected) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
    });

    // Auto-submit after selection with delay for visual feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_isAnswerSelected) {
        _submitAnswer(answerIndex);
      }
    });
  }

  void _submitAnswer(int answerIndex) {
    if (_isAnswerSelected || _questions == null) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _isAnswerSelected = true;
    });

    // Safety check to prevent RangeError
    if (_questions == null ||
        _questions!.isEmpty ||
        _currentQuestionIndex >= _questions!.length) {
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

      // Update preferences from completed game
      if (_selectedDifficulty != null &&
          _selectedTopic != null &&
          _selectedQuestionCount != null) {
        updatePreferencesFromGameCompletion(
          score: _score,
          totalQuestions: _questions?.length ?? 0,
        );
      }
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
    // Watch preferences for changes
    final currentPrefs = ref.watch(currentUserGamePreferencesProvider);

    // Handle preference changes
    if (currentPrefs != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final categoryChanged =
              _selectedTopic != currentPrefs.preferredCategory;

          if (categoryChanged ||
              _selectedDifficulty !=
                  _mapGameDifficultyToAI(currentPrefs.preferredDifficulty)) {
            setState(() {
              _selectedDifficulty = _mapGameDifficultyToAI(
                currentPrefs.preferredDifficulty,
              );
              _selectedTopic = currentPrefs.preferredCategory;
              _selectedQuestionCount = currentPrefs.preferredQuestionCount;
              _selectedTimeLimit = currentPrefs.preferredTimeLimit;
            });

            if (categoryChanged &&
                _questions != null &&
                _questions!.isNotEmpty) {
              _regenerateQuestionsIfNeeded();
            }
          }
        }
      });
    }

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid based on screen width
          final crossAxisCount = constraints.maxWidth > 600 ? 2 : 2;
          final childAspectRatio = constraints.maxWidth > 600 ? 2.5 : 2.2;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _fadeController.value),
                    child: Opacity(
                      opacity: _fadeController.value,
                      child: _buildEnhancedGridAnswerOption(
                        index,
                        question.options[index],
                        question,
                        themeData,
                        colorScheme,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListViewOptions(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: question.options.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              final delay = index * 0.1;
              final animation =
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _slideController,
                      curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
                    ),
                  );

              return SlideTransition(
                position: animation,
                child: FadeTransition(
                  opacity: _slideController,
                  child: _buildEnhancedListAnswerOption(
                    index,
                    question.options[index],
                    question,
                    themeData,
                    colorScheme,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Enhanced grid answer option with improved visual design
  Widget _buildEnhancedGridAnswerOption(
    int index,
    String option,
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = _isAnswerSelected && index == question.correctAnswer;
    final isWrong = _isAnswerSelected && isSelected && !isCorrect;

    return GestureDetector(
      onTap: _isAnswerSelected ? null : () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: _getAnswerGradient(
            isSelected,
            isCorrect,
            isWrong,
            colorScheme,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getAnswerBorderColor(
              isSelected,
              isCorrect,
              isWrong,
              colorScheme,
            ),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (isSelected || isCorrect)
              BoxShadow(
                color: _getAnswerShadowColor(isCorrect, isWrong, colorScheme),
                blurRadius: isCorrect ? 12 : 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern for visual interest
            if (isCorrect)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Option letter (A, B, C, D)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getOptionLetterColor(
                          isSelected,
                          isCorrect,
                          isWrong,
                          colorScheme,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getAnswerBorderColor(
                            isSelected,
                            isCorrect,
                            isWrong,
                            colorScheme,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: themeData.typography.titleSmall.copyWith(
                            color: _getAnswerTextColor(
                              isSelected,
                              isCorrect,
                              isWrong,
                              colorScheme,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Answer text
                    Flexible(
                      child: Text(
                        option,
                        style: themeData.typography.bodyLarge.copyWith(
                          color: _getAnswerTextColor(
                            isSelected,
                            isCorrect,
                            isWrong,
                            colorScheme,
                          ),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Correct answer indicator
                    if (isCorrect)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),

                    // Wrong answer indicator
                    if (isWrong)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Icon(Icons.cancel, color: Colors.red, size: 24),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced list answer option with improved visual design
  Widget _buildEnhancedListAnswerOption(
    int index,
    String option,
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = _isAnswerSelected && index == question.correctAnswer;
    final isWrong = _isAnswerSelected && isSelected && !isCorrect;

    return GestureDetector(
      onTap: _isAnswerSelected ? null : () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        height: 80,
        decoration: BoxDecoration(
          gradient: _getAnswerGradient(
            isSelected,
            isCorrect,
            isWrong,
            colorScheme,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getAnswerBorderColor(
              isSelected,
              isCorrect,
              isWrong,
              colorScheme,
            ),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (isSelected || isCorrect)
              BoxShadow(
                color: _getAnswerShadowColor(isCorrect, isWrong, colorScheme),
                blurRadius: isCorrect ? 16 : 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Animated background effect for correct answers
            if (isCorrect)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.withValues(alpha: 0.05),
                        Colors.green.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Option letter circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getOptionLetterColor(
                            isSelected,
                            isCorrect,
                            isWrong,
                            colorScheme,
                          ),
                          _getOptionLetterColor(
                            isSelected,
                            isCorrect,
                            isWrong,
                            colorScheme,
                          ).withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getAnswerBorderColor(
                          isSelected,
                          isCorrect,
                          isWrong,
                          colorScheme,
                        ),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getOptionLetterColor(
                            isSelected,
                            isCorrect,
                            isWrong,
                            colorScheme,
                          ).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: themeData.typography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Answer text
                  Expanded(
                    child: Text(
                      option,
                      style: themeData.typography.titleMedium.copyWith(
                        color: _getAnswerTextColor(
                          isSelected,
                          isCorrect,
                          isWrong,
                          colorScheme,
                        ),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Status indicator
                  if (isCorrect)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 24),
                    )
                  else if (isWrong)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    )
                  else if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
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

  // Enhanced visual design helper methods
  LinearGradient _getAnswerGradient(
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    ColorScheme colorScheme,
  ) {
    if (isCorrect) {
      return LinearGradient(
        colors: [
          Colors.green.withValues(alpha: 0.2),
          Colors.green.withValues(alpha: 0.1),
        ],
      );
    } else if (isWrong) {
      return LinearGradient(
        colors: [
          Colors.red.withValues(alpha: 0.2),
          Colors.red.withValues(alpha: 0.1),
        ],
      );
    } else if (isSelected) {
      return LinearGradient(
        colors: [
          colorScheme.primary.withValues(alpha: 0.2),
          colorScheme.primary.withValues(alpha: 0.1),
        ],
      );
    } else {
      return LinearGradient(
        colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
      );
    }
  }

  Color _getAnswerBorderColor(
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    ColorScheme colorScheme,
  ) {
    if (isCorrect) return Colors.green;
    if (isWrong) return Colors.red;
    if (isSelected) return colorScheme.primary;
    return colorScheme.outline.withValues(alpha: 0.3);
  }

  Color _getAnswerTextColor(
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    ColorScheme colorScheme,
  ) {
    if (isCorrect) return Colors.green.shade700;
    if (isWrong) return Colors.red.shade700;
    if (isSelected) return colorScheme.primary;
    return colorScheme.onSurface;
  }

  Color _getOptionLetterColor(
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    ColorScheme colorScheme,
  ) {
    if (isCorrect) return Colors.green;
    if (isWrong) return Colors.red;
    if (isSelected) return colorScheme.primary;
    return colorScheme.primaryContainer;
  }

  Color _getAnswerShadowColor(
    bool isCorrect,
    bool isWrong,
    ColorScheme colorScheme,
  ) {
    if (isCorrect) return Colors.green.withValues(alpha: 0.3);
    if (isWrong) return Colors.red.withValues(alpha: 0.3);
    return colorScheme.primary.withValues(alpha: 0.2);
  }
}
