import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/barrel.dart';
import '../../../core/theme/design_system.dart';
import '../models/game_model.dart';
import 'game_design_cards.dart';

/// Classic Quiz Game Screen
/// Traditional math quiz with multiple choice questions
class ClassicQuizScreen extends ConsumerStatefulWidget {
  const ClassicQuizScreen({super.key});

  @override
  ConsumerState<ClassicQuizScreen> createState() => _ClassicQuizScreenState();
}

class _ClassicQuizScreenState extends ConsumerState<ClassicQuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResults = false;
  List<Map<String, dynamic>> _questions = [];
  List<int> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _initializeGameWithPreferences();
  }

  Future<void> _initializeGameWithPreferences() async {
    try {
      // Load user preferences
      final prefsService = ref.read(userPreferencesServiceProvider);
      final preferences = await prefsService.getGamePreferences();
      
      // Generate questions based on preferences
      _generateQuestionsFromPreferences(preferences);
    } catch (e) {
      // Fallback to default questions
      _generateQuestions();
    }
  }

  void _generateQuestionsFromPreferences(UserGamePreferences preferences) {
    // Use preferences to generate appropriate questions
    final questionCount = preferences.preferredQuestionCount;
    final difficulty = preferences.preferredDifficulty;
    final category = preferences.preferredCategory;
    
    _questions = _generateDynamicQuestions(
      count: questionCount,
      difficulty: difficulty,
      category: category,
    );
  }

  void _generateQuestions() {
    _questions = [
      {
        'question': 'What is 5 + 7?',
        'options': ['10', '11', '12', '13'],
        'correctAnswer': 2,
        'explanation': '5 + 7 = 12',
      },
      {
        'question': 'What is 15 - 8?',
        'options': ['5', '6', '7', '8'],
        'correctAnswer': 2,
        'explanation': '15 - 8 = 7',
      },
      {
        'question': 'What is 4 × 6?',
        'options': ['20', '22', '24', '26'],
        'correctAnswer': 2,
        'explanation': '4 × 6 = 24',
      },
      {
        'question': 'What is 20 ÷ 4?',
        'options': ['3', '4', '5', '6'],
        'correctAnswer': 2,
        'explanation': '20 ÷ 4 = 5',
      },
      {
        'question': 'What is 9 + 3?',
        'options': ['10', '11', '12', '13'],
        'correctAnswer': 2,
        'explanation': '9 + 3 = 12',
      },
    ];
    _userAnswers = List.filled(_questions.length, -1);
  }

  List<Map<String, dynamic>> _generateDynamicQuestions({
    required int count,
    required GameDifficulty difficulty,
    required GameCategory category,
  }) {
    final questions = <Map<String, dynamic>>[];
    
    for (int i = 0; i < count; i++) {
      questions.add(_generateSingleQuestion(category, difficulty, i));
    }
    
    return questions;
  }

  Map<String, dynamic> _generateSingleQuestion(
    GameCategory category,
    GameDifficulty difficulty,
    int index,
  ) {
    final random = (DateTime.now().millisecond + index) % 100;
    
    switch (category) {
      case GameCategory.addition:
        return _generateAdditionQuestion(difficulty, random);
      case GameCategory.subtraction:
        return _generateSubtractionQuestion(difficulty, random);
      case GameCategory.multiplication:
        return _generateMultiplicationQuestion(difficulty, random);
      case GameCategory.division:
        return _generateDivisionQuestion(difficulty, random);
      default:
        return _generateAdditionQuestion(difficulty, random);
    }
  }

  Map<String, dynamic> _generateAdditionQuestion(GameDifficulty difficulty, int random) {
    int a = 1, b = 1;
    switch (difficulty) {
      case GameDifficulty.easy:
        a = (random % 9) + 1;
        b = (random % 9) + 1;
        break;
      case GameDifficulty.normal:
        a = (random % 50) + 10;
        b = (random % 50) + 10;
        break;
      case GameDifficulty.genius:
        a = (random % 100) + 50;
        b = (random % 100) + 50;
        break;
      case GameDifficulty.quantum:
        a = (random % 500) + 100;
        b = (random % 500) + 100;
        break;
    }
    
    final correct = a + b;
    final options = [
      correct.toString(),
      (correct + (random % 5) + 1).toString(),
      (correct - (random % 5) - 1).toString(),
      (correct + (random % 10) + 5).toString(),
    ];
    options.shuffle();
    final correctIndex = options.indexOf(correct.toString());
    
    return {
      'question': 'What is $a + $b?',
      'options': options,
      'correctAnswer': correctIndex,
      'explanation': '$a + $b = $correct',
    };
  }

  Map<String, dynamic> _generateSubtractionQuestion(GameDifficulty difficulty, int random) {
    int a = 10, b = 1;
    switch (difficulty) {
      case GameDifficulty.easy:
        a = (random % 15) + 10;
        b = (random % a) + 1;
        break;
      case GameDifficulty.normal:
        a = (random % 80) + 20;
        b = (random % a) + 1;
        break;
      case GameDifficulty.genius:
        a = (random % 150) + 50;
        b = (random % a) + 1;
        break;
      case GameDifficulty.quantum:
        a = (random % 800) + 200;
        b = (random % a) + 1;
        break;
    }
    
    final correct = a - b;
    final options = [
      correct.toString(),
      (correct + (random % 5) + 1).toString(),
      (correct - (random % 5) - 1).toString(),
      (correct + (random % 10) + 5).toString(),
    ];
    options.shuffle();
    final correctIndex = options.indexOf(correct.toString());
    
    return {
      'question': 'What is $a - $b?',
      'options': options,
      'correctAnswer': correctIndex,
      'explanation': '$a - $b = $correct',
    };
  }

  Map<String, dynamic> _generateMultiplicationQuestion(GameDifficulty difficulty, int random) {
    int a = 1, b = 1;
    switch (difficulty) {
      case GameDifficulty.easy:
        a = (random % 10) + 1;
        b = (random % 10) + 1;
        break;
      case GameDifficulty.normal:
        a = (random % 12) + 1;
        b = (random % 12) + 1;
        break;
      case GameDifficulty.genius:
        a = (random % 20) + 1;
        b = (random % 15) + 1;
        break;
      case GameDifficulty.quantum:
        a = (random % 50) + 1;
        b = (random % 25) + 1;
        break;
    }
    
    final correct = a * b;
    final options = [
      correct.toString(),
      (correct + (random % 10) + 1).toString(),
      (correct - (random % 10) - 1).toString(),
      (correct + (random % 20) + 10).toString(),
    ];
    options.shuffle();
    final correctIndex = options.indexOf(correct.toString());
    
    return {
      'question': 'What is $a × $b?',
      'options': options,
      'correctAnswer': correctIndex,
      'explanation': '$a × $b = $correct',
    };
  }

  Map<String, dynamic> _generateDivisionQuestion(GameDifficulty difficulty, int random) {
    int result = 1, divisor = 2;
    switch (difficulty) {
      case GameDifficulty.easy:
        result = (random % 10) + 1;
        divisor = (random % 5) + 2;
        break;
      case GameDifficulty.normal:
        result = (random % 20) + 5;
        divisor = (random % 8) + 2;
        break;
      case GameDifficulty.genius:
        result = (random % 50) + 10;
        divisor = (random % 12) + 3;
        break;
      case GameDifficulty.quantum:
        result = (random % 100) + 20;
        divisor = (random % 20) + 5;
        break;
    }
    
    final dividend = result * divisor;
    final options = [
      result.toString(),
      (result + (random % 5) + 1).toString(),
      (result - (random % 5) - 1).toString(),
      (result + (random % 10) + 5).toString(),
    ];
    options.shuffle();
    final correctIndex = options.indexOf(result.toString());
    
    return {
      'question': 'What is $dividend ÷ $divisor?',
      'options': options,
      'correctAnswer': correctIndex,
      'explanation': '$dividend ÷ $divisor = $result',
    };
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;

      if (answerIndex == _questions[_currentQuestionIndex]['correctAnswer']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _showResults = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResults = false;
      _userAnswers = List.filled(_questions.length, -1);
    });
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
      currentRoute: '/classic-quiz',
      navigationItems: navigationItems,
      child: _buildQuizContent(themeData, colorScheme),
    );
  }

  Widget _buildQuizContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    if (_showResults) {
      return _buildResultsScreen(themeData, colorScheme);
    }

    return _buildQuestionScreen(themeData, colorScheme);
  }

  Widget _buildQuestionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final userAnswer = _userAnswers[_currentQuestionIndex];

    return Padding(
      padding: DesignSystem.padding24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator with design card
          GameDesignCards.buildProgressCard(
            context: context,
            ref: ref,
            title:
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            subtitle: 'Score: $_score',
            progress: (_currentQuestionIndex + 1) / _questions.length,
            color: colorScheme.primary,
            icon: Icons.quiz,
          ),
          SizedBox(height: context.adaptiveLayout.sectionSpacing),

          // Question
          Text(
            currentQuestion['question'],
            style: themeData.typography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.adaptiveLayout.sectionSpacing),

          // Answer options
          Expanded(
            child: Column(
              children: List.generate(
                currentQuestion['options'].length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: context.adaptiveLayout.cardSpacing,
                  ),
                  child: _buildAnswerOption(
                    themeData,
                    colorScheme,
                    currentQuestion['options'][index],
                    index,
                    userAnswer,
                    currentQuestion['correctAnswer'],
                  ),
                ),
              ),
            ),
          ),

          // Next button
          if (userAnswer != -1)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: context.adaptiveLayout.cardSpacing,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'Finish Quiz',
                  style: themeData.typography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    String option,
    int index,
    int userAnswer,
    int correctAnswer,
  ) {
    bool isSelected = userAnswer == index;
    bool isCorrect = index == correctAnswer;
    bool showCorrectAnswer = userAnswer != -1;

    Color backgroundColor = colorScheme.surface;
    Color borderColor = colorScheme.outline;

    if (showCorrectAnswer) {
      if (isCorrect) {
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.1);
      borderColor = colorScheme.primary;
    }

    return InkWell(
      onTap: userAnswer == -1 ? () => _selectAnswer(index) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.adaptiveLayout.contentPadding + 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: themeData.typography.bodyLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (showCorrectAnswer && isCorrect)
              Icon(Icons.check_circle, color: Colors.green, size: 24),
            if (showCorrectAnswer && isSelected && !isCorrect)
              Icon(Icons.cancel, color: Colors.red, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final percentage = (_score / _questions.length * 100).round();
    final isPerfect = _score == _questions.length;
    final isGood = percentage >= 80;

    return Padding(
      padding: DesignSystem.padding24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Results header
          Icon(
            isPerfect
                ? Icons.celebration
                : (isGood ? Icons.thumb_up : Icons.school),
            size: 80,
            color: isPerfect
                ? Colors.amber
                : (isGood ? Colors.green : colorScheme.primary),
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing + 4),
          Text(
            isPerfect
                ? 'Perfect Score!'
                : (isGood ? 'Great Job!' : 'Keep Learning!'),
            style: themeData.typography.headlineLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
          Text(
            'You got $_score out of ${_questions.length} correct',
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.adaptiveLayout.sectionSpacing),

          // Score display with design card
          GameDesignCards.buildStatsCard(
            context: context,
            ref: ref,
            title: 'Score',
            value: '$percentage%',
            icon: Icons.stars,
            color: colorScheme.primary,
          ),
          SizedBox(height: context.adaptiveLayout.sectionSpacing),

          // Action buttons with quick actions
          Row(
            children: [
              Expanded(
                child: GameQuickActions.buildActionButton(
                  context: context,
                  ref: ref,
                  title: 'Back to Games',
                  icon: Icons.arrow_back,
                  color: colorScheme.primary,
                  onPressed: () => context.go('/game-selection'),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GameQuickActions.buildActionButton(
                  context: context,
                  ref: ref,
                  title: 'Try Again',
                  icon: Icons.refresh,
                  color: colorScheme.primary,
                  onPressed: _restartQuiz,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
