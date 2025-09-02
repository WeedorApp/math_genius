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
/// Features: Performance Optimized, Subtle Animations, Perfect Typography
class RevolutionaryQuizUI extends ConsumerStatefulWidget {
  const RevolutionaryQuizUI({super.key});

  @override
  ConsumerState<RevolutionaryQuizUI> createState() => _RevolutionaryQuizUIState();
}

class _RevolutionaryQuizUIState extends ConsumerState<RevolutionaryQuizUI> {
  // Game state
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _showResults = false;
  bool _answerSubmitted = false;  // Prevent double submissions
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

  // No animation controllers - static interface for best performance

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
    _loadUserGradeLevel();
    _loadPreferencesAndGame();
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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final gameService = ref.read(gameServiceProvider);
      
      // Performance optimized question generation
      final aiQuestions = await gameService.generateAIQuestions(
        category: _category,
        difficulty: _difficulty,
        count: _questionCount,
        gradeLevel: _userGradeLevel,
        forceRefresh: false,  // Use cache for better performance
      );

      if (!mounted) return;  // Check mounted state after async operation

      // Optimized conversion with pre-allocated list
      final questions = List<Map<String, dynamic>>.generate(
        aiQuestions.length,
        (index) {
          final aiQ = aiQuestions[index];
          return {
            'question': aiQ.question,
            'options': aiQ.options,
            'correctIndex': aiQ.correctAnswer,
            'hint': aiQ.hint,
            'explanation': aiQ.explanation,
          };
        },
      );

      if (mounted) {
        setState(() {
          _questions = questions;
          _currentIndex = 0;
          _score = 0;
          _showResults = false;
          _currentStreak = 0;
          _isOnFire = false;
          _answerHistory.clear();
          _answerSubmitted = false;  // Reset for new game
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
        
        // Time warning (sound only, no animations)
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
    if (kDebugMode) {
      debugPrint('🔍 _submitAnswer called with index: $selectedIndex');
      debugPrint('🔍 Answer submitted flag: $_answerSubmitted');
    }

    // Prevent double submissions
    if (_answerSubmitted) {
      if (kDebugMode) debugPrint('❌ Answer already submitted for this question');
      return;
    }

    if (_currentIndex >= _questions.length || _questions.isEmpty) {
      if (kDebugMode) debugPrint('❌ Cannot submit - invalid state');
      return;
    }

    final question = _questions[_currentIndex];
    final correctIndex = question['correctIndex'] as int?;
    if (correctIndex == null) {
      if (kDebugMode) debugPrint('❌ Cannot submit - no correct index');
      return;
    }
    
    // Mark answer as submitted
    _answerSubmitted = true;
    
    final isCorrect = selectedIndex == correctIndex;
    
    if (kDebugMode) {
      debugPrint('✅ Answer submitted: ${isCorrect ? 'CORRECT' : 'INCORRECT'}');
      debugPrint('🎯 Selected: $selectedIndex, Correct: $correctIndex');
    }

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
      
      // Simple success feedback (no excessive animations)
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

    // Simple achievement feedback

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
    Future.delayed(const Duration(milliseconds: 400), () {  // Much faster transition
      if (mounted) {
        setState(() {
          if (_currentIndex < _questions.length - 1) {
            _currentIndex++;
            _timeRemaining = _timeLimit;
            _questionStartTime = DateTime.now();
            _answerSubmitted = false;  // Reset for new question
            // Log state transition
            if (kDebugMode) {
              debugPrint('✅ Moved to question ${_currentIndex + 1}/${_questions.length}');
            }
          } else {
            // Game complete
            final accuracy = (_score / _questions.length) * 100;
            if (accuracy == 100) {
              _showAchievement('Perfect Score!', '🌟 100% accuracy achieved!', Colors.purple);
            }

            setState(() => _showResults = true);

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
    // Cache MediaQuery for performance
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isTablet = screenSize.width > 600;

    // Optimize preference watching (only when needed)
    if (!_isLoading && !_showResults) {
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
    final categoryColor = _getCategoryColor(_category);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              categoryColor.withValues(alpha: 0.05),
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
              // Optimized loading icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(_category),
                  size: 48,
                  color: categoryColor,
                ),
              ),
              const SizedBox(height: 32),
              
              // Optimized loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  strokeWidth: 3,
                  backgroundColor: categoryColor.withValues(alpha: 0.15),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Simple loading text
              Text(
                'Preparing ${_getCategoryDisplayName(_category)} questions...',
                style: TextStyle(
                  fontSize: 18,
                  color: _getCategoryColor(_category),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
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
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Enhanced stats
                      _buildPremiumStatsBar(),
                      
                      const SizedBox(height: 12),
                      
                      // Question card (no animations)
                      Flexible(
                        flex: 2,
                        child: _buildPremiumQuestionCard(question),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Answer grid (no animations)
                      Flexible(
                        flex: 3,
                        child: _buildRevolutionaryAnswerGrid(options, isTablet),
                      ),
                      
                      const SizedBox(height: 4),
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
                        
                        // Enhanced title section (overflow-safe)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Compact title row
                              Flexible(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(_category),
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _getCategoryDisplayName(_category),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Q${_currentIndex + 1}/${_questions.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Simple timer (no animations)
                        Container(
                          width: 70,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _timeRemaining <= 10 
                                  ? [Colors.red.shade400, Colors.red.shade600]
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
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
    // Cache calculations for performance
    final accuracy = _answerHistory.isEmpty 
        ? 0 
        : ((_answerHistory.where((a) => a).length / _answerHistory.length) * 100).round();
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score
          Expanded(
            child: _buildOptimizedStatItem(
              Icons.star_rounded,
              '$_score',
              'Score',
              Colors.amber,
            ),
          ),
          
          Container(width: 1, height: 35, color: Colors.grey.shade200),
          
          // Streak
          Expanded(
            child: _buildOptimizedStatItem(
              _isOnFire ? Icons.local_fire_department_rounded : Icons.flash_on_rounded,
              '$_currentStreak',
              'Streak',
              _isOnFire ? Colors.orange : Colors.blue,
            ),
          ),
          
          Container(width: 1, height: 35, color: Colors.grey.shade200),
          
          // Accuracy
          Expanded(
            child: _buildOptimizedStatItem(
              Icons.trending_up_rounded,
              '$accuracy%',
              'Accuracy',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedStatItem(IconData icon, String value, String label, Color color) {
    return Padding(
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
                  color: color.withValues(alpha: 0.12),
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
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumQuestionCard(Map<String, dynamic> question) {
    final questionText = question['question'] as String? ?? 'Question not available';
    final hint = question['hint'] as String?;
    final categoryColor = _getCategoryColor(_category);
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 280,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Optimized category icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(_category),
                      size: 26,
                      color: categoryColor,
                    ),
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
          );
  }

  Widget _buildRevolutionaryAnswerGrid(List<String> options, bool isTablet) {
    if (options.isEmpty) {
      return const Center(
        child: Text(
          'No answer options available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Ensure we have valid options (performance optimized)
    final validOptions = options.length > 4 ? options.sublist(0, 4) : options;
    if (validOptions.length < 2) {
      return const Center(
        child: Text(
          'Invalid question format',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Use Column for better performance than GridView
    if (isTablet && validOptions.length >= 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildRevolutionaryAnswerButton(validOptions[0], 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildRevolutionaryAnswerButton(validOptions[1], 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRevolutionaryAnswerButton(validOptions[2], 2)),
              const SizedBox(width: 12),
              if (validOptions.length > 3)
                Expanded(child: _buildRevolutionaryAnswerButton(validOptions[3], 3))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );
    } else {
      // Single column for mobile or fewer options
      return Column(
        children: validOptions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRevolutionaryAnswerButton(entry.value, entry.key),
          );
        }).toList(),
      );
    }
  }

  Widget _buildRevolutionaryAnswerButton(String option, int index) {
    // Validate input
    if (option.isEmpty) {
      return const SizedBox.shrink();
    }

    // Performance optimized color selection
    const colors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Green  
      Color(0xFFF59E0B), // Orange
      Color(0xFF8B5CF6), // Purple
    ];
    
    final buttonColor = colors[index.clamp(0, colors.length - 1)];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _answerSubmitted ? null : () {
          if (kDebugMode) {
            debugPrint('🎯 Answer button $index tapped - Option: $option');
          }
          
          // Immediate haptic feedback to confirm click
          if (_hapticOn) {
            HapticFeedback.selectionClick();
          }
          
          _submitAnswer(index);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _answerSubmitted ? Colors.grey.shade400 : buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            // Simple letter badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Option text
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                
                // Simple result header
                Container(
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
                              blurRadius: 15,
                              spreadRadius: 2,
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
      
      // No animations to reset

      setState(() {
        _currentIndex = 0;
        _score = 0;
        _showResults = false;
        _currentStreak = 0;
        _bestStreak = 0;
        _isOnFire = false;
        _answerHistory.clear();
        _answerSubmitted = false;  // Reset for new game
        _averageResponseTime = 0.0;
      });

      _loadGame();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in _playAgain: $e');
      }
      _loadGame();
    }
  }

  // Helper methods for category colors, icons, and display names
  String _getCategoryDisplayName(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return 'Addition';
      case GameCategory.subtraction:
        return 'Subtraction';
      case GameCategory.multiplication:
        return 'Multiply';
      case GameCategory.division:
        return 'Division';
      case GameCategory.fractions:
        return 'Fractions';
      case GameCategory.percentages:
        return 'Percentages';
      case GameCategory.algebra:
        return 'Algebra';
      case GameCategory.geometry:
        return 'Geometry';
      case GameCategory.calculus:
        return 'Calculus';
      case GameCategory.decimals:
        return 'Decimals';
      case GameCategory.wordProblems:
        return 'Word Problems';
      case GameCategory.patterns:
        return 'Patterns';
      case GameCategory.measurement:
        return 'Measurement';
      case GameCategory.dataAnalysis:
        return 'Data Analysis';
    }
  }

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
      case GameCategory.calculus:
        return const Color(0xFF8B5CF6);
      case GameCategory.decimals:
        return const Color(0xFFEC4899);
      case GameCategory.wordProblems:
        return const Color(0xFF14B8A6);
      case GameCategory.patterns:
        return const Color(0xFFF59E0B);
      case GameCategory.measurement:
        return const Color(0xFF84CC16);
      case GameCategory.dataAnalysis:
        return const Color(0xFF6366F1);
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
      case GameCategory.calculus:
        return Icons.functions_rounded;
      case GameCategory.decimals:
        return Icons.money_rounded;
      case GameCategory.wordProblems:
        return Icons.article_rounded;
      case GameCategory.patterns:
        return Icons.pattern_rounded;
      case GameCategory.measurement:
        return Icons.straighten_rounded;
      case GameCategory.dataAnalysis:
        return Icons.analytics_rounded;
    }
  }

  @override
  void dispose() {
    // Cancel timer first
    _timer?.cancel();
    
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

  /// Performance monitoring (no animations)
  void _monitorAnimationPerformance() {
    if (kDebugMode && _currentIndex == 0) {
      debugPrint('🎯 Static interface - no animations running');
    }
  }
}
