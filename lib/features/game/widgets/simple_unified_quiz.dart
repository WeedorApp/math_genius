import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Removed unused import

// Core imports
import '../../../core/barrel.dart';

// Game imports  
import '../models/game_model.dart';
import '../mixins/game_preferences_mixin.dart';
import '../mixins/unified_preference_sync_mixin.dart';
import '../services/game_service.dart';

/// Simple Unified Quiz Screen
/// Clean, production-ready implementation with unified preferences
class SimpleUnifiedQuiz extends ConsumerStatefulWidget {
  const SimpleUnifiedQuiz({super.key});

  @override
  ConsumerState<SimpleUnifiedQuiz> createState() => _SimpleUnifiedQuizState();
}

class _SimpleUnifiedQuizState extends ConsumerState<SimpleUnifiedQuiz> 
    with GamePreferencesMixin<SimpleUnifiedQuiz>, UnifiedPreferenceSyncMixin<SimpleUnifiedQuiz> {
  
  // Game state
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _showResults = false;
  Timer? _timer;
  int _timeRemaining = 30;

  // Preferences (implementing GamePreferencesMixin)
  GameDifficulty _difficulty = GameDifficulty.normal;
  GameCategory _category = GameCategory.addition;
  int _questionCount = 10;
  int _timeLimit = 30;
  bool _soundOn = true;
  bool _hapticOn = true;

  @override
  void initState() {
    super.initState();
    initializePreferencesSync();
    initializeUnifiedPreferenceSync(); // Add comprehensive sync
    _loadGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // GamePreferencesMixin implementation
  @override
  GameDifficulty get selectedDifficulty => _difficulty;
  @override
  GameCategory get selectedCategory => _category;
  @override
  int get selectedQuestionCount => _questionCount;
  @override
  int get selectedTimeLimit => _timeLimit;
  @override
  bool get soundEnabled => _soundOn;
  @override
  bool get hapticFeedbackEnabled => _hapticOn;
  @override
  String get gameMode => 'unified';

  @override
  void onDifficultyChanged(GameDifficulty difficulty) {
    setState(() => _difficulty = difficulty);
  }

  @override
  void onCategoryChanged(GameCategory category) {
    setState(() => _category = category);
  }

  @override
  void onQuestionCountChanged(int count) {
    setState(() => _questionCount = count);
  }

  @override
  void onTimeLimitChanged(int timeLimit) {
    setState(() {
      _timeLimit = timeLimit;
      _timeRemaining = timeLimit;
    });
  }

  @override
  void onSoundEnabledChanged(bool enabled) {
    setState(() => _soundOn = enabled);
  }

  @override
  void onHapticFeedbackChanged(bool enabled) {
    setState(() => _hapticOn = enabled);
  }

  @override
  void onPreferencesLoaded(UserGamePreferences preferences) {
    setState(() {
      _difficulty = preferences.preferredDifficulty;
      _category = preferences.preferredCategory;
      _questionCount = preferences.preferredQuestionCount;
      _timeLimit = preferences.preferredTimeLimit;
      _soundOn = preferences.soundEnabled;
      _hapticOn = preferences.hapticFeedbackEnabled;
    });
    _loadGame();
  }

  Future<void> _loadGame() async {
    setState(() => _isLoading = true);
    
    try {
      final gameService = ref.read(gameServiceProvider);
      final aiQuestions = await gameService.generateAIQuestions(
        gradeLevel: GradeLevel.grade5,
        category: _category,
        difficulty: _difficulty,
        count: _questionCount,
      );

      setState(() {
        _questions = aiQuestions.map((q) => {
          'question': q.question,
          'options': q.options,
          'correct': q.correctAnswer,
        }).toList();
        _currentIndex = 0;
        _score = 0;
        _timeRemaining = _timeLimit;
        _isLoading = false;
      });
      
      _startTimer();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading game: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _submitAnswer(-1);
      }
    });
  }

  void _submitAnswer(int answerIndex) {
    _timer?.cancel();
    
    final isCorrect = answerIndex == _questions[_currentIndex]['correct'];
    if (isCorrect) {
      setState(() => _score++);
    }

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? 'Correct! 🎉' : 'Try again! 💪'),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Next question or finish
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _timeRemaining = _timeLimit;
          });
          _startTimer();
        } else {
          setState(() => _showResults = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Preference synchronization is now handled by UnifiedPreferenceSyncMixin

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showResults) {
      return _buildResultsScreen();
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Math Quiz')),
        body: const Center(
          child: Text('Loading questions...'),
        ),
      );
    }

    return _buildQuestionScreen();
  }

  Widget _buildQuestionScreen() {
    final question = _questions[_currentIndex];
    final options = question['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${_questions.length}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
            ),
            // Score and time
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Score: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Time: $_timeRemaining', 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: _timeRemaining <= 10 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Question
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          question['question'],
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Options
                    ...options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _submitAnswer(index),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: _getOptionColor(index),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(option, style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _questions.isEmpty ? 0.0 : (_score / _questions.length) * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Complete!'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                'Final Score',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '$_score / ${_questions.length}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${accuracy.toStringAsFixed(1)}% Accuracy',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _playAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Play Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
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

  void _playAgain() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showResults = false;
      _timeRemaining = _timeLimit;
    });
    _loadGame();
  }

  Color _getOptionColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    return colors[index % colors.length];
  }

  // UnifiedPreferenceSyncMixin implementations
  @override
  void applyGamePreferences(UserGamePreferences prefs) {
    final shouldReload = _difficulty != prefs.preferredDifficulty ||
                        _category != prefs.preferredCategory ||
                        _questionCount != prefs.preferredQuestionCount ||
                        _timeLimit != prefs.preferredTimeLimit;

    setState(() {
      _difficulty = prefs.preferredDifficulty;
      _category = prefs.preferredCategory;
      _questionCount = prefs.preferredQuestionCount;
      _timeLimit = prefs.preferredTimeLimit;
      _soundOn = prefs.soundEnabled;
      _hapticOn = prefs.hapticFeedbackEnabled;
    });

    // Reload game if core parameters changed
    if (shouldReload && _questions.isNotEmpty) {
      _loadGame();
    }
  }

  @override
  void applyLearningPreferences(UserGamePreferences prefs) {
    // Apply advanced learning preferences if available
    // For SimpleUnifiedQuiz, we use basic implementation
  }

  @override
  void applyAIPreferences(UserGamePreferences prefs) {
    // AI preferences don't apply to SimpleUnifiedQuiz
    // This method is required by the mixin but can be empty
  }

  @override
  void applyAccessibilityPreferences(UserGamePreferences prefs) {
    // Accessibility preferences are handled at the app level
    // This method is required by the mixin but can be empty for games
  }

  @override
  void applyUIPreferences(UserGamePreferences prefs) {
    // UI preferences like theme are handled at the app level
    // This method is required by the mixin but can be empty for games
  }

  @override
  void showSyncFeedback(UserGamePreferences prefs) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sync, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Settings synced: ${prefs.preferredCategory.name} - ${prefs.preferredDifficulty.name}'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
