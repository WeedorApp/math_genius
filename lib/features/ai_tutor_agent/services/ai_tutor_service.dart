import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:math';

// Models
import '../models/tutor_model.dart';

/// AI Tutor Service for Math Genius
class AITutorService {
  static const String _tutorSessionsKey = 'tutor_sessions';
  static const String _tutorContextsKey = 'tutor_contexts';
  static const String _aiHintsKey = 'ai_hints';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final FlutterTts _tts;

  AITutorService(this._prefs, this._hiveBox) : _tts = FlutterTts();

  /// Initialize voice interface
  Future<void> initializeVoiceInterface() async {
    try {
      // Initialize TTS
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // STT temporarily disabled
      if (kDebugMode) {
        print('Speech-to-text temporarily disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing voice interface: $e');
      }
    }
  }

  /// Create a new tutor session
  Future<TutorSession> createTutorSession(String studentId, int grade) async {
    try {
      // Get or create tutor context
      final context =
          await getTutorContext(studentId) ??
          TutorContext(
            studentId: studentId,
            grade: grade,
            lastSession: DateTime.now(),
          );

      final session = TutorSession(
        id: _generateId(),
        studentId: studentId,
        context: context,
        startTime: DateTime.now(),
      );

      await _saveTutorSession(session);
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating tutor session: $e');
      }
      rethrow;
    }
  }

  /// Get tutor context for a student
  Future<TutorContext?> getTutorContext(String studentId) async {
    try {
      final contextsString = _prefs.getString(_tutorContextsKey);
      if (contextsString == null) return null;

      final contextsMap = jsonDecode(contextsString) as Map<String, dynamic>;
      final contextData = contextsMap[studentId];
      if (contextData == null) return null;

      return TutorContext.fromJson(contextData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tutor context: $e');
      }
      return null;
    }
  }

  /// Save tutor context
  Future<void> saveTutorContext(TutorContext context) async {
    try {
      final contextsString = _prefs.getString(_tutorContextsKey);
      final contextsMap = contextsString != null
          ? Map<String, dynamic>.from(jsonDecode(contextsString))
          : <String, dynamic>{};

      contextsMap[context.studentId] = context.toJson();

      await _prefs.setString(_tutorContextsKey, jsonEncode(contextsMap));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving tutor context: $e');
      }
    }
  }

  /// Generate AI hint for a question
  Future<AIHint> generateHint(
    String question,
    String topic,
    int difficulty,
  ) async {
    try {
      // This would integrate with TFLite for local AI processing
      // For now, we'll use rule-based hint generation
      final hint = await _generateRuleBasedHint(question, topic, difficulty);

      final aiHint = AIHint(
        id: _generateId(),
        question: question,
        hint: hint.hint,
        steps: hint.steps,
        explanation: hint.explanation,
        topic: topic,
        difficulty: difficulty,
      );

      await _cacheAIHint(aiHint);
      return aiHint;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating AI hint: $e');
      }
      rethrow;
    }
  }

  /// Send message to tutor
  Future<TutorMessage> sendMessage(
    String sessionId,
    String content,
    bool isFromTutor, {
    TutorMode? mode,
    String? topic,
  }) async {
    try {
      final session = await getTutorSession(sessionId);
      if (session == null) throw Exception('Session not found');

      final message = TutorMessage(
        id: _generateId(),
        content: content,
        isFromTutor: isFromTutor,
        timestamp: DateTime.now(),
        mode: mode,
        topic: topic,
      );

      final updatedMessages = List<TutorMessage>.from(session.messages);
      updatedMessages.add(message);

      final updatedSession = session.copyWith(messages: updatedMessages);
      await _saveTutorSession(updatedSession);

      return message;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      rethrow;
    }
  }

  /// Generate AI response based on student input
  Future<TutorMessage> generateAIResponse(
    String sessionId,
    String studentInput,
  ) async {
    try {
      final session = await getTutorSession(sessionId);
      if (session == null) throw Exception('Session not found');

      // Analyze student input and generate appropriate response
      final response = await _analyzeAndRespond(studentInput, session);

      return await sendMessage(
        sessionId,
        response,
        true,
        mode: session.currentMode,
        topic: session.currentTopic,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error generating AI response: $e');
      }
      rethrow;
    }
  }

  /// Speak text using TTS
  Future<void> speakText(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('Error speaking text: $e');
      }
    }
  }

  /// Listen for speech input
  Future<String?> listenForSpeech() async {
    // STT temporarily disabled
    if (kDebugMode) {
      print('Speech-to-text temporarily disabled');
    }
    return null;
  }

  /// Get tutor session by ID
  Future<TutorSession?> getTutorSession(String sessionId) async {
    try {
      final sessions = await getAllTutorSessions();
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tutor session: $e');
      }
      return null;
    }
  }

  /// Get all tutor sessions
  Future<List<TutorSession>> getAllTutorSessions() async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final sessionsData = _hiveBox.get(_tutorSessionsKey);
        if (sessionsData != null) {
          final sessionsList = jsonDecode(sessionsData as String) as List;
          return sessionsList
              .map(
                (session) =>
                    TutorSession.fromJson(session as Map<String, dynamic>),
              )
              .toList();
        }
      }

      // Fallback to SharedPreferences
      final sessionsString = _prefs.getString(_tutorSessionsKey);
      if (sessionsString == null) return [];

      final sessionsList = jsonDecode(sessionsString) as List;
      return sessionsList
          .map(
            (session) => TutorSession.fromJson(session as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all tutor sessions: $e');
      }
      return [];
    }
  }

  /// End tutor session
  Future<TutorSession?> endTutorSession(String sessionId) async {
    try {
      final session = await getTutorSession(sessionId);
      if (session == null) return null;

      final updatedSession = session.copyWith(
        endTime: DateTime.now(),
        isActive: false,
      );

      await _saveTutorSession(updatedSession);

      // Update tutor context
      final context = session.context.copyWith(
        lastSession: DateTime.now(),
        totalSessions: session.context.totalSessions + 1,
      );
      await saveTutorContext(context);

      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error ending tutor session: $e');
      }
      return null;
    }
  }

  /// Generate rule-based hint (placeholder for TFLite integration)
  Future<({String hint, List<String> steps, String explanation})>
  _generateRuleBasedHint(String question, String topic, int difficulty) async {
    // Simple rule-based hint generation
    // In a real implementation, this would use TFLite models

    String hint = '';
    List<String> steps = [];
    String explanation = '';

    if (topic.toLowerCase().contains('addition')) {
      hint = 'Try breaking down the numbers into smaller parts.';
      steps = [
        '1. Break down the first number',
        '2. Break down the second number',
        '3. Add the parts together',
        '4. Combine the results',
      ];
      explanation =
          'Addition is about combining quantities. Breaking numbers into smaller parts can make it easier to add them.';
    } else if (topic.toLowerCase().contains('multiplication')) {
      hint = 'Think of multiplication as repeated addition.';
      steps = [
        '1. Identify the two numbers to multiply',
        '2. Think of the first number as groups',
        '3. Each group has the second number of items',
        '4. Count all items together',
      ];
      explanation =
          'Multiplication is a shortcut for repeated addition. For example, 3 × 4 means 3 groups of 4 items each.';
    } else if (topic.toLowerCase().contains('algebra')) {
      hint = 'Try to isolate the variable on one side of the equation.';
      steps = [
        '1. Identify the variable you need to solve for',
        '2. Move all terms with the variable to one side',
        '3. Move all other terms to the other side',
        '4. Simplify and solve',
      ];
      explanation =
          'In algebra, we solve for unknown values by isolating them on one side of the equation.';
    } else {
      hint = 'Take it step by step and don\'t rush.';
      steps = [
        '1. Read the problem carefully',
        '2. Identify what you need to find',
        '3. Choose the right method',
        '4. Solve step by step',
        '5. Check your answer',
      ];
      explanation =
          'Math problems are easier when you break them down into smaller steps.';
    }

    return (hint: hint, steps: steps, explanation: explanation);
  }

  /// Analyze student input and generate response
  Future<String> _analyzeAndRespond(String input, TutorSession session) async {
    final inputLower = input.toLowerCase();

    // Simple response generation based on keywords
    if (inputLower.contains('help') || inputLower.contains('stuck')) {
      return 'I\'m here to help! What specific part are you having trouble with?';
    } else if (inputLower.contains('hint')) {
      return 'Let me give you a hint: Try breaking the problem into smaller steps.';
    } else if (inputLower.contains('explain')) {
      return 'I\'d be happy to explain! Which concept would you like me to clarify?';
    } else if (inputLower.contains('practice')) {
      return 'Great idea! Let\'s practice with some similar problems.';
    } else if (inputLower.contains('thank')) {
      return 'You\'re welcome! Keep up the great work!';
    } else if (inputLower.contains('bye') || inputLower.contains('goodbye')) {
      return 'Goodbye! Remember, practice makes perfect. Come back anytime!';
    } else {
      // Generate contextual response based on session state
      return _generateContextualResponse(input, session);
    }
  }

  /// Generate contextual response
  String _generateContextualResponse(String input, TutorSession session) {
    final context = session.context;

    if (context.mood == TutorMood.encouraging) {
      return 'That\'s a great question! Let\'s work through it together.';
    } else if (context.mood == TutorMood.challenging) {
      return 'Interesting approach! Let\'s see if we can find an even better way.';
    } else if (context.mood == TutorMood.celebratory) {
      return 'Excellent thinking! You\'re really getting the hang of this!';
    } else {
      return 'I understand. Let\'s break this down step by step.';
    }
  }

  /// Cache AI hint
  Future<void> _cacheAIHint(AIHint hint) async {
    try {
      final hints = await _getCachedAIHints();
      hints.add(hint);

      final hintsJson = jsonEncode(hints.map((h) => h.toJson()).toList());

      // Save to both Hive and SharedPreferences
      if (_hiveBox != null) {
        await _hiveBox.put(_aiHintsKey, hintsJson);
      }
      await _prefs.setString(_aiHintsKey, hintsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching AI hint: $e');
      }
    }
  }

  /// Get cached AI hints
  Future<List<AIHint>> _getCachedAIHints() async {
    try {
      final hintsString = _prefs.getString(_aiHintsKey);
      if (hintsString == null) return [];

      final hintsList = jsonDecode(hintsString) as List;
      return hintsList
          .map((hint) => AIHint.fromJson(hint as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached AI hints: $e');
      }
      return [];
    }
  }

  /// Save tutor session
  Future<void> _saveTutorSession(TutorSession session) async {
    try {
      final sessions = await getAllTutorSessions();
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);

      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      final sessionsJson = jsonEncode(sessions.map((s) => s.toJson()).toList());

      // Save to both Hive and SharedPreferences
      if (_hiveBox != null) {
        await _hiveBox.put(_tutorSessionsKey, sessionsJson);
      }
      await _prefs.setString(_tutorSessionsKey, sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving tutor session: $e');
      }
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}

/// Riverpod providers for AI tutor management
final aiTutorServiceProvider = Provider<AITutorService>((ref) {
  throw UnimplementedError('AITutorService must be initialized');
});

final tutorSessionsProvider = FutureProvider<List<TutorSession>>((ref) async {
  final aiTutorService = ref.read(aiTutorServiceProvider);
  return aiTutorService.getAllTutorSessions();
});

final tutorSessionProvider = FutureProvider.family<TutorSession?, String>((
  ref,
  sessionId,
) async {
  final aiTutorService = ref.read(aiTutorServiceProvider);
  return aiTutorService.getTutorSession(sessionId);
});

final tutorContextProvider = FutureProvider.family<TutorContext?, String>((
  ref,
  studentId,
) async {
  final aiTutorService = ref.read(aiTutorServiceProvider);
  return aiTutorService.getTutorContext(studentId);
});
