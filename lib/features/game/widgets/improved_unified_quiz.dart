import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Core imports
import '../../../core/barrel.dart';

// Game imports
import '../models/game_model.dart';
import '../mixins/game_preferences_mixin.dart';
import '../mixins/unified_preference_sync_mixin.dart';
import '../services/game_service.dart';
import '../../user_management/services/user_management_service.dart';

/// Improved Unified Quiz Screen
/// Enhanced with streaks, hints, adaptive difficulty, and better UX
class ImprovedUnifiedQuiz extends ConsumerStatefulWidget {
  const ImprovedUnifiedQuiz({super.key});

  @override
  ConsumerState<ImprovedUnifiedQuiz> createState() =>
      _ImprovedUnifiedQuizState();
}

class _ImprovedUnifiedQuizState extends ConsumerState<ImprovedUnifiedQuiz>
    with
        GamePreferencesMixin<ImprovedUnifiedQuiz>,
        UnifiedPreferenceSyncMixin<ImprovedUnifiedQuiz>,
        TickerProviderStateMixin {
  // Game state
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _showResults = false;
  Timer? _timer;
  int _timeRemaining = 30;

  // Enhanced game mechanics
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _isOnFire = false;
  final List<bool> _answerHistory = [];
  double _averageResponseTime = 0.0;
  DateTime? _questionStartTime;

  // Achievement tracking (simplified)
  final Set<String> _categoriesPlayed = {};

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Preferences
  GameDifficulty _difficulty = GameDifficulty.normal;
  GameCategory _category = GameCategory.addition;
  int _questionCount = 10;
  int _timeLimit = 30;
  bool _soundOn = true;
  bool _hapticOn = true;
  GradeLevel _userGradeLevel = GradeLevel.grade5;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    initializePreferencesSync();
    initializeUnifiedPreferenceSync();
    _loadUserGradeLevel();
    _loadPreferencesAndGame();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
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
  String get gameMode => 'improved';

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

  Future<void> _loadPreferencesAndGame() async {
    try {
      final prefs = ref.read(currentUserGamePreferencesProvider);
      if (prefs != null) {
        setState(() {
          _difficulty = prefs.preferredDifficulty;
          _category = prefs.preferredCategory;
          _questionCount = prefs.preferredQuestionCount;
          _timeLimit = prefs.preferredTimeLimit;
          _soundOn = prefs.soundEnabled;
          _hapticOn = prefs.hapticFeedbackEnabled;
        });
      }
      await _loadGame();
    } catch (e) {
      debugPrint('❌ Error loading preferences: $e');
      _loadGame();
    }
  }

  Future<void> _loadUserGradeLevel() async {
    try {
      final userService = ref.read(userManagementServiceProvider);
      final currentUser = await userService.getCurrentUser();

      if (currentUser?.gradeLevel != null) {
        setState(() {
          _userGradeLevel = currentUser!.gradeLevel!;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user grade level: $e');
    }
  }

  Future<void> _loadGame() async {
    setState(() => _isLoading = true);

    try {
      final gameService = ref.read(gameServiceProvider);
      final aiQuestions = await gameService.generateAIQuestions(
        gradeLevel: _userGradeLevel,
        category: _category,
        difficulty: _difficulty,
        count: _questionCount,
        forceRefresh: true,
      );

      if (aiQuestions.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No questions generated. Please try again.'),
            ),
          );
        }
        return;
      }

      setState(() {
        _questions = aiQuestions
            .map(
              (q) => {
                'question': q.question,
                'options': q.options,
                'correct': q.correctAnswer.clamp(0, q.options.length - 1),
                'hint': q.hint,
                'explanation': q.explanation,
              },
            )
            .toList();
        _currentIndex = 0;
        _score = 0;
        _currentStreak = 0;
        _isOnFire = false;
        _answerHistory.clear();
        _timeRemaining = _timeLimit;
        _questionStartTime = DateTime.now();
        _isLoading = false;
      });

      _startTimer();

      // Play game start sound
      try {
        final audioService = ref.read(audioServiceProvider);
        audioService.playSound(SoundType.gameStart, category: _category.name);
      } catch (e) {
        // Audio service not available - continue without sound
      }

      // Track category for achievements
      _categoriesPlayed.add(_category.name);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading game: $e')));
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

    // Safety check
    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      return;
    }

    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 0;

    final isCorrect = answerIndex == _questions[_currentIndex]['correct'];
    final question = _questions[_currentIndex];

    // Update statistics
    _answerHistory.add(isCorrect);
    _updateGameStats(isCorrect, responseTime);

    if (isCorrect) {
      setState(() {
        _score++;
        _currentStreak++;
        if (_currentStreak > _bestStreak) {
          _bestStreak = _currentStreak;
        }
        if (_currentStreak >= 5) {
          _isOnFire = true;
        }
      });
    } else {
      setState(() {
        _currentStreak = 0;
        _isOnFire = false;
      });
    }

    // Show feedback
    _showEnhancedFeedback(isCorrect, question);

    // Play sound effects
    _playAudioFeedback(isCorrect);

    // Check for achievements
    _checkAchievements(isCorrect);

    // Haptic feedback
    if (_hapticOn) {
      if (isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }

    // Move to next question
    _moveToNextQuestion();
  }

  void _updateGameStats(bool isCorrect, int responseTime) {
    final totalAnswers = _answerHistory.length;
    _averageResponseTime =
        ((_averageResponseTime * (totalAnswers - 1)) + responseTime) /
        totalAnswers;
  }

  void _playAudioFeedback(bool isCorrect) {
    if (!_soundOn) return;

    try {
      final audioService = ref.read(audioServiceProvider);

      if (isCorrect) {
        if (_isOnFire) {
          audioService.playSound(SoundType.fire, category: _category.name);
        } else if (_currentStreak >= 3) {
          audioService.playSound(SoundType.streak, category: _category.name);
        } else {
          audioService.playSound(SoundType.correct, category: _category.name);
        }
      } else {
        audioService.playSound(SoundType.incorrect, category: _category.name);
      }
    } catch (e) {
      // Audio service not available - continue without sound
    }
  }

  void _checkAchievements(bool isCorrect) {
    // Simple achievement notifications
    if (isCorrect && _score == 1) {
      _showSimpleAchievement(
        'First Success!',
        '⭐ Got your first question correct!',
        Colors.amber,
      );
    }

    if (_currentStreak == 5) {
      _showSimpleAchievement(
        'Streak Master!',
        '⚡ 5 questions in a row!',
        Colors.blue,
      );
    }

    if (_currentStreak == 10) {
      _showSimpleAchievement(
        'On Fire!',
        '🔥 10 questions in a row!',
        Colors.orange,
      );
    }
  }

  void _showSimpleAchievement(String title, String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(message, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Complex achievement celebration removed for simplicity

  void _showEnhancedFeedback(bool isCorrect, Map<String, dynamic> question) {
    if (!mounted) return;

    String message;
    Color backgroundColor;
    IconData icon;

    if (isCorrect) {
      if (_isOnFire) {
        message = '🔥 ON FIRE! $_currentStreak in a row!';
        backgroundColor = Colors.orange;
        icon = Icons.local_fire_department;
      } else if (_currentStreak >= 3) {
        message = '⚡ $_currentStreak streak! Keep going!';
        backgroundColor = Colors.blue;
        icon = Icons.flash_on;
      } else {
        message = 'Correct! 🎉';
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
      }
    } else {
      message = 'Try again! 💪';
      backgroundColor = Colors.red;
      icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _moveToNextQuestion() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _questions.isNotEmpty) {
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _timeRemaining = _timeLimit;
            _questionStartTime = DateTime.now();
          });
          _startTimer();
        } else {
          // Game complete - check for perfect score
          final accuracy = (_score / _questions.length) * 100;
          if (accuracy == 100) {
            _showSimpleAchievement(
              'Perfect Score!',
              '🌟 100% accuracy achieved!',
              Colors.purple,
            );
          }

          setState(() => _showResults = true);
          _pulseController.repeat(reverse: true);

          // Play game complete sound
          try {
            final audioService = ref.read(audioServiceProvider);
            audioService.playSound(
              SoundType.gameComplete,
              category: _category.name,
            );
          } catch (e) {
            // Continue without sound
          }

          // Log game progress
          _logGameProgress();
        }
      }
    });
  }

  void _showHint(String hint) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hint'),
          ],
        ),
        content: Text(hint, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch preferences for real-time updates
    final currentPrefs = ref.watch(currentUserGamePreferencesProvider);

    if (currentPrefs != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final categoryChanged = _category != currentPrefs.preferredCategory;
          final shouldReload =
              _difficulty != currentPrefs.preferredDifficulty ||
              categoryChanged ||
              _questionCount != currentPrefs.preferredQuestionCount ||
              _timeLimit != currentPrefs.preferredTimeLimit;

          if (shouldReload) {
            applySynchronizedPreferences(currentPrefs);
          }
        }
      });
    }

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(_category).withValues(alpha: 0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Icon(
                    _getCategoryIcon(_category),
                    size: 60,
                    color: _getCategoryColor(_category),
                  ),
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCategoryColor(_category),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing ${_category.name} questions...',
                  style: TextStyle(
                    fontSize: 16,
                    color: _getCategoryColor(_category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_showResults) {
      return _buildResultsScreen();
    }

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Loading questions...')));
    }

    return _buildQuestionScreen();
  }

  Widget _buildQuestionScreen() {
    // Safety check
    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Error loading question. Please restart.')),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as List<String>;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(_category).withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Progress
                _buildProgress(),
                // Score/Streak/Timer
                _buildScoreDisplay(),
                // Question content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Question card
                        _buildQuestionCard(question),
                        // Answer options
                        _buildAnswerOptions(options),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(_category),
            _getCategoryColor(_category).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/game-selection');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _category.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Icon(
              _getCategoryIcon(_category),
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: (_currentIndex + 1) / _questions.length,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(_category)),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(height: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Score', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          // Streak
          Expanded(
            child: Column(
              children: [
                Icon(
                  _isOnFire ? Icons.local_fire_department : Icons.flash_on,
                  color: _isOnFire ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentStreak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isOnFire ? Colors.orange : Colors.blue,
                  ),
                ),
                const Text('Streak', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          // Timer
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.timer,
                  color: _timeRemaining <= 10 ? Colors.red : Colors.blue,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_timeRemaining',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining <= 10 ? Colors.red : Colors.blue,
                  ),
                ),
                const Text('Time', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getCategoryColor(_category).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(_category),
              size: 32,
              color: _getCategoryColor(_category),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            if (question['hint'] != null &&
                question['hint'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showHint(question['hint']),
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: const Text('Need a hint?'),
                style: TextButton.styleFrom(
                  foregroundColor: _getCategoryColor(_category),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(List<String> options) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _submitAnswer(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getOptionColor(index),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _questions.isEmpty
        ? 0.0
        : (_score / _questions.length) * 100;
    final isExcellent = accuracy >= 90;
    final isGood = accuracy >= 70;
    final resultColor = isExcellent
        ? Colors.green
        : isGood
        ? Colors.orange
        : Colors.red;
    final resultIcon = isExcellent
        ? Icons.star
        : isGood
        ? Icons.thumb_up
        : Icons.trending_up;
    final resultMessage = isExcellent
        ? 'Excellent!'
        : isGood
        ? 'Good Job!'
        : 'Keep Practicing!';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [resultColor.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Icon(resultIcon, size: 80, color: resultColor),
                ),
                const SizedBox(height: 24),
                Text(
                  resultMessage,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 32),
                // Stats card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Score',
                              '$_score/${_questions.length}',
                              Icons.star,
                              Colors.amber,
                            ),
                            _buildStatColumn(
                              'Best Streak',
                              '$_bestStreak',
                              Icons.flash_on,
                              Colors.blue,
                            ),
                            _buildStatColumn(
                              'Accuracy',
                              '${accuracy.toStringAsFixed(1)}%',
                              Icons.track_changes,
                              resultColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _playAgain,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(_category),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),

                // Achievement display removed for simplicity
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Progress saving simplified for now
  void _logGameProgress() {
    if (kDebugMode) {
      debugPrint('📊 Game Progress:');
      debugPrint('   Category: ${_category.name}');
      debugPrint('   Grade: ${_userGradeLevel.name}');
      debugPrint('   Score: $_score/${_questions.length}');
      debugPrint('   Best Streak: $_bestStreak');
      debugPrint(
        '   Avg Response: ${(_averageResponseTime / 1000).toStringAsFixed(1)}s',
      );
    }
  }

  void _playAgain() {
    _timer?.cancel();
    _fadeController.reset();
    _pulseController.reset();

    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showResults = false;
      _timeRemaining = _timeLimit;
      _questions.clear();
      _currentStreak = 0;
      _isOnFire = false;
      _answerHistory.clear();
      _averageResponseTime = 0.0;
      _questionStartTime = DateTime.now();
    });

    _fadeController.forward();
    _loadGame();
  }

  // Helper methods
  Color _getOptionColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade600,
    ];
    return colors[index % colors.length];
  }

  Color _getCategoryColor(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Colors.green.shade600;
      case GameCategory.subtraction:
        return Colors.blue.shade600;
      case GameCategory.multiplication:
        return Colors.orange.shade600;
      case GameCategory.division:
        return Colors.red.shade600;
      case GameCategory.fractions:
        return Colors.purple.shade600;
      case GameCategory.decimals:
        return Colors.teal.shade600;
      case GameCategory.percentages:
        return Colors.indigo.shade600;
      case GameCategory.geometry:
        return Colors.pink.shade600;
      case GameCategory.algebra:
        return Colors.deepOrange.shade600;
      case GameCategory.calculus:
        return Colors.brown.shade600;
      case GameCategory.wordProblems:
        return Colors.cyan.shade600;
      case GameCategory.patterns:
        return Colors.lime.shade600;
      case GameCategory.measurement:
        return Colors.amber.shade600;
      case GameCategory.dataAnalysis:
        return Colors.blueGrey.shade600;
    }
  }

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Icons.add_circle;
      case GameCategory.subtraction:
        return Icons.remove_circle;
      case GameCategory.multiplication:
        return Icons.close;
      case GameCategory.division:
        return Icons.pie_chart;
      case GameCategory.fractions:
        return Icons.pie_chart_outline;
      case GameCategory.decimals:
        return Icons.looks_one;
      case GameCategory.percentages:
        return Icons.percent;
      case GameCategory.geometry:
        return Icons.pentagon;
      case GameCategory.algebra:
        return Icons.functions;
      case GameCategory.calculus:
        return Icons.calculate;
      case GameCategory.wordProblems:
        return Icons.description;
      case GameCategory.patterns:
        return Icons.pattern;
      case GameCategory.measurement:
        return Icons.straighten;
      case GameCategory.dataAnalysis:
        return Icons.analytics;
    }
  }

  // UnifiedPreferenceSyncMixin implementations
  @override
  void applyGamePreferences(UserGamePreferences prefs) {
    final categoryChanged = _category != prefs.preferredCategory;

    if (categoryChanged) {
      final gameService = ref.read(gameServiceProvider);
      gameService.clearCachedQuestionsForCategory(_category);
      gameService.clearCachedQuestionsForCategory(prefs.preferredCategory);
    }

    setState(() {
      _difficulty = prefs.preferredDifficulty;
      _category = prefs.preferredCategory;
      _questionCount = prefs.preferredQuestionCount;
      _timeLimit = prefs.preferredTimeLimit;
      _soundOn = prefs.soundEnabled;
      _hapticOn = prefs.hapticFeedbackEnabled;
    });

    if (_questions.isNotEmpty) {
      _currentIndex = 0;
      _score = 0;
      _timer?.cancel();
      _loadGame();
    }
  }

  @override
  void applyLearningPreferences(UserGamePreferences prefs) {}

  @override
  void applyAIPreferences(UserGamePreferences prefs) {}

  @override
  void applyAccessibilityPreferences(UserGamePreferences prefs) {}

  @override
  void applyUIPreferences(UserGamePreferences prefs) {}
}
