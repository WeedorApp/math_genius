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
// Removed unused mixin imports
import '../services/game_service.dart';
import '../../user_management/services/user_management_service.dart';

/// Ultra-Optimized Quiz Screen
/// World-class design with maximum screen utilization and best UX
class UltraOptimizedQuiz extends ConsumerStatefulWidget {
  const UltraOptimizedQuiz({super.key});

  @override
  ConsumerState<UltraOptimizedQuiz> createState() => _UltraOptimizedQuizState();
}

class _UltraOptimizedQuizState extends ConsumerState<UltraOptimizedQuiz>
    with TickerProviderStateMixin {
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
  final Set<String> _categoriesPlayed = {};

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  // Removed unused _progressAnimation

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
    _loadUserGradeLevel();
    _loadPreferencesAndGame();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Removed unused _progressAnimation initialization
  }

  Future<void> _loadUserGradeLevel() async {
    try {
      final userService = ref.read(userManagementServiceProvider);
      final currentUser = await userService.getCurrentUser();
      if (currentUser?.gradeLevel != null && mounted) {
        setState(() {
          _userGradeLevel = currentUser!.gradeLevel!;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading grade level: $e');
    }
  }

  Future<void> _loadPreferencesAndGame() async {
    await _loadPreferences();
    await _loadGame();
  }

  Future<void> _loadPreferences() async {
    try {
      final currentPrefs = ref.read(currentUserGamePreferencesProvider);
      if (currentPrefs != null && mounted) {
        setState(() {
          _category = currentPrefs.preferredCategory;
          _difficulty = currentPrefs.preferredDifficulty;
          _questionCount = currentPrefs.preferredQuestionCount;
          _timeLimit = currentPrefs.preferredTimeLimit;
          _soundOn = currentPrefs.soundEnabled;
          // Note: hapticEnabled property may not exist in UserGamePreferences
          // _hapticOn = currentPrefs.hapticEnabled;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _loadGame() async {
    setState(() => _isLoading = true);

    try {
      final gameService = ref.read(gameServiceProvider);
      final aiQuestions = await gameService.generateAIQuestions(
        category: _category,
        difficulty: _difficulty,
        count: _questionCount,
        gradeLevel: _userGradeLevel,
        forceRefresh: true,
      );

      // Convert AIQuestion to Map<String, dynamic>
      final questions = aiQuestions.map((aiQ) => {
        'question': aiQ.question,
        'options': aiQ.options,
        'correctIndex': aiQ.correctAnswer,
        'hint': aiQ.hint,
        'explanation': aiQ.explanation,
      }).toList();

      if (mounted) {
        setState(() {
          _questions = questions;
          _currentIndex = 0;
          _score = 0;
          _showResults = false;
          _currentStreak = 0;
          _isOnFire = false;
          _answerHistory.clear();
          _timeRemaining = _timeLimit;
          _questionStartTime = DateTime.now();
          _isLoading = false;
        });

        _startTimer();
        _slideController.forward();
        _bounceController.forward();

        // Play game start sound
        try {
          final audioService = ref.read(audioServiceProvider);
          audioService.playSound(SoundType.gameStart, category: _category.name);
        } catch (e) {
          // Audio service not available - continue without sound
        }

        _categoriesPlayed.add(_category.name);
      }
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
        
        // Time warning at 10 seconds
        if (_timeRemaining == 10) {
          try {
            final audioService = ref.read(audioServiceProvider);
            audioService.playSound(SoundType.timeWarning);
          } catch (e) {
            // Continue without sound
          }
        }
      } else {
        timer.cancel();
        if (mounted) _submitAnswer(-1); // Time's up
      }
    });
  }

  void _submitAnswer(int selectedIndex) {
    if (_currentIndex >= _questions.length) return;

    final question = _questions[_currentIndex];
    final correctIndex = question['correctIndex'] as int;
    final isCorrect = selectedIndex == correctIndex;

    // Calculate response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 0;

    _answerHistory.add(isCorrect);
    _updateGameStats(isCorrect, responseTime);

    if (isCorrect) {
      _score++;
      _currentStreak++;
      _bestStreak = _currentStreak > _bestStreak ? _currentStreak : _bestStreak;
      _isOnFire = _currentStreak >= 5;
    } else {
      _currentStreak = 0;
      _isOnFire = false;
    }

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
    if (isCorrect && _score == 1) {
      _showAchievement('First Success!', '⭐ Got your first question correct!', Colors.amber);
    }

    if (_currentStreak == 5) {
      _showAchievement('Streak Master!', '⚡ 5 questions in a row!', Colors.blue);
    }

    if (_currentStreak == 10) {
      _showAchievement('On Fire!', '🔥 10 questions in a row!', Colors.orange);
    }
  }

  void _showAchievement(String title, String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.white, size: 20),
            const SizedBox(width: 8),
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
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _moveToNextQuestion() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          if (_currentIndex < _questions.length - 1) {
            _currentIndex++;
            _timeRemaining = _timeLimit;
            _questionStartTime = DateTime.now();
            _slideController.reset();
            _slideController.forward();
          } else {
            // Game complete
            final accuracy = (_score / _questions.length) * 100;
            if (accuracy == 100) {
              _showAchievement('Perfect Score!', '🌟 100% accuracy achieved!', Colors.purple);
            }

            setState(() => _showResults = true);
            _bounceController.repeat(reverse: true);

            // Play game complete sound
            try {
              final audioService = ref.read(audioServiceProvider);
              audioService.playSound(SoundType.gameComplete, category: _category.name);
            } catch (e) {
              // Continue without sound
            }

            _logGameProgress();
          }
        });
        _startTimer();
      }
    });
  }

  void _logGameProgress() {
    if (kDebugMode) {
      debugPrint('📊 Game Progress:');
      debugPrint('   Category: ${_category.name}');
      debugPrint('   Grade: ${_userGradeLevel.name}');
      debugPrint('   Score: $_score/${_questions.length}');
      debugPrint('   Best Streak: $_bestStreak');
      debugPrint('   Avg Response: ${(_averageResponseTime / 1000).toStringAsFixed(1)}s');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    // Watch preferences for real-time updates
    final currentPrefs = ref.watch(currentUserGamePreferencesProvider);
    if (currentPrefs != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final shouldReload = _category != currentPrefs.preferredCategory ||
              _difficulty != currentPrefs.preferredDifficulty ||
              _questionCount != currentPrefs.preferredQuestionCount ||
              _timeLimit != currentPrefs.preferredTimeLimit;

          if (shouldReload) {
            _applySynchronizedPreferences(currentPrefs);
          }
        }
      });
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_showResults) {
      return _buildUltraResultsScreen();
    }

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Loading questions...')));
    }

    return _buildUltraQuizScreen(isTablet);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(_category).withValues(alpha: 0.15),
              _getCategoryColor(_category).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _bounceAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(_category).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(_category),
                    size: 48,
                    color: _getCategoryColor(_category),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(_category)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing ${_category.name} questions...',
                style: TextStyle(
                  fontSize: 16,
                  color: _getCategoryColor(_category),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltraQuizScreen(bool isTablet) {
    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Error loading question. Please restart.')),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as List<String>;
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(_category).withValues(alpha: 0.08),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Ultra-compact header with progress
              _buildUltraHeader(progress),
              
              // Main content area
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        // Compact stats row
                        _buildCompactStats(),
                        
                        const SizedBox(height: 8),
                        
                        // Question section (optimized)
                        _buildUltraQuestionCard(question),
                        
                        const SizedBox(height: 12),
                        
                        // Answer options (optimized)
                        Expanded(
                          child: _buildUltraAnswerGrid(options, isTablet),
                        ),
                        
                        const SizedBox(height: 4),
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

  Widget _buildUltraHeader(double progress) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _getCategoryColor(_category),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(_category).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with back button, title, and timer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Back button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/game-selection');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Title and progress
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(_category),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _category.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_currentIndex + 1} of ${_questions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Timer
                  Container(
                    width: 60,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 10 
                          ? Colors.red.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$_timeRemaining',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Progress bar
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score
          Expanded(
            child: _buildStatItem(
              Icons.star,
              '$_score',
              'Score',
              Colors.amber,
            ),
          ),
          
          Container(width: 1, height: 30, color: Colors.grey[200]),
          
          // Streak
          Expanded(
            child: _buildStatItem(
              _isOnFire ? Icons.local_fire_department : Icons.flash_on,
              '$_currentStreak',
              'Streak',
              _isOnFire ? Colors.orange : Colors.blue,
            ),
          ),
          
          Container(width: 1, height: 30, color: Colors.grey[200]),
          
          // Accuracy
          Expanded(
            child: _buildStatItem(
              Icons.trending_up,
              '${_answerHistory.isEmpty ? 0 : ((_answerHistory.where((a) => a).length / _answerHistory.length) * 100).round()}%',
              'Accuracy',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraQuestionCard(Map<String, dynamic> question) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(_category).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category icon (smaller)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(_category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(_category),
                size: 24,
                color: _getCategoryColor(_category),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Question text
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Hint button if available
            if (question['hint'] != null && question['hint'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showHint(question['hint']),
                icon: Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: _getCategoryColor(_category),
                ),
                label: Text(
                  'Hint',
                  style: TextStyle(
                    color: _getCategoryColor(_category),
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(60, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: _getCategoryColor(_category).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUltraAnswerGrid(List<String> options, bool isTablet) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        childAspectRatio: isTablet ? 5.0 : 6.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return ScaleTransition(
          scale: _bounceAnimation,
          child: _buildUltraAnswerButton(options[index], index),
        );
      },
    );
  }

  Widget _buildUltraAnswerButton(String option, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    
    final color = colors[index % colors.length];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _submitAnswer(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            // Letter badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
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
            
            const SizedBox(width: 10),
            
            // Option text
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
    );
  }

  Widget _buildUltraResultsScreen() {
    final accuracy = _questions.isEmpty ? 0.0 : (_score / _questions.length) * 100;
    final isExcellent = accuracy >= 90;
    final isGood = accuracy >= 70;
    final resultColor = isExcellent ? Colors.green : isGood ? Colors.orange : Colors.red;
    final resultIcon = isExcellent ? Icons.star : isGood ? Icons.thumb_up : Icons.trending_up;
    final resultMessage = isExcellent ? 'Excellent!' : isGood ? 'Good Job!' : 'Keep Practicing!';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              resultColor.withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Result header
                ScaleTransition(
                  scale: _bounceAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                    ),
                    child: Column(
                      children: [
                        Icon(resultIcon, color: resultColor, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          resultMessage,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${accuracy.round()}% Accuracy',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Stats grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildResultStatCard(
                        Icons.score,
                        '$_score / ${_questions.length}',
                        'Score',
                        Colors.blue,
                      ),
                      _buildResultStatCard(
                        Icons.flash_on,
                        '$_bestStreak',
                        'Best Streak',
                        Colors.orange,
                      ),
                      _buildResultStatCard(
                        Icons.timer,
                        '${(_averageResponseTime / 1000).toStringAsFixed(1)}s',
                        'Avg Time',
                        Colors.green,
                      ),
                      _buildResultStatCard(
                        _getCategoryIcon(_category),
                        _category.name,
                        'Category',
                        _getCategoryColor(_category),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/game-selection');
                          }
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _getCategoryColor(_category),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: _getCategoryColor(_category)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHint(String hint) {
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
        content: Text(hint),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _playAgain() {
    _timer?.cancel();
    _slideController.reset();
    _bounceController.reset();
    _progressController.reset();

    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showResults = false;
      _currentStreak = 0;
      _bestStreak = 0;
      _isOnFire = false;
      _answerHistory.clear();
      _averageResponseTime = 0.0;
    });

    _loadGame();
  }

  // Helper methods for category colors and icons
  Color _getCategoryColor(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return const Color(0xFF4CAF50);
      case GameCategory.subtraction:
        return const Color(0xFF2196F3);
      case GameCategory.multiplication:
        return const Color(0xFFFF9800);
      case GameCategory.division:
        return const Color(0xFF9C27B0);
      case GameCategory.fractions:
        return const Color(0xFFE91E63);
      case GameCategory.percentages:
        return const Color(0xFF00BCD4);
      case GameCategory.algebra:
        return const Color(0xFF3F51B5);
      case GameCategory.geometry:
        return const Color(0xFF795548);
      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Icons.add;
      case GameCategory.subtraction:
        return Icons.remove;
      case GameCategory.multiplication:
        return Icons.close;
      case GameCategory.division:
        return Icons.percent;
      case GameCategory.fractions:
        return Icons.pie_chart;
      case GameCategory.percentages:
        return Icons.show_chart;
      case GameCategory.algebra:
        return Icons.functions;
      case GameCategory.geometry:
        return Icons.category;
      default:
        return Icons.calculate;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _bounceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _applySynchronizedPreferences(UserGamePreferences preferences) {
    setState(() {
      _category = preferences.preferredCategory;
      _difficulty = preferences.preferredDifficulty;
      _questionCount = preferences.preferredQuestionCount;
      _timeLimit = preferences.preferredTimeLimit;
      _soundOn = preferences.soundEnabled;
      // Note: hapticEnabled property may not exist
      // _hapticOn = preferences.hapticEnabled;
    });
    _loadGame();
  }
}
