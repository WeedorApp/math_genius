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

/// Simple Unified Quiz Screen
/// Clean, production-ready implementation with unified preferences
class SimpleUnifiedQuiz extends ConsumerStatefulWidget {
  const SimpleUnifiedQuiz({super.key});

  @override
  ConsumerState<SimpleUnifiedQuiz> createState() => _SimpleUnifiedQuizState();
}

class _SimpleUnifiedQuizState extends ConsumerState<SimpleUnifiedQuiz>
    with
        GamePreferencesMixin<SimpleUnifiedQuiz>,
        UnifiedPreferenceSyncMixin<SimpleUnifiedQuiz>,
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
  int _totalCorrect = 0;
  int _totalIncorrect = 0;
  bool _isOnFire = false; // 5+ streak
  List<bool> _answerHistory = [];
  double _averageResponseTime = 0.0;
  DateTime? _questionStartTime;

  // Animation controllers for enhanced UI
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // Preferences (implementing GamePreferencesMixin)
  GameDifficulty _difficulty = GameDifficulty.normal;
  GameCategory _category = GameCategory.addition;
  int _questionCount = 10;
  int _timeLimit = 30;
  bool _soundOn = true;
  bool _hapticOn = true;
  GradeLevel _userGradeLevel =
      GradeLevel.grade5; // Default, will be loaded from user

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('✅ NEW SIMPLE UNIFIED QUIZ SCREEN BEING USED! (Correct)');
      debugPrint('🎮 SIMPLE UNIFIED QUIZ INITIALIZING');
    }
    _initializeAnimations();
    initializePreferencesSync();
    initializeUnifiedPreferenceSync(); // Add comprehensive sync
    _loadUserGradeLevel(); // Load user's actual grade level
    _loadPreferencesAndGame(); // Load preferences first, then game
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  /// Load preferences first, then initialize game with correct settings
  Future<void> _loadPreferencesAndGame() async {
    try {
      // Load current preferences first
      final prefs = ref.read(currentUserGamePreferencesProvider);
      if (prefs != null) {
        debugPrint('🔄 Loading preferences before game initialization');
        debugPrint('   Preference category: ${prefs.preferredCategory.name}');
        debugPrint(
          '   Preference difficulty: ${prefs.preferredDifficulty.name}',
        );

        // Apply preferences immediately
        setState(() {
          _difficulty = prefs.preferredDifficulty;
          _category = prefs.preferredCategory;
          _questionCount = prefs.preferredQuestionCount;
          _timeLimit = prefs.preferredTimeLimit;
          _soundOn = prefs.soundEnabled;
          _hapticOn = prefs.hapticFeedbackEnabled;
        });
      }

      // Now load the game with the correct preferences
      await _loadGame();
    } catch (e) {
      debugPrint('❌ Error loading preferences and game: $e');
      // Fallback to loading game with defaults
      _loadGame();
    }
  }

  /// Load the user's actual grade level from their profile
  Future<void> _loadUserGradeLevel() async {
    try {
      final userService = ref.read(userManagementServiceProvider);
      final currentUser = await userService.getCurrentUser();

      if (currentUser?.gradeLevel != null) {
        setState(() {
          _userGradeLevel = currentUser!.gradeLevel!;
        });
        debugPrint('👤 Loaded user grade level: ${_userGradeLevel.name}');
      } else {
        debugPrint(
          '⚠️ User has no grade level set, using default: ${_userGradeLevel.name}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading user grade level: $e');
      // Keep default grade level
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
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
      // Debug: Print what category we're requesting
      debugPrint('🎯 Loading game with category: ${_category.name}');
      debugPrint('🎯 Difficulty: ${_difficulty.name}');
      debugPrint('🎯 Question count: $_questionCount');

      final gameService = ref.read(gameServiceProvider);
      final aiQuestions = await gameService.generateAIQuestions(
        gradeLevel: _userGradeLevel, // Use actual user grade level!
        category: _category,
        difficulty: _difficulty,
        count: _questionCount,
        forceRefresh:
            true, // Always get fresh questions to reflect preference changes
      );

      // Safety check: Ensure we have valid questions
      if (aiQuestions.isEmpty) {
        setState(() {
          _isLoading = false;
        });
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
                'correct': q.correctAnswer.clamp(
                  0,
                  q.options.length - 1,
                ), // Clamp to valid range
                'category': q.category.name,
                'hint': q.hint,
                'explanation': q.explanation,
              },
            )
            .toList();
        _currentIndex = 0;
        _score = 0;
        _currentStreak = 0;
        _totalCorrect = 0;
        _totalIncorrect = 0;
        _isOnFire = false;
        _answerHistory.clear();
        _timeRemaining = _timeLimit;
        _questionStartTime = DateTime.now();
        _isLoading = false;
      });

      // Debug: Verify questions match requested category AND grade
      debugPrint(
        '✅ Generated ${aiQuestions.length} questions for ${_category.name} (${_userGradeLevel.name})',
      );
      for (int i = 0; i < aiQuestions.length && i < 3; i++) {
        debugPrint(
          '   Q${i + 1}: ${aiQuestions[i].category.name} (${aiQuestions[i].gradeLevel.name}) - ${aiQuestions[i].question.substring(0, 50)}...',
        );
      }

      _startTimer();
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

    // Safety check to prevent RangeError
    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      debugPrint(
        '❌ Range error prevented: _currentIndex $_currentIndex >= ${_questions.length}',
      );
      return;
    }

    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 0;

    final isCorrect = answerIndex == _questions[_currentIndex]['correct'];
    final question = _questions[_currentIndex];

    // Update game statistics
    _answerHistory.add(isCorrect);
    _updateGameStats(isCorrect, responseTime);

    if (isCorrect) {
      setState(() {
        _score++;
        _currentStreak++;
        _totalCorrect++;
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
        _totalIncorrect++;
        _isOnFire = false;
      });
    }

    // Enhanced feedback with streak information
    _showEnhancedFeedback(isCorrect, question);

    // Trigger haptic feedback if enabled
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
    // Update average response time
    final totalAnswers = _answerHistory.length;
    _averageResponseTime =
        ((_averageResponseTime * (totalAnswers - 1)) + responseTime) /
        totalAnswers;

    // Adaptive difficulty adjustment
    _checkForDifficultyAdjustment();
  }

  void _checkForDifficultyAdjustment() {
    // Only adjust if we have enough data and auto-adjust is enabled
    if (_answerHistory.length < 3) return;

    final recentAnswers = _answerHistory.take(5).toList();
    final recentAccuracy =
        recentAnswers.where((answer) => answer).length / recentAnswers.length;

    // Suggest difficulty increase if doing very well
    if (recentAccuracy >= 0.9 && _currentStreak >= 5) {
      _suggestDifficultyIncrease();
    }
    // Suggest difficulty decrease if struggling
    else if (recentAccuracy <= 0.4 && _currentStreak == 0) {
      _suggestDifficultyDecrease();
    }
  }

  void _suggestDifficultyIncrease() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('You\'re doing great! Try a harder difficulty?'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Upgrade',
          textColor: Colors.white,
          onPressed: () => _increaseDifficulty(),
        ),
      ),
    );
  }

  void _suggestDifficultyDecrease() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.support, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Having trouble? Try an easier difficulty?')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Easier',
          textColor: Colors.white,
          onPressed: () => _decreaseDifficulty(),
        ),
      ),
    );
  }

  void _increaseDifficulty() {
    GameDifficulty newDifficulty;
    switch (_difficulty) {
      case GameDifficulty.easy:
        newDifficulty = GameDifficulty.normal;
        break;
      case GameDifficulty.normal:
        newDifficulty = GameDifficulty.genius;
        break;
      case GameDifficulty.genius:
        newDifficulty = GameDifficulty.quantum;
        break;
      case GameDifficulty.quantum:
        return; // Already at max
    }

    setState(() => _difficulty = newDifficulty);
    _loadGame(); // Reload with new difficulty
  }

  void _decreaseDifficulty() {
    GameDifficulty newDifficulty;
    switch (_difficulty) {
      case GameDifficulty.quantum:
        newDifficulty = GameDifficulty.genius;
        break;
      case GameDifficulty.genius:
        newDifficulty = GameDifficulty.normal;
        break;
      case GameDifficulty.normal:
        newDifficulty = GameDifficulty.easy;
        break;
      case GameDifficulty.easy:
        return; // Already at min
    }

    setState(() => _difficulty = newDifficulty);
    _loadGame(); // Reload with new difficulty
  }

  void _showEnhancedFeedback(bool isCorrect, Map<String, dynamic> question) {
    if (!mounted) return;

    String message;
    Color backgroundColor;
    IconData icon;

    if (isCorrect) {
      if (_isOnFire) {
        message = '🔥 ON FIRE! ${_currentStreak} in a row!';
        backgroundColor = Colors.orange;
        icon = Icons.local_fire_department;
      } else if (_currentStreak >= 3) {
        message = '⚡ ${_currentStreak} streak! Keep going!';
        backgroundColor = Colors.blue;
        icon = Icons.flash_on;
      } else {
        message = 'Correct! 🎉';
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
      }
    } else {
      message = 'Try again! 💪';
      if (question['hint'] != null && question['hint'].toString().isNotEmpty) {
        message += '\nHint: ${question['hint']}';
      }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _moveToNextQuestion() {
    // Next question or finish with smooth animations
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _questions.isNotEmpty) {
        // Safety check to prevent range errors
        if (_currentIndex < _questions.length - 1) {
          // Animate out current question
          _fadeController.reverse().then((_) {
            if (mounted) {
              // Double-check bounds before updating index
              if (_currentIndex + 1 < _questions.length) {
                setState(() {
                  _currentIndex++;
                  _timeRemaining = _timeLimit;
                  _questionStartTime =
                      DateTime.now(); // Reset timer for response tracking
                });

                // Animate in new question
                _slideController.reset();
                _fadeController.forward();
                _slideController.forward();
                _progressController.forward();
                _startTimer();
              } else {
                // Safety fallback - show results
                setState(() => _showResults = true);
                _fadeController.forward();
                _pulseController.repeat(reverse: true);
              }
            }
          });
        } else {
          // Game complete - show results with animation
          _fadeController.reverse().then((_) {
            if (mounted) {
              setState(() => _showResults = true);
              _fadeController.forward();
              _pulseController.repeat(reverse: true);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch preferences and trigger updates
    final currentPrefs = ref.watch(currentUserGamePreferencesProvider);

    // Check if preferences have changed and update accordingly
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
            // Use the mixin's synchronized preference application
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
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        _category,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getCategoryIcon(_category),
                      size: 60,
                      color: _getCategoryColor(_category),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCategoryColor(_category),
                  ),
                  strokeWidth: 4,
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
      return Scaffold(
        appBar: AppBar(title: const Text('Math Quiz')),
        body: const Center(child: Text('Loading questions...')),
      );
    }

    return _buildQuestionScreen();
  }

  Widget _buildQuestionScreen() {
    // Safety check to prevent RangeError
    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      debugPrint(
        '❌ Range error prevented in _buildQuestionScreen: _currentIndex $_currentIndex >= ${_questions.length}',
      );
      return const Scaffold(
        body: Center(
          child: Text('Error loading question. Please restart the game.'),
        ),
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
              _getCategoryColor(_category).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              _buildEnhancedHeader(),

              // Animated Progress Bar
              _buildAnimatedProgress(),

              // Enhanced Score and Timer Display
              _buildEnhancedScoreTimer(),

              // Main Question Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Enhanced Question Card
                          Flexible(
                            flex: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _buildEnhancedQuestionCard(question),
                                ),
                                // Hint button
                                if (question['hint'] != null &&
                                    question['hint'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showHint(question['hint']),
                                      icon: const Icon(
                                        Icons.lightbulb_outline,
                                        size: 16,
                                      ),
                                      label: const Text('Need a hint?'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _getCategoryColor(
                                          _category,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Enhanced Answer Options
                          Flexible(
                            flex: 3,
                            child: _buildEnhancedAnswerOptions(options),
                          ),
                        ],
                      ),
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

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(_category),
            _getCategoryColor(_category).withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(_category).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _category.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(_category),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgress() {
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[200],
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return LinearProgressIndicator(
            value:
                ((_currentIndex + 1) / _questions.length) *
                _progressAnimation.value,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCategoryColor(_category),
            ),
            borderRadius: BorderRadius.circular(4),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedScoreTimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score Section
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Score',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(_category),
                  ),
                ),
              ],
            ),
          ),

          // Streak Section
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOnFire ? Icons.local_fire_department : Icons.flash_on,
                      color: _isOnFire ? Colors.orange : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Streak',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_currentStreak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isOnFire ? Colors.orange : Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Timer Section
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: _timeRemaining <= 10 ? Colors.red : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Time',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: _timeRemaining <= 10 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining <= 10 ? Colors.red : Colors.blue,
                  ),
                  child: Text('$_timeRemaining'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuestionCard(Map<String, dynamic> question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(_category).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              question['question'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAnswerOptions(List<String> options) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: double.infinity,
            height: 56, // Fixed height to ensure consistent spacing
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _submitAnswer(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        _getOptionColor(index),
                        _getOptionColor(index).withValues(alpha: 0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border.all(
                      color: _getOptionColor(index).withValues(alpha: 0.5),
                      width: 1,
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
                            color: Colors.white,
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
            colors: [
              resultColor.withValues(alpha: 0.1),
              Colors.white,
              resultColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Animated Result Icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(resultIcon, size: 60, color: resultColor),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Result Message
                  Text(
                    resultMessage,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: resultColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: resultColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
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
                              _bestStreak >= 5
                                  ? Icons.local_fire_department
                                  : Icons.flash_on,
                              _bestStreak >= 5 ? Colors.orange : Colors.blue,
                            ),
                            _buildStatColumn(
                              'Accuracy',
                              '${accuracy.toStringAsFixed(1)}%',
                              Icons.track_changes,
                              resultColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Category',
                              _category.name,
                              _getCategoryIcon(_category),
                              _getCategoryColor(_category),
                            ),
                            _buildStatColumn(
                              'Avg Time',
                              '${(_averageResponseTime / 1000).toStringAsFixed(1)}s',
                              Icons.speed,
                              Colors.purple,
                            ),
                            _buildStatColumn(
                              'Grade',
                              _userGradeLevel.name.toUpperCase(),
                              Icons.school,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey[200],
                          ),
                          child: LinearProgressIndicator(
                            value: accuracy / 100,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              resultColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Enhanced Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          onPressed: _playAgain,
                          icon: Icons.refresh,
                          label: 'Play Again',
                          color: _getCategoryColor(_category),
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          onPressed: () => context.pop(),
                          icon: Icons.home,
                          label: 'Home',
                          color: Colors.grey.shade600,
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: isPrimary ? 8 : 2,
          shadowColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: color.withValues(alpha: 0.5),
              width: isPrimary ? 0 : 2,
            ),
          ),
        ),
      ),
    );
  }

  void _showHint(String hint) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: _getCategoryColor(_category)),
            const SizedBox(width: 8),
            const Text('Hint'),
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

  void _playAgain() {
    // Stop any running timers and reset animations
    _timer?.cancel();
    _fadeController.reset();
    _slideController.reset();
    _progressController.reset();

    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showResults = false;
      _timeRemaining = _timeLimit;
      _questions.clear(); // Clear questions to prevent stale data
      // Reset enhanced game stats
      _currentStreak = 0;
      _totalCorrect = 0;
      _totalIncorrect = 0;
      _isOnFire = false;
      _answerHistory.clear();
      _averageResponseTime = 0.0;
      _questionStartTime = DateTime.now();
    });

    // Start fresh animations
    _fadeController.forward();
    _loadGame();
  }

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
    final shouldReload =
        _difficulty != prefs.preferredDifficulty ||
        categoryChanged ||
        _questionCount != prefs.preferredQuestionCount ||
        _timeLimit != prefs.preferredTimeLimit;

    // Clear cache if category changed to ensure fresh questions
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

    // Reload game if core parameters changed (with range error protection)
    if (shouldReload && _questions.isNotEmpty) {
      debugPrint('🔄 Reloading game due to preference changes');
      // Reset game state to prevent range errors
      _currentIndex = 0;
      _score = 0;
      _timer?.cancel();
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
              Text(
                'Settings synced: ${prefs.preferredCategory.name} - ${prefs.preferredDifficulty.name}',
              ),
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
