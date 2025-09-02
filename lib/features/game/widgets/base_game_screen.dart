import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../core/barrel.dart';

// Models
import '../models/game_model.dart';
import '../mixins/game_preferences_mixin.dart';
import '../mixins/game_navigation_mixin.dart';

/// Base class for all game screens to eliminate code duplication
abstract class BaseGameScreen<T extends ConsumerStatefulWidget> extends ConsumerState<T>
    with
        GamePreferencesMixin<T>,
        GameNavigationMixin<T>,
        NativeIntegrationMixin<T> {
  
  // Common game state
  int currentQuestionIndex = 0;
  int score = 0;
  bool showResults = false;
  List<Map<String, dynamic>> questions = [];
  List<int> userAnswers = [];
  int timeRemaining = 30;
  int initialTimeLimit = 30;
  Timer? timer;
  DateTime? questionStartTime;
  int hintsUsed = 0;
  String? currentSessionId;
  bool isLoading = false;
  String? errorMessage;

  // Core preferences state
  GameDifficulty selectedDifficulty = GameDifficulty.normal;
  GameCategory selectedCategory = GameCategory.addition;
  int selectedQuestionCount = 10;
  int selectedTimeLimit = 30;
  bool soundEnabled = true;
  bool hapticFeedbackEnabled = true;
  bool autoStartNextGame = false;

  // Advanced preferences
  bool autoAdjustDifficulty = false;
  bool smartTopicRotation = false;
  bool spacedRepetition = false;
  double learningIntensity = 0.5;
  List<GameCategory> focusTopics = [];

  // AI preferences
  String aiPersonality = 'friendly';
  String aiStyle = 'encouraging';
  double questionComplexity = 0.5;

  // Accessibility preferences
  double fontSize = 16.0;
  bool highContrastMode = false;
  bool reducedMotion = false;

  @override
  void initState() {
    super.initState();
    initializePreferencesSync();
    initializeGameNavigation();
    initializeGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // Abstract methods that subclasses must implement
  Future<void> initializeGame();
  Widget buildGameContent(BuildContext context);
  Future<void> generateQuestions();
  Future<void> submitAnswer(int answerIndex);
  void nextQuestion();

  // Common implementations
  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeRemaining > 0) {
            timeRemaining--;
          } else {
            submitAnswer(-1); // Time's up
            timer.cancel();
          }
        });
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void resetTimer() {
    setState(() {
      timeRemaining = initialTimeLimit;
    });
  }

  // Common preference handling
  @override
  void onPreferencesLoaded(UserGamePreferences preferences) {
    setState(() {
      selectedDifficulty = preferences.preferredDifficulty;
      selectedCategory = preferences.preferredCategory;
      selectedQuestionCount = preferences.preferredQuestionCount;
      selectedTimeLimit = preferences.preferredTimeLimit;
      soundEnabled = preferences.soundEnabled;
      hapticFeedbackEnabled = preferences.hapticFeedbackEnabled;
      autoStartNextGame = preferences.autoStartNextGame;
      
      // Advanced preferences
      autoAdjustDifficulty = preferences.autoAdjustDifficulty;
      smartTopicRotation = preferences.smartTopicRotation;
      spacedRepetition = preferences.spacedRepetition;
      learningIntensity = preferences.learningIntensity;
      focusTopics = List.from(preferences.focusTopics);
      
      // AI preferences
      aiPersonality = preferences.aiPersonality;
      aiStyle = preferences.aiStyle;
      questionComplexity = preferences.questionComplexity;
      
      // Accessibility preferences
      fontSize = preferences.fontSize;
      highContrastMode = preferences.highContrastMode;
      reducedMotion = preferences.reducedMotion;
      
      // Update time limits
      initialTimeLimit = preferences.preferredTimeLimit;
      timeRemaining = preferences.preferredTimeLimit;
    });
    
    // Regenerate questions with new preferences
    generateQuestions();
  }

  // Common UI builders
  Widget buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                  isLoading = false;
                });
                initializeGame();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProgressIndicator() {
    if (questions.isEmpty) return const SizedBox();
    
    return LinearProgressIndicator(
      value: (currentQuestionIndex + 1) / questions.length,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).primaryColor,
      ),
    );
  }

  Widget buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('Score', style: Theme.of(context).textTheme.labelSmall),
              Text('$score', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          Column(
            children: [
              Text('Question', style: Theme.of(context).textTheme.labelSmall),
              Text(
                '${currentQuestionIndex + 1}/${questions.length}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          Column(
            children: [
              Text('Time', style: Theme.of(context).textTheme.labelSmall),
              Text(
                '$timeRemaining',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: timeRemaining <= 10 ? Colors.red : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Main build method
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return buildLoadingScreen();
    }

    if (errorMessage != null) {
      return buildErrorScreen();
    }

    return buildGameContent(context);
  }
}
