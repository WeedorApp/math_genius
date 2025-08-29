import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

// Core imports
import '../../../core/barrel.dart';

// Models
import '../models/game_model.dart';
import '../models/ai_difficulty_model.dart';

// Services
import '../services/ai_native_game_service.dart';
import '../../../core/ai/chatgpt_service.dart';
import '../../user_management/services/user_management_service.dart';

/// ChatGPT-Enhanced AI-Native Game Screen
/// Real AI-powered learning with ChatGPT integration
class ChatGPTEnhancedGameScreen extends ConsumerStatefulWidget {
  const ChatGPTEnhancedGameScreen({super.key});

  @override
  ConsumerState<ChatGPTEnhancedGameScreen> createState() =>
      _ChatGPTEnhancedGameScreenState();
}

class _ChatGPTEnhancedGameScreenState
    extends ConsumerState<ChatGPTEnhancedGameScreen>
    with TickerProviderStateMixin {
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
  List<Map<String, dynamic>> _answerHistory = [];

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
    _initializeChatGPTGame();
  }

  Future<void> _initializeChatGPTGame() async {
    if (_selectedDifficulty == null ||
        _selectedTopic == null ||
        _selectedQuestionCount == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user with error handling
      UserManagementService? userManagementService;
      try {
        userManagementService = ref.read(userManagementServiceProvider);
      } catch (e) {
        if (kDebugMode) {
          print(
            'ChatGPT Game: UserManagementService provider not available: $e',
          );
        }
        throw Exception('User management service not available');
      }

      final currentUser = await userManagementService!.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Generate AI-native questions with ChatGPT
      final questions = await ref
          .read(aiNativeGameServiceProvider)
          .generateAINativeQuestions(
            difficultyLevel: _selectedDifficulty!,
            category: _selectedTopic!, // Use selected topic
            count: _selectedQuestionCount!,
            userId: currentUser.id,
            userContext: {
              'previousScores': [],
              'learningObjectives': [],
              'preferredCategories': [],
            },
          );

      if (questions.isEmpty) {
        throw Exception('Failed to generate questions');
      }

      setState(() {
        _questions = questions;
        _currentQuestionIndex = 0;
        _score = 0;
        _timeRemaining = _selectedTimeLimit;
        _isLoading = false;
        _answerHistory.clear();
      });

      _startTimer();
      _fadeController.forward();

      if (kDebugMode) {
        print(
          'ChatGPT-Enhanced game initialized with ${questions.length} questions',
        );
        print('Difficulty: ${_selectedDifficulty!.name}');
        print('Question count: $_selectedQuestionCount');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize game: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error initializing ChatGPT-enhanced game: $e');
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
          }
        });
      }
    });
  }

  void _submitAnswer(int answerIndex) async {
    if (_isAnswerSelected || _questions == null) return;

    setState(() {
      _isAnswerSelected = true;
      _selectedAnswerIndex = answerIndex;
    });

    final currentQuestion = _questions![_currentQuestionIndex];
    final isCorrect = answerIndex == currentQuestion.correctAnswer;
    final timeBonus = _timeRemaining > 0 ? (_timeRemaining * 0.1).round() : 0;
    final baseScore = isCorrect ? 10 : 0;
    final totalScore = baseScore + timeBonus;

    // Record answer for AI analysis
    _answerHistory.add({
      'question': currentQuestion.question,
      'userAnswer': answerIndex >= 0
          ? currentQuestion.options[answerIndex]
          : 'No answer',
      'correctAnswer': currentQuestion.options[currentQuestion.correctAnswer],
      'timeSpent': currentQuestion.timeLimit - _timeRemaining,
      'isCorrect': isCorrect,
    });

    if (isCorrect) {
      setState(() {
        _score += totalScore;
      });
      _pulseController.forward();
    }

    // Generate personalized hint using ChatGPT
    if (!isCorrect) {
      await _generatePersonalizedHint(currentQuestion, answerIndex);
    }

    // Show feedback
    _showAIFeedback(isCorrect, currentQuestion, totalScore);

    // Move to next question or end game
    Timer(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions!.length - 1) {
        _nextQuestion();
      } else {
        _endGame();
      }
    });
  }

  Future<void> _generatePersonalizedHint(
    AIQuestion question,
    int userAnswerIndex,
  ) async {
    try {
      final chatGPTService = ref.read(chatGPTServiceProvider);
      final personalizedHint = await chatGPTService.generatePersonalizedHint(
        question: question.question,
        userAnswer: userAnswerIndex >= 0
            ? question.options[userAnswerIndex]
            : 'No answer',
        isCorrect: false,
        difficultyLevel: _selectedDifficulty!,
      );

      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'AI Hint: $personalizedHint',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating personalized hint: $e');
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _isAnswerSelected = false;
      _selectedAnswerIndex = null;
      _timeRemaining = _selectedTimeLimit;
    });
    _startTimer();
    _slideController.forward();
  }

  void _endGame() async {
    _timer?.cancel();

    final totalQuestions = _questions!.length;
    final correctAnswers = _score ~/ 10; // Approximate based on score
    final accuracy = (correctAnswers / totalQuestions) * 100;

    // Get AI analysis of performance
    Map<String, dynamic> aiAnalysis = {};
    try {
      final chatGPTService = ref.read(chatGPTServiceProvider);
      UserManagementService? userManagementService;
      try {
        userManagementService = ref.read(userManagementServiceProvider);
      } catch (e) {
        if (kDebugMode) {
          print(
            'ChatGPT Game: UserManagementService provider not available: $e',
          );
        }
        throw Exception('User management service not available');
      }
      final currentUser = await userManagementService!.getCurrentUser();

      if (currentUser != null) {
        aiAnalysis = await chatGPTService.analyzePerformance(
          answers: _answerHistory,
          difficultyLevel: _selectedDifficulty!,
          userId: currentUser.id,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting AI analysis: $e');
      }
      aiAnalysis = {
        'analysis': 'Performance analysis temporarily unavailable',
        'recommendations': ['Continue practicing', 'Review basic concepts'],
        'nextSteps': ['Try easier questions', 'Focus on fundamentals'],
        'confidence': 0.6,
      };
    }

    setState(() {
      _showResults = true;
      _gameResults = {
        'totalScore': _score,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'accuracy': accuracy,
        'difficulty': _selectedDifficulty!.name,
        'timeSpent':
            _questions!.first.timeLimit * totalQuestions - _timeRemaining,
        'aiInsights': _generateAIInsights(),
        'aiAnalysis': aiAnalysis['analysis'] ?? 'No AI analysis available',
        'aiRecommendations': aiAnalysis['recommendations'] ?? [],
        'aiNextSteps': aiAnalysis['nextSteps'] ?? [],
        'aiConfidence': aiAnalysis['confidence'] ?? 0.8,
      };
    });
  }

  String _generateAIInsights() {
    final accuracy = _gameResults!['accuracy'] as double;
    final _ = _selectedDifficulty!.name;

    if (accuracy >= 90) {
      return 'Exceptional performance! You\'ve mastered this difficulty level.';
    } else if (accuracy >= 80) {
      return 'Great work! You\'re showing strong understanding of the concepts.';
    } else if (accuracy >= 70) {
      return 'Good progress! Keep practicing to improve your skills.';
    } else if (accuracy >= 60) {
      return 'You\'re on the right track. Consider reviewing the basics.';
    } else {
      return 'Don\'t worry! Learning takes time. Try an easier difficulty next time.';
    }
  }

  void _showAIFeedback(bool isCorrect, AIQuestion question, int score) {
    final message = isCorrect ? 'Excellent! +$score points' : 'Not quite right';
    AdaptiveUISystem.showAdaptiveSnackBar(
      context: context,
      message: message,
      isError: !isCorrect,
      duration: const Duration(seconds: 2),
    );
  }

  void _showRestartDialog() {
    AdaptiveUISystem.showAdaptiveDialog(
      context: context,
      child: AlertDialog(
        title: const Text(
          'Restart Game?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to restart the game? This will reset your current progress and score.',
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _questions = null;
      _currentQuestionIndex = 0;
      _score = 0;
      _timeRemaining = 30;
      _isAnswerSelected = false;
      _selectedAnswerIndex = null;
      _showResults = false;
      _gameResults = null;
      _answerHistory = [];
      _showDifficultySelection = true;
      _showTopicSelection = false;
      _showQuestionCountSelection = false;
      _showTimeLimitSelection = false;
      _selectedDifficulty = null;
      _selectedTopic = null;
      _selectedQuestionCount = null;
      _selectedTimeLimit = 30;
    });
    _timer?.cancel();
    _fadeController.reset();
    _slideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

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
      currentRoute: '/chatgpt-enhanced-quiz',
      navigationItems: navigationItems,
      child: _buildGameContent(themeData, colorScheme),
    );
  }

  Widget _buildGameContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
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

    if (_questions == null) {
      return _buildErrorScreen(themeData, colorScheme);
    }

    return _buildGameScreen(themeData, colorScheme);
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
              SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
              Text(
                'Powered by ChatGPT AI',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: themeData.typography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: themeData.typography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                'AI will generate personalized questions',
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
            const SizedBox(height: 8),
            Text(
              'ChatGPT is creating personalized questions',
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
                onPressed: _restartGame,
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

  Widget _buildGameScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final currentQuestion = _questions![_currentQuestionIndex];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header with progress and timer
              _buildGameHeader(themeData, colorScheme, currentQuestion),
              const SizedBox(height: 24),

              // Question display
              Expanded(
                child: _buildQuestionDisplay(
                  currentQuestion,
                  themeData,
                  colorScheme,
                ),
              ),

              // Answer options
              Expanded(
                child: _buildAnswerOptions(
                  currentQuestion,
                  themeData,
                  colorScheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    AIQuestion question,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Progress indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions!.length}',
                  style: themeData.typography.labelMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions!.length,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Restart button
          IconButton(
            onPressed: _showRestartDialog,
            icon: Icon(Icons.refresh, color: colorScheme.error),
            tooltip: 'Restart Game',
          ),
          const SizedBox(width: 16),

          // Layout toggle button
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
          const SizedBox(width: 16),

          // Score
          Column(
            children: [
              Text(
                'Score',
                style: themeData.typography.labelSmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                _score.toString(),
                style: themeData.typography.titleLarge.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Timer
          Column(
            children: [
              Text(
                'Time',
                style: themeData.typography.labelSmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _timeRemaining <= 10
                      ? colorScheme.error
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_timeRemaining',
                  style: themeData.typography.titleMedium.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDisplay(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and difficulty badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Question ${_currentQuestionIndex + 1}',
                  style: themeData.typography.labelSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(
                    question.difficulty,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question.difficulty.name.toUpperCase(),
                  style: themeData.typography.labelSmall.copyWith(
                    color: _getDifficultyColor(question.difficulty),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question text
          Expanded(
            child: Center(
              child: Text(
                question.question,
                style: themeData.typography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Question category
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                question.category.name.toUpperCase(),
                style: themeData.typography.labelSmall.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Answer options header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.quiz, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select Your Answer',
                  style: themeData.typography.titleSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Answer options grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _isGridView
                  ? _buildGridViewOptions(question, themeData, colorScheme)
                  : _buildListViewOptions(question, themeData, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

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
        backgroundColor = colorScheme.surface;
        borderColor = colorScheme.outline.withValues(alpha: 0.3);
        textColor = colorScheme.onSurface.withValues(alpha: 0.6);
      }
    } else {
      backgroundColor = isSelected
          ? colorScheme.primary.withValues(alpha: 0.1)
          : colorScheme.surface;
      borderColor = isSelected
          ? colorScheme.primary
          : colorScheme.outline.withValues(alpha: 0.3);
      textColor = isSelected ? colorScheme.primary : colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: _isAnswerSelected ? null : () => _submitAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Option letter
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: themeData.typography.labelLarge.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
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
                    : colorScheme.outline.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridViewOptions(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(question.options.length, (index) {
        return _buildAnswerOption(
          index,
          question.options[index],
          question,
          themeData,
          colorScheme,
        );
      }),
    );
  }

  Widget _buildListViewOptions(
    AIQuestion question,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        return _buildAnswerOption(
          index,
          question.options[index],
          question,
          themeData,
          colorScheme,
        );
      },
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
                child: SingleChildScrollView(
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
                                style: themeData.typography.titleMedium
                                    .copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                results['totalScore'].toString(),
                                style: themeData.typography.displaySmall
                                    .copyWith(
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
                              color: colorScheme.secondary.withValues(
                                alpha: 0.2,
                              ),
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
                                    'AI Insights',
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

                        const SizedBox(height: 16),

                        // AI Analysis
                        if (results['aiAnalysis'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics,
                                      size: 20,
                                      color: colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Analysis',
                                      style: themeData.typography.titleSmall
                                          .copyWith(
                                            color: colorScheme.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  results['aiAnalysis'],
                                  style: themeData.typography.bodyMedium
                                      .copyWith(color: colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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
                      onPressed: _restartGame,
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

  Color _getDifficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Colors.green;
      case GameDifficulty.normal:
        return Colors.blue;
      case GameDifficulty.genius:
        return Colors.orange;
      case GameDifficulty.quantum:
        return Colors.red;
    }
  }
}
