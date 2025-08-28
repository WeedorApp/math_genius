import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/barrel.dart';
import '../../../core/theme/design_system.dart';
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
    _generateQuestions();
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
