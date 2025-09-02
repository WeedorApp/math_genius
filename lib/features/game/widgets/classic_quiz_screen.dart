import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';
import '../../../core/barrel.dart';
import '../../../core/theme/design_system.dart';
import '../models/game_model.dart';
import '../mixins/game_preferences_mixin.dart';
import '../mixins/game_navigation_mixin.dart';
import '../../student/services/student_analytics_service.dart';
import '../../user_management/services/user_management_service.dart';
import 'game_design_cards.dart';

/// Classic Quiz Game Screen
/// Traditional math quiz with multiple choice questions
class ClassicQuizScreen extends ConsumerStatefulWidget {
  const ClassicQuizScreen({super.key});

  @override
  ConsumerState<ClassicQuizScreen> createState() => _ClassicQuizScreenState();
}

class _ClassicQuizScreenState extends ConsumerState<ClassicQuizScreen>
    with
        GamePreferencesMixin<ClassicQuizScreen>,
        GameNavigationMixin<ClassicQuizScreen>,
        NativeIntegrationMixin<ClassicQuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResults = false;
  List<Map<String, dynamic>> _questions = [];
  List<int> _userAnswers = [];
  int _timeRemaining = 30; // Default 30 seconds
  int _initialTimeLimit = 30; // Store the original time limit
  Timer? _timer;
  DateTime? _questionStartTime; // Track when question was displayed
  int _hintsUsed = 0; // Track hints used for current question
  String? _currentSessionId; // Track current study session

  // Core preferences state
  GameDifficulty _selectedDifficulty = GameDifficulty.normal;
  GameCategory _selectedCategory = GameCategory.addition;
  int _selectedQuestionCount = 10;
  int _selectedTimeLimit = 30;
  bool _soundEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _autoStartNextGame = false;

  // Advanced learning preferences
  bool _autoAdjustDifficulty = false;
  bool _smartTopicRotation = false;
  bool _spacedRepetition = false;
  double _learningIntensity = 0.5;
  List<GameCategory> _focusTopics = [];

  // AI preferences
  String _aiPersonality = 'Encouraging';
  String _aiStyle = 'Adaptive';
  double _questionComplexity = 0.5;

  // Accessibility preferences
  double _fontSize = 1.0;
  bool _highContrastMode = false;
  bool _reducedMotion = false;

  // Learning analytics
  int _consecutiveCorrect = 0;
  int _consecutiveIncorrect = 0;
  final List<GameCategory> _strugglingTopics = [];
  final Map<GameCategory, double> _topicAccuracy = {};

  // Student grade level awareness
  GradeLevel _studentGradeLevel = GradeLevel.grade5; // Default
  final bool _gradeAwareQuestions = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🚨 OLD CLASSIC QUIZ SCREEN BEING USED! (Should use SimpleUnifiedQuiz)');
      debugPrint('🎮 CLASSIC QUIZ INITIALIZING');
      debugPrint('   📊 Initial Category: ${_selectedCategory.name}');
      debugPrint('   🎯 Initial Difficulty: ${_selectedDifficulty.name}');
      debugPrint('   🎓 Initial Grade: ${_studentGradeLevel.name}');
    }
    initializePreferencesSync(); // Initialize preferences synchronization
    initializeGameNavigation(); // Initialize navigation handling
    initializeNativeFeatures(); // Initialize native platform features
    _initializeGameWithPreferences();
    _startStudySession(); // Start tracking study session
    // Real-time settings sync will be set up in build method
  }

  // GameNavigationMixin implementation
  @override
  bool get isGameActive => !_showResults && _questions.isNotEmpty;

  @override
  bool get hasGameProgress => _currentQuestionIndex > 0 || _score > 0;

  @override
  String get gameMode => 'classic';

  @override
  Map<String, dynamic> get currentGameState => {
    'currentQuestionIndex': _currentQuestionIndex,
    'score': _score,
    'timeRemaining': _timeRemaining,
    'questions': _questions,
    'userAnswers': _userAnswers,
    'showResults': _showResults,
  };

  @override
  Future<void> saveGameProgress() async {
    try {
      // Save current game state to preferences/storage
      await updateGamePreferences(
        difficulty: _selectedDifficulty,
        category: _selectedCategory,
        questionCount: _selectedQuestionCount,
        timeLimit: _selectedTimeLimit,
      );

      // TODO: Save actual game session state for resumption
      debugPrint('Classic Quiz progress saved');
    } catch (e) {
      debugPrint('Error saving classic quiz progress: $e');
    }
  }

  @override
  Future<void> pauseGame() async {
    _pauseTimer();
  }

  @override
  Future<void> resumeGame() async {
    if (!_showResults && _questions.isNotEmpty) {
      _startTimer();
    }
  }

  @override
  void resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResults = false;
      _userAnswers = List.generate(_questions.length, (index) => -1);
      _timeRemaining = _initialTimeLimit;
    });
    _resetTimer();
  }

  // GamePreferencesMixin implementation
  @override
  GameDifficulty? get selectedDifficulty => _selectedDifficulty;

  @override
  GameCategory? get selectedCategory => _selectedCategory;

  @override
  int? get selectedQuestionCount => _selectedQuestionCount;

  @override
  int get selectedTimeLimit => _selectedTimeLimit;

  @override
  bool get soundEnabled => _soundEnabled;

  @override
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;

  // gameMode already implemented in GamePreferencesMixin

  @override
  void onDifficultyChanged(GameDifficulty difficulty) {
    if (mounted) {
      setState(() {
        _selectedDifficulty = difficulty;
      });
      _regenerateQuestionsIfNeeded();
      // Immediately sync to preferences
      updateDifficulty(difficulty);
    }
  }

  @override
  void onCategoryChanged(GameCategory category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
      });
      _regenerateQuestionsIfNeeded();
      // Immediately sync to preferences
      updateCategory(category);
    }
  }

  @override
  void onQuestionCountChanged(int count) {
    if (mounted) {
      setState(() {
        _selectedQuestionCount = count;
      });
      _regenerateQuestionsIfNeeded();
      // Immediately sync to preferences
      updateQuestionCount(count);
    }
  }

  @override
  void onTimeLimitChanged(int timeLimit) {
    if (mounted) {
      setState(() {
        _selectedTimeLimit = timeLimit;
        _timeRemaining = timeLimit;
        _initialTimeLimit = timeLimit;
      });
      _restartTimer();
      // Immediately sync to preferences
      updateTimeLimit(timeLimit);
    }
  }

  @override
  void onSoundEnabledChanged(bool enabled) {
    if (mounted) {
      setState(() {
        _soundEnabled = enabled;
      });
      // Immediately sync to preferences
      updateSoundEnabled(enabled);
    }
  }

  @override
  void onHapticFeedbackChanged(bool enabled) {
    if (mounted) {
      setState(() {
        _hapticFeedbackEnabled = enabled;
      });
      // Immediately sync to preferences
      updateHapticFeedback(enabled);
    }
  }

  @override
  void onPreferencesLoaded(UserGamePreferences preferences) {
    if (mounted) {
      setState(() {
        // Core game preferences
        _selectedDifficulty = preferences.preferredDifficulty;
        _selectedCategory = preferences.preferredCategory;
        _selectedQuestionCount = preferences.preferredQuestionCount;
        _selectedTimeLimit = preferences.preferredTimeLimit;
        _timeRemaining = preferences.preferredTimeLimit;
        _initialTimeLimit = preferences.preferredTimeLimit;
        _soundEnabled = preferences.soundEnabled;
        _hapticFeedbackEnabled = preferences.hapticFeedbackEnabled;
        _autoStartNextGame = preferences.autoStartNextGame;

        // Advanced learning preferences
        _autoAdjustDifficulty = preferences.autoAdjustDifficulty;
        _smartTopicRotation = preferences.smartTopicRotation;
        _spacedRepetition = preferences.spacedRepetition;
        _learningIntensity = preferences.learningIntensity;
        _focusTopics = List.from(preferences.focusTopics);

        // AI preferences
        _aiPersonality = preferences.aiPersonality;
        _aiStyle = preferences.aiStyle;
        _questionComplexity = preferences.questionComplexity;

        // Accessibility preferences
        _fontSize = preferences.fontSize;
        _highContrastMode = preferences.highContrastMode;
        _reducedMotion = preferences.reducedMotion;
      });

      _generateQuestionsFromPreferences(preferences);
      _syncPreferencesToGameState(preferences);

      if (kDebugMode) {
        debugPrint('✅ ALL preferences loaded into classic quiz:');
        debugPrint('   🎯 Difficulty: ${preferences.preferredDifficulty.name}');
        debugPrint('   📚 Category: ${preferences.preferredCategory.name}');
        debugPrint('   🔢 Questions: ${preferences.preferredQuestionCount}');
        debugPrint('   ⏰ Time: ${preferences.preferredTimeLimit}s');
        debugPrint(
          '   🧠 Learning Intensity: ${preferences.learningIntensity}',
        );
        debugPrint('   🤖 AI Personality: ${preferences.aiPersonality}');
        debugPrint('   ♿ Font Size: ${(preferences.fontSize * 100).round()}%');
        debugPrint(
          '🔄 AFTER LOADING - Current _selectedCategory: ${_selectedCategory.name}',
        );

        if (_selectedCategory == GameCategory.percentages) {
          debugPrint(
            '✅ PERCENTAGES CATEGORY CONFIRMED - Should generate percentage questions',
          );
        } else {
          debugPrint(
            '❌ CATEGORY MISMATCH - Expected percentages, got ${_selectedCategory.name}',
          );
        }
      }
    }
  }

  /// Sync loaded preferences to current game state
  void _syncPreferencesToGameState(UserGamePreferences preferences) {
    // Ensure game state matches loaded preferences exactly
    if (_selectedDifficulty != preferences.preferredDifficulty ||
        _selectedCategory != preferences.preferredCategory ||
        _selectedQuestionCount != preferences.preferredQuestionCount ||
        _selectedTimeLimit != preferences.preferredTimeLimit ||
        _soundEnabled != preferences.soundEnabled ||
        _hapticFeedbackEnabled != preferences.hapticFeedbackEnabled) {
      if (kDebugMode) {
        debugPrint('🔄 Syncing preferences to game state');
        debugPrint('   📊 Difficulty: ${preferences.preferredDifficulty.name}');
        debugPrint('   📚 Category: ${preferences.preferredCategory.name}');
        debugPrint('   🔢 Questions: ${preferences.preferredQuestionCount}');
        debugPrint('   ⏰ Time: ${preferences.preferredTimeLimit}s');
        debugPrint('   🔊 Sound: ${preferences.soundEnabled}');
        debugPrint('   📳 Haptic: ${preferences.hapticFeedbackEnabled}');
      }

      // Force regenerate questions if category or difficulty changed
      final shouldRegenerateQuestions =
          _selectedDifficulty != preferences.preferredDifficulty ||
          _selectedCategory != preferences.preferredCategory ||
          _selectedQuestionCount != preferences.preferredQuestionCount;

      if (shouldRegenerateQuestions && !_showResults) {
        _generateQuestionsFromPreferences(preferences);
      }
    }
  }

  /// Sync game state to match external preference changes
  void _syncGameStateToPreferences(UserGamePreferences preferences) {
    if (!mounted) return;

    setState(() {
      _selectedDifficulty = preferences.preferredDifficulty;
      _selectedCategory = preferences.preferredCategory;
      _selectedQuestionCount = preferences.preferredQuestionCount;
      _selectedTimeLimit = preferences.preferredTimeLimit;
      _timeRemaining = preferences.preferredTimeLimit;
      _initialTimeLimit = preferences.preferredTimeLimit;
      _soundEnabled = preferences.soundEnabled;
      _hapticFeedbackEnabled = preferences.hapticFeedbackEnabled;
    });

    // Regenerate questions if needed
    if (!_showResults) {
      _generateQuestionsFromPreferences(preferences);
    }

    if (kDebugMode) {
      debugPrint('✅ Game state synced to external preference changes');
    }
  }

  /// Regenerate questions when preferences change during gameplay
  void _regenerateQuestionsIfNeeded() {
    if (!_showResults && _questions.isNotEmpty) {
      _generateQuestionsFromCurrentPreferences();
      _currentQuestionIndex = 0;
      _userAnswers = List.generate(_questions.length, (index) => -1);
      _restartTimer();
    }
  }

  /// Restart timer with current time limit
  void _restartTimer() {
    _timer?.cancel();
    _timeRemaining = _selectedTimeLimit;
    _startTimer();
  }

  /// Generate questions using current preferences with focus topics consideration
  void _generateQuestionsFromCurrentPreferences() {
    GameCategory categoryToUse = _selectedCategory;

    // Use focus topics if available and spaced repetition is enabled
    if (_focusTopics.isNotEmpty && _spacedRepetition) {
      categoryToUse = _focusTopics.first;
      if (kDebugMode) {
        debugPrint('🎯 Using focus topic: ${categoryToUse.name}');
      }
    }

    _questions = _generateDynamicQuestions(
      count: _selectedQuestionCount,
      difficulty: _selectedDifficulty,
      category: categoryToUse,
    );

    if (_questions.isEmpty) {
      _generateQuestions(); // Fallback
    }
  }

  Future<void> _initializeGameWithPreferences() async {
    try {
      // Load user preferences
      final prefsService = ref.read(userPreferencesServiceProvider);
      final preferences = await prefsService.getGamePreferences();

      if (kDebugMode) {
        debugPrint('🔧 LOADING PREFERENCES:');
        debugPrint(
          '   📚 Loaded Category: ${preferences.preferredCategory.name}',
        );
        debugPrint(
          '   🎯 Loaded Difficulty: ${preferences.preferredDifficulty.name}',
        );
      }

      // Load student grade level from user profile
      await _loadStudentGradeLevel();

      // Validate preferences and generate questions
      if (preferences.preferredQuestionCount > 0) {
        _generateQuestionsFromPreferences(preferences);
      } else {
        // Fallback if preferences are invalid
        _generateQuestions();
      }

      // Ensure we have a valid user answers list
      _userAnswers = List.generate(_questions.length, (index) => -1);

      // Update UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading preferences: $e');
      }
      // Fallback to default questions on any error
      _generateQuestions();
      _userAnswers = List.generate(_questions.length, (index) => -1);

      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Load student's grade level from user profile
  Future<void> _loadStudentGradeLevel() async {
    try {
      final userManagementService = ref.read(userManagementServiceProvider);
      final currentUser = await userManagementService.getCurrentUser();

      if (currentUser?.gradeLevel != null) {
        setState(() {
          _studentGradeLevel = currentUser!.gradeLevel!;
        });

        if (kDebugMode) {
          debugPrint(
            '🎓 Student grade level loaded: ${_studentGradeLevel.name}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading student grade level: $e');
      }
    }
  }

  void _generateQuestionsFromPreferences(UserGamePreferences preferences) {
    // Use preferences to generate appropriate questions
    final questionCount = preferences.preferredQuestionCount.clamp(
      1,
      50,
    ); // Ensure valid count
    final difficulty = preferences.preferredDifficulty;
    final category = preferences.preferredCategory;
    final timeLimit = preferences.preferredTimeLimit;

    // Set time limit from preferences
    _timeRemaining = timeLimit;
    _initialTimeLimit = timeLimit;

    _questions = _generateDynamicQuestions(
      count: questionCount,
      difficulty: difficulty,
      category: category,
    );

    // Fallback if dynamic generation fails
    if (_questions.isEmpty) {
      _generateQuestions(); // Use default questions
    }

    // Start timer after questions are generated
    _startTimer();
  }

  List<Map<String, dynamic>> _generateDynamicQuestions({
    required int count,
    required GameDifficulty difficulty,
    required GameCategory category,
  }) {
    final questions = <Map<String, dynamic>>[];
    final safeCount = count.clamp(1, 50); // Ensure valid count

    for (int i = 0; i < safeCount; i++) {
      try {
        final question = _generateSingleQuestion(category, difficulty, i);
        questions.add(question);
      } catch (e) {
        // If generation fails, add a simple fallback question
        questions.add({
          'question': 'What is ${i + 1} + ${i + 1}?',
          'options': [
            '${(i + 1) * 2}',
            '${(i + 1) * 2 + 1}',
            '${(i + 1) * 2 - 1}',
            '${(i + 1) * 2 + 2}',
          ],
          'correctAnswer': 0,
          'explanation': '${i + 1} + ${i + 1} = ${(i + 1) * 2}',
        });
      }
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

  Map<String, dynamic> _generateAdditionQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    int a = 1, b = 1;
    final safeRandom = random == 0 ? 1 : random;

    // Apply question complexity multiplier
    final complexityMultiplier = _questionComplexity;

    // Grade-level aware question generation
    final gradeAdjustment = _getGradeAdjustment(_studentGradeLevel);

    switch (difficulty) {
      case GameDifficulty.easy:
        final baseRange = ((9 * complexityMultiplier) * gradeAdjustment)
            .round();
        a = (safeRandom % baseRange.clamp(1, 20)) + 1;
        b = (safeRandom % baseRange.clamp(1, 20)) + 1;
        break;
      case GameDifficulty.normal:
        final baseRange = ((50 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(10, 100)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        b =
            (safeRandom % baseRange.clamp(10, 100)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        break;
      case GameDifficulty.genius:
        final baseRange = ((100 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(50, 500)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 2;
        b =
            (safeRandom % baseRange.clamp(50, 500)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 2;
        break;
      case GameDifficulty.quantum:
        final baseRange = ((500 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(100, 1000)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 5;
        b =
            (safeRandom % baseRange.clamp(100, 1000)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 5;
        break;
    }

    // Apply learning intensity for additional challenge
    if (_learningIntensity > 0.7) {
      a = (a * 1.5).round();
      b = (b * 1.5).round();
    }

    final correct = a + b;
    final options = <String>[
      correct.toString(),
      (correct + (safeRandom % 5) + 1).toString(),
      (correct - (safeRandom % 5) - 1).toString(),
      (correct + (safeRandom % 10) + 5).toString(),
    ];

    // Remove duplicates and ensure we have exactly 4 unique options
    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length + 10).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'What is $a + $b?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation': '$a + $b = $correct',
      'gradeLevel': _studentGradeLevel.name,
    };
  }

  Map<String, dynamic> _generateSubtractionQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    int a = 10, b = 1;
    final safeRandom = random == 0 ? 1 : random;

    // Apply question complexity multiplier
    final complexityMultiplier = _questionComplexity;

    // Grade-level aware question generation
    final gradeAdjustment = _getGradeAdjustment(_studentGradeLevel);

    switch (difficulty) {
      case GameDifficulty.easy:
        final baseRange = ((15 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(10, 30)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        b = (safeRandom % (a ~/ 2)) + 1;
        break;
      case GameDifficulty.normal:
        final baseRange = ((80 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(20, 150)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 2;
        b = (safeRandom % (a ~/ 2)) + 1;
        break;
      case GameDifficulty.genius:
        final baseRange = ((150 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(50, 300)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 3;
        b = (safeRandom % (a ~/ 2)) + 1;
        break;
      case GameDifficulty.quantum:
        final baseRange = ((800 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(200, 1200)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 8;
        b = (safeRandom % (a ~/ 2)) + 1;
        break;
    }

    // Apply learning intensity for additional challenge
    if (_learningIntensity > 0.7) {
      a = (a * 1.5).round();
      b = (b * 1.2).round(); // Slightly less increase for subtrahend
    }

    final correct = a - b;
    final options = <String>[
      correct.toString(),
      (correct + (safeRandom % 5) + 1).toString(),
      (correct - (safeRandom % 5) - 1).toString(),
      (correct + (safeRandom % 10) + 5).toString(),
    ];

    // Remove duplicates and ensure we have exactly 4 unique options
    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length + 10).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'What is $a - $b?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation': '$a - $b = $correct',
      'gradeLevel': _studentGradeLevel.name,
    };
  }

  Map<String, dynamic> _generateMultiplicationQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    int a = 1, b = 1;
    final safeRandom = random == 0 ? 1 : random;

    // Apply question complexity multiplier
    final complexityMultiplier = _questionComplexity;

    // Grade-level aware question generation
    final gradeAdjustment = _getGradeAdjustment(_studentGradeLevel);

    switch (difficulty) {
      case GameDifficulty.easy:
        final baseRange = ((10 * complexityMultiplier) * gradeAdjustment)
            .round();
        a = (safeRandom % baseRange.clamp(2, 12)) + 1;
        b = (safeRandom % baseRange.clamp(2, 12)) + 1;
        break;
      case GameDifficulty.normal:
        final baseRange = ((12 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(3, 20)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        b = (safeRandom % baseRange.clamp(3, 20)) + 1;
        break;
      case GameDifficulty.genius:
        final baseRange = ((20 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(5, 35)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        b = (safeRandom % (baseRange * 0.75).round().clamp(3, 25)) + 1;
        break;
      case GameDifficulty.quantum:
        final baseRange = ((50 * complexityMultiplier) * gradeAdjustment)
            .round();
        a =
            (safeRandom % baseRange.clamp(10, 75)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        b = (safeRandom % (baseRange * 0.5).round().clamp(5, 40)) + 1;
        break;
    }

    // Apply learning intensity for additional challenge
    if (_learningIntensity > 0.7) {
      a = (a * 1.3).round();
      b = (b * 1.2).round();
    }

    final correct = a * b;
    final options = <String>[
      correct.toString(),
      (correct + (safeRandom % 10) + 1).toString(),
      (correct - (safeRandom % 10) - 1).toString(),
      (correct + (safeRandom % 20) + 10).toString(),
    ];

    // Remove duplicates and ensure we have exactly 4 unique options
    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length + 15).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'What is $a × $b?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation': '$a × $b = $correct',
      'gradeLevel': _studentGradeLevel.name,
    };
  }

  Map<String, dynamic> _generateDivisionQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    int result = 1, divisor = 2;
    final safeRandom = random == 0 ? 1 : random;

    // Apply question complexity multiplier
    final complexityMultiplier = _questionComplexity;

    // Grade-level aware question generation
    final gradeAdjustment = _getGradeAdjustment(_studentGradeLevel);

    switch (difficulty) {
      case GameDifficulty.easy:
        final baseRange = ((10 * complexityMultiplier) * gradeAdjustment)
            .round();
        result = (safeRandom % baseRange.clamp(2, 15)) + 1;
        divisor = (safeRandom % 5).clamp(2, 8) + 2;
        break;
      case GameDifficulty.normal:
        final baseRange = ((20 * complexityMultiplier) * gradeAdjustment)
            .round();
        result =
            (safeRandom % baseRange.clamp(5, 35)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        divisor = (safeRandom % 8).clamp(2, 12) + 2;
        break;
      case GameDifficulty.genius:
        final baseRange = ((50 * complexityMultiplier) * gradeAdjustment)
            .round();
        result =
            (safeRandom % baseRange.clamp(10, 75)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        divisor = (safeRandom % 12).clamp(3, 18) + 3;
        break;
      case GameDifficulty.quantum:
        final baseRange = ((100 * complexityMultiplier) * gradeAdjustment)
            .round();
        result =
            (safeRandom % baseRange.clamp(20, 150)) +
            _getGradeLevelMinimum(_studentGradeLevel);
        divisor = (safeRandom % 20).clamp(5, 25) + 5;
        break;
    }

    // Apply learning intensity for additional challenge
    if (_learningIntensity > 0.7) {
      result = (result * 1.4).round();
      divisor = (divisor * 1.1).round().clamp(2, 25);
    }

    final dividend = result * divisor;
    final options = <String>[
      result.toString(),
      (result + (safeRandom % 5) + 1).toString(),
      (result - (safeRandom % 5) - 1).toString(),
      (result + (safeRandom % 10) + 5).toString(),
    ];

    // Remove duplicates and ensure we have exactly 4 unique options
    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((result + uniqueOptions.length + 8).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(result.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'What is $dividend ÷ $divisor?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation': '$dividend ÷ $divisor = $result',
      'gradeLevel': _studentGradeLevel.name,
    };
  }

  /// Generate percentage questions with grade-level and difficulty awareness
  Map<String, dynamic> _generatePercentageQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    final safeRandom = random == 0 ? 1 : random;

    if (kDebugMode) {
      debugPrint('📊 GENERATING PERCENTAGE QUESTION:');
      debugPrint('   🎯 Difficulty: ${difficulty.name}');
      debugPrint('   🎓 Grade Level: ${_studentGradeLevel.name}');
      debugPrint('   🔢 Random Seed: $safeRandom');
    }

    // Apply question complexity multiplier
    final complexityMultiplier = _questionComplexity;

    // Grade-level aware question generation
    final gradeAdjustment = _getGradeAdjustment(_studentGradeLevel);

    // Grade 5 context: Students typically learn basic percentages (10%, 25%, 50%, etc.)
    // Higher grades can handle more complex percentages and decimal percentages

    int baseNumber;
    int percentage;
    String questionType;

    switch (difficulty) {
      case GameDifficulty.easy:
        // Simple percentages with round numbers
        final baseRange = ((100 * complexityMultiplier) * gradeAdjustment)
            .round();
        baseNumber =
            ((safeRandom % baseRange.clamp(20, 200)) +
                _getGradeLevelMinimum(_studentGradeLevel)) *
            10;
        percentage = _getGradeAppropriatePercentage(
          _studentGradeLevel,
          true,
        ); // Simple percentages
        break;
      case GameDifficulty.normal:
        // Standard percentages
        final baseRange = ((200 * complexityMultiplier) * gradeAdjustment)
            .round();
        baseNumber =
            (safeRandom % baseRange.clamp(50, 500)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 5;
        percentage = _getGradeAppropriatePercentage(_studentGradeLevel, false);
        break;
      case GameDifficulty.genius:
        // Complex percentages with larger numbers
        final baseRange = ((500 * complexityMultiplier) * gradeAdjustment)
            .round();
        baseNumber =
            (safeRandom % baseRange.clamp(100, 1000)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 10;
        percentage = _getGradeAppropriatePercentage(_studentGradeLevel, false);
        break;
      case GameDifficulty.quantum:
        // Advanced percentages with very large numbers or complex scenarios
        final baseRange = ((1000 * complexityMultiplier) * gradeAdjustment)
            .round();
        baseNumber =
            (safeRandom % baseRange.clamp(200, 2000)) +
            _getGradeLevelMinimum(_studentGradeLevel) * 20;
        percentage = _getAdvancedPercentage(_studentGradeLevel, safeRandom);
        break;
    }

    // Apply learning intensity for additional challenge
    if (_learningIntensity > 0.7) {
      baseNumber = (baseNumber * 1.5).round();
      if (percentage < 50) {
        percentage = (percentage * 1.2).round().clamp(1, 99);
      }
    }

    // Choose question type based on grade level
    final questionTypes = _getGradeAppropriateQuestionTypes(_studentGradeLevel);
    questionType = questionTypes[safeRandom % questionTypes.length];

    if (kDebugMode) {
      debugPrint('   📊 Base Number: $baseNumber');
      debugPrint('   📊 Percentage: $percentage%');
      debugPrint('   📊 Question Type: $questionType');
      debugPrint('   📊 Available Types: $questionTypes');
    }

    final result = _buildPercentageQuestion(
      baseNumber,
      percentage,
      questionType,
      safeRandom,
    );

    if (kDebugMode) {
      debugPrint('   ✅ Final Question: ${result['question']}');
      debugPrint(
        '   ✅ Correct Answer: ${result['options'][result['correctAnswer']]}',
      );
    }

    return result;
  }

  /// Get grade-appropriate percentage values
  int _getGradeAppropriatePercentage(GradeLevel gradeLevel, bool simple) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        // Very basic: 50%, 25%, 10%
        final basicPercentages = [50, 25, 10];
        return simple
            ? basicPercentages[DateTime.now().millisecond %
                  basicPercentages.length]
            : 50;
      case GradeLevel.grade3:
      case GradeLevel.grade4:
      case GradeLevel.grade5:
        // Elementary: Common percentages
        if (simple) {
          final simplePercentages = [10, 20, 25, 50, 75];
          return simplePercentages[DateTime.now().millisecond %
              simplePercentages.length];
        } else {
          final standardPercentages = [15, 30, 40, 60, 80];
          return standardPercentages[DateTime.now().millisecond %
              standardPercentages.length];
        }
      case GradeLevel.grade6:
      case GradeLevel.grade7:
      case GradeLevel.grade8:
        // Middle school: More variety
        if (simple) {
          final simplePercentages = [12, 15, 25, 30, 40, 60, 75];
          return simplePercentages[DateTime.now().millisecond %
              simplePercentages.length];
        } else {
          final standardPercentages = [18, 35, 42, 55, 65, 85];
          return standardPercentages[DateTime.now().millisecond %
              standardPercentages.length];
        }
      case GradeLevel.grade9:
      case GradeLevel.grade10:
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        // High school: Complex percentages
        if (simple) {
          final simplePercentages = [8, 12, 15, 18, 22, 35, 45, 65, 85];
          return simplePercentages[DateTime.now().millisecond %
              simplePercentages.length];
        } else {
          final complexPercentages = [13, 17, 23, 28, 33, 47, 53, 67, 73, 83];
          return complexPercentages[DateTime.now().millisecond %
              complexPercentages.length];
        }
    }
  }

  /// Get advanced percentage for quantum difficulty
  int _getAdvancedPercentage(GradeLevel gradeLevel, int random) {
    if (gradeLevel.index >= GradeLevel.grade9.index) {
      // High school: Include decimal percentages
      final advancedPercentages = [12.5, 16.7, 33.3, 66.7, 87.5, 125, 150, 175];
      return advancedPercentages[random % advancedPercentages.length].round();
    } else if (gradeLevel.index >= GradeLevel.grade6.index) {
      // Middle school: Challenging but manageable
      final middleSchoolPercentages = [15, 18, 22, 28, 35, 45, 55, 65, 78, 85];
      return middleSchoolPercentages[random % middleSchoolPercentages.length];
    } else {
      // Elementary: Keep it reasonable
      final elementaryPercentages = [20, 25, 30, 40, 50, 60, 75, 80];
      return elementaryPercentages[random % elementaryPercentages.length];
    }
  }

  /// Get grade-appropriate question types
  List<String> _getGradeAppropriateQuestionTypes(GradeLevel gradeLevel) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        return ['simple_of']; // "What is 50% of 20?"
      case GradeLevel.grade3:
      case GradeLevel.grade4:
      case GradeLevel.grade5:
        return ['simple_of', 'find_whole']; // Basic percentage problems
      case GradeLevel.grade6:
      case GradeLevel.grade7:
      case GradeLevel.grade8:
        return ['simple_of', 'find_whole', 'find_percent', 'increase_decrease'];
      case GradeLevel.grade9:
      case GradeLevel.grade10:
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        return [
          'simple_of',
          'find_whole',
          'find_percent',
          'increase_decrease',
          'compound',
          'word_problem',
        ];
    }
  }

  /// Build specific percentage question based on type
  Map<String, dynamic> _buildPercentageQuestion(
    int baseNumber,
    int percentage,
    String questionType,
    int random,
  ) {
    switch (questionType) {
      case 'simple_of':
        return _buildSimplePercentageOfQuestion(baseNumber, percentage, random);
      case 'find_whole':
        return _buildFindWholeQuestion(baseNumber, percentage, random);
      case 'find_percent':
        return _buildFindPercentQuestion(baseNumber, percentage, random);
      case 'increase_decrease':
        return _buildIncreaseDecreaseQuestion(baseNumber, percentage, random);
      case 'compound':
        return _buildCompoundPercentageQuestion(baseNumber, percentage, random);
      case 'word_problem':
        return _buildPercentageWordProblem(baseNumber, percentage, random);
      default:
        return _buildSimplePercentageOfQuestion(baseNumber, percentage, random);
    }
  }

  /// Build "What is X% of Y?" questions
  Map<String, dynamic> _buildSimplePercentageOfQuestion(
    int baseNumber,
    int percentage,
    int random,
  ) {
    final correct = (baseNumber * percentage / 100).round();
    final options = <String>[
      correct.toString(),
      (correct + (random % 10) + 5).toString(),
      (correct - (random % 8) - 3).toString(),
      (correct * 1.2).round().toString(),
    ];

    // Remove duplicates and ensure we have exactly 4 unique options
    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length * 7 + 12).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'What is $percentage% of $baseNumber?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          '$percentage% of $baseNumber = ($percentage ÷ 100) × $baseNumber = $correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build "X is Y% of what number?" questions
  Map<String, dynamic> _buildFindWholeQuestion(
    int baseNumber,
    int percentage,
    int random,
  ) {
    final partValue = (baseNumber * percentage / 100).round();
    final correct = baseNumber;
    final options = <String>[
      correct.toString(),
      (correct + (random % 15) + 10).toString(),
      (correct - (random % 12) - 5).toString(),
      (correct * 1.3).round().toString(),
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length * 8 + 15).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        '$partValue is $percentage% of what number?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          'If $partValue is $percentage% of a number, then the number = $partValue ÷ ($percentage ÷ 100) = $correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build "What percent is X of Y?" questions
  Map<String, dynamic> _buildFindPercentQuestion(
    int baseNumber,
    int percentage,
    int random,
  ) {
    final partValue = (baseNumber * percentage / 100).round();
    final correct = percentage;
    final options = <String>[
      '$correct%',
      '${correct + (random % 8) + 3}%',
      '${correct - (random % 6) - 2}%',
      '${(correct * 1.4).round()}%',
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add('${correct + uniqueOptions.length * 5 + 8}%');
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf('$correct%');

    return {
      'question': _getGradeAppropriateQuestionText(
        'What percent is $partValue of $baseNumber?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation': '$partValue ÷ $baseNumber × 100% = $correct%',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build percentage increase/decrease questions
  Map<String, dynamic> _buildIncreaseDecreaseQuestion(
    int baseNumber,
    int percentage,
    int random,
  ) {
    final isIncrease = random % 2 == 0;
    final correct = isIncrease
        ? (baseNumber * (100 + percentage) / 100).round()
        : (baseNumber * (100 - percentage) / 100).round();

    final options = <String>[
      correct.toString(),
      (correct + (random % 20) + 10).toString(),
      (correct - (random % 15) - 8).toString(),
      isIncrease
          ? (baseNumber + (baseNumber * percentage / 100 * 0.8))
                .round()
                .toString()
          : (baseNumber - (baseNumber * percentage / 100 * 1.2))
                .round()
                .toString(),
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length * 12 + 20).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    final verb = isIncrease ? 'increased' : 'decreased';
    return {
      'question': _getGradeAppropriateQuestionText(
        'What is $baseNumber $verb by $percentage%?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          '$baseNumber $verb by $percentage% = $baseNumber × ${isIncrease ? (100 + percentage) : (100 - percentage)}% = $correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build compound percentage questions (for advanced grades)
  Map<String, dynamic> _buildCompoundPercentageQuestion(
    int baseNumber,
    int percentage,
    int random,
  ) {
    final firstIncrease = percentage;
    final secondDecrease = (percentage * 0.6).round();
    final afterFirst = (baseNumber * (100 + firstIncrease) / 100).round();
    final correct = (afterFirst * (100 - secondDecrease) / 100).round();

    final options = <String>[
      correct.toString(),
      (correct + (random % 25) + 15).toString(),
      (correct - (random % 20) - 10).toString(),
      (baseNumber * (100 + firstIncrease - secondDecrease) / 100)
          .round()
          .toString(), // Common mistake
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length * 18 + 30).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'A number $baseNumber is increased by $firstIncrease%, then decreased by $secondDecrease%. What is the result?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          '$baseNumber × (100 + $firstIncrease)% × (100 - $secondDecrease)% = $correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build percentage word problems
  Map<String, dynamic> _buildPercentageWordProblem(
    int baseNumber,
    int percentage,
    int random,
  ) {
    final contexts = _getGradeAppropriateContexts(_studentGradeLevel);
    final context = contexts[random % contexts.length];

    return _buildContextualPercentageProblem(
      baseNumber,
      percentage,
      context,
      random,
    );
  }

  /// Get grade-appropriate contexts for word problems
  List<String> _getGradeAppropriateContexts(GradeLevel gradeLevel) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
      case GradeLevel.grade1:
      case GradeLevel.grade2:
      case GradeLevel.grade3:
        return ['toys', 'candy', 'stickers'];
      case GradeLevel.grade4:
      case GradeLevel.grade5:
      case GradeLevel.grade6:
        return ['pizza', 'students', 'books', 'games'];
      case GradeLevel.grade7:
      case GradeLevel.grade8:
        return ['discount', 'test_scores', 'sports', 'population'];
      case GradeLevel.grade9:
      case GradeLevel.grade10:
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        return ['investment', 'salary', 'sales', 'statistics', 'business'];
    }
  }

  /// Build contextual percentage problems
  Map<String, dynamic> _buildContextualPercentageProblem(
    int baseNumber,
    int percentage,
    String context,
    int random,
  ) {
    switch (context) {
      case 'discount':
        return _buildDiscountProblem(baseNumber, percentage, random);
      case 'test_scores':
        return _buildTestScoreProblem(baseNumber, percentage, random);
      case 'investment':
        return _buildInvestmentProblem(baseNumber, percentage, random);
      default:
        return _buildSimplePercentageOfQuestion(baseNumber, percentage, random);
    }
  }

  /// Build discount problems
  Map<String, dynamic> _buildDiscountProblem(
    int basePrice,
    int discountPercent,
    int random,
  ) {
    final discount = (basePrice * discountPercent / 100).round();
    final correct = basePrice - discount;

    final options = <String>[
      '\$$correct',
      '\$${correct + (random % 15) + 8}',
      '\$${correct - (random % 12) - 5}',
      '\$$discount', // Common mistake - showing discount instead of final price
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add('\$${correct + uniqueOptions.length * 10 + 20}');
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf('\$$correct');

    return {
      'question': _getGradeAppropriateQuestionText(
        'A jacket costs \$$basePrice. If there is a $discountPercent% discount, what is the final price?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          'Discount = \$$basePrice × $discountPercent% = \$$discount. Final price = \$$basePrice - \$$discount = \$$correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build test score problems
  Map<String, dynamic> _buildTestScoreProblem(
    int totalQuestions,
    int percentage,
    int random,
  ) {
    final correct = (totalQuestions * percentage / 100).round();

    final options = <String>[
      correct.toString(),
      (correct + (random % 5) + 2).toString(),
      (correct - (random % 4) - 1).toString(),
      (totalQuestions - correct).toString(), // Common mistake
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add((correct + uniqueOptions.length * 3 + 6).toString());
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf(correct.toString());

    return {
      'question': _getGradeAppropriateQuestionText(
        'On a test with $totalQuestions questions, Sarah got $percentage% correct. How many questions did she get right?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          '$percentage% of $totalQuestions = $percentage ÷ 100 × $totalQuestions = $correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Build investment problems (for high school)
  Map<String, dynamic> _buildInvestmentProblem(
    int principal,
    int rate,
    int random,
  ) {
    final interest = (principal * rate / 100).round();
    final correct = principal + interest;

    final options = <String>[
      '\$$correct',
      '\$${correct + (random % 50) + 25}',
      '\$${correct - (random % 30) - 15}',
      '\$$interest', // Common mistake - showing interest instead of total
    ];

    final uniqueOptions = options.toSet().toList();
    while (uniqueOptions.length < 4) {
      uniqueOptions.add('\$${correct + uniqueOptions.length * 40 + 80}');
    }

    uniqueOptions.shuffle();
    final correctIndex = uniqueOptions.indexOf('\$$correct');

    return {
      'question': _getGradeAppropriateQuestionText(
        'If you invest \$$principal at $rate% simple interest for 1 year, what is the total amount?',
        _studentGradeLevel,
      ),
      'options': uniqueOptions.take(4).toList(),
      'correctAnswer': correctIndex,
      'explanation':
          'Interest = \$$principal × $rate% = \$$interest. Total = \$$principal + \$$interest = \$$correct',
      'gradeLevel': _studentGradeLevel.name,
      'category': 'percentages',
      'difficulty': _selectedDifficulty.name,
    };
  }

  /// Force category to percentages for testing (temporary method)
  void _forcePercentageQuestionsForTesting() {
    if (kDebugMode) {
      debugPrint('🧪 FORCING PERCENTAGE QUESTIONS FOR TESTING');
      setState(() {
        _selectedCategory = GameCategory.percentages;
        _selectedDifficulty = GameDifficulty.quantum;
        _studentGradeLevel = GradeLevel.grade5;
      });
      _generateQuestions();
      debugPrint(
        '✅ Forced generation complete - should see percentage questions now',
      );
    }
  }

  /// Generate placeholder questions for other categories (to be implemented)
  Map<String, dynamic> _generateFractionQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    // Placeholder - will implement if needed
    return _generateAdditionQuestion(difficulty, random);
  }

  Map<String, dynamic> _generateDecimalQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    // Placeholder - will implement if needed
    return _generateAdditionQuestion(difficulty, random);
  }

  Map<String, dynamic> _generateAlgebraQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    // Placeholder - will implement if needed
    return _generateAdditionQuestion(difficulty, random);
  }

  Map<String, dynamic> _generateGeometryQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    // Placeholder - will implement if needed
    return _generateAdditionQuestion(difficulty, random);
  }

  Map<String, dynamic> _generateWordProblemQuestion(
    GameDifficulty difficulty,
    int random,
  ) {
    // Placeholder - will implement if needed
    return _generateAdditionQuestion(difficulty, random);
  }

  void _selectAnswer(int answerIndex) {
    final isCorrect =
        answerIndex == _questions[_currentQuestionIndex]['correctAnswer'];

    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;

      if (isCorrect) {
        _score++;
        _consecutiveCorrect++;
        _consecutiveIncorrect = 0;
      } else {
        _consecutiveCorrect = 0;
        _consecutiveIncorrect++;
      }
    });

    // Update topic accuracy tracking
    _updateTopicAccuracy(_selectedCategory, isCorrect);

    // Apply adaptive difficulty if enabled
    if (_autoAdjustDifficulty) {
      _applyAdaptiveDifficulty();
    }

    // Apply smart topic rotation if enabled
    if (_smartTopicRotation && _consecutiveIncorrect >= 3) {
      _applySmartTopicRotation();
    }

    // Apply spaced repetition if enabled
    if (_spacedRepetition) {
      _applySpacedRepetition(_selectedCategory, isCorrect);
    }

    // Check focus topics and adjust if needed
    if (_focusTopics.isNotEmpty && !_focusTopics.contains(_selectedCategory)) {
      _suggestFocusTopicSwitch();
    }

    // Provide native haptic feedback (respects settings)
    if (_hapticFeedbackEnabled) {
      if (isCorrect) {
        triggerSuccessHaptic(); // Success haptic for correct answers
      } else {
        triggerErrorHaptic(); // Error haptic for incorrect answers
      }
    }

    // Play sound feedback (respects settings)
    if (_soundEnabled) {
      _playSoundFeedback(isCorrect);
    }

    // Show visual feedback with AI personality
    _showAnswerFeedbackWithPersonality(isCorrect, answerIndex);

    // Track the question performance
    _trackQuestionPerformance(isCorrect: isCorrect);
  }

  /// Play sound feedback based on settings
  void _playSoundFeedback(bool isCorrect) {
    // Sound feedback implementation would go here
    // For now, just log the action
    if (kDebugMode) {
      debugPrint('🔊 Sound feedback: ${isCorrect ? "Success" : "Error"}');
    }
  }

  /// Show visual answer feedback with AI personality
  void _showAnswerFeedbackWithPersonality(bool isCorrect, int answerIndex) {
    String message;
    IconData icon;
    Color color;

    // AI personality-based feedback
    if (isCorrect) {
      switch (_aiPersonality) {
        case 'Encouraging':
          message = '🌟 Great job! You got it right!';
          break;
        case 'Challenging':
          message = '🎯 Correct! Ready for a harder one?';
          break;
        case 'Patient':
          message = '🤗 Well done! Take your time on the next one.';
          break;
        case 'Energetic':
          message = '⚡ Awesome! You\'re on fire!';
          break;
        default:
          message = '✅ Correct!';
      }
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      switch (_aiPersonality) {
        case 'Encouraging':
          message = '💪 Not quite, but you\'re learning! Try again!';
          break;
        case 'Challenging':
          message = '🎯 Think harder! You can figure this out!';
          break;
        case 'Patient':
          message = '🤗 That\'s okay, let\'s try a different approach.';
          break;
        case 'Energetic':
          message = '⚡ Oops! Shake it off and keep going!';
          break;
        default:
          message = '❌ Try again!';
      }
      icon = Icons.refresh;
      color = Colors.orange;
    }

    // Show personality-based feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          duration: Duration(milliseconds: _reducedMotion ? 1000 : 2000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint('🤖 AI Feedback ($_aiPersonality): $message');
    }
  }

  /// Update topic accuracy tracking
  void _updateTopicAccuracy(GameCategory category, bool isCorrect) {
    if (!_topicAccuracy.containsKey(category)) {
      _topicAccuracy[category] = 0.0;
    }

    // Simple moving average for accuracy
    final currentAccuracy = _topicAccuracy[category]!;
    final newAccuracy = (currentAccuracy + (isCorrect ? 100 : 0)) / 2;
    _topicAccuracy[category] = newAccuracy;

    // Update struggling topics list
    if (newAccuracy < 60 && !_strugglingTopics.contains(category)) {
      _strugglingTopics.add(category);
    } else if (newAccuracy >= 80 && _strugglingTopics.contains(category)) {
      _strugglingTopics.remove(category);
    }
  }

  /// Apply adaptive difficulty based on performance
  void _applyAdaptiveDifficulty() {
    if (_consecutiveCorrect >= 5) {
      // Increase difficulty if too easy
      final currentIndex = GameDifficulty.values.indexOf(_selectedDifficulty);
      if (currentIndex < GameDifficulty.values.length - 1) {
        final newDifficulty = GameDifficulty.values[currentIndex + 1];
        setState(() => _selectedDifficulty = newDifficulty);
        _showSettingsChangeNotification(
          '🎯 Difficulty increased to ${newDifficulty.name} - you\'re doing great!',
        );
      }
    } else if (_consecutiveIncorrect >= 3) {
      // Decrease difficulty if too hard
      final currentIndex = GameDifficulty.values.indexOf(_selectedDifficulty);
      if (currentIndex > 0) {
        final newDifficulty = GameDifficulty.values[currentIndex - 1];
        setState(() => _selectedDifficulty = newDifficulty);
        _showSettingsChangeNotification(
          '🤗 Difficulty adjusted to ${newDifficulty.name} - let\'s build confidence!',
        );
      }
    }
  }

  /// Apply smart topic rotation based on performance
  void _applySmartTopicRotation() {
    if (_strugglingTopics.isNotEmpty) {
      // Don't rotate to struggling topics when having trouble
      return;
    }

    // Don't rotate away from specifically selected topics like percentages
    final userSelectedTopics = [
      GameCategory.percentages,
      GameCategory.fractions,
      GameCategory.decimals,
      GameCategory.algebra,
      GameCategory.geometry,
      GameCategory.calculus,
    ];

    if (userSelectedTopics.contains(_selectedCategory)) {
      if (kDebugMode) {
        debugPrint(
          '🚫 Smart topic rotation disabled - user selected ${_selectedCategory.name}',
        );
      }
      return;
    }

    // Only rotate between basic arithmetic topics
    final basicArithmeticCategories = [
      GameCategory.addition,
      GameCategory.subtraction,
      GameCategory.multiplication,
      GameCategory.division,
    ].where((cat) => cat != _selectedCategory).toList();

    if (basicArithmeticCategories.isNotEmpty) {
      final newCategory = basicArithmeticCategories.first;
      setState(() => _selectedCategory = newCategory);
      _showSettingsChangeNotification(
        '🔄 Switched to ${newCategory.name} for variety!',
      );
      _regenerateQuestionsIfNeeded();
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _resetTimer();
    } else {
      _pauseTimer();
      setState(() {
        _showResults = true;
      });

      // End the study session when game completes
      _endStudySession();

      // Update preferences from completed game
      final correctCount = _userAnswers
          .asMap()
          .entries
          .where(
            (entry) =>
                entry.key < _questions.length &&
                entry.value == _questions[entry.key]['correctAnswer'],
          )
          .length;

      updatePreferencesFromGameCompletion(
        score: correctCount,
        totalQuestions: _questions.length,
      );

      // Auto-start next game if enabled
      if (_autoStartNextGame) {
        _scheduleAutoStartNextGame();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    // Mark the start time for this question
    _questionStartTime = DateTime.now();
    _hintsUsed = 0; // Reset hints for new question

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer?.cancel();
        // Track timeout as incorrect answer
        _trackQuestionPerformance(isCorrect: false, isTimeout: true);
        // Auto-advance to next question when time runs out
        _nextQuestion();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    // Reset timer based on user preferences
    setState(() {
      _timeRemaining = _initialTimeLimit;
    });
    _startTimer();
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  /// Start a study session for analytics tracking
  Future<void> _startStudySession() async {
    try {
      final userManagementService = ref.read(userManagementServiceProvider);
      final currentUser = await userManagementService.getCurrentUser();

      if (currentUser?.id == null) return;

      final analyticsService = ref.read(studentAnalyticsServiceProvider);

      _currentSessionId = await analyticsService.startStudySession(
        studentId: currentUser!.id,
        sessionType: 'classic_quiz',
        topicsStudied: [_selectedCategory.name],
      );

      debugPrint('📚 Study session started: $_currentSessionId');
    } catch (e) {
      debugPrint('Error starting study session: $e');
    }
  }

  /// End the current study session
  Future<void> _endStudySession() async {
    try {
      if (_currentSessionId == null || !mounted) return;

      final userManagementService = ref.read(userManagementServiceProvider);
      final currentUser = await userManagementService.getCurrentUser();

      if (currentUser?.id == null) return;

      final analyticsService = ref.read(studentAnalyticsServiceProvider);
      final correctCount = _userAnswers
          .asMap()
          .entries
          .where(
            (entry) =>
                entry.key < _questions.length &&
                entry.value == _questions[entry.key]['correctAnswer'],
          )
          .length;

      await analyticsService.endStudySession(
        studentId: currentUser!.id,
        sessionId: _currentSessionId!,
        questionsAnswered: _questions.length,
        correctAnswers: correctCount,
      );

      debugPrint('📚 Study session ended: $_currentSessionId');
    } catch (e) {
      debugPrint('Error ending study session: $e');
    }
  }

  /// Setup real-time settings synchronization
  void _setupRealTimeSettingsSync() {
    // Listen to settings changes and update game immediately
    ref.listen(userGamePreferencesNotifierProvider, (previous, next) {
      if (mounted && next.hasValue && next.value != null) {
        _applySettingsInRealTime(next.value!);
      }
    });
  }

  /// Apply ALL settings changes in real-time during gameplay
  void _applySettingsInRealTime(UserGamePreferences newPreferences) {
    if (!mounted) return;

    final oldDifficulty = _selectedDifficulty;
    final oldCategory = _selectedCategory;
    final oldQuestionCount = _selectedQuestionCount;
    final oldTimeLimit = _selectedTimeLimit;

    setState(() {
      // Core game preferences
      _selectedDifficulty = newPreferences.preferredDifficulty;
      _selectedCategory = newPreferences.preferredCategory;
      _selectedQuestionCount = newPreferences.preferredQuestionCount;
      _selectedTimeLimit = newPreferences.preferredTimeLimit;
      _soundEnabled = newPreferences.soundEnabled;
      _hapticFeedbackEnabled = newPreferences.hapticFeedbackEnabled;
      _autoStartNextGame = newPreferences.autoStartNextGame;
      _initialTimeLimit = newPreferences.preferredTimeLimit;

      // Advanced learning preferences
      _autoAdjustDifficulty = newPreferences.autoAdjustDifficulty;
      _smartTopicRotation = newPreferences.smartTopicRotation;
      _spacedRepetition = newPreferences.spacedRepetition;
      _learningIntensity = newPreferences.learningIntensity;
      _focusTopics = List.from(newPreferences.focusTopics);

      // AI preferences
      _aiPersonality = newPreferences.aiPersonality;
      _aiStyle = newPreferences.aiStyle;
      _questionComplexity = newPreferences.questionComplexity;

      // Accessibility preferences
      _fontSize = newPreferences.fontSize;
      _highContrastMode = newPreferences.highContrastMode;
      _reducedMotion = newPreferences.reducedMotion;
    });

    // Note: Don't call mixin handler here to prevent infinite loop
    // The mixin methods would trigger another preference update

    // Show visual feedback for settings changes
    if (oldDifficulty != newPreferences.preferredDifficulty) {
      _showSettingsChangeNotification(
        'Difficulty updated to ${newPreferences.preferredDifficulty.name}',
      );
    }
    if (oldCategory != newPreferences.preferredCategory) {
      _showSettingsChangeNotification(
        'Category changed to ${newPreferences.preferredCategory.name}',
      );
    }
    if (oldQuestionCount != newPreferences.preferredQuestionCount) {
      _showSettingsChangeNotification(
        'Question count set to ${newPreferences.preferredQuestionCount}',
      );
    }
    if (oldTimeLimit != newPreferences.preferredTimeLimit) {
      _showSettingsChangeNotification(
        'Time limit changed to ${newPreferences.preferredTimeLimit}s',
      );
      // Update current timer if game is active
      if (_questions.isNotEmpty && !_showResults) {
        _timeRemaining = newPreferences.preferredTimeLimit;
        _resetTimer();
      }
    }

    // Regenerate questions if difficulty or category changed
    if (oldDifficulty != newPreferences.preferredDifficulty ||
        oldCategory != newPreferences.preferredCategory) {
      _regenerateQuestionsWithNewSettings();
    }

    if (kDebugMode) {
      debugPrint('🔄 Settings applied in real-time:');
      debugPrint(
        '   📊 Difficulty: ${newPreferences.preferredDifficulty.name}',
      );
      debugPrint('   📚 Category: ${newPreferences.preferredCategory.name}');
      debugPrint('   🔢 Questions: ${newPreferences.preferredQuestionCount}');
      debugPrint('   ⏰ Time: ${newPreferences.preferredTimeLimit}s');
      debugPrint('   🔊 Sound: ${newPreferences.soundEnabled}');
      debugPrint('   📳 Haptic: ${newPreferences.hapticFeedbackEnabled}');
    }
  }

  /// Show visual notification when settings change
  void _showSettingsChangeNotification(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.settings, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Regenerate questions when settings change
  void _regenerateQuestionsWithNewSettings() {
    if (!mounted || _showResults) return;

    // Save current progress
    final currentProgress = {
      'currentIndex': _currentQuestionIndex,
      'score': _score,
      'answers': List<int>.from(_userAnswers),
    };

    // Generate new questions with updated settings
    _generateQuestions();

    // Restore progress if possible
    if (currentProgress['currentIndex'] as int < _selectedQuestionCount) {
      setState(() {
        _currentQuestionIndex = currentProgress['currentIndex'] as int;
        _score = currentProgress['score'] as int;
        _userAnswers = currentProgress['answers'] as List<int>;
      });
    }

    if (kDebugMode) {
      debugPrint('🔄 Questions regenerated with new settings');
    }
  }

  /// Enhanced settings-aware question generation
  void _generateQuestions() {
    if (kDebugMode) {
      debugPrint('🔧 GENERATING QUESTIONS:');
      debugPrint('   📊 Current Category: ${_selectedCategory.name}');
      debugPrint('   🎯 Current Difficulty: ${_selectedDifficulty.name}');
      debugPrint('   🎓 Current Grade: ${_studentGradeLevel.name}');
      debugPrint('   🔢 Question Count: $_selectedQuestionCount');
    }

    setState(() {
      // Create new lists instead of clearing fixed-length lists
      _questions = <Map<String, dynamic>>[];
      _userAnswers = <int>[];

      // Generate questions based on current settings
      for (int i = 0; i < _selectedQuestionCount; i++) {
        Map<String, dynamic> question;

        switch (_selectedCategory) {
          case GameCategory.addition:
            question = _generateAdditionQuestion(_selectedDifficulty, i);
            if (kDebugMode) {
              debugPrint(
                '🔢 Generated addition question: ${question['question']}',
              );
            }
            break;
          case GameCategory.subtraction:
            question = _generateSubtractionQuestion(_selectedDifficulty, i);
            if (kDebugMode) {
              debugPrint(
                '➖ Generated subtraction question: ${question['question']}',
              );
            }
            break;
          case GameCategory.multiplication:
            question = _generateMultiplicationQuestion(_selectedDifficulty, i);
            if (kDebugMode) {
              debugPrint(
                '✖️ Generated multiplication question: ${question['question']}',
              );
            }
            break;
          case GameCategory.division:
            question = _generateDivisionQuestion(_selectedDifficulty, i);
            if (kDebugMode) {
              debugPrint(
                '➗ Generated division question: ${question['question']}',
              );
            }
            break;
          case GameCategory.percentages:
            question = _generatePercentageQuestion(_selectedDifficulty, i);
            if (kDebugMode) {
              debugPrint(
                '📊 Generated percentage question: ${question['question']}',
              );
              debugPrint(
                '📊 Question type: ${question['category']} - Grade: ${question['gradeLevel']} - Difficulty: ${question['difficulty']}',
              );
            }
            break;
          case GameCategory.fractions:
            question = _generateFractionQuestion(_selectedDifficulty, i);
            break;
          case GameCategory.decimals:
            question = _generateDecimalQuestion(_selectedDifficulty, i);
            break;
          case GameCategory.algebra:
            question = _generateAlgebraQuestion(_selectedDifficulty, i);
            break;
          case GameCategory.geometry:
            question = _generateGeometryQuestion(_selectedDifficulty, i);
            break;
          case GameCategory.wordProblems:
            question = _generateWordProblemQuestion(_selectedDifficulty, i);
            break;
          default:
            question = _generateAdditionQuestion(_selectedDifficulty, i);
        }

        _questions.add(question);
        _userAnswers.add(-1); // -1 means no answer selected
      }
    });

    if (kDebugMode) {
      debugPrint(
        '📝 Generated ${_questions.length} questions for ${_selectedCategory.name} at ${_selectedDifficulty.name} difficulty (Grade: ${_studentGradeLevel.name})',
      );
      debugPrint(
        '🎯 Header Settings: ${_selectedDifficulty.name} + ${_selectedCategory.name} + ${_studentGradeLevel.name}',
      );
      debugPrint(
        '📊 Question Settings: All questions match header configuration',
      );

      // Show first few questions for verification
      for (int i = 0; i < _questions.length.clamp(0, 3); i++) {
        debugPrint('   Question ${i + 1}: ${_questions[i]['question']}');
        if (_questions[i].containsKey('category')) {
          debugPrint('   Category: ${_questions[i]['category']}');
        }
      }
    }
  }

  /// Track question performance for analytics
  Future<void> _trackQuestionPerformance({
    required bool isCorrect,
    bool isTimeout = false,
  }) async {
    try {
      if (_questionStartTime == null) return;

      final responseTime = DateTime.now().difference(_questionStartTime!);
      final currentQuestion = _questions[_currentQuestionIndex];
      final userManagementService = ref.read(userManagementServiceProvider);
      final currentUser = await userManagementService.getCurrentUser();

      if (currentUser?.id == null) return;

      final analyticsService = ref.read(studentAnalyticsServiceProvider);

      await analyticsService.trackQuestionPerformance(
        studentId: currentUser!.id,
        questionId:
            'classic_${_currentQuestionIndex}_${DateTime.now().millisecondsSinceEpoch}',
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        gradeLevel: _studentGradeLevel, // Use actual student grade level
        isCorrect: isCorrect,
        responseTime: responseTime,
        hintsUsed: _hintsUsed,
        gameMode: 'classic_quiz',
        additionalData: {
          'question': currentQuestion['question'],
          'options': currentQuestion['options'],
          'correctAnswer': currentQuestion['correctAnswer'],
          'isTimeout': isTimeout,
          'timeLimit': _initialTimeLimit,
          'timeRemaining': _timeRemaining,
          'gradeLevel': _studentGradeLevel.name,
          'gradeAware': _gradeAwareQuestions,
        },
      );

      debugPrint(
        '📊 Question performance tracked: ${isCorrect ? "Correct" : "Incorrect"} in ${responseTime.inSeconds}s',
      );
    } catch (e) {
      debugPrint('Error tracking question performance: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // End study session asynchronously without waiting
    // Use unawaited to prevent blocking dispose()
    if (_currentSessionId != null) {
      _endStudySession().catchError((e) {
        debugPrint('Error ending study session during dispose: $e');
      });
    }
    super.dispose();
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResults = false;
      _userAnswers = List.generate(_questions.length, (index) => -1);
      _consecutiveCorrect = 0;
      _consecutiveIncorrect = 0;
    });
    _startTimer();
  }

  /// Schedule auto-start of next game
  void _scheduleAutoStartNextGame() {
    if (!mounted) return;

    Timer(const Duration(seconds: 3), () {
      if (mounted && _autoStartNextGame) {
        _showAutoStartNotification();
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            _restartQuiz();
          }
        });
      }
    });
  }

  /// Show auto-start notification
  void _showAutoStartNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('🚀 Auto-starting next game in 2 seconds...'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Apply spaced repetition logic
  void _applySpacedRepetition(GameCategory category, bool isCorrect) {
    if (!isCorrect) {
      // Add to spaced repetition queue for review
      if (kDebugMode) {
        debugPrint('📚 Added ${category.name} to spaced repetition queue');
      }
    }
  }

  /// Suggest switching to focus topics
  void _suggestFocusTopicSwitch() {
    if (_focusTopics.isNotEmpty) {
      final focusTopic = _focusTopics.first;
      _showSettingsChangeNotification(
        '🎯 Consider switching to focus topic: ${focusTopic.name}',
      );
    }
  }

  /// Apply AI style to question presentation
  String _getAIStyleFeedback() {
    switch (_aiStyle) {
      case 'Adaptive':
        return 'Adaptive AI';
      case 'Progressive':
        return 'Progressive';
      case 'Mixed':
        return 'Mixed Mode';
      default:
        return 'AI Active';
    }
  }

  /// Get color for difficulty level
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

  /// Get icon for category
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
      case GameCategory.algebra:
        return Icons.functions;
      case GameCategory.geometry:
        return Icons.square;
      case GameCategory.calculus:
        return Icons.auto_graph;
      case GameCategory.fractions:
        return Icons.pie_chart;
      case GameCategory.decimals:
        return Icons.more_horiz;
      case GameCategory.percentages:
        return Icons.percent;
      case GameCategory.wordProblems:
        return Icons.article;
      case GameCategory.measurement:
        return Icons.straighten;
      case GameCategory.dataAnalysis:
        return Icons.bar_chart;
      case GameCategory.patterns:
        return Icons.pattern;
    }
  }

  /// Get display name for category
  String _getCategoryDisplayName(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return 'Addition';
      case GameCategory.subtraction:
        return 'Subtraction';
      case GameCategory.multiplication:
        return 'Multiplication';
      case GameCategory.division:
        return 'Division';
      case GameCategory.algebra:
        return 'Algebra';
      case GameCategory.geometry:
        return 'Geometry';
      case GameCategory.calculus:
        return 'Calculus';
      case GameCategory.fractions:
        return 'Fractions';
      case GameCategory.decimals:
        return 'Decimals';
      case GameCategory.percentages:
        return 'Percentages';
      case GameCategory.wordProblems:
        return 'Word Problems';
      case GameCategory.measurement:
        return 'Measurement';
      case GameCategory.dataAnalysis:
        return 'Data Analysis';
      case GameCategory.patterns:
        return 'Patterns';
    }
  }

  /// Get grade-level adjustment multiplier for question difficulty
  double _getGradeAdjustment(GradeLevel gradeLevel) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return 0.3; // Much simpler questions
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        return 0.5; // Simpler questions
      case GradeLevel.grade3:
      case GradeLevel.grade4:
        return 0.7; // Slightly simpler
      case GradeLevel.grade5:
      case GradeLevel.grade6:
        return 1.0; // Standard difficulty
      case GradeLevel.grade7:
      case GradeLevel.grade8:
        return 1.3; // More challenging
      case GradeLevel.grade9:
      case GradeLevel.grade10:
        return 1.5; // High school level
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        return 1.8; // Advanced level
    }
  }

  /// Get minimum number value appropriate for grade level
  int _getGradeLevelMinimum(GradeLevel gradeLevel) {
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return 1; // Single digits
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        return 1; // Single to double digits
      case GradeLevel.grade3:
      case GradeLevel.grade4:
        return 5; // Double digits
      case GradeLevel.grade5:
      case GradeLevel.grade6:
        return 10; // Teens and up
      case GradeLevel.grade7:
      case GradeLevel.grade8:
        return 15; // More complex numbers
      case GradeLevel.grade9:
      case GradeLevel.grade10:
        return 20; // Higher numbers
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        return 25; // Advanced numbers
    }
  }

  /// Get grade-appropriate question text formatting
  String _getGradeAppropriateQuestionText(
    String baseQuestion,
    GradeLevel gradeLevel,
  ) {
    // For younger grades, use more encouraging language
    switch (gradeLevel) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
      case GradeLevel.grade1:
        return baseQuestion.replaceAll('What is', 'Can you find');
      case GradeLevel.grade2:
      case GradeLevel.grade3:
        return baseQuestion.replaceAll('What is', 'What equals');
      default:
        return baseQuestion; // Standard format for higher grades
    }
  }

  /// Get grade level display name
  String _getGradeLevelDisplayName(GradeLevel gradeLevel) {
    switch (gradeLevel) {
      case GradeLevel.preK:
        return 'Pre-K';
      case GradeLevel.kindergarten:
        return 'Kindergarten';
      case GradeLevel.grade1:
        return '1st Grade';
      case GradeLevel.grade2:
        return '2nd Grade';
      case GradeLevel.grade3:
        return '3rd Grade';
      case GradeLevel.grade4:
        return '4th Grade';
      case GradeLevel.grade5:
        return '5th Grade';
      case GradeLevel.grade6:
        return '6th Grade';
      case GradeLevel.grade7:
        return '7th Grade';
      case GradeLevel.grade8:
        return '8th Grade';
      case GradeLevel.grade9:
        return '9th Grade';
      case GradeLevel.grade10:
        return '10th Grade';
      case GradeLevel.grade11:
        return '11th Grade';
      case GradeLevel.grade12:
        return '12th Grade';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    // Setup real-time settings synchronization by calling the dedicated method
    _setupRealTimeSettingsSync();

    // Watch accessibility preferences for real-time updates
    final accessibilitySettings = ref.watch(accessibilitySettingsProvider);
    final animationDuration = ref.watch(
      adaptiveAnimationDurationProvider(const Duration(milliseconds: 300)),
    );

    // Watch for preference changes and sync automatically
    final currentPrefs = ref.watch(currentUserGamePreferencesProvider);
    if (currentPrefs != null) {
      // Check if we need to sync preferences to game state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_selectedDifficulty != currentPrefs.preferredDifficulty ||
                _selectedCategory != currentPrefs.preferredCategory ||
                _selectedQuestionCount != currentPrefs.preferredQuestionCount ||
                _selectedTimeLimit != currentPrefs.preferredTimeLimit ||
                _soundEnabled != currentPrefs.soundEnabled ||
                _hapticFeedbackEnabled != currentPrefs.hapticFeedbackEnabled)) {
          _syncGameStateToPreferences(currentPrefs);
        }
      });
    }

    return PopScope(
      canPop: _showResults, // Only allow pop when game is finished
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_showResults) {
          final canGoBack =
              await NavigationEnhancements.handleGameBackNavigation(
                context: context,
                isGameActive: !_showResults,
                onSaveProgress: () async {
                  await saveGameProgress();
                },
              );

          if (canGoBack && context.mounted) {
            context.go('/game-modes');
          }
        }
      },
      child: _buildGameContent(
        context,
        themeData,
        colorScheme,
        animationDuration,
        accessibilitySettings,
      ),
    );
  }

  Widget _buildGameContent(
    BuildContext context,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Duration animationDuration,
    Map<String, dynamic> accessibilitySettings,
  ) {
    final navigationItems = [
      const NavigationItem(title: 'Home', icon: Icons.home, route: '/home'),
      const NavigationItem(
        title: 'Games',
        icon: Icons.games,
        route: '/game-modes',
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
      child: AccessibilityService.addScreenReaderSemantics(
        child: _buildQuizContent(themeData, colorScheme, animationDuration),
        screenReaderOptimized:
            accessibilitySettings['screenReaderOptimized'] ?? false,
        label: 'Classic Quiz Game',
        hint: 'Math quiz with multiple choice questions',
      ),
    );
  }

  Widget _buildQuizContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Duration animationDuration,
  ) {
    if (_showResults) {
      return _buildResultsScreen(themeData, colorScheme);
    }

    return _buildQuestionScreen(themeData, colorScheme, animationDuration);
  }

  Widget _buildQuestionScreen(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Duration animationDuration,
  ) {
    // Safety check to prevent RangeError
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final userAnswer = _userAnswers[_currentQuestionIndex];

    return PopScope(
      canPop: false, // Disable system back button to avoid conflicts
      onPopInvokedWithResult: (didPop, result) {
        // Let our custom back button handle all navigation
        debugPrint(
          'System back intercepted - using custom back button instead',
        );
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Professional Header
              _buildProfessionalHeader(context, colorScheme),

              // Main Content Area - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    context.adaptiveLayout.contentPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Card
                      _buildModernQuestionCard(currentQuestion, colorScheme),

                      SizedBox(
                        height: context.adaptiveLayout.cardSpacing * 1.5,
                      ),

                      // Answer Options
                      _buildAnswerOptionsSection(
                        currentQuestion,
                        userAnswer,
                        colorScheme,
                        animationDuration,
                      ),

                      // Hint Section (if available)
                      if (currentQuestion.containsKey('hint') &&
                          currentQuestion['hint'] != null)
                        _buildHintSection(currentQuestion['hint'], colorScheme),

                      SizedBox(height: context.adaptiveLayout.cardSpacing * 2),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigation(userAnswer, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernQuestionCard(
    Map<String, dynamic> currentQuestion,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.quiz,
                  size: 14,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Multiple Choice',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.adaptiveLayout.cardSpacing),

          // Question text with accessibility-aware styling
          Text(
            currentQuestion['question'],
            style: TextStyle(
              color: _highContrastMode ? Colors.black : colorScheme.onSurface,
              fontSize: 22 * _fontSize, // Apply font size preference
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptionsSection(
    Map<String, dynamic> currentQuestion,
    int userAnswer,
    ColorScheme colorScheme,
    Duration animationDuration,
  ) {
    final options = currentQuestion['options'] as List;
    final correctAnswer = currentQuestion['correctAnswer'] as int;

    // Determine if we should use grid or list layout based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final useGridLayout = screenWidth > 600 && options.length <= 4;

    if (useGridLayout) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) => _buildModernAnswerCard(
          options[index],
          index,
          userAnswer,
          correctAnswer,
          colorScheme,
          animationDuration,
        ),
      );
    } else {
      return Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: context.adaptiveLayout.cardSpacing,
            ),
            child: _buildModernAnswerCard(
              option,
              index,
              userAnswer,
              correctAnswer,
              colorScheme,
              animationDuration,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildModernAnswerCard(
    String option,
    int index,
    int userAnswer,
    int correctAnswer,
    ColorScheme colorScheme,
    Duration animationDuration,
  ) {
    final isSelected = userAnswer == index;
    final isCorrect = index == correctAnswer;
    final showResult = userAnswer != -1;
    final showCorrect = showResult && isCorrect;
    final showIncorrect = showResult && isSelected && !isCorrect;

    Color cardColor;
    Color textColor;
    Color borderColor;
    IconData? icon;

    if (showCorrect) {
      cardColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green[700]!;
      borderColor = Colors.green;
      icon = Icons.check_circle;
    } else if (showIncorrect) {
      cardColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red[700]!;
      borderColor = Colors.red;
      icon = Icons.cancel;
    } else if (isSelected) {
      cardColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      borderColor = colorScheme.primary;
    } else {
      cardColor = colorScheme.surface;
      textColor = colorScheme.onSurface;
      borderColor = colorScheme.outline.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: userAnswer == -1 ? () => _selectAnswer(index) : null,
      child: AnimatedContainer(
        duration: animationDuration,
        padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected || showResult ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected && userAnswer == -1)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Option letter
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: showResult
                    ? (showCorrect
                          ? Colors.green
                          : showIncorrect
                          ? Colors.red
                          : colorScheme.primaryContainer)
                    : colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: showResult
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Option text
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Result icon
            if (icon != null)
              Icon(
                icon,
                color: showCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintSection(String hint, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(top: context.adaptiveLayout.cardSpacing),
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: colorScheme.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(int userAnswer, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Debug button for testing percentage questions (only in debug mode)
            if (kDebugMode && _selectedCategory != GameCategory.percentages)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _forcePercentageQuestionsForTesting,
                  icon: const Icon(Icons.science),
                  label: const Text('Test %'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (kDebugMode && _selectedCategory != GameCategory.percentages)
              const SizedBox(width: 8),

            // Next/Finish button
            Expanded(
              flex: _currentQuestionIndex > 0 ? 1 : 2,
              child: ElevatedButton.icon(
                onPressed: userAnswer != -1 ? _nextQuestion : null,
                icon: Icon(
                  _currentQuestionIndex < _questions.length - 1
                      ? Icons.arrow_forward
                      : Icons.check_circle,
                ),
                label: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'Finish Quiz',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: userAnswer != -1 ? 2 : 0,
                ),
              ),
            ),
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

  /// Builds a professional header section with back button, progress, timer, and score
  Widget _buildProfessionalHeader(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Back button, Title with settings, Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact back button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    debugPrint('Back button tapped - checking game state');
                    if (_showResults || _questions.isEmpty) {
                      context.go('/game-modes');
                    } else {
                      final canGoBack =
                          await NavigationEnhancements.handleGameBackNavigation(
                            context: context,
                            isGameActive: true,
                            onSaveProgress: () async {
                              await saveGameProgress();
                            },
                          );

                      if (canGoBack && context.mounted) {
                        context.go('/game-modes');
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: colorScheme.onSurface,
                      size: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title and settings section - optimized layout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row with difficulty badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Classic Quiz',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                              _selectedDifficulty,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getDifficultyColor(_selectedDifficulty),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _selectedDifficulty.name.toUpperCase(),
                            style: TextStyle(
                              color: _getDifficultyColor(_selectedDifficulty),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Category and question info row
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(_selectedCategory),
                          color: colorScheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getCategoryDisplayName(_selectedCategory),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Q${_currentQuestionIndex + 1}/${_questions.length}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Grade level and AI style row
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: colorScheme.secondary,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getGradeLevelDisplayName(_studentGradeLevel),
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.smart_toy,
                          color: colorScheme.tertiary,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getAIStyleFeedback(),
                            style: TextStyle(
                              color: colorScheme.tertiary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Compact stats section
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 10
                          ? Colors.red.withValues(alpha: 0.1)
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _timeRemaining <= 10
                            ? Colors.red.withValues(alpha: 0.5)
                            : colorScheme.tertiary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _timeRemaining <= 10
                              ? Icons.timer
                              : Icons.access_time,
                          color: _timeRemaining <= 10
                              ? Colors.red
                              : colorScheme.onTertiaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_timeRemaining}s',
                          style: TextStyle(
                            color: _timeRemaining <= 10
                                ? Colors.red
                                : colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.primaryContainer.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_score',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar - more compact
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
