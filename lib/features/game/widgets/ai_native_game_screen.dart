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

  // Time limit state
  int _selectedTimeLimit = 30;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    initializePreferencesSync();
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
  bool get soundEnabled => true;

  @override
  bool get hapticFeedbackEnabled => true;

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
  void onSoundEnabledChanged(bool enabled) {}

  @override
  void onHapticFeedbackChanged(bool enabled) {}

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

        if (_selectedDifficulty != null &&
            _selectedTopic != null &&
            _selectedQuestionCount != null) {
          _showTopicSelection = false;
          _showQuestionCountSelection = false;
          _showTimeLimitSelection = false;
          _startGame();
        }
      });
    }
  }

  void _regenerateQuestionsIfNeeded() {
    if (!_showResults &&
        !_isLoading &&
        _selectedDifficulty != null &&
        _selectedTopic != null &&
        _selectedQuestionCount != null) {
      _startGame();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timeRemaining = _selectedTimeLimit;
    _startTimer();
  }

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

      setState(() {
        _selectedDifficulty = _mapGameDifficultyToAI(
          preferences.preferredDifficulty,
        );
        _selectedTopic = preferences.preferredCategory;
        _selectedQuestionCount = preferences.preferredQuestionCount;
        _timeRemaining = preferences.preferredTimeLimit;

        if (_selectedDifficulty != null &&
            _selectedTopic != null &&
            _selectedQuestionCount != null) {
          _showTopicSelection = false;
          _showQuestionCountSelection = false;
          _showTimeLimitSelection = false;
          _startGame();
        }
      });
    } catch (e) {
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
        userId: 'demo_user',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

    if (_isLoading) {
      return _buildLoadingScreen(colorScheme);
    }
    if (_errorMessage != null) {
      return _buildErrorScreen(colorScheme);
    }
    if (_showResults) {
      return _buildResultsScreen(colorScheme);
    }
    if (_questions != null) {
      return _buildGameScreen(colorScheme);
    }
    if (_showTimeLimitSelection) {
      return _buildTimeLimitSelectionScreen(colorScheme);
    }
    if (_showQuestionCountSelection) {
      return _buildQuestionCountSelectionScreen(colorScheme);
    }
    if (_showTopicSelection) {
      return _buildTopicSelectionScreen(colorScheme);
    }
    return _buildDifficultySelectionScreen(colorScheme);
  }

  // --- UI Helper methods ---
  // (All .withValues(alpha: ...) replaced with .withValues(alpha:...))

  // Example loading screen
  Widget _buildLoadingScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
    );
  }

  // Example error screen
  Widget _buildErrorScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _restartGame,
              child: const Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }

  // Example results screen
  Widget _buildResultsScreen(ColorScheme colorScheme) {
    final results = _gameResults ?? {};
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quiz Complete!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score: ${results['score'] ?? 0}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Correct: ${results['correctAnswers'] ?? 0} / ${results['totalQuestions'] ?? 0}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Time: ${results['timeSpent'] ?? 0}s',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Accuracy: ${((results['accuracy'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Example game screen (simplified)
  Widget _buildGameScreen(ColorScheme colorScheme) {
    final question = _questions![_currentQuestionIndex];
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Question ${_currentQuestionIndex + 1} / ${_questions!.length}',
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showRestartDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: _timeRemaining / _selectedTimeLimit,
              color: colorScheme.primary,
              backgroundColor: colorScheme.primary.withValues(alpha:0.1),
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (i) {
              final isSelected = _selectedAnswerIndex == i;
              final isCorrect =
                  _isAnswerSelected && i == question.correctAnswer;
              final isWrong = _isAnswerSelected && isSelected && !isCorrect;
              return GestureDetector(
                onTap: !_isAnswerSelected ? () => _selectAnswer(i) : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: _getAnswerGradient(
                      isSelected,
                      isCorrect,
                      isWrong,
                      colorScheme,
                    ),
                    border: Border.all(
                      color: _getAnswerBorderColor(
                        isSelected,
                        isCorrect,
                        isWrong,
                        colorScheme,
                      ),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getAnswerShadowColor(
                          isCorrect,
                          isWrong,
                          colorScheme,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getOptionLetterColor(
                          isSelected,
                          isCorrect,
                          isWrong,
                          colorScheme,
                        ).withValues(alpha:0.15),
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (_isAnswerSelected && isCorrect)
                        Icon(Icons.check_circle, color: Colors.green),
                      if (_isAnswerSelected && isWrong)
                        Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            if (_isAnswerSelected &&
                _currentQuestionIndex < _questions!.length - 1)
              ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('Next'),
              ),
            if (_isAnswerSelected &&
                _currentQuestionIndex == _questions!.length - 1)
              ElevatedButton(onPressed: _endGame, child: const Text('Finish')),
          ],
        ),
      ),
    );
  }

  // You would implement _buildDifficultySelectionScreen, _buildTopicSelectionScreen,
  // _buildQuestionCountSelectionScreen, _buildTimeLimitSelectionScreen similarly,
  // using .withOpacity for all color alpha values and following Material 3 design.

  // --- Color/Gradient helpers ---
  LinearGradient _getAnswerGradient(
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    ColorScheme colorScheme,
  ) {
    if (isCorrect) {
      return LinearGradient(
        colors: [Colors.green.withValues(alpha:0.2), Colors.green.withValues(alpha:0.1)],
      );
    } else if (isWrong) {
      return LinearGradient(
        colors: [Colors.red.withValues(alpha:0.2), Colors.red.withValues(alpha:0.1)],
      );
    } else if (isSelected) {
      return LinearGradient(
        colors: [
          colorScheme.primary.withValues(alpha:0.2),
          colorScheme.primary.withValues(alpha:0.1),
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
    return colorScheme.outline.withValues(alpha:0.3);
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
    if (isCorrect) return Colors.green.withValues(alpha:0.3);
    if (isWrong) return Colors.red.withValues(alpha:0.3);
    return colorScheme.primary.withValues(alpha:0.2);
  }

  // Missing method definitions
  Widget _buildTimeLimitSelectionScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Time Limit'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Choose time limit per question:'),
            const SizedBox(height: 20),
            ...List.generate(4, (index) {
              final timeLimits = [15, 30, 45, 60];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: () => _selectTimeLimit(timeLimits[index]),
                  child: Text('${timeLimits[index]} seconds'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountSelectionScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Question Count'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('How many questions?'),
            const SizedBox(height: 20),
            ...List.generate(4, (index) {
              final counts = [5, 10, 15, 20];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: () => _selectQuestionCount(counts[index]),
                  child: Text('${counts[index]} questions'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelectionScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Topic'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Choose a math topic:'),
            const SizedBox(height: 20),
            ...GameCategory.values.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => _selectTopic(category),
                  child: Text(category.name.toUpperCase()),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelectionScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Difficulty'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Choose difficulty level:'),
            const SizedBox(height: 20),
            ...AIDifficulty.values.map((difficulty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => _selectDifficulty(difficulty),
                  child: Text(difficulty.name.toUpperCase()),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
