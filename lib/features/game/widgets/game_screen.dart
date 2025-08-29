import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Core imports
import '../../../core/barrel.dart';

// Game imports
import '../barrel.dart';

/// Main game screen for Math Genius
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameSession? _currentSession;
  GameQuestion? _currentQuestion;
  int _currentQuestionIndex = 0;
  int _timeRemaining = 30;
  Timer? _timer;
  bool _isAnswerSubmitted = false;
  int? _selectedAnswer;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showDifficultySelection = true;
  bool _showTopicSelection = false;
  bool _showQuestionCountSelection = false;
  bool _showTimeLimitSelection = false;
  GameDifficulty? _selectedDifficulty;
  GameCategory? _selectedTopic;
  int? _selectedQuestionCount;
  int _selectedTimeLimit = 30;
  bool _isGridView = true;
  bool _showResults = false;
  Map<String, dynamic>? _gameResults;
  DateTime? _gameStartTime;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefsService = ref.read(userPreferencesServiceProvider);
      final preferences = await prefsService.getGamePreferences();
      
      // Auto-configure based on user preferences
      setState(() {
        _selectedDifficulty = preferences.preferredDifficulty;
        _selectedTopic = preferences.preferredCategory;
        _selectedQuestionCount = preferences.preferredQuestionCount;
        _selectedTimeLimit = preferences.preferredTimeLimit;
        _timeRemaining = preferences.preferredTimeLimit;
        
        // Skip selection screens if preferences are set
        if (_selectedDifficulty != null && _selectedTopic != null && _selectedQuestionCount != null) {
          _showDifficultySelection = false;
          _showTopicSelection = false;
          _showQuestionCountSelection = false;
          _showTimeLimitSelection = false;
          
          // Auto-start the game
          _initializeGame();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      // Continue with manual selection if preferences loading fails
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectDifficulty(GameDifficulty difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
      _showDifficultySelection = false;
      _showTopicSelection = true;
    });
  }

  void _selectTopic(GameCategory topic) {
    setState(() {
      _selectedTopic = topic;
      _showTopicSelection = false;
      _showQuestionCountSelection = true;
    });
  }

  void _selectQuestionCount(int count) {
    setState(() {
      _selectedQuestionCount = count;
      _showQuestionCountSelection = false;
      _showTimeLimitSelection = true;
    });
  }

  void _selectTimeLimit(int timeLimit) {
    setState(() {
      _selectedTimeLimit = timeLimit;
      _showTimeLimitSelection = false;
    });
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (_selectedDifficulty == null ||
        _selectedTopic == null ||
        _selectedQuestionCount == null) {
      setState(() {
        _errorMessage = 'Please select difficulty, topic, and question count';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Create a demo game session
      final gameService = ref.read(gameServiceProvider);
      final player = GamePlayer(
        id: 'demo_player_1',
        name: 'Math Genius',
        role: PlayerRole.host,
        lastActive: DateTime.now(),
      );

      final session = await gameService.createAIGameSession(
        name: 'Classic Math Quiz',
        gradeLevel: GradeLevel.grade3,
        difficulty: _selectedDifficulty!,
        category: _selectedTopic!,
        players: [player],
        questionCount: _selectedQuestionCount!,
        timeLimit: _selectedTimeLimit * 60, // Convert to seconds
      );

      // Add null safety checks
      if (session.questions.isEmpty) {
        setState(() {
          _errorMessage = 'No questions were generated. Please try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentSession = session;
        _currentQuestion = session.questions[0];
        _timeRemaining = _selectedTimeLimit;
        _isLoading = false;
        _gameStartTime = DateTime.now();
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize game: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _submitAnswer(-1); // Time's up
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _submitAnswer(int answerIndex) async {
    if (_isAnswerSubmitted ||
        _currentSession == null ||
        _currentQuestion == null) {
      return;
    }

    setState(() {
      _isAnswerSubmitted = true;
      _selectedAnswer = answerIndex;
    });

    _timer?.cancel();

    try {
      final gameService = ref.read(gameServiceProvider);
      final isCorrect = await gameService.submitAnswer(
        _currentSession!.id,
        'demo_player_1',
        _currentQuestion!.id,
        answerIndex,
        Duration(seconds: 30 - _timeRemaining),
      );

      // Update score
      if (isCorrect) {
        setState(() {
          _score += 10;
        });
      }

      // Show result using adaptive snackbar
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: isCorrect ? 'Correct! 🎉' : 'Incorrect! Try again.',
          isError: !isCorrect,
          duration: const Duration(seconds: 2),
        );
      }

      // Wait a bit then move to next question
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _nextQuestion();
        }
      });
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error submitting answer: $e',
          isError: true,
        );
      }
    }
  }

  void _nextQuestion() {
    if (_currentSession == null) return;

    final nextIndex = _currentQuestionIndex + 1;
    if (nextIndex < _currentSession!.questions.length) {
      setState(() {
        _currentQuestionIndex = nextIndex;
        _currentQuestion = _currentSession!.questions[nextIndex];
        _timeRemaining = _currentQuestion!.timeLimit;
        _isAnswerSubmitted = false;
        _selectedAnswer = null;
      });
      _startTimer();
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    if (_currentSession == null) return;

    try {
      final gameService = ref.read(gameServiceProvider);
      await gameService.endGameSession(_currentSession!.id);

      // Calculate game duration
      final gameDuration = _gameStartTime != null
          ? DateTime.now().difference(_gameStartTime!).inSeconds
          : 0;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameResultScreen(gameDuration: gameDuration),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error ending game: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    if (_showDifficultySelection) {
      return _buildDifficultySelectionScreen(themeData, colorScheme);
    }

    if (_showTopicSelection) {
      return _buildTopicSelectionScreen(themeData, colorScheme);
    }

    if (_showQuestionCountSelection) {
      return _buildQuestionCountSelectionScreen(themeData, colorScheme);
    }

    if (_showTimeLimitSelection) {
      return _buildTimeLimitSelectionScreen(themeData, colorScheme);
    }

    if (_isLoading) {
      return _buildLoadingScreen(themeData, colorScheme);
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(themeData, colorScheme);
    }

    if (_showResults) {
      return _buildResultsScreen(themeData, colorScheme);
    }

    if (_currentSession == null || _currentQuestion == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading game...',
                style: themeData.typography.bodyLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AdaptiveUISystem.adaptiveAppBar(
        context: context,
        title: 'Math Quiz',
        themeData: themeData,
        colorScheme: colorScheme,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.adaptiveLayout.contentPadding,
              vertical: context.adaptiveLayout.contentPadding / 2,
            ),
            decoration: BoxDecoration(
              color: _timeRemaining <= 10
                  ? Colors.red
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_timeRemaining}s',
              style: themeData.typography.labelLarge.copyWith(
                color: _timeRemaining <= 10
                    ? Colors.white
                    : colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value:
                  (_currentQuestionIndex + 1) /
                  _currentSession!.questions.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_currentSession!.questions.length}',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Question card
            Expanded(
              child: Card(
                color: colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Question text
                      Text(
                        _currentQuestion!.question,
                        style: themeData.typography.headlineMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Answer options
                      ..._currentQuestion!.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = _selectedAnswer == index;
                        final isCorrect =
                            index == _currentQuestion!.correctAnswer;

                        Color backgroundColor =
                            colorScheme.surfaceContainerHighest;
                        Color textColor = colorScheme.onSurfaceVariant;

                        if (_isAnswerSubmitted) {
                          if (isCorrect) {
                            backgroundColor = Colors.green;
                            textColor = Colors.white;
                          } else if (isSelected) {
                            backgroundColor = Colors.red;
                            textColor = Colors.white;
                          }
                        } else if (isSelected) {
                          backgroundColor = colorScheme.primary;
                          textColor = colorScheme.onPrimary;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: _isAnswerSubmitted
                                ? null
                                : () => _submitAnswer(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? textColor
                                          : colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(
                                          65 + index,
                                        ), // A, B, C, D
                                        style: themeData.typography.labelLarge
                                            .copyWith(
                                              color: isSelected
                                                  ? backgroundColor
                                                  : colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: themeData.typography.bodyLarge
                                          .copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  if (_isAnswerSubmitted && isCorrect)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  if (_isAnswerSubmitted &&
                                      isSelected &&
                                      !isCorrect)
                                    Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Score display
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.adaptiveLayout.contentPadding,
                vertical: context.adaptiveLayout.contentPadding / 2,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Score: $_score',
                style: themeData.typography.labelLarge.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelectionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Difficulty',
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
          padding: EdgeInsets.all(context.adaptiveLayout.sectionSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Your Challenge Level',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: context.adaptiveLayout.cardSpacing,
                  mainAxisSpacing: context.adaptiveLayout.cardSpacing,
                  children: [
                    _buildDifficultyCard(
                      GameDifficulty.easy,
                      'Easy',
                      'Perfect for beginners',
                      Icons.school,
                      Colors.green,
                      themeData,
                      colorScheme,
                    ),
                    _buildDifficultyCard(
                      GameDifficulty.normal,
                      'Normal',
                      'Balanced challenge',
                      Icons.trending_up,
                      Colors.blue,
                      themeData,
                      colorScheme,
                    ),
                    _buildDifficultyCard(
                      GameDifficulty.genius,
                      'Genius',
                      'Advanced concepts',
                      Icons.psychology,
                      Colors.orange,
                      themeData,
                      colorScheme,
                    ),
                    _buildDifficultyCard(
                      GameDifficulty.quantum,
                      'Quantum',
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
    GameDifficulty difficulty,
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
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  context.adaptiveLayout.contentPadding / 1.5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              SizedBox(height: context.adaptiveLayout.cardSpacing * 0.75),
              Text(
                title,
                style: themeData.typography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.adaptiveLayout.cardSpacing / 3),
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
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.adaptiveLayout.sectionSpacing),
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
              SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
              Text(
                'From PreK to Grade 12',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),
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
        _isGridView
            ? GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: children,
              )
            : Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: child,
                      ),
                    )
                    .toList(),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          'Question Count',
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
                    _buildQuestionCountOption(
                      10,
                      'Quick Quiz',
                      'Perfect for a quick practice',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCountOption(
                      25,
                      'Standard Quiz',
                      'Balanced learning session',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCountOption(
                      50,
                      'Extended Quiz',
                      'Comprehensive practice',
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCountOption(
                      100,
                      'Marathon Quiz',
                      'Ultimate challenge',
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

  Widget _buildQuestionCountOption(
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
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: themeData.typography.headlineSmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              color: colorScheme.outline.withValues(alpha: 0.5),
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
          'Time Limit',
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
                'Select Time Limit',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How much time per question?',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildTimeLimitOption(
                      15,
                      'Quick (15s)',
                      'Fast-paced challenge',
                      Icons.speed,
                      Colors.green,
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeLimitOption(
                      30,
                      'Standard (30s)',
                      'Balanced timing',
                      Icons.timer,
                      Colors.blue,
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeLimitOption(
                      45,
                      'Relaxed (45s)',
                      'More time to think',
                      Icons.schedule,
                      Colors.orange,
                      themeData,
                      colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeLimitOption(
                      60,
                      'Extended (1m)',
                      'Maximum thinking time',
                      Icons.hourglass_empty,
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

  Widget _buildTimeLimitOption(
    int timeLimit,
    String title,
    String subtitle,
    IconData icon,
    Color color,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
              color: colorScheme.outline.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
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
              'Generating Classic Questions...',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creating personalized learning experience',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: themeData.typography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Failed to load game',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _showDifficultySelection = true;
                    _showTopicSelection = false;
                    _showQuestionCountSelection = false;
                    _showTimeLimitSelection = false;
                    _selectedDifficulty = null;
                    _selectedTopic = null;
                    _selectedQuestionCount = null;
                    _selectedTimeLimit = 30;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: themeData.typography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Text(
                'Game Complete!',
                style: themeData.typography.headlineLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Results card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Score display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Final Score',
                              style: themeData.typography.titleMedium.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              results['totalScore'].toString(),
                              style: themeData.typography.displaySmall.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Statistics
                      _buildStatRow(
                        'Questions',
                        results['totalQuestions'].toString(),
                        themeData,
                        colorScheme,
                      ),
                      _buildStatRow(
                        'Correct',
                        results['correctAnswers'].toString(),
                        themeData,
                        colorScheme,
                      ),
                      _buildStatRow(
                        'Accuracy',
                        '${results['accuracy'].toStringAsFixed(1)}%',
                        themeData,
                        colorScheme,
                      ),
                      _buildStatRow(
                        'Difficulty',
                        results['difficulty'].toString().toUpperCase(),
                        themeData,
                        colorScheme,
                      ),
                      _buildStatRow(
                        'Time Spent',
                        '${results['timeSpent']}s',
                        themeData,
                        colorScheme,
                      ),

                      const SizedBox(height: 24),

                      // AI Insights
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  size: 20,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Classic Insights',
                                  style: themeData.typography.titleSmall
                                      .copyWith(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              results['aiInsights'],
                              style: themeData.typography.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
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
                      child: Text(
                        'Back to Home',
                        style: themeData.typography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showDifficultySelection = true;
                          _showTopicSelection = false;
                          _showQuestionCountSelection = false;
                          _showTimeLimitSelection = false;
                          _showResults = false;
                          _gameResults = null;
                          _selectedDifficulty = null;
                          _selectedTopic = null;
                          _selectedQuestionCount = null;
                          _selectedTimeLimit = 30;
                          _score = 0;
                          _gameStartTime = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Try Again',
                        style: themeData.typography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildStatRow(
    String label,
    String value,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: themeData.typography.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: themeData.typography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Game result screen
class GameResultScreen extends ConsumerWidget {
  final int gameDuration;

  const GameResultScreen({super.key, this.gameDuration = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'Game Complete!',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: themeData.typography.headlineLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You completed the math quiz!',
                style: themeData.typography.bodyLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Time: ${gameDuration}s',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Play Again',
                  style: themeData.typography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
