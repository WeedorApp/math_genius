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
import '../services/game_service.dart';
import '../../user_management/services/user_management_service.dart';

/// Revolutionary Quiz UI - The Ultimate Educational App Experience
/// Features: Glassmorphism, Advanced Animations, Perfect Typography, Gamification
class RevolutionaryQuizUI extends ConsumerStatefulWidget {
  const RevolutionaryQuizUI({super.key});

  @override
  ConsumerState<RevolutionaryQuizUI> createState() => _RevolutionaryQuizUIState();
}

class _RevolutionaryQuizUIState extends ConsumerState<RevolutionaryQuizUI>
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

  // Advanced animation controllers
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  // Removed unused _particleAnimation
  late Animation<double> _pulseAnimation;

  // Preferences
  GameDifficulty _difficulty = GameDifficulty.normal;
  GameCategory _category = GameCategory.addition;
  int _questionCount = 10;
  int _timeLimit = 30;
  bool _soundOn = true;
  final bool _hapticOn = true;
  
  // Performance optimizations integrated
  GradeLevel _userGradeLevel = GradeLevel.grade5;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserGradeLevel();
    _loadPreferencesAndGame();
  }

  void _initializeAnimations() {
    // Slide animation for smooth transitions
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bounce animation for interactive feedback
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Glow animation for premium effects
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particle animation for celebrations
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulse animation for emphasis
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Removed unused _particleAnimation initialization

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticInOut),
    );

    // Start initial animations with performance optimization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _glowController.status != AnimationStatus.forward) {
        _glowController.repeat(reverse: true);
      }
    });
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
        
        // Time warning effects
        if (_timeRemaining == 10) {
          _pulseController.repeat();
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
    if (_currentIndex >= _questions.length || _questions.isEmpty) return;

    final question = _questions[_currentIndex];
    final correctIndex = question['correctIndex'] as int?;
    if (correctIndex == null) return;
    
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
      
      // Trigger celebration animations
      if (_particleController.status != AnimationStatus.forward) {
        _particleController.reset();
        _particleController.forward();
      }
      if (_isOnFire && _glowController.status != AnimationStatus.forward) {
        _glowController.repeat(reverse: true);
      }
    } else {
      _currentStreak = 0;
      _isOnFire = false;
      _glowController.stop();
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

    // Trigger celebration particle effect
    if (_particleController.status != AnimationStatus.forward) {
      _particleController.reset();
      _particleController.forward();
    }

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
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            
            // Log state transition
            if (kDebugMode) {
              debugPrint('✅ Moved to question ${_currentIndex + 1}/${_questions.length}');
            }
            if (_particleController.status == AnimationStatus.forward) {
              _particleController.reset();
            }
            _pulseController.stop();
            _pulseController.reset();
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

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(_category).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/game-selection');
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(_category),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      return _buildRevolutionaryLoadingScreen();
    }

    if (_showResults) {
      return _buildRevolutionaryResultsScreen();
    }

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Loading questions...')));
    }

    // Validate game state before building UI
    if (!_validateGameState()) {
      return _buildErrorScreen('Invalid game state detected');
    }

    // Monitor animation performance in debug mode (throttled)
    if (kDebugMode && _currentIndex == 0) {
      _monitorAnimationPerformance();
    }

    return _buildRevolutionaryQuizScreen(isTablet);
  }

  Widget _buildRevolutionaryLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _getCategoryColor(_category).withValues(alpha: 0.2),
              _getCategoryColor(_category).withValues(alpha: 0.05),
              Colors.white,
            ],
            center: Alignment.center,
            radius: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated loading icon with glow effect
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(_category).withValues(alpha: 0.4 + (_glowAnimation.value * 0.3)),
                          blurRadius: 30 + (_glowAnimation.value * 20),
                          spreadRadius: 5 + (_glowAnimation.value * 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(_category),
                      size: 48,
                      color: _getCategoryColor(_category),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Premium loading indicator
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(_category)),
                  strokeWidth: 4,
                  backgroundColor: _getCategoryColor(_category).withValues(alpha: 0.2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading text with animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Text(
                      'Preparing ${_category.name} questions...',
                      style: TextStyle(
                        fontSize: 18,
                        color: _getCategoryColor(_category),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Creating the perfect challenge for you',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevolutionaryQuizScreen(bool isTablet) {
    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(_category).withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading question',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Please restart the game'),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as List<String>? ?? [];
    if (options.isEmpty) {
      return _buildErrorScreen('No answer options available');
    }
    
    final progress = _questions.isNotEmpty ? (_currentIndex + 1) / _questions.length : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(_category).withValues(alpha: 0.05),
              Colors.white,
              _getCategoryColor(_category).withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Revolutionary header with glassmorphism
              _buildGlassmorphicHeader(progress),
              
              // Main content with advanced animations
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        // Enhanced stats with micro-interactions
                        _buildPremiumStatsBar(),
                        
                        const SizedBox(height: 12),
                        
                        // Premium question card with advanced effects
                        Flexible(
                          flex: 2,
                          child: _buildPremiumQuestionCard(question),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Revolutionary answer grid
                        Flexible(
                          flex: 3,
                          child: _buildRevolutionaryAnswerGrid(options, isTablet),
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

  Widget _buildGlassmorphicHeader(double progress) {
    return Container(
      height: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(_category).withValues(alpha: 0.9),
            _getCategoryColor(_category).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(_category).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Glassmorphic background effect
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top row with enhanced elements
                  Expanded(
                    child: Row(
                      children: [
                        // Premium back button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
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
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Enhanced title section
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _glowAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2 + (_glowAnimation.value * 0.1)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(_category),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _category.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Question ${_currentIndex + 1} of ${_questions.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Premium timer with pulsing effect
                        AnimatedBuilder(
                          animation: _timeRemaining <= 10 ? _pulseAnimation : _bounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _timeRemaining <= 10 ? _pulseAnimation.value : 1.0,
                              child: Container(
                                width: 70,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _timeRemaining <= 10 
                                        ? [Colors.red, const Color(0xFFB91C1C)]
                                        : [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.15)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$_timeRemaining',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Enhanced progress bar with glow effect
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.9 + (_glowAnimation.value * 0.1)),
                            ),
                          );
                        },
                      ),
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

  Widget _buildPremiumStatsBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _getCategoryColor(_category).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score with animation
          Expanded(
            child: _buildPremiumStatItem(
              Icons.star_rounded,
              '$_score',
              'Score',
              Colors.amber,
              _score > 0,
            ),
          ),
          
          Container(width: 1, height: 35, color: Colors.grey[200]),
          
          // Streak with fire effect
          Expanded(
            child: _buildPremiumStatItem(
              _isOnFire ? Icons.local_fire_department_rounded : Icons.flash_on_rounded,
              '$_currentStreak',
              'Streak',
              _isOnFire ? Colors.orange : Colors.blue,
              _currentStreak > 0,
            ),
          ),
          
          Container(width: 1, height: 35, color: Colors.grey[200]),
          
          // Accuracy with trend indicator
          Expanded(
            child: _buildPremiumStatItem(
              Icons.trending_up_rounded,
              '${_answerHistory.isEmpty ? 0 : ((_answerHistory.where((a) => a).length / _answerHistory.length) * 100).round()}%',
              'Accuracy',
              Colors.green,
              _answerHistory.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatItem(IconData icon, String value, String label, Color color, bool animate) {
    return AnimatedBuilder(
      animation: animate ? _bounceAnimation : _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: animate ? _bounceAnimation.value : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumQuestionCard(Map<String, dynamic> question) {
    final questionText = question['question'] as String? ?? 'Question not available';
    final hint = question['hint'] as String?;
    
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 120,
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getCategoryColor(_category).withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: _getCategoryColor(_category).withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enhanced category icon with glow (smaller)
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getCategoryColor(_category).withValues(alpha: 0.15),
                              _getCategoryColor(_category).withValues(alpha: 0.25),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _getCategoryColor(_category).withValues(alpha: 0.3 + (_glowAnimation.value * 0.2)),
                              blurRadius: 12 + (_glowAnimation.value * 8),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCategoryIcon(_category),
                          size: 28,
                          color: _getCategoryColor(_category),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Enhanced question text with better constraints
                  Flexible(
                    child: Text(
                      questionText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Premium hint button (more compact)
                  if (hint != null && hint.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(_category).withValues(alpha: 0.1),
                            _getCategoryColor(_category).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getCategoryColor(_category).withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _showPremiumHint(hint),
                        icon: Icon(
                          Icons.lightbulb_rounded,
                          size: 14,
                          color: _getCategoryColor(_category),
                        ),
                        label: Text(
                          'Hint',
                          style: TextStyle(
                            color: _getCategoryColor(_category),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(80, 32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevolutionaryAnswerGrid(List<String> options, bool isTablet) {
    if (options.isEmpty) {
      return Center(
        child: Text(
          'No answer options available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Ensure we have at least 2 options, max 4
    final validOptions = options.take(4).toList();
    if (validOptions.length < 2) {
      return Center(
        child: Text(
          'Invalid question format',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        childAspectRatio: isTablet ? 4.8 : 5.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: validOptions.length,
      itemBuilder: (context, index) {
        if (index >= validOptions.length) {
          return const SizedBox.shrink();
        }
        
        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: _buildRevolutionaryAnswerButton(validOptions[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildRevolutionaryAnswerButton(String option, int index) {
    // Validate input
    if (option.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue gradient
      [const Color(0xFF10B981), const Color(0xFF047857)], // Green gradient
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Orange gradient
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Purple gradient
    ];
    
    final safeIndex = index.clamp(0, colors.length - 1);
    final colorGradient = colors[safeIndex];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorGradient[0].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _submitAnswer(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colorGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Premium letter badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Enhanced option text
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Subtle arrow indicator
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevolutionaryResultsScreen() {
    final accuracy = _questions.isEmpty ? 0.0 : (_score / _questions.length) * 100;
    final isExcellent = accuracy >= 90;
    final isGood = accuracy >= 70;
    final resultColor = isExcellent ? Colors.green : isGood ? Colors.orange : Colors.red;
    final resultIcon = isExcellent ? Icons.star_rounded : isGood ? Icons.thumb_up_rounded : Icons.trending_up_rounded;
    final resultMessage = isExcellent ? 'Outstanding!' : isGood ? 'Great Job!' : 'Keep Learning!';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              resultColor.withValues(alpha: 0.15),
              resultColor.withValues(alpha: 0.05),
              Colors.white,
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Premium result header
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bounceAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: resultColor.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                colors: [resultColor, Color.lerp(resultColor, Colors.black, 0.2)!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: resultColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(resultIcon, color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              resultMessage,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: resultColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${accuracy.round()}% Accuracy',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Enhanced stats grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildPremiumResultCard(
                        Icons.score_rounded,
                        '$_score / ${_questions.length}',
                        'Final Score',
                        Colors.blue,
                      ),
                      _buildPremiumResultCard(
                        Icons.flash_on_rounded,
                        '$_bestStreak',
                        'Best Streak',
                        Colors.orange,
                      ),
                      _buildPremiumResultCard(
                        Icons.timer_rounded,
                        '${(_averageResponseTime / 1000).toStringAsFixed(1)}s',
                        'Avg Time',
                        Colors.green,
                      ),
                      _buildPremiumResultCard(
                        _getCategoryIcon(_category),
                        _category.name,
                        'Category',
                        _getCategoryColor(_category),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Premium action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getCategoryColor(_category),
                              Color.lerp(_getCategoryColor(_category), Colors.black, 0.2)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _getCategoryColor(_category).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _playAgain,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Play Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getCategoryColor(_category),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/game-selection');
                            }
                          },
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Home'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: _getCategoryColor(_category),
                            elevation: 0,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  Widget _buildPremiumResultCard(IconData icon, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumHint(String? hint) {
    if (hint == null || hint.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 20,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(_category).withValues(alpha: 0.2),
                          _getCategoryColor(_category).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: _getCategoryColor(_category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Hint',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(_category),
                      Color.lerp(_getCategoryColor(_category), Colors.black, 0.2)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _playAgain() {
    try {
      // Cancel timer first
      _timer?.cancel();
      
      // Safely reset all animations
      if (_slideController.status != AnimationStatus.dismissed) {
        _slideController.reset();
      }
      if (_bounceController.status != AnimationStatus.dismissed) {
        _bounceController.reset();
      }
      if (_glowController.status != AnimationStatus.dismissed) {
        _glowController.stop();
        _glowController.reset();
      }
      if (_particleController.status != AnimationStatus.dismissed) {
        _particleController.reset();
      }
      if (_pulseController.status != AnimationStatus.dismissed) {
        _pulseController.stop();
        _pulseController.reset();
      }

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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in _playAgain: $e');
      }
      // Fallback - just reload the game
      _loadGame();
    }
  }

  // Helper methods for category colors and icons
  Color _getCategoryColor(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return const Color(0xFF10B981);
      case GameCategory.subtraction:
        return const Color(0xFF3B82F6);
      case GameCategory.multiplication:
        return const Color(0xFFF59E0B);
      case GameCategory.division:
        return const Color(0xFF8B5CF6);
      case GameCategory.fractions:
        return const Color(0xFFEF4444);
      case GameCategory.percentages:
        return const Color(0xFF06B6D4);
      case GameCategory.algebra:
        return const Color(0xFF6366F1);
      case GameCategory.geometry:
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Icons.add_rounded;
      case GameCategory.subtraction:
        return Icons.remove_rounded;
      case GameCategory.multiplication:
        return Icons.close_rounded;
      case GameCategory.division:
        return Icons.percent_rounded;
      case GameCategory.fractions:
        return Icons.pie_chart_rounded;
      case GameCategory.percentages:
        return Icons.show_chart_rounded;
      case GameCategory.algebra:
        return Icons.functions_rounded;
      case GameCategory.geometry:
        return Icons.category_rounded;
      default:
        return Icons.calculate_rounded;
    }
  }

  @override
  void dispose() {
    // Cancel timer first
    _timer?.cancel();
    
    // Stop all animations before disposing
    _slideController.stop();
    _bounceController.stop();
    _glowController.stop();
    _particleController.stop();
    _pulseController.stop();
    
    // Dispose animation controllers
    _slideController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    
    super.dispose();
  }

  void _applySynchronizedPreferences(UserGamePreferences preferences) {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Applying synchronized preferences:');
        debugPrint('   Category: ${_category.name} → ${preferences.preferredCategory.name}');
        debugPrint('   Difficulty: ${_difficulty.name} → ${preferences.preferredDifficulty.name}');
        debugPrint('   Questions: $_questionCount → ${preferences.preferredQuestionCount}');
        debugPrint('   Time Limit: $_timeLimit → ${preferences.preferredTimeLimit}');
      }

      setState(() {
        _category = preferences.preferredCategory;
        _difficulty = preferences.preferredDifficulty;
        _questionCount = preferences.preferredQuestionCount;
        _timeLimit = preferences.preferredTimeLimit;
        _soundOn = preferences.soundEnabled;
      });
      
      _loadGame();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error applying synchronized preferences: $e');
      }
      // Continue with current preferences if sync fails
    }
  }

  /// Debug helper to validate game state (throttled logging)
  bool _validateGameState() {
    if (_questions.isEmpty) {
      if (kDebugMode) debugPrint('❌ Game state invalid: No questions loaded');
      return false;
    }
    
    if (_currentIndex < 0 || _currentIndex >= _questions.length) {
      if (kDebugMode) debugPrint('❌ Game state invalid: Current index out of bounds ($_currentIndex/${_questions.length})');
      return false;
    }
    
    final currentQuestion = _questions[_currentIndex];
    if (currentQuestion['options'] == null || (currentQuestion['options'] as List).isEmpty) {
      if (kDebugMode) debugPrint('❌ Game state invalid: No options for current question');
      return false;
    }
    
    // Only log success on question transitions, not every build
    return true;
  }

  /// Performance monitoring for animations (throttled)
  void _monitorAnimationPerformance() {
    if (kDebugMode) {
      final activeAnimations = [
        if (_slideController.isAnimating) 'slide',
        if (_bounceController.isAnimating) 'bounce', 
        if (_glowController.isAnimating) 'glow',
        if (_particleController.isAnimating) 'particle',
        if (_pulseController.isAnimating) 'pulse',
      ];
      
      // Only log when animations change or on first question
      if (activeAnimations.isNotEmpty && _currentIndex == 0) {
        debugPrint('🎭 Animation system active: ${activeAnimations.join(', ')}');
      }
    }
  }
}
