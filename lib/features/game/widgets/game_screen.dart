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

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    try {
      // Create a demo game session
      final gameService = ref.read(gameServiceProvider);
      final player = GamePlayer(
        id: 'demo_player_1',
        name: 'Math Genius',
        role: PlayerRole.host,
        lastActive: DateTime.now(),
      );

      final session = await gameService.createGameSession(
        name: 'Demo Math Quiz',
        difficulty: GameDifficulty.normal,
        category: GameCategory.addition,
        players: [player],
        questionCount: 5,
        timeLimit: 300,
      );

      setState(() {
        _currentSession = session;
        _currentQuestion = session.questions.isNotEmpty
            ? session.questions[0]
            : null;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing game: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCorrect ? 'Correct! 🎉' : 'Incorrect! Try again.'),
            backgroundColor: isCorrect ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting answer: $e'),
            backgroundColor: Colors.red,
          ),
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

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameResultScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

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
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'Math Quiz',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_currentSession!.questions.length}',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

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

            const SizedBox(height: 24),

            // Score display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Score: ${_currentSession!.players.first.score}',
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
}

/// Game result screen
class GameResultScreen extends ConsumerWidget {
  const GameResultScreen({super.key});

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
