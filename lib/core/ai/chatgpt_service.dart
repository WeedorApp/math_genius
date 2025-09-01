import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// Models
import '../../features/game/models/ai_difficulty_model.dart';
import '../../features/game/models/game_model.dart';

// Configuration
import 'chatgpt_config.dart';

// Preferences
import '../preferences/preferences_notifier.dart';

/// Advanced ChatGPT Service for Math Genius
/// Real AI model integration for intelligent question generation and analysis
class ChatGPTService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  final String _apiKey;
  final http.Client _httpClient;
  final ChatGPTConfig _config;

  ChatGPTService(this._apiKey, this._httpClient, this._config);

  /// Generate AI-powered mathematical questions with real-time preference integration
  Future<List<AIQuestion>> generateAIQuestions({
    required AIDifficulty difficultyLevel,
    required GameCategory category,
    required int count,
    String? userId,
    Map<String, dynamic>? userContext,
    WidgetRef? ref, // For accessing real-time preferences
  }) async {
    try {
      // Check if ChatGPT is enabled and API key is available
      if (!_config.isEnabled || !_config.hasApiKey) {
        if (kDebugMode) {
          print('ChatGPT: Disabled or no API key available');
        }
        return [];
      }

      // Get real-time preferences for AI customization
      Map<String, dynamic> enhancedContext = Map.from(userContext ?? {});
      if (ref != null) {
        final currentPrefs = ref.read(currentUserGamePreferencesProvider);
        if (currentPrefs != null) {
          enhancedContext.addAll({
            'aiPersonality': currentPrefs.aiPersonality,
            'aiStyle': currentPrefs.aiStyle,
            'chatGPTModel': currentPrefs.chatGPTModel,
            'tutoringStyle': currentPrefs.tutoringStyle,
            'explanationDepth': currentPrefs.explanationDepth,
            'questionComplexity': currentPrefs.questionComplexity,
            'learningIntensity': currentPrefs.learningIntensity,
          });
          
          if (kDebugMode) {
            print('ChatGPT: Using real-time preferences - ${currentPrefs.aiPersonality} personality, ${currentPrefs.tutoringStyle} style');
          }
        }
      }

      if (kDebugMode) {
        print(
          'ChatGPT: Generating $count questions for $difficultyLevel difficulty',
        );
      }

      final questions = <AIQuestion>[];

      for (int i = 0; i < count; i++) {
        final question = await _generateSingleAIQuestion(
          difficultyLevel,
          category,
          userId,
          enhancedContext, // Use enhanced context with preferences
        );
        questions.add(question);
      }

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('ChatGPT: Error generating questions: $e');
      }
      return [];
    }
  }

  /// Generate a single AI question using ChatGPT
  Future<AIQuestion> _generateSingleAIQuestion(
    AIDifficulty difficultyLevel,
    GameCategory category,
    String? userId,
    Map<String, dynamic>? userContext,
  ) async {
    final prompt = _buildQuestionPrompt(difficultyLevel, category, userContext);

    final response = await _callChatGPT(prompt);
    final questionData = response; // response is already Map<String, dynamic>

    return AIQuestion(
      id: _generateId(),
      question: questionData['question'],
      options: questionData['options'],
      correctAnswer: questionData['correctAnswer'],
      category: category,
      difficulty: _mapDifficultyToGame(difficultyLevel),
      gradeLevel: _determineGradeLevel(difficultyLevel),
      explanation: questionData['explanation'],
      hint: questionData['hint'],
      timeLimit: _getTimeLimit(difficultyLevel),
      aiMetadata: {
        'model': _config.model,
        'difficulty': difficultyLevel.name,
        'category': category.name,
        'generationMethod': 'chatgpt',
        'confidence': questionData['confidence'] ?? 0.85,
        'complexity': _calculateComplexity(difficultyLevel),
      },
      confidence: questionData['confidence'] ?? 0.85,
      learningObjectives: _getLearningObjectives(difficultyLevel, category),
      visualAid: questionData['visualAid'],
    );
  }

  /// Build comprehensive prompt for ChatGPT
  String _buildQuestionPrompt(
    AIDifficulty difficultyLevel,
    GameCategory category,
    Map<String, dynamic>? userContext,
  ) {
    final difficultyConfig = _getDifficultyConfig(difficultyLevel);
    final categoryDescription = _getCategoryDescription(category);

    return '''
You are an expert mathematics educator creating questions for the Math Genius learning platform.

DIFFICULTY LEVEL: ${difficultyLevel.name.toUpperCase()}
- Cognitive Load: ${difficultyConfig['cognitiveLoad']}
- Time Limit: ${difficultyConfig['timeLimit']} seconds
- Success Threshold: ${difficultyConfig['successThreshold']}%
- Learning Mode: ${difficultyConfig['learningMode']}

CATEGORY: $categoryDescription

REQUIREMENTS:
1. Create a mathematical question appropriate for ${difficultyLevel.name} difficulty
2. Generate 4 multiple choice options (A, B, C, D)
3. Provide a clear explanation of the solution
4. Include a helpful hint for students
5. Ensure the question tests ${difficultyConfig['cognitiveSkills'].join(', ')}

USER CONTEXT: ${userContext != null ? jsonEncode(userContext) : 'No specific context'}

Please respond in the following JSON format:
{
  "question": "The mathematical question text",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswer": 0,
  "explanation": "Step-by-step solution explanation",
  "hint": "A helpful hint for students",
  "confidence": 0.85,
  "visualAid": "optional_visual_description",
  "learningObjectives": ["objective1", "objective2"],
  "cognitiveSkills": ["skill1", "skill2"]
}

Make the question engaging, educational, and appropriate for the specified difficulty level.
''';
  }

  /// Call ChatGPT API
  Future<Map<String, dynamic>> _callChatGPT(String prompt) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _config.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert mathematics educator specializing in creating engaging, educational questions for students of all levels.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': _config.maxTokens,
          'temperature': _config.temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        final message = choices.first['message'] as Map<String, dynamic>;
        final content = message['content'] as String;

        return _parseChatGPTResponse(content);
      } else {
        throw Exception(
          'ChatGPT API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatGPT: API call error: $e');
      }
      // Fallback to local generation
      return _generateFallbackQuestion();
    }
  }

  /// Parse ChatGPT response
  Map<String, dynamic> _parseChatGPTResponse(String content) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // If no JSON found, parse manually
      return _parseManualResponse(content);
    } catch (e) {
      if (kDebugMode) {
        print('ChatGPT: Error parsing response: $e');
      }
      return _generateFallbackQuestion();
    }
  }

  /// Parse response manually if JSON parsing fails
  Map<String, dynamic> _parseManualResponse(String content) {
    // Extract question
    final questionMatch = RegExp(
      r'question["\s]*:["\s]*"([^"]+)"',
    ).firstMatch(content);
    final question = questionMatch?.group(1) ?? 'What is 2 + 2?';

    // Extract options
    final optionsMatch = RegExp(
      r'options["\s]*:["\s]*\[(.*?)\]',
    ).firstMatch(content);
    List<String> options = ['3', '4', '5', '6'];
    if (optionsMatch != null) {
      final optionsString = optionsMatch.group(1)!;
      final optionMatches = RegExp(r'"([^"]+)"').allMatches(optionsString);
      options = optionMatches.map((m) => m.group(1)!).toList();
    }

    // Extract correct answer
    final correctMatch = RegExp(
      r'correctAnswer["\s]*:["\s]*(\d+)',
    ).firstMatch(content);
    final correctAnswer = int.tryParse(correctMatch?.group(1) ?? '1') ?? 1;

    // Extract explanation
    final explanationMatch = RegExp(
      r'explanation["\s]*:["\s]*"([^"]+)"',
    ).firstMatch(content);
    final explanation =
        explanationMatch?.group(1) ?? 'Add the numbers together.';

    // Extract hint
    final hintMatch = RegExp(r'hint["\s]*:["\s]*"([^"]+)"').firstMatch(content);
    final hint = hintMatch?.group(1) ?? 'Count on your fingers if needed.';

    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'hint': hint,
      'confidence': 0.8,
    };
  }

  /// Generate fallback question when ChatGPT fails
  Map<String, dynamic> _generateFallbackQuestion([
    AIDifficulty? difficultyLevel,
    GameCategory? category,
  ]) {
    final random = Random();

    switch (category ?? GameCategory.addition) {
      case GameCategory.addition:
        final a = random.nextInt(20) + 1;
        final b = random.nextInt(20) + 1;
        final answer = a + b;

        return {
          'question': 'What is $a + $b?',
          'options': _generateOptions(answer, 4, random),
          'correctAnswer': 0,
          'explanation': 'To add $a and $b, count: $a + $b = ${a + b}',
          'hint': 'Count on your fingers or use a number line.',
          'confidence': 0.9,
        };

      case GameCategory.subtraction:
        final a = random.nextInt(20) + 10;
        final b = random.nextInt(10) + 1;
        final answer = a - b;

        return {
          'question': 'What is $a - $b?',
          'options': _generateOptions(answer, 4, random),
          'correctAnswer': 0,
          'explanation': 'To subtract $b from $a: $a - $b = ${a - b}',
          'hint': 'Start with the larger number and count backwards.',
          'confidence': 0.9,
        };

      default:
        return _generateFallbackQuestion(
          difficultyLevel,
          GameCategory.addition,
        );
    }
  }

  /// Generate options with unpredictable placement
  List<String> _generateOptions(int correctAnswer, int count, Random random) {
    final options = <String>[];
    final usedNumbers = <int>{correctAnswer};

    // Add correct answer
    options.add(correctAnswer.toString());

    // Generate wrong answers
    while (options.length < count) {
      int wrongAnswer = correctAnswer + random.nextInt(10) - 5;
      if (wrongAnswer <= 0) wrongAnswer = correctAnswer + random.nextInt(5) + 1;

      if (!usedNumbers.contains(wrongAnswer)) {
        options.add(wrongAnswer.toString());
        usedNumbers.add(wrongAnswer);
      }
    }

    // Shuffle options multiple times for unpredictability
    for (int i = 0; i < 3; i++) {
      options.shuffle(random);
    }

    return options;
  }

  /// Get difficulty configuration
  Map<String, dynamic> _getDifficultyConfig(AIDifficulty difficultyLevel) {
    switch (difficultyLevel) {
      case AIDifficulty.beginner:
        return {
          'cognitiveLoad': 'Low',
          'timeLimit': 60,
          'successThreshold': 70,
          'learningMode': 'Scaffolded',
          'cognitiveSkills': [
            'Basic computation',
            'Number recognition',
            'Simple problem solving',
          ],
        };
      case AIDifficulty.intermediate:
        return {
          'cognitiveLoad': 'Medium',
          'timeLimit': 45,
          'successThreshold': 80,
          'learningMode': 'Progressive',
          'cognitiveSkills': [
            'Analytical thinking',
            'Pattern recognition',
            'Logical reasoning',
          ],
        };
      case AIDifficulty.advanced:
        return {
          'cognitiveLoad': 'High',
          'timeLimit': 30,
          'successThreshold': 85,
          'learningMode': 'Challenge',
          'cognitiveSkills': [
            'Complex problem solving',
            'Abstract thinking',
            'Mathematical insight',
          ],
        };
      case AIDifficulty.expert:
        return {
          'cognitiveLoad': 'Very High',
          'timeLimit': 20,
          'successThreshold': 90,
          'learningMode': 'Mastery',
          'cognitiveSkills': [
            'Genius-level reasoning',
            'Mathematical mastery',
            'Innovative thinking',
          ],
        };
    }
  }

  /// Get category description
  String _getCategoryDescription(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return 'Basic addition operations with whole numbers';
      case GameCategory.subtraction:
        return 'Basic subtraction operations with whole numbers';
      case GameCategory.multiplication:
        return 'Multiplication facts and basic multiplication problems';
      case GameCategory.division:
        return 'Division facts and basic division problems';
      case GameCategory.algebra:
        return 'Basic algebraic concepts and equations';
      case GameCategory.geometry:
        return 'Geometric shapes, measurements, and spatial reasoning';
      case GameCategory.calculus:
        return 'Advanced mathematical concepts including derivatives and integrals';
      default:
        return 'General mathematical concepts';
    }
  }

  /// Map AI difficulty to game difficulty
  GameDifficulty _mapDifficultyToGame(AIDifficulty aiDifficulty) {
    switch (aiDifficulty) {
      case AIDifficulty.beginner:
        return GameDifficulty.easy;
      case AIDifficulty.intermediate:
        return GameDifficulty.normal;
      case AIDifficulty.advanced:
        return GameDifficulty.genius;
      case AIDifficulty.expert:
        return GameDifficulty.quantum;
    }
  }

  /// Determine grade level based on difficulty
  GradeLevel _determineGradeLevel(AIDifficulty difficultyLevel) {
    switch (difficultyLevel) {
      case AIDifficulty.beginner:
        return GradeLevel.grade1;
      case AIDifficulty.intermediate:
        return GradeLevel.grade3;
      case AIDifficulty.advanced:
        return GradeLevel.grade6;
      case AIDifficulty.expert:
        return GradeLevel.grade9;
    }
  }

  /// Get time limit for difficulty
  int _getTimeLimit(AIDifficulty difficultyLevel) {
    switch (difficultyLevel) {
      case AIDifficulty.beginner:
        return 60;
      case AIDifficulty.intermediate:
        return 45;
      case AIDifficulty.advanced:
        return 30;
      case AIDifficulty.expert:
        return 20;
    }
  }

  /// Calculate complexity score
  double _calculateComplexity(AIDifficulty difficultyLevel) {
    switch (difficultyLevel) {
      case AIDifficulty.beginner:
        return 0.3;
      case AIDifficulty.intermediate:
        return 0.5;
      case AIDifficulty.advanced:
        return 0.7;
      case AIDifficulty.expert:
        return 0.9;
    }
  }

  /// Get learning objectives
  List<String> _getLearningObjectives(
    AIDifficulty difficultyLevel,
    GameCategory category,
  ) {
    final objectives = <String>[];

    switch (difficultyLevel) {
      case AIDifficulty.beginner:
        objectives.addAll([
          'Master basic mathematical concepts',
          'Develop problem-solving strategies',
          'Build confidence in mathematical thinking',
        ]);
        break;
      case AIDifficulty.intermediate:
        objectives.addAll([
          'Apply mathematical concepts to real problems',
          'Develop analytical thinking skills',
          'Improve problem-solving efficiency',
        ]);
        break;
      case AIDifficulty.advanced:
        objectives.addAll([
          'Master advanced mathematical concepts',
          'Develop sophisticated problem-solving strategies',
          'Build mathematical intuition and insight',
        ]);
        break;
      case AIDifficulty.expert:
        objectives.addAll([
          'Achieve mathematical mastery',
          'Develop genius-level problem-solving skills',
          'Create innovative mathematical solutions',
        ]);
        break;
    }

    return objectives;
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  /// Analyze student performance using ChatGPT
  Future<Map<String, dynamic>> analyzePerformance({
    required List<Map<String, dynamic>> answers,
    required AIDifficulty difficultyLevel,
    required String userId,
  }) async {
    try {
      if (!_config.isEnabled || !_config.hasApiKey) {
        return {
          'analysis': 'ChatGPT analysis disabled',
          'recommendations': ['Continue practicing'],
          'strengths': [],
          'weaknesses': [],
        };
      }

      final prompt = _buildAnalysisPrompt(answers, difficultyLevel, userId);
      final response = await _callChatGPT(prompt);

      return {
        'analysis': response['analysis'] ?? 'No analysis available',
        'recommendations':
            response['recommendations'] ?? ['Continue practicing'],
        'strengths': response['strengths'] ?? [],
        'weaknesses': response['weaknesses'] ?? [],
        'difficultyLevel': difficultyLevel.name,
        'userId': userId,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChatGPT: Error analyzing performance: $e');
      }
      return {
        'analysis': 'Analysis failed',
        'recommendations': ['Continue practicing'],
        'strengths': [],
        'weaknesses': [],
      };
    }
  }

  /// Build analysis prompt
  String _buildAnalysisPrompt(
    List<Map<String, dynamic>> answers,
    AIDifficulty difficultyLevel,
    String userId,
  ) {
    final answerData = answers
        .map(
          (a) => {
            'question': a['question'],
            'userAnswer': a['userAnswer'],
            'correctAnswer': a['correctAnswer'],
            'timeSpent': a['timeSpent'],
            'isCorrect': a['isCorrect'],
          },
        )
        .toList();

    return '''
Analyze the following student performance data and provide insights:

STUDENT ID: $userId
DIFFICULTY LEVEL: ${difficultyLevel.name.toUpperCase()}
ANSWERS: ${jsonEncode(answerData)}

Please provide analysis in JSON format:
{
  "analysis": "Detailed analysis of student performance",
  "recommendations": ["recommendation1", "recommendation2"],
  "nextSteps": ["step1", "step2"],
  "confidence": 0.85
}

Focus on:
1. Strengths and weaknesses
2. Learning patterns
3. Areas for improvement
4. Recommended next actions
''';
  }

  /// Generate personalized hints using ChatGPT
  Future<String> generatePersonalizedHint({
    required String question,
    required String userAnswer,
    required bool isCorrect,
    required AIDifficulty difficultyLevel,
  }) async {
    try {
      final prompt =
          '''
Generate a personalized hint for this student:

QUESTION: $question
STUDENT ANSWER: $userAnswer
CORRECT: $isCorrect
DIFFICULTY: ${difficultyLevel.name}

Provide a helpful, encouraging hint that guides the student toward the correct solution.
Keep it concise and educational.
''';

      final response = await _callChatGPT(prompt);
      return response['hint'] ?? 'Think about this step by step.';
    } catch (e) {
      if (kDebugMode) {
        print('ChatGPT: Error generating hint: $e');
      }
      return 'Take your time and think carefully about this problem.';
    }
  }
}

/// Riverpod providers for ChatGPT service
final chatGPTServiceProvider = Provider<ChatGPTService>((ref) {
  // In production, this should be loaded from environment variables
  const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  return ChatGPTService(apiKey, http.Client(), ref.read(chatGPTConfigProvider));
});

final chatGPTQuestionsProvider =
    FutureProvider.family<List<AIQuestion>, Map<String, dynamic>>((
      ref,
      params,
    ) {
      return ref
          .read(chatGPTServiceProvider)
          .generateAIQuestions(
            difficultyLevel: params['difficultyLevel'] as AIDifficulty,
            category: params['category'] as GameCategory,
            count: params['count'] as int,
            userId: params['userId'] as String?,
            userContext: params['userContext'] as Map<String, dynamic>?,
          );
    });

final chatGPTAnalysisProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      params,
    ) {
      return ref
          .read(chatGPTServiceProvider)
          .analyzePerformance(
            answers: params['answers'] as List<Map<String, dynamic>>,
            difficultyLevel: params['difficultyLevel'] as AIDifficulty,
            userId: params['userId'] as String,
          );
    });
